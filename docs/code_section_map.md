# Code Section Map / 代码分段说明

## Photovoltaic Case / 光伏算例

File:

```text
matlab/photovoltaic_case.m
```

| Section | Code title | 中文说明 |
|---|---|---|
| 0 | Per-unit base-value settings | 代码第 0 部分。 |
| 1 | Construct the system admittance matrix Y | 代码第 1 部分。 |
| 2 | PV capacity settings | 代码第 2 部分。 |
| 3 | PV control-type settings | 代码第 3 部分。 |
| 4 | Admittance-matrix partitioning | 代码第 4 部分。 |
| 5 | Construct the equivalent admittance matrix Yeq | 代码第 5 部分。 |
| 6 | Detailed-model PV control parameters | 代码第 6 部分。 |
| 7 | Detailed-model tripping-iteration parameters | 代码第 7 部分。 |
| 8 | Equivalent PV parameters | 代码第 8 部分。 |
| 9 | Sweep the PCC voltage | 代码第 9 部分。 |
| 9.1 | Common-voltage intermediate model and branch-mismatch analysis variables | 代码第 9.1 部分。 |
| 9.2 | Admissible-Law-Approximation Error approximation variables | 代码第 9.2 部分。 |
| 10 | fsolve solver settings | 代码第 10 部分。 |
| 11 | Solve the detailed model, equivalent model, and common-voltage model | 代码第 11 部分。 |
| 12 | Sort by voltage in ascending order | 代码第 12 部分。 |
| 13 | Current conversion | 代码第 13 部分。 |
| 15 | Plotting | 代码第 15 部分。 |
| 15.1 | Aggregation error decomposition | 代码第 15.1 部分。 |
| 15.4 | CaseII-Comparison of PCC current among the detailed model, equivalent model, EMT, and EMTeq | 代码第 15.4 部分。 |
| 16 | Save results to the workspace | 代码第 16 部分。 |

## Wind Farm Case / 风电场算例

File:

```text
matlab/wind_farm_case.m
```

| Section | Code title | 中文说明 |
|---|---|---|
| 0 | Per-unit base values | 代码第 0 部分。 |
| 1 | Construct the admittance matrix | 代码第 1 部分。 |
| 2 | Wind-turbine/PV capacity | 代码第 2 部分。 |
| 3 | Control type | 代码第 3 部分。 |
| 4 | Admittance-matrix partitioning | 代码第 4 部分。 |
| 5 | Equivalent admittance matrix Yeq | 代码第 5 部分。 |
| 6 | Detailed-model control parameters | 代码第 6 部分。 |
| 7 | Tripping-iteration parameters | 代码第 7 部分。 |
| 8 | Equivalent-model parameters | 代码第 8 部分。 |
| 9 | Sweep the PCC voltage | 代码第 9 部分。 |
| 10 | fsolve settings | 代码第 10 部分。 |
| 11 | Solve the detailed model, equivalent model, and common-voltage model | 代码第 11 部分。 |
| 12 | Sort by voltage in ascending order | 代码第 12 部分。 |
| 13 | Current conversion | 代码第 13 部分。 |
| 13.1 | d/q decomposition error | 代码第 13.1 部分。 |
| 14 | Vp = 1 atvoltage | 代码第 14 部分。 |
| 15 | Plotting | 代码第 15 部分。 |
| 15.1 | Aggregation error decomposition | 代码第 15.1 部分。 |
| 15.2 | Norm of the equivalent-side branch-adaptive propagation operator | 代码第 15.2 部分。 |
| 15.3 | d/q decomposition error of delta_{alpha,beta} | 代码第 15.3 部分。 |
| 15.4 | Case IV: comparison of PCC current among the detailed model, equivalent model, and EMT points | 代码第 15.4 部分。 |
| 15.5 | PCC current d/q components: comparison between the detailed and equivalent models | 代码第 15.5 部分。 |
| 15.6 | Terminal voltages of all wind-turbine nodes versus PCC voltage | 代码第 15.6 部分。 |
| 16 | Save results | 代码第 16 部分。 |
