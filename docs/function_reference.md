# Function Reference / 函数索引

This document lists the main functions and local helper functions in the MATLAB files.

本文档列出 MATLAB 文件中的主函数和局部辅助函数。

---

## Photovoltaic Case / 光伏算例

File:

文件：

```text
matlab/photovoltaic_case.m
```

- `photovoltaic_case`: main function of the photovoltaic case / 光伏算例主函数
- `Y = build_Y_7bus(lineScale)`: constructs the nodal admittance matrix / 构造节点导纳矩阵
- `F = residual_equation_trip_iter_with_node0_in_Y(x, Vp, YIp, YII, pv, tripMask)`: defines nonlinear residual equations for fsolve / 定义 fsolve 非线性残差方程
- `[VIeq, I_PVeq, tripEq, x_sol, exitflag_final] = ...`: local helper function / 局部辅助函数
- `F = residual_equation_eq_online(x, Vp, Yeq_Ip, Yeq_II, pv_eq)`: defines nonlinear residual equations for fsolve / 定义 fsolve 非线性残差方程
- `I = fIBR_model_trip_iter(VI, pv, tripMask)`: computes IBR current injection / 计算 IBR 电流注入
- `I = single_pv_current_no_trip_gate(V, s_k, type, k, pv)`: local helper function / 局部辅助函数
- `Ieq = equivalent_AB_current_no_trip_gate(Veq, Vp, pv_eq)`: local helper function / 局部辅助函数
- `[Vc, G_Vc, tripC, x_sol, exitflag_final] = ...`: local helper function / 局部辅助函数
- `F = residual_common_voltage_online(x, Vp, Yeq_Ip, Yeq_II, pv, tripC)`: defines nonlinear residual equations for fsolve / 定义 fsolve 非线性残差方程
- `G_Vc = common_voltage_current_sum_no_trip_gate(Vc, pv, tripC)`: local helper function / 局部辅助函数
- `[bcv, rI_aug] = compute_common_voltage_bias_and_residual( ...`: defines nonlinear residual equations for fsolve / 定义 fsolve 非线性残差方程
- `[ecv_consistent_approx, ecv_branch_approx, mI_aug, rI_alpha_aug, condM, ...`: local helper function / 局部辅助函数
- `[eal_consistent_approx, eal_func_approx, delta_ab, me_beta, condMe, ...`: local helper function / 局部辅助函数
- `branchID = classify_all_branches(Vpv, pv, tripMask)`: local helper function / 局部辅助函数
- `bid = classify_single_branch(V, s_k, type, k, pv, isTrip)`: local helper function / 局部辅助函数
- `branchID = classify_equiv_branch(V, Vp, pv_eq, isTrip)`: local helper function / 局部辅助函数
- `Iinj_aug = forced_injection_aug(U, pv, branchID)`: local helper function / 局部辅助函数
- `I = single_pv_current_forced_branch(V, s_k, type, k, pv, branchID)`: local helper function / 局部辅助函数
- `Ieq = equivalent_current_forced_branch(V, Vp, pv_eq, branchID)`: local helper function / 局部辅助函数
- `Jreal = numerical_jacobian_forced_injection(U0, pv, branchID)`: local helper function / 局部辅助函数
- `Jreal = numerical_jacobian_equiv_forced_branch(V0, Vp, pv_eq, branchID)`: local helper function / 局部辅助函数
- `Ar = complex_matrix_to_real(A)`: local helper function / 局部辅助函数
- `v_pu = pv_voltage_control_pu(V_complex_pu, Vbase_kV, Vctrl_base_kV)`: local helper function / 局部辅助函数
- `[vL, vtrip, vblock] = get_threshold_by_type(type, pv)`: local helper function / 局部辅助函数
- `u = project_current_limit(u0, Imax, priority)`: applies current-limiting logic / 应用电流限幅逻辑

---

## Wind Farm Case / 风电场算例

