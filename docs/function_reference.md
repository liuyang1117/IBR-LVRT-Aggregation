# Function Reference / 函数索引

## photovoltaic_case.m

- `photovoltaic_case`
- `Y = build_Y_7bus(lineScale)`
- `F = residual_equation_trip_iter_with_node0_in_Y(x, Vp, YIp, YII, pv, tripMask)`
- `[VIeq, I_PVeq, tripEq, x_sol, exitflag_final] = ...`
- `F = residual_equation_eq_online(x, Vp, Yeq_Ip, Yeq_II, pv_eq)`
- `I = fIBR_model_trip_iter(VI, pv, tripMask)`
- `I = single_pv_current_no_trip_gate(V, s_k, type, k, pv)`
- `Ieq = equivalent_AB_current_no_trip_gate(Veq, Vp, pv_eq)`
- `[Vc, G_Vc, tripC, x_sol, exitflag_final] = ...`
- `F = residual_common_voltage_online(x, Vp, Yeq_Ip, Yeq_II, pv, tripC)`
- `G_Vc = common_voltage_current_sum_no_trip_gate(Vc, pv, tripC)`
- `[bcv, rI_aug] = compute_common_voltage_bias_and_residual( ...`
- `[evd_consistent_approx, evd_branch_approx, mI_aug, rI_alpha_aug, condM, ...`
- `[efs_consistent_approx, efs_func_approx, delta_ab, me_beta, condMe, ...`
- `branchID = classify_all_branches(Vpv, pv, tripMask)`
- `bid = classify_single_branch(V, s_k, type, k, pv, isTrip)`
- `branchID = classify_equiv_branch(V, Vp, pv_eq, isTrip)`
- `Iinj_aug = forced_injection_aug(U, pv, branchID)`
- `I = single_pv_current_forced_branch(V, s_k, type, k, pv, branchID)`
- `Ieq = equivalent_current_forced_branch(V, Vp, pv_eq, branchID)`
- `Jreal = numerical_jacobian_forced_injection(U0, pv, branchID)`
- `Jreal = numerical_jacobian_equiv_forced_branch(V0, Vp, pv_eq, branchID)`
- `Ar = complex_matrix_to_real(A)`
- `v_pu = pv_voltage_control_pu(V_complex_pu, Vbase_kV, Vctrl_base_kV)`
- `[vL, vtrip, vblock] = get_threshold_by_type(type, pv)`
- `u = project_current_limit(u0, Imax, priority)`

## wind_farm_case.m

- `wind_farm_case`
- `Y = build_Y_7bus(lineScale)`
- `F = residual_equation_trip_iter_with_node0_in_Y(x, Vp, YIp, YII, pv, tripMask)`
- `[VIeq, I_PVeq, tripEq, x_sol, exitflag_final] = ...`
- `F = residual_equation_eq_online(x, Vp, Yeq_Ip, Yeq_II, pv_eq)`
- `I = fIBR_model_trip_iter(VI, pv, tripMask)`
- `I = single_pv_current_no_trip_gate(V, s_k, type, k, pv)`
- `Ieq = equivalent_AB_current_no_trip_gate(Veq, Vp, pv_eq)`
- `[Vc, G_Vc, tripC, x_sol, exitflag_final] = ...`
- `F = residual_common_voltage_online(x, Vp, Yeq_Ip, Yeq_II, pv, tripC)`
- `G_Vc = common_voltage_current_sum_no_trip_gate(Vc, pv, tripC)`
- `[bcv, rI_aug] = compute_common_voltage_bias_and_residual( ...`
- `[evd_consistent_approx, evd_branch_approx, mI_aug, rI_alpha_aug, ...`
- `[efs_consistent_approx, efs_func_approx, delta_ab, me_beta, ...`
- `branchID = classify_all_branches(Vpv, pv, tripMask)`
- `bid = classify_single_branch(V, s_k, type, k, pv, isTrip)`
- `Iinj_aug = forced_injection_aug(U, pv, branchID)`
- `I = single_pv_current_forced_branch(V, s_k, type, k, pv, branchID)`
- `branchID = classify_equiv_branch(V, Vp, pv_eq, isTrip)`
- `Ieq = equivalent_current_forced_branch(V, Vp, pv_eq, branchID)`
- `Jreal = numerical_jacobian_forced_injection(U0, pv, branchID)`
- `Jreal = numerical_jacobian_equiv_forced_branch(V0, Vp, pv_eq, branchID)`
- `Ar = complex_matrix_to_real(A)`
- `v_pu = pv_voltage_control_pu(V_complex_pu, Vbase_kV, Vctrl_base_kV)`
- `[vL, vtrip, vblock] = get_threshold_by_type(type, pv)`
- `u = project_current_limit(u0, Imax, priority)`

## Notes / 说明

Most helper functions are placed as local functions at the end of each main `.m` file.

大多数辅助函数以局部函数形式放在主 `.m` 文件末尾，因此运行时只需要调用主函数即可。
