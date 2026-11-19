* PRIVATE DERIVATIVE 2026-10-22: extra local-margin stopping criterion only.
* Independent Stata/Mata implementation. This is NOT the official ppmlhdfe.
* Exact pair-block elimination, normal-equation CG, full-predictor line search.
* No Python estimates, fitted values, penalties, or altered outcomes are inputs.
mata:
mata set matastrict on
mata set matalnum on
class OilSystem {
    real colvector p,e,i,t,op,oe,oi,mu,root,s0,tc,sv,scale
    real matrix ip,ie,ii,x
    real rowvector xs
    real scalar np,ne,ni,n,total,trend,withx,last_iter,last_error
    void setup()
    real matrix gs()
    void weights()
    real colvector pair_project()
    real colvector pair_residual()
    real colvector z()
    real colvector matvec()
    real colvector rmatvec()
    real colvector normal()
    real colvector solve_score()
    real scalar score()
}
real matrix OilSystem::gs(real matrix v, real scalar which)
{
    if (which==1) return(panelsum(v[op,.],ip))
    if (which==2) return(panelsum(v[oe,.],ie))
    return(panelsum(v[oi,.],ii))
}
void OilSystem::setup(real scalar hastrend)
{
    p=st_data(. ,"__op_p");e=st_data(. ,"__op_e");i=st_data(. ,"__op_i")
    t=(st_data(. ,"year"):-2012)/12
    x=st_data(. ,tokens("meanpd5_post pri5_post trendpd5_post distance_post2022 dependence_post trend_dependence_post"))
    n=rows(p);np=max(p);ne=max(e);ni=max(i);trend=hastrend;withx=1
    op=order(p,1);oe=order(e,1);oi=order(i,1)
    ip=panelsetup(p[op],1);ie=panelsetup(e[oe],1);ii=panelsetup(i[oi],1)
    xs=sqrt(quadcolsum((x:-mean(x)):^2)/n)
    assert(min(xs)>0);x=x:/xs
}
void OilSystem::weights(real colvector w)
{
    real colvector anchor,ids,idx,dt,mt,nn
    real scalar g,j
    mu=w;root=sqrt(mu);s0=gs(mu,1)
    assert(min(s0)>0)
    anchor=J(np,1,.)
    for (g=1;g<=np;g++) {
        ids=op[|ip[g,1]\ip[g,2]|]
        idx=selectindex(mu[ids]:==max(mu[ids]));j=idx[1]
        anchor[g]=t[ids[j]]
    }
    dt=t-anchor[p];mt=gs(mu:*dt,1):/s0;tc=dt-mt[p]
    sv=gs(mu:*tc:^2,1);sv=rowmax((sv,J(np,1,1e-290)))
    nn=gs(mu,2)\gs(mu,3)
    if (withx) nn=nn\quadcolsum(mu:*x:^2)'
    scale=1:/sqrt(rowmax((nn,J(rows(nn),1,1e-290))))
}
real colvector OilSystem::pair_project(real colvector v)
{
    real colvector a,b,out
    a=gs(root:*v,1):/s0;out=v-root:*a[p]
    if (trend) {
        b=gs(root:*tc:*v,1):/sv
        out=out-root:*tc:*b[p]
    }
    return(out)
}
real colvector OilSystem::pair_residual(real colvector v)
{
    real colvector a,b,out
    a=gs(mu:*v,1):/s0;out=v-a[p]
    if (trend) {
        b=gs(mu:*tc:*v,1):/sv
        out=out-tc:*b[p]
    }
    return(out)
}
real colvector OilSystem::z(real colvector c)
{
    real colvector out
    out=c[e]+c[ne:+i]
    if (withx) out=out+x*c[|ne+ni+1\ne+ni+6|]
    return(out)
}
real colvector OilSystem::matvec(real colvector c)
{
    return(pair_project(root:*z(c:*scale)))
}
real colvector OilSystem::rmatvec(real colvector v)
{
    real colvector w,out
    w=root:*pair_project(v);out=gs(w,2)\gs(w,3)
    if (withx) out=out\quadcross(x,w)
    return(out:*scale)
}
real colvector OilSystem::normal(real colvector c)
{
    return(rmatvec(matvec(c)))
}
real colvector OilSystem::solve_score(real colvector resid,real scalar tol)
{
    real colvector a,b,rr,g,q,r,d,ad
    real scalar rho,newrho,den,alpha,k,target
    a=gs(resid,1):/s0;rr=resid-mu:*a[p]
    if (trend) {
        b=gs(resid:*tc,1):/sv
        rr=rr-mu:*tc:*b[p]
    }
    g=gs(rr,2)\gs(rr,3)
    if (withx) g=g\quadcross(x,rr)
    g=g:*scale
    q=J(rows(g),1,0);r=g;d=r;rho=quadcross(r,r)
    target=max((1e-14,tol*sqrt(rho)))
    last_iter=0
    if (sqrt(rho)<=target) {
        last_error=sqrt(rho)
        return(q)
    }
    for (k=1;k<=14000;k++) {
        ad=normal(d);den=quadcross(d,ad)
        if (den<=0 | missing(den)) {
            last_error=sqrt(quadcross(g-normal(q),g-normal(q)))
            printf("CG_NONPOSITIVE k=%g residual=%g\n",k,last_error)
            _error(430)
        }
        alpha=rho/den;q=q+alpha*d;r=r-alpha*ad
        newrho=quadcross(r,r);last_iter=k
        if (sqrt(newrho)<=target) break
        d=r+(newrho/rho)*d;rho=newrho
    }
    last_error=sqrt(quadcross(g-normal(q),g-normal(q)))
    if (k>14000) {
        printf("CG_ITERATION_LIMIT residual=%g\n",last_error)
        _error(430)
    }
    return(q:*scale)
}
real scalar OilSystem::score(real colvector resid)
{
    real scalar err
    err=max(abs(gs(resid,1)\gs(resid,2)\gs(resid,3)\quadcross(x,resid)))
    if (trend) err=max((err,max(abs(gs(resid:*t,1)))))
    return(err/total)
}
real scalar oil_objective(real colvector eta,real colvector y)
{
    if (hasmissing(eta) | max(eta)>700) return(.)
    return(quadsum(exp(eta)-y:*eta))
}
void oil_fit(real scalar hastrend,real scalar maxiter,string scalar iterfile)
{
    class OilSystem scalar S
    real colvector y,eta,mu,beta,c,other,resid,a,b,step,trial,coef,se
    real matrix xr,H,Hi,clusters,V,results
    real scalar it,j,alpha,gd,old,newval,err,db,bt,converged,orth,sp_orth,f,localerr
    real colvector margin_p,margin_e,margin_i
    S=OilSystem();S.setup(hastrend)
    y=st_data(. ,"tradevalue")/1e9;S.total=quadsum(y)
    beta=J(6,1,0)
    eta=ln((S.gs(y,1):/S.gs(J(S.n,1,1),1))[S.p])
    margin_p=S.gs(y,1);margin_e=S.gs(y,2);margin_i=S.gs(y,3)
    assert(min(margin_p)>0 & min(margin_e)>0 & min(margin_i)>0)
    converged=0
    f=fopen(iterfile,"w")
    fput(f,"iteration,objective,step_fraction,score_relative,max_beta_step,CG_iterations,CG_residual,min_eta,max_eta,local_margin_relative_error")
    printf("COLD_START_MATA N=%g pairs=%g trend=%g\n",S.n,S.np,hastrend)
    for (it=1;it<=maxiter;it++) {
        mu=exp(eta);S.weights(mu)
        c=S.solve_score(y-mu,2e-11);other=S.z(c)
        resid=y-mu-mu:*other
        a=S.gs(resid,1):/S.s0;step=other+a[S.p]
        if (hastrend) {
            b=S.gs(resid:*S.tc,1):/S.sv
            step=step+S.tc:*b[S.p]
        }
        old=oil_objective(eta,y);gd=quadcross(mu-y,step)
        assert(gd<=1e-9*S.total)
        alpha=min((1,30/max((30,max(abs(step))))))
        for (bt=0;bt<70;bt++) {
            trial=eta+alpha*step;newval=oil_objective(trial,y)
            if (!missing(newval) & newval<=old+1e-4*alpha*gd+2e-12*S.total) break
            alpha=alpha/2
        }
        if (bt>=70) {
            fclose(f)
            _error(430)
        }
        eta=trial;beta=beta+alpha*c[|S.ne+S.ni+1\S.ne+S.ni+6|]
        err=S.score(y-exp(eta));db=max(abs(alpha*c[|S.ne+S.ni+1\S.ne+S.ni+6|]:/(S.xs')))
        printf("MATA_ITER %g obj=%21.13g alpha=%g score=%g beta_step=%g CG=%g mineta=%g btrend=%g\n",it,newval,alpha,err,db,S.last_iter,min(eta),beta[3]/S.xs[3])
        localerr=max(abs(S.gs(y-exp(eta),1)):/margin_p \ abs(S.gs(y-exp(eta),2)):/margin_e \ abs(S.gs(y-exp(eta),3)):/margin_i)
        printf("LOCAL_MARGIN_ERROR %g\n",localerr)
        fput(f,invtokens(strofreal((it,newval,alpha,err,db,S.last_iter,S.last_error,min(eta),max(eta),localerr),"%24.16g"),","))
        if (err<1e-9 & db<1e-6 & abs(old-newval)/S.total<1e-10 & localerr<1e-8) {
            converged=1
            break
        }
    }
    fclose(f)
    st_numscalar("op_local_margin_error",localerr)
    st_numscalar("op_converged",converged)
    if (!converged) _error(430)
    mu=exp(eta);assert(!hasmissing(eta));assert(all(select(mu,y:>0):>0))
    S.withx=0;S.weights(mu);xr=J(S.n,6,.)
    for (j=1;j<=6;j++) {
        c=S.solve_score(mu:*S.x[,j],2e-12)
        xr[,j]=S.pair_residual(S.x[,j]-S.z(c))
        printf("MATA_INFERENCE term=%g CG=%g residual=%g\n",j,S.last_iter,S.last_error)
    }
    H=quadcross(xr,mu,xr);Hi=invsym(H);assert(all(diagonal(Hi):>0))
    printf("MATA_COV H=%gx%g Hi=%gx%g xs=%gx%g\n",rows(H),cols(H),rows(Hi),cols(Hi),rows(S.xs),cols(S.xs))
    clusters=S.gs((y-mu):*xr,1)
    printf("MATA_COV cluster_scores=%gx%g\n",rows(clusters),cols(clusters))
    V=diag(1:/S.xs')*Hi*quadcross(clusters,clusters)*Hi*diag(1:/S.xs')*(S.np/(S.np-1))
    printf("MATA_COV V=%gx%g\n",rows(V),cols(V))
    printf("MATA_COV beta=%gx%g\n",rows(beta),cols(beta))
    coef=beta:/(S.xs')
    printf("MATA_OUTPUT coef=%gx%g\n",rows(coef),cols(coef))
    se=sqrt(diagonal(V))
    printf("MATA_OUTPUT se=%gx%g\n",rows(se),cols(se))
    assert(!hasmissing(V));assert(min(se)>0)
    st_matrix("op_B",coef');st_matrix("op_V",V)
    printf("MATA_OUTPUT matrices_saved\n")
    results=(coef,se,2*normal(-abs(coef:/se)),coef-1.95996398454*se,coef+1.95996398454*se)
    printf("MATA_OUTPUT result_table_saved\n")
    st_matrix("op_results",results)
    printf("MATA_OUTPUT observations=%g eta=%gx%g mu=%gx%g indices=%g,%g\n",st_nobs(),rows(eta),cols(eta),rows(mu),cols(mu),st_varindex("op_eta"),st_varindex("op_mu"))
    st_store((1::S.n),st_varindex("op_eta"),eta:+ln(1e9))
    st_store((1::S.n),st_varindex("op_mu"),mu:*1e9)
    st_numscalar("op_N",S.n);st_numscalar("op_pairs",S.np);st_numscalar("op_iterations",it)
    st_numscalar("op_score",S.score(y-mu));st_numscalar("op_objective",oil_objective(eta,y))
    orth=0;sp_orth=0
    for (j=1;j<=6;j++) {
        orth=max((orth,max(abs(S.gs(mu:*xr[,j],1)\S.gs(mu:*xr[,j],2)\S.gs(mu:*xr[,j],3)))/S.total))
        if (hastrend) sp_orth=max((sp_orth,max(abs(S.gs(mu:*S.t:*xr[,j],1)))/S.total))
    }
    st_numscalar("op_orth",orth);st_numscalar("op_slope_orth",sp_orth)
    assert(orth<1e-8 & sp_orth<1e-8)
    printf("MATA_COMPLETED converged=1 score=%g orth=%g slope_orth=%g\n",S.score(y-mu),orth,sp_orth)
}
end

capture program drop oil_sparse_ppml
program define oil_sparse_ppml,eclass
    version 17
    syntax , TREND(integer) [MAXIter(integer 120)]
    tempvar sample
    tempfile iterfile
    gen byte `sample'=1
    mata: oil_fit(`trend',`maxiter',st_local("iterfile"))
    copy "`iterfile'" "iterations.csv",replace
    matrix colnames op_B=meanpd5_post pri5_post trendpd5_post distance_post2022 dependence_post trend_dependence_post
    matrix colnames op_V=meanpd5_post pri5_post trendpd5_post distance_post2022 dependence_post trend_dependence_post
    matrix rownames op_V=meanpd5_post pri5_post trendpd5_post distance_post2022 dependence_post trend_dependence_post
    ereturn post op_B op_V,esample(`sample') obs(`=scalar(op_N)')
    ereturn scalar converged=scalar(op_converged)
    ereturn scalar N_clust=scalar(op_pairs)
    ereturn scalar ic=scalar(op_iterations)
    ereturn scalar score_relative=scalar(op_score)
    ereturn scalar local_margin_relative_error=scalar(op_local_margin_error)
    ereturn scalar FE_orthogonality=scalar(op_orth)
    ereturn scalar slope_orthogonality=scalar(op_slope_orth)
    ereturn local cmd "oil_sparse_ppml"
    ereturn local title "Independent Stata/Mata PPML numerical verification"
    ereturn local vce "cluster"
    ereturn local clustvar "pair_id"
    ereturn display
end
