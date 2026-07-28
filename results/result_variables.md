# Result Variables / 结果变量说明

The scripts generate numerical variables in the MATLAB workspace.

程序会在 MATLAB 工作区生成数值变量。

Common variables include:

常见变量包括：

| Variable | Meaning | 中文含义 |
|---|---|---|
| `Ip_plot` | Original PCC current | 原始模型并网点电流 |
| `Ipeq_plot` | Equivalent PCC current | 等值模型并网点电流 |
| `Hc_plot` | Common-voltage PCC current | 公共电压模型并网点电流 |
| `ecv_plot` | Common-voltage / Common-Voltage-Reduction Error | 同电压压缩误差 |
| `eal_plot` | Aggregation-law / Admissible-Law-Approximation Error | 允许函数类近似误差 |
| `etot_plot` | Total aggregation error | 总聚合误差 |
| `ecv_piecewise_approx_plot` | Branch-adaptive approximation of `ecv` | `ecv` 的分支自适应近似 |
| `eal_piecewise_approx_plot` | Branch-adaptive approximation of `eal` | `eal` 的分支自适应近似 |
| `Kvd_piecewiseNorm_plot` | Original-side propagation-operator norm | 原始侧传播算子范数 |
| `Kfs_piecewiseNorm_plot` | Equivalent-side propagation-operator norm | 等值侧传播算子范数 |
