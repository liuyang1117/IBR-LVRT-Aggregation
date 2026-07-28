# Figure Outputs / 图像输出说明

## Photovoltaic Case / 光伏算例

The photovoltaic code saves figures according to the MATLAB figure names.

光伏程序会按照 MATLAB figure 的 `Name` 保存图像。

- `聚合误差分解`
- `并网点电流详细模型、等值模型与EMT对比`
- `并网点电流详细模型、等值模型与EMT对比`
- `并网点电流详细模型、等值模型与EMT对比`
- `并网点电流详细模型、等值模型与EMT对比`

## Wind Farm Case / 风电场算例

The updated wind-farm code contains the following figure names.

更新后的风电场程序包含以下图像名称。

- `聚合误差分解`
- `同电压压缩误差近似残差`
- `允许函数类近似误差近似残差`
- `ecv与eal近似残差对比`
- `等值侧分支自适应传播算子范数`
- `delta_ab的dq分解误差`
- `并网点电流详细模型、等值模型与EMT点对比`
- `并网点电流dq分量详细模型与等值模型对比`
- `各风机节点端电压随并网点电压变化`

Compared with the previous version, the wind-farm code adds extra plots related to the approximation residuals and d/q component analysis.

相比之前版本，风电场程序增加了与近似残差和 d/q 分量分析相关的图。


## Error figure terminology / 误差图像术语

- `ecv`: Common-Voltage-Reduction Error / 同电压压缩误差。
- `eal`: Admissible-Law-Approximation Error / 允许函数类近似误差。
- `e_cv - \hat{e}_{cv}`: residual of the Common-Voltage-Reduction Error approximation / 同电压压缩误差近似残差。
- `e_al - \hat{e}_{al}`: residual of the Admissible-Law-Approximation Error approximation / 允许函数类近似误差近似残差。

The wind-farm code contains additional figures for the approximation residuals and related error components.

风机代码新增了近似残差及相关误差分量图。
