# Data Folder / 数据文件夹

This folder contains the key parameters extracted from the paper:

**LVRT Aggregability of IBR Clusters: Conditions and Errors**

本文件夹整理了论文中的主要算例参数，用于补齐开源仓库中的 `data/` 文件夹。

## Error-Term Terminology / 误差项术语

The data files use the following updated error-term names:

本文件夹统一采用以下更新后的误差项名称：

| Symbol | English name | 中文名称 | Meaning |
|---|---|---|---|
| `ecv` | Common-Voltage-Reduction Error | 同电压压缩误差 | Error component associated with reducing the detailed multi-terminal model to a common-voltage representation |
| `eal` | Admissible-Law-Approximation Error | 允许函数类近似误差 | Error component associated with approximating the aggregated response within the admissible equivalent law class |
| `e` | Total aggregation error | 总聚合误差 | Total difference between the detailed model and the aggregated equivalent model |

Accordingly, the RMS columns are named `RMS_abs_ecv` and `RMS_abs_eal`.

因此，RMS 误差列统一命名为 `RMS_abs_ecv` 和 `RMS_abs_eal`。

## Files / 文件说明

| File | Description | 中文说明 |
|---|---|---|
| `case_study_summary.csv` | Summary of Cases I-a, I-b, II, III, and IV, including total error, ecv, and eal RMS values | 五个算例的网络条件、控制异质性、聚合结果，以及总误差、同电压压缩误差和允许函数类近似误差的 RMS 数值 |
| `pv_benchmark_control_parameters.csv` | Control parameters of the six-PV benchmark | 六光伏算例的控制参数 |
| `wind_farm_caseiv_control_parameters.csv` | Control parameters of the two turbine types in Case IV | Case IV 两类风机的控制参数 |
| `global_settings_and_voltage_levels.csv` | System base, PCC voltage sweep levels, and error-term definitions | 系统基准容量、并网点电压扫描点和误差项定义 |
| `code_case_mapping.csv` | Mapping between MATLAB files and paper cases, including updated error-term convention | MATLAB 程序与论文算例的对应关系，并说明更新后的误差项命名 |

## Main Extracted Parameters / 主要提取参数

### PV benchmark / 光伏算例

- Case I-a: `Imax = 1.0`, `voff = 0.4`
- Case I-b: `Imax = 1.0`, `voff = 0.4`
- Case II:
  - CP group: `Imax = 1.0`, `voff = 0.4`
  - CC group: `Imax = 1.1`, `voff = 0.3`
  - Related error term: `eal`, Admissible-Law-Approximation Error / 允许函数类近似误差
- Case III:
  - `Imax = 1.0`, `voff = 0.4`
  - Related error term: `ecv`, Common-Voltage-Reduction Error / 同电压压缩误差

### Wind farm Case IV / 风电场算例 Case IV

- Type-A turbines: `kq = 2.7`, `Imax = 1.1`, `voff = 0.4`, indices `1,3,5,6,7,9,11,12`
- Type-B turbines: `kq = 2.2`, `Imax = 1.0`, `voff = 0.3`, indices `2,4,8,10`
- Case IV may contain both `ecv` and `eal` components.

Case IV 可能同时包含 `ecv` 同电压压缩误差和 `eal` 允许函数类近似误差。

## Source / 来源

All parameters are extracted from Tables I–III and Section VI of the paper. The error-term names in this data folder follow the updated repository terminology.

所有参数均来自论文第 VI 节以及表 I、表 II、表 III。本数据文件夹中的误差项名称采用更新后的仓库术语。