File:

文件：

```text
matlab/wind_farm_case.m
```

- `wind_farm_case`: main function of the wind farm case / 风电场算例主函数
- `Y = build_Y_7bus(lineScale)`: constructs the nodal admittance matrix / 构造节点导纳矩阵
- `F = residual_equation_trip_iter_with_node0_in_Y(x, Vp, YIp, YII, pv, tripMask)`: defines nonlinear residual equations for fsolve / 定义 fsolve 非线性残差方程
- `[VIeq, I_PVeq, tripEq, x_sol, exitflag_final] = ...`: local helper function / 局部辅助函数
- `F = residual_equation_eq_online(x, Vp, Yeq_Ip, Yeq_II, pv_eq)`: defines nonlinear residual equations for fsolve / 定义 fsolve 非线性残差方程
- `I = fIBR_model_trip_iter(VI, pv, tripMask)`: computes IBR current injection / 计算 IBR 电流注入
- `I = single_pv_current_no_trip_gate(V, s_k, type, k, pv)`: local helper function / 局部辅助函数
- `Ieq = equivalent_AB_current_no_trip_gate(Veq, Vp, pv_eq)`: local helper function / 局部辅助函数
- `[Vc, G_Vc, tripC, x_sol, exitflag_final] = ...`: local helper function / 局部辅助函数
- `F = residual_common_voltage_online(x, Vp, Yeq_Ip, Yeq_II, pv, tripC)`: defines nonlinear residual equations for fsolve / 定义 fsolve 非线性残差方程
- `G_Vc = common_voltage_current_sum_no_trip_gate(Vc, pv, tripC)`: local helper function / 局部辅助函数
- `[bcv, rI_aug] = compute_common_voltage_bias_and_residual( ...`: defines nonlinear residual equations for fsolve / 定义 fsolve 非线性残差方程
- `[ecv_consistent_approx, ecv_branch_approx, mI_aug, rI_alpha_aug, ...`: local helper function / 局部辅助函数
- `[eal_consistent_approx, eal_func_approx, delta_ab, me_beta, ...`: local helper function / 局部辅助函数
- `branchID = classify_all_branches(Vpv, pv, tripMask)`: local helper function / 局部辅助函数
- `bid = classify_single_branch(V, s_k, type, k, pv, isTrip)`: local helper function / 局部辅助函数
- `Iinj_aug = forced_injection_aug(U, pv, branchID)`: local helper function / 局部辅助函数
- `I = single_pv_current_forced_branch(V, s_k, type, k, pv, branchID)`: local helper function / 局部辅助函数
- `branchID = classify_equiv_branch(V, Vp, pv_eq, isTrip)`: local helper function / 局部辅助函数
- `Ieq = equivalent_current_forced_branch(V, Vp, pv_eq, branchID)`: local helper function / 局部辅助函数
- `Jreal = numerical_jacobian_forced_injection(U0, pv, branchID)`: local helper function / 局部辅助函数
- `Jreal = numerical_jacobian_equiv_forced_branch(V0, Vp, pv_eq, branchID)`: local helper function / 局部辅助函数
- `Ar = complex_matrix_to_real(A)`: local helper function / 局部辅助函数
- `v_pu = pv_voltage_control_pu(V_complex_pu, Vbase_kV, Vctrl_base_kV)`: local helper function / 局部辅助函数
- `[vL, vtrip, vblock] = get_threshold_by_type(type, pv)`: local helper function / 局部辅助函数
- `u = project_current_limit(u0, Imax, priority)`: applies current-limiting logic / 应用电流限幅逻辑

---

## Notes / 说明

Most helper functions are local functions placed at the end of each main `.m` file.

大多数辅助函数都作为局部函数放在主 `.m` 文件末尾。

Therefore, users usually only need to run the main functions:

因此，用户通常只需要运行主函数：

```matlab
photovoltaic_case
wind_farm_case
```
