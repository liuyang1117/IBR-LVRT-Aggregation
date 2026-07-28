# Photovoltaic Case Example / 光伏算例示例

```matlab
clear; clc; close all;
addpath('matlab');
photovoltaic_case;
```

Updated key settings:

更新后的关键设置：

```matlab
s = [2;4;2;4;2;2];
ctrlType = [1;1;1;2;2;2];
```

The updated code uses `ecv` for Common-Voltage-Reduction Error and `eal` for Admissible-Law-Approximation Error; their approximations are denoted by `^ecv` and `^eal` in the descriptions.

更新后的代码使用 `ecv` 表示同电压压缩误差，使用 `eal` 表示允许函数类近似误差；说明中用 `^ecv` 和 `^eal` 表示对应近似值。
