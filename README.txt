全球原油贸易 PPML 论文复现资料｜2026-11-16

从冻结数据和已归档的结果起步。数据以出口国 ex、进口国 im、年份 year 为唯一键，附录模型的支持标记按这三个字段与冻结面板合并。估计使用 Stata/MP 18（脚本语法版本 17）和随包提供的程序版本；各运行脚本列明容差。严格国家对趋势使用 Python 3.12 的自定义稀疏求解程序。Python 依赖见 strict_refinement/requirements-python.txt。原始数据重新下载、投票理想点再估计和逐份原始报告再清洗不在本包范围内。

1. 主模型 M1–M3、A–D。进入 main_models 运行 Stata do run_all.do，再运行 python audit_results.py。可在资料包根目录运行 python interactions.py，从冻结的政治历史、距离及时间指标核对交互项数值。估计继续使用原来的储存精度。
2. 普通附录回归。Stata 执行 do "绝对路径/appendix_models/run_all.do" "绝对路径/appendix_models" "绝对路径/appendix_models/data/regression_panel.dta"，再从该子目录执行 do post_estimation.do，最后运行 python audit_results.py。该模块包含年度模型、端点、窗口、投票门槛、净重、原始投票、主要国家剔除等 80 个规格。随包提供已核验的三批估计；顺序全跑可能耗时较长。
3. 缺报及角色筛选。Stata 执行 do "绝对路径/reporting_checks/run_all.do" "绝对路径/reporting_checks"。本轮日志覆盖基准和八个筛选规格。python reporting_checks/recheck_supports.py 使用冻结候选数据和事前缺报规则，重新生成两组角色样本并对照八组最终观测键。same_sample_audit.json 记录模型 D 复算数值及同键下结果变量、回归量和固定效应编码的一致性。事前覆盖和冲击后覆盖均以主模型 D 的记录贸易额为分母。
4. 历史伪冲击、供应商重要性与 Wald 检验。进入 new_checks，执行 Stata do run_all.do，之后运行 python audit_results.py 和 python reproduce_scales.py。复核等权国家对统计与供应商分位数请从包根目录运行 python summary_statistics/reproduce_summaries.py。
5. 缺报口径及物量数据。Stata 执行 do "绝对路径/source_checks/run_all.do" "绝对路径/source_checks" actual，再执行对应子目录的 python audit_results.py。镜像出口对照在 strict_pair_trends 中执行 do run_mirror.do "该目录的绝对路径" 及 python audit_mirror.py。
6. 严格国家对趋势。从包根目录运行 python strict_refinement/refine_strict.py 2023 --cold 和 python strict_refinement/refine_strict.py 2024 --cold，再运行 python strict_refinement/audit_refinement.py。标准 ppmlhdfe 在严格趋势规格下尚未通过全部数值检验。采用独立求解器通过本地边际、时间矩和原模型列空间核验的结果。
7. Figure 1–2。从包根目录运行 python figures/reproduce_flow_coverage.py --mother figures/flow_inputs.dta，随后运行 python figures/reproduce_figures.py（需要 matplotlib）。前者从冻结流量汇总，后者以经核验的年度系数出图。代码及附录列表保留两图的覆盖与缩放规则。投票记录计数见论文附录 A7。

建议在资料包副本中重运行，脚本会更新各自的输出文件。SHA256.json 记录发出时的各文件校验值。
