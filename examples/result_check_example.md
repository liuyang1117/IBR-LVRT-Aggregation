# Result Check Example / 结果检查示例

## Purpose / 目的

This example shows how to check key output variables after running a MATLAB case.

本示例说明运行 MATLAB 算例后如何检查关键输出变量。

---

## 1. Check Whether `result` Exists / 检查 `result` 是否存在

```matlab
exist('result', 'var')
```

If the output is `1`, the `result` variable exists.

如果输出为 `1`，说明 `result` 变量存在。

---

## 2. Show Available Fields / 查看结果字段

```matlab
fieldnames(result)
```

Typical fields include:

典型字段包括：

```matlab
Vp_abs
H
Hc
Heq
ecv
eal
etot
condMI_piecewise
condMe_piecewise
Kcv_piecewiseNorm
Kal_piecewiseNorm
```

---

## 3. Check Error Decomposition / 检查误差分解

Theoretically:

理论上：

```text
etot = ecv + eal
```

In MATLAB:

在 MATLAB 中：

```matlab
check_error = max(abs(result.etot - (result.ecv + result.eal)));
disp(check_error);
```

If `check_error` is close to zero, the error decomposition is correct.

如果 `check_error` 接近 0，说明误差分解关系正确。

---

## 4. Plot Error Terms Manually / 手动画误差项

```matlab
figure;
plot(result.Vp_abs, abs(result.etot), 'LineWidth', 1.5);
hold on;
plot(result.Vp_abs, abs(result.ecv), '--', 'LineWidth', 1.5);
plot(result.Vp_abs, abs(result.eal), ':', 'LineWidth', 1.5);
grid on;

xlabel('|V_p| (p.u.)');
ylabel('Current Error (p.u.)');
legend('|e|', '|e_{cv}|', '|e_{al}|');
```

This figure compares the total aggregation error, Common-Voltage-Reduction Error, and Admissible-Law-Approximation Error.

该图用于比较总聚合误差、同电压压缩误差和允许函数类近似误差。

---

## 5. Check Dominant Error Source / 判断主导误差来源

```matlab
rms_ecv = sqrt(mean(abs(result.ecv).^2));
rms_eal = sqrt(mean(abs(result.eal).^2));

fprintf('RMS |e_cv| = %.6e\n', rms_ecv);
fprintf('RMS |e_al| = %.6e\n', rms_eal);
```

Interpretation:

解释：

```text
If RMS |e_cv| > RMS |e_al|, common-voltage reduction dominates.
If RMS |e_al| > RMS |e_cv|, admissible-law approximation dominates.
```

```text
如果 RMS |e_cv| 更大，说明同电压压缩误差占主导。
如果 RMS |e_al| 更大，说明允许函数类近似误差占主导。
```
