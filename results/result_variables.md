# Result Variables / 结果变量说明

The MATLAB scripts save key outputs into the workspace variable `result`.

MATLAB 程序会将关键结果保存到工作区变量 `result` 中。

## Main Variables / 主要变量

| Variable | Meaning | 中文含义 |
|---|---|---|
| `result.Sbase_MVA` | System power base | 系统容量基准 |
| `result.Vbase_kV` | Voltage base | 电压基准 |
| `result.Y` | Original network admittance matrix | 原始网络导纳矩阵 |
| `result.Yeq` | Equivalent network admittance matrix | 等值网络导纳矩阵 |
| `result.s` | Device capacity vector | 设备容量向量 |
| `result.ctrlType` | Control type vector | 控制类型向量 |
| `result.Vp_abs` | PCC voltage magnitude vector | 并网点电压幅值向量 |
| `result.H` | PCC current of the original model | 原始详细模型并网点电流 |
| `result.Hc` | PCC current of the common-voltage model | 公共电压模型并网点电流 |
| `result.Heq` | PCC current of the aggregated model | 聚合等值模型并网点电流 |
| `result.ecv` | Common-Voltage-Reduction Error | 同电压压缩误差 |
| `result.eal` | Admissible-Law-Approximation Error | 允许函数类近似误差 |
| `result.etot` | Total aggregation error | 总聚合误差 |
| `result.condMI_piecewise` | Condition number of original-side sensitivity matrix | 原始侧灵敏度矩阵条件数 |
| `result.condMe_piecewise` | Condition number of equivalent-side sensitivity matrix | 等值侧灵敏度矩阵条件数 |
| `result.Kcv_piecewiseNorm` | Norm of common-voltage-reduction propagation operator | 同电压压缩传播算子范数 |
| `result.Kal_piecewiseNorm` | Norm of admissible-law-approximation propagation operator | 允许函数类近似传播算子范数 |

---

## Error Decomposition Check / 误差分解检查

The following relation should hold:

应满足以下关系：

```text
etot = ecv + eal
```

MATLAB check:

MATLAB 检查方法：

```matlab
check_error = max(abs(result.etot - (result.ecv + result.eal)));
disp(check_error);
```

If `check_error` is close to zero, the decomposition is correct.

如果 `check_error` 接近 0，说明误差分解正确。
