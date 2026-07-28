# Update Notes / 更新说明

This version updates the terminology of the two aggregation-error components throughout the repository and the MATLAB code comments.

本版本对仓库文档和 MATLAB 代码注释中的两类聚合误差术语进行了统一修改。

## Updated terminology / 更新后的术语

| Symbol | Updated English name | Updated Chinese name |
|---|---|---|
| `ecv` / `e_cv` | Common-Voltage-Reduction Error | 同电压压缩误差 |
| `eal` / `e_al` | Admissible-Law-Approximation Error | 允许函数类近似误差 |

## Updated MATLAB files / 更新后的 MATLAB 文件

```text
matlab/photovoltaic_case.m  <=  photovoltaic_case(5).m
matlab/wind_farm_case.m     <=  wind_farm_case(4).m
```

Executable variable names such as `Kvd*` and `Kfs*` are kept unchanged to avoid breaking the program, while comments, labels, and documentation are updated to the new terminology.

为避免破坏程序运行，`Kvd*` 和 `Kfs*` 等可执行变量名保持不变；代码注释、图像标签和仓库文档已改为新的术语。
