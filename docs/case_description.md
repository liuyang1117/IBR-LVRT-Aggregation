# Case Description / 算例说明

## Photovoltaic Case / 光伏算例

The photovoltaic script studies a six-unit PV benchmark connected to a 10.5 kV network.

光伏程序研究一个接入 10.5 kV 网络的六光伏单元基准算例。

Updated main settings:

更新后的主要设置：

```matlab
s = [2;4;2;4;2;2];
ctrlType = [1;1;1;2;2;2];
```

where `ctrlType = 1` denotes constant-power active-current control and `ctrlType = 2` denotes constant-current active-current control.

其中 `ctrlType = 1` 表示恒功率型有功电流控制，`ctrlType = 2` 表示恒电流型有功电流控制。

## Wind Farm Case / 风电场算例

The wind-farm script studies a twelve-unit offshore wind farm connected to a 66 kV collection network.

风电场程序研究一个接入 66 kV 集电网络的十二风机算例。

Updated main settings:

更新后的主要设置：

```matlab
s = [2;4;2;4;2;2;2;4;2;4;2;2];
ctrlType = [1;2;1;2;1;1;1;2;1;2;1;1];
```

The updated wind-farm script also includes additional figures for approximation residuals and d/q decomposition analysis.

更新后的风电场程序还增加了近似残差和 d/q 分解分析相关图像。

## CloudPSS EMT Validation / CloudPSS 电磁暂态验证

The corresponding cases are also implemented on the CloudPSS EMT platform for validation.

对应算例也在 CloudPSS 电磁暂态平台上搭建，用于验证 MATLAB 数值结果和理论分析。
