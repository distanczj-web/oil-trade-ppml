def hash_frame(frame):
    return hashlib.sha256(pd.util.hash_pandas_object(frame, index=False).to_numpy().tobytes()).hexdigest()

def prune(mask, spec):
    mask = mask.copy()
    keys = [s.split('##')[0] for s in spec.fe.split()]
    positive = d[spec.outcome].gt(0).to_numpy()
    for iteration in range(100):
        drop = np.zeros(len(d), bool)
        for key in keys:
            code = d[key].to_numpy(dtype=int)
            n = np.bincount(code[mask], minlength=code.max() + 1)
            p = np.bincount(code[mask & positive], minlength=code.max() + 1)
            drop |= mask & ((n[code] <= 1) | (p[code] == 0))
        if not drop.any():
            return mask
        stage.append(dict(model=spec.model, stage='FE_pruning', removed=int(drop.sum()), positive_removed=int((drop & positive).sum())))
        mask[drop] = False
    raise RuntimeError('Pruning failed to stabilize')

def certify(mask, spec):
    begin = time.monotonic()
    checkpoint = OUT / ('checkpoint_' + args.bundle + '_' + spec.model + '.npy')
    if checkpoint.exists():
        prior = np.load(checkpoint)
        assert len(prior) == len(mask)
        mask &= prior
    for attempt in range(60):
        mask = prune(mask, spec)
        v = d.loc[mask]
        positive = v[spec.outcome].to_numpy() > 0
        if not len(v) or not positive.any():
            raise RuntimeError('Empty supported sample: ' + spec.model)
        if 'pair_id##c.time' in spec.fe:
            bounds = v.groupby('pair_id').time.agg(['min', 'max'])
            pp = v.loc[positive].groupby('pair_id').time.agg(['count', 'first'])
            bb = bounds.join(pp)
            bb = bb[bb['count'].eq(1) & (bb['first'].eq(bb['min']) | bb['first'].eq(bb['max']))].copy()
            bb['slope'] = np.where(bb['first'].eq(bb['min']), 1.0, -1.0)
            bb['intercept'] = -bb['slope'] * bb['first']
            z = v.pair_id.map(bb.slope).fillna(0).to_numpy() * v.time.to_numpy() + v.pair_id.map(bb.intercept).fillna(0).to_numpy()
            assert np.abs(z[positive]).max(initial=0) == 0 and z.min(initial=0) >= 0
            drop = ~positive & (z > 0)
            if drop.any():
                bb.to_csv(OUT / (spec.model + '_analytic_witness_' + str(attempt) + '.csv'))
                stage.append(dict(model=spec.model, stage='analytic_pair_slope_separation', removed=int(drop.sum()), positive_removed=0))
                mask[v.index.to_numpy()[drop]] = False
                np.save(checkpoint, mask)
                print('ANALYTIC_REMOVED', spec.model, int(drop.sum()), flush=True)
                continue
        blocks = []
        for term in spec.fe.split():
            key = term.split('##')[0]
            codes, levels = pd.factorize(v[key], sort=True)
            block = sparse.csr_matrix((np.ones(len(v)), (np.arange(len(v)), codes)), shape=(len(v), len(levels)))
            blocks.append(block)
            if '##c.' in term:
                slope = term.split('##c.')[1]
                blocks.append(block.multiply(v[slope].to_numpy()[:, None]).tocsr())
        reg = v[spec.terms.split()].to_numpy(dtype=float)
        std = reg.std(axis=0)
        std = np.where(std > 1e-14, std, 1.0)
        blocks.append(sparse.csr_matrix(reg / std))
        X = sparse.hstack(blocks, format='csr')
        original_columns = X.shape[1]
        if 'pair_id##c.time' in spec.fe:
            vv = v.reset_index(drop=True)
            pp = vv.loc[positive].groupby('pair_id').time.agg(['idxmin', 'idxmax', 'count'])
            first = vv.pair_id.map(pp['idxmin']).to_numpy(dtype=int)
            last = vv.pair_id.map(pp['idxmax']).to_numpy(dtype=int)
            tt = vv.time.to_numpy(dtype=float)
            gap = tt[last] - tt[first]
            w2 = np.divide(tt - tt[first], gap, out=np.zeros(len(vv)), where=gap != 0)
            otherblocks = []
            for key in ['ex_year', 'im_year']:
                codes, levels = pd.factorize(vv[key], sort=True)
                otherblocks.append(sparse.csr_matrix((np.ones(len(vv)), (np.arange(len(vv)), codes)), shape=(len(vv), len(levels))))
            otherblocks.append(sparse.csr_matrix(reg / std))
            Z = sparse.hstack(otherblocks, format='csr')
            reduced = Z - Z[first].multiply((1 - w2)[:, None]) - Z[last].multiply(w2[:, None])
            one = vv.pair_id.map(pp['count']).eq(1).to_numpy()
            if one.any():
                codes, levels = pd.factorize(vv.loc[one, 'pair_id'], sort=True)
                slopes = sparse.csr_matrix((tt[one] - tt[first[one]], (np.flatnonzero(one), codes)), shape=(len(vv), len(levels)))
                reduced = sparse.hstack([reduced, slopes], format='csr')
            X = reduced.tocsr()
            X.eliminate_zeros()
            print('PAIR_SLOPE_NULLSPACE', spec.model, 'columns', original_columns, 'to', X.shape[1], flush=True)
        Xp, X0 = (X[positive], X[~positive])
        if X0.shape[0]:
            for method in ['highs-ipm', 'highs-ds']:
                sol = linprog(-np.asarray(X0.sum(axis=0)).ravel(), A_ub=sparse.vstack([-X0, X0], format='csr'), b_ub=np.r_[np.zeros(X0.shape[0]), np.ones(X0.shape[0])], A_eq=Xp, b_eq=np.zeros(Xp.shape[0]), bounds=(None, None), method=method, options={'primal_feasibility_tolerance': 1e-08, 'dual_feasibility_tolerance': 1e-08, 'ipm_optimality_tolerance': 1e-10, 'time_limit': 240, 'threads': 2})
                if sol.success:
                    break
                print('LP_SOLVER_RETRY', spec.model, method, sol.message, flush=True)
            if not sol.success:
                raise RuntimeError(spec.model + ': ' + sol.message)
            z = X @ sol.x
            poserr = float(np.abs(z[positive]).max(initial=0))
            zeromin = float(z[~positive].min(initial=0))
            if poserr > 1e-06 or zeromin < -1e-06:
                raise RuntimeError('Invalid separation certificate ' + spec.model)
            separated = ~positive & (z > 1e-07)
            objective = float(-sol.fun)
        else:
            separated = np.zeros(len(v), bool)
            objective = poserr = zeromin = 0.0
        if separated.any():
            idx = v.index.to_numpy()[separated]
            stage.append(dict(model=spec.model, stage='LP_separation', removed=len(idx), positive_removed=0, objective=objective))
            mask[idx] = False
            np.save(checkpoint, mask)
            print('LP_REMOVED', spec.model, len(idx), flush=True)
            continue
        if abs(objective) > 1e-05:
            raise RuntimeError('Nonzero objective without identified zero rows ' + spec.model)
        rec = dict(model=spec.model, N=int(mask.sum()), pairs=int(v.pair_id.nunique()), positive=int(positive.sum()), objective=objective, max_positive_residual=poserr, min_zero_certificate=zeromin, full_design_columns=original_columns, lp_parameterized_columns=X.shape[1], seconds=time.monotonic() - begin, keys_sha256=hash_frame(v[['ex', 'im', 'year']]))
        return (mask, rec)
    raise RuntimeError('Separation support did not stabilize ' + spec.model)