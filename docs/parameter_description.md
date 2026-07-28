# Parameter Description / 参数说明

## Base Values / 基准值

| Parameter | Meaning | 中文含义 |
|---|---|---|
| `Sbase_MVA` | System power base | 系统容量基准 |
| `Vbase_kV` | Network voltage base | 网络电压基准 |
| `Vctrl_base_kV` | Controller voltage base | 控制电压基准 |
| `Ilimit_base_ratio` | Current-limit conversion factor | 限幅基准换算系数 |
| `Ibase_kA` | Base current | 基准电流 |

## Photovoltaic Case / 光伏算例

| Parameter | Value | 中文说明 |
|---|---|---|
| `Sbase_MVA` | 100 | 系统容量基准 |
| `Vbase_kV` | 10.5 | 网络电压基准 |
| `Vctrl_base_kV` | 10.0 | 控制电压基准 |
| `s` | `[2;4;2;4;2;2]` | 光伏容量向量 |
| `ctrlType` | `[1;1;1;2;2;2]` | 1 为恒功率，2 为恒电流 |
| `pv.Imax_single_vec(ctrlType == 1)` | 1.0 | 恒功率单元限幅 |
| `pv.Imax_single_vec(ctrlType == 2)` | 1.1 | 恒电流单元限幅 |
| `pv_eq.Imax_single` | 1.05 | 等值模型限幅 |
| `pv.priority` | `q_first` | 无功优先 |

## Wind Farm Case / 风电场算例

| Parameter | Value | 中文说明 |
|---|---|---|
| `Sbase_MVA` | 100 | 系统容量基准 |
| `Vbase_kV` | 66 | 网络电压基准 |
| `s` | `[2;4;2;4;2;2;2;4;2;4;2;2]` | 风机容量向量 |
| `ctrlType` | `[1;2;1;2;1;1;1;2;1;2;1;1]` | 控制类型向量 |
| `kq_type1` | 2.7 | Type-A 无功电流支撑系数 |
| `kq_type2` | 2.2 | Type-B 无功电流支撑系数 |
| `Imax_type1` | 1.10 | Type-A 电流限幅 |
| `Imax_type2` | 1.00 | Type-B 电流限幅 |
| `pv_eq.vtrip` | 0.35 | 等值模型脱网阈值 |
| `priority` | `q_first` | 无功优先 |
