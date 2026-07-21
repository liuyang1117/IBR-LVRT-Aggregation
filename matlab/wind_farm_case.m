function wind_farm_case

clc;
close all;

%% ============================================================
%  0. 标幺基准值
% ============================================================

Sbase_MVA = 100;
Vbase_kV  = 66;
Vctrl_base_kV = 66.0;

Ilimit_base_ratio = Vbase_kV / Vctrl_base_kV;

Ibase_kA = Sbase_MVA / (sqrt(3) * Vbase_kV);
Ibase_A  = Ibase_kA * 1000;

disp('================ 标幺基准值 ================');
fprintf('Sbase = %.4f MVA\n', Sbase_MVA);
fprintf('Vbase = %.4f kV\n', Vbase_kV);
fprintf('Vctrl_base = %.4f kV\n', Vctrl_base_kV);
fprintf('Ilimit_base_ratio = %.6f\n', Ilimit_base_ratio);
fprintf('Ibase = %.6f kA\n', Ibase_kA);
fprintf('Ibase = %.2f A\n', Ibase_A);

%% ============================================================
%  1. 构造导纳矩阵
% ============================================================

lineScale = 1;
Y = build_Y_7bus(lineScale);

nTotal = size(Y,1);
nPV = nTotal - 2;
nInternal = nTotal - 1;

%% ============================================================
%  2. 风机/光伏容量
% ============================================================

s = [2;4;2;4;2;2;2;4;2;4;2;2];

if length(s) ~= nPV
    error('容量向量 s 的长度必须等于光伏数量。');
end

Ssum = sum(s);
s_aug = [0; s];

disp('================ 容量信息 ================');
fprintf('s = [');
fprintf(' %.4f', s);
fprintf(' ] MW\n');
fprintf('s_aug = [');
fprintf(' %.4f', s_aug);
fprintf(' ] MW\n');
fprintf('Ssum = %.4f MW\n', Ssum);
fprintf('Ssum / Sbase = %.6f p.u.\n', Ssum / Sbase_MVA);

%% ============================================================
%  3. 控制类型
% ============================================================
% type = 1：恒功率有功电流模型
% type = 2：恒电流有功电流模型

ctrlType = [1;2;1;2;1;1;1;2;1;2;1;1];

if length(ctrlType) ~= nPV
    error('ctrlType 的长度必须等于光伏数量。');
end

%% ============================================================
%  4. 导纳矩阵分块
% ============================================================

Ypp = Y(1,1);
YpI = Y(1,2:end);
YIp = Y(2:end,1);
YII = Y(2:end,2:end);

if length(s_aug) ~= nInternal
    error('s_aug 的长度必须等于内部节点数量。');
end

%% ============================================================
%  5. 等值导纳矩阵 Yeq
% ============================================================

Yred = Ypp - YpI * (YII \ YIp);
Bmat = -YpI / YII;
Avec = -YII \ YIp;

a = s_aug.' * Avec / Ssum;
c = s_aug.' * (YII \ s_aug);
den = c / Ssum;

Yeq = [
    Yred + a * Bmat * s_aug / den,    -Bmat * s_aug / den;
    -Ssum * a / den,                  Ssum / den
];

Yeq_pp = Yeq(1,1);
Yeq_pI = Yeq(1,2);
Yeq_Ip = Yeq(2,1);
Yeq_II = Yeq(2,2);

disp('================ 等值网络参数 ================');
disp('Yred = ');
disp(Yred);
disp('A = ');
disp(Avec);
disp('B = ');
disp(Bmat);
disp('a = ');
disp(a);
disp('c = ');
disp(c);
disp('Yeq = ');
disp(Yeq);

%% ============================================================
%  6. 详细模型控制参数
% ============================================================

pv.s = s;
pv.ctrlType = ctrlType;

pv.Sbase_MVA = Sbase_MVA;
pv.Vbase_kV = Vbase_kV;
pv.Vctrl_base_kV = Vctrl_base_kV;
pv.Ilimit_base_ratio = Ilimit_base_ratio;

pv.Id0_single = 0.5;
pv.Iq0_single = 0.0;

pv.Imax_single = 1.0;
pv.Imax_single_vec = zeros(nPV,1);
pv.Imax_single_vec(ctrlType == 1) = 1.10;
pv.Imax_single_vec(ctrlType == 2) = 1.00;

pv.kq_type1 = 2.7;
pv.kq_type2 = 2.2;
pv.vLVRT = 0.90;

pv.vpre = Vbase_kV / Vctrl_base_kV;

pv.normalConstP.vmin = 0.90;
pv.normalConstP.vmax = 1.20;

pv.constP.vL     = 0.90;
pv.constP.vtrip  = 0.40;
pv.constP.vblock = 0.19;

pv.constI.vL     = 0.90;
pv.constI.vtrip  = 0.30;
pv.constI.vblock = 0.19;

pv.gateWidth = 0;
pv.priority = 'q_first';

%% ============================================================
%  7. 脱网迭代参数
% ============================================================

tripLatchAcrossVp = false;
tripMask_global = false(nPV,1);

maxTripIter = nPV + 5;
tripTol = 1e-10;

%% ============================================================
%  8. 等值模型参数
% ============================================================

idxP = (ctrlType == 1);
idxI = (ctrlType == 2);

SP = sum(s(idxP));
SI = sum(s(idxI));
Seq = Ssum;

Aeq = SP / Seq;
Beq = SI / Seq;

if abs(Aeq + Beq - 1) > 1e-10
    error('Aeq + Beq 不等于 1。');
end

pv_eq = struct();

pv_eq.Sbase_MVA = Sbase_MVA;
pv_eq.Vbase_kV = Vbase_kV;
pv_eq.Vctrl_base_kV = Vctrl_base_kV;
pv_eq.Ilimit_base_ratio = Ilimit_base_ratio;
pv_eq.Seq = Seq;

pv_eq.A = Aeq;
pv_eq.B = Beq;

pv_eq.Id0_single = 0.5;
pv_eq.Iq0_single = 0.0;

pv_eq.kq_type1 = 2.7;
pv_eq.kq_type2 = 2.2;
pv_eq.vLVRT = 0.90;

pv_eq.vpre = Vbase_kV / Vctrl_base_kV;

pv_eq.Imax_type1 = 1.10;
pv_eq.Imax_type2 = 1.00;

pv_eq.vL     = 0.90;
pv_eq.vtrip  = 0.35;
pv_eq.vblock = 0.19;

pv_eq.vp_normal_min = 0.90;
pv_eq.vp_normal_max = 1.20;
pv_eq.vp_min = 0.20;

pv_eq.gateWidth = pv.gateWidth;
pv_eq.priority  = pv.priority;

fprintf('\n================ 等值模型参数 ================\n');
fprintf('SP = %.6f MW\n', SP);
fprintf('SI = %.6f MW\n', SI);
fprintf('Seq = %.6f MW\n', Seq);
fprintf('Aeq = %.6f\n', Aeq);
fprintf('Beq = %.6f\n', Beq);
fprintf('Aeq + Beq = %.6f\n', Aeq + Beq);
fprintf('Imax_type1 = %.6f\n', pv_eq.Imax_type1);
fprintf('Imax_type2 = %.6f\n', pv_eq.Imax_type2);
fprintf('vtrip_eq = %.6f p.u.\n', pv_eq.vtrip);
fprintf('vblock_eq = %.6f p.u.\n', pv_eq.vblock);

%% ============================================================
%  9. 扫描并网点电压
% ============================================================

Vp_abs_vec = linspace(1, 0.2, 301);
theta_p = 0;

Ip_vec = zeros(size(Vp_abs_vec));
Ip_abs_vec = zeros(size(Vp_abs_vec));

V1_store = zeros(size(Vp_abs_vec));
VI_store = zeros(nPV, length(Vp_abs_vec));

Ipeq_vec = zeros(size(Vp_abs_vec));
Ipeq_abs_vec = zeros(size(Vp_abs_vec));
VIeq_store = zeros(size(Vp_abs_vec));

I_PVsum_detail_vec = zeros(size(Vp_abs_vec));
I_PVeq_vec = zeros(size(Vp_abs_vec));
eq_node_residual_vec = zeros(size(Vp_abs_vec));

tripMask_store = false(nPV, length(Vp_abs_vec));
tripIter_store = zeros(size(Vp_abs_vec));
tripEq_store = false(size(Vp_abs_vec));

%% 公共电压模型与误差分解变量

Vc_vec = zeros(size(Vp_abs_vec));
Hc_vec = zeros(size(Vp_abs_vec));
G_Vc_vec = zeros(size(Vp_abs_vec));

evd_vec = zeros(size(Vp_abs_vec));
efs_vec = zeros(size(Vp_abs_vec));
etot_vec = zeros(size(Vp_abs_vec));

bcv_vec = zeros(size(Vp_abs_vec));
rI_norm_vec = zeros(size(Vp_abs_vec));

tripC_store = false(nPV, length(Vp_abs_vec));

%% 电压分散误差相关变量

% 式(50)：一致分支电压分散误差近似
% evd_50 = bcv + YpI * inv(M_I^alpha) * rI_alpha
evd_consistent_approx_vec = zeros(size(Vp_abs_vec));

% 式(53)：不一致分支电压分散误差近似
% evd_53 = bcv + YpI * inv(M_I^alphaStar) * (rI_alpha + mI)
evd_branch_approx_vec = zeros(size(Vp_abs_vec));

% 分支自适应电压分散误差近似：
% 同一分支用式(50)，不同分支用式(53)
evd_piecewise_approx_vec = zeros(size(Vp_abs_vec));

rI_alpha_aug_store = zeros(nInternal, length(Vp_abs_vec));
mI_aug_store = zeros(nInternal, length(Vp_abs_vec));

rI_alpha_norm_vec = zeros(size(Vp_abs_vec));
mI_norm_vec = zeros(size(Vp_abs_vec));

branchMismatchCount_vec = zeros(size(Vp_abs_vec));

% 当前电压点实际采用的 e_vd 近似公式编号：50=同分支，53=异分支
evdFormulaID_vec = zeros(size(Vp_abs_vec));

condMIAlpha_vec = zeros(size(Vp_abs_vec));
condMIAlphaStar_vec = zeros(size(Vp_abs_vec));

% 分支自适应选择后的 M_I 条件数：
% 同一分支用 M_I^alpha，不同分支用 M_I^alphaStar
condMI_piecewise_vec = zeros(size(Vp_abs_vec));

% 原始侧传播算子：K_vd = Y_pI * M_I^(-1)
% 由于 K_vd 是矩阵，画图时采用其二范数 ||K_vd||_2。
KvdAlphaNorm_vec = zeros(size(Vp_abs_vec));
KvdAlphaStarNorm_vec = zeros(size(Vp_abs_vec));
Kvd_piecewiseNorm_vec = zeros(size(Vp_abs_vec));
Kvd_piecewise_real_store = cell(size(Vp_abs_vec));

branchCommon_store = zeros(nPV, length(Vp_abs_vec));
branchTrue_store   = zeros(nPV, length(Vp_abs_vec));

%% 函数结构误差相关变量

% 式(60)：一致分支函数结构误差近似
% efs_60 = -Yeq_pI * inv(M_e^beta) * delta_ab
efs_consistent_approx_vec = zeros(size(Vp_abs_vec));

% 式(63)：不一致分支函数结构误差近似
% efs_63 = -Yeq_pI * inv(M_e^betaStar) * (delta_ab + me)
efs_func_approx_vec = zeros(size(Vp_abs_vec));

% 分支自适应函数结构误差近似：
% 同一分支用式(60)，不同分支用式(63)
efs_piecewise_approx_vec = zeros(size(Vp_abs_vec));

delta_ab_vec = zeros(size(Vp_abs_vec));
me_beta_vec = zeros(size(Vp_abs_vec));

delta_ab_norm_vec = zeros(size(Vp_abs_vec));
me_norm_vec = zeros(size(Vp_abs_vec));

condMeBeta_vec = zeros(size(Vp_abs_vec));
condMeBetaStar_vec = zeros(size(Vp_abs_vec));

% 分支自适应选择后的 M_e 条件数：
% 同一分支用 M_e^beta，不同分支用 M_e^betaStar
condMe_piecewise_vec = zeros(size(Vp_abs_vec));

% 等值侧传播算子：K_fs = -Y_pe^eq * M_e^(-1)
% 由于 K_fs 是矩阵，画图时采用其二范数 ||K_fs||_2。
KfsBetaNorm_vec = zeros(size(Vp_abs_vec));
KfsBetaStarNorm_vec = zeros(size(Vp_abs_vec));
Kfs_piecewiseNorm_vec = zeros(size(Vp_abs_vec));
Kfs_piecewise_real_store = cell(size(Vp_abs_vec));

% 当前电压点实际采用的 e_fs 近似公式编号：60=同分支，63=异分支
efsFormulaID_vec = zeros(size(Vp_abs_vec));

eqBranchMismatch_vec = zeros(size(Vp_abs_vec));

branchBeta_vec = zeros(size(Vp_abs_vec));
branchBetaStar_vec = zeros(size(Vp_abs_vec));

%% ============================================================
%  10. fsolve 设置
% ============================================================

if exist('fsolve','file') ~= 2
    error('需要 Optimization Toolbox 中的 fsolve。');
end

opt = optimoptions('fsolve', ...
    'Display','off', ...
    'FunctionTolerance',1e-10, ...
    'StepTolerance',1e-10, ...
    'MaxIterations',800, ...
    'MaxFunctionEvaluations',80000);

U0 = ones(nInternal,1);
x0 = [real(U0); imag(U0)];

VIeq0 = 1 + 0j;
x0_eq = [real(VIeq0); imag(VIeq0)];

Vc0 = 1 + 0j;
x0_c = [real(Vc0); imag(Vc0)];

%% ============================================================
%  11. 求解详细模型、等值模型和公共电压模型
% ============================================================

for k = 1:length(Vp_abs_vec)

    Vp = Vp_abs_vec(k) * exp(1j*theta_p);

    %% ================= 详细模型求解 =================

    if tripLatchAcrossVp
        tripMask = tripMask_global;
    else
        tripMask = false(nPV,1);
    end

    x_sol = x0;

    for tripIter = 1:maxTripIter

        tripMask_old = tripMask;

        fun = @(x) residual_equation_trip_iter_with_node0_in_Y( ...
            x, Vp, YIp, YII, pv, tripMask);

        [x_sol, ~, exitflag] = fsolve(fun, x0, opt);

        if exitflag <= 0
            warning('详细模型：Vp = %.4f，脱网迭代 %d 可能未收敛。', ...
                Vp_abs_vec(k), tripIter);
        end

        U = x_sol(1:nInternal) + 1j*x_sol(nInternal+1:end);
        V1 = U(1);
        VI = U(2:end);

        for ii = 1:nPV

            if ~tripMask(ii)

                type_i = pv.ctrlType(ii);
                [~, vtrip_i, ~] = get_threshold_by_type(type_i, pv);

                v_ctrl_i = pv_voltage_control_pu(VI(ii), pv.Vbase_kV, pv.Vctrl_base_kV);

                if v_ctrl_i <= vtrip_i + tripTol
                    tripMask(ii) = true;
                end

            end

        end

        if isequal(tripMask, tripMask_old)
            break;
        end

        x0 = x_sol;

    end

    if tripIter >= maxTripIter
        warning('详细模型：Vp = %.4f 达到最大脱网迭代次数。', Vp_abs_vec(k));
    end

    if tripLatchAcrossVp
        tripMask_global = tripMask;
    end

    U = x_sol(1:nInternal) + 1j*x_sol(nInternal+1:end);
    V1 = U(1);
    VI = U(2:end);

    I_PV_detail_vec = fIBR_model_trip_iter(VI, pv, tripMask);
    I_PVsum_detail = sum(I_PV_detail_vec);

    H = -(Ypp * Vp + YpI * U);

    Ip_vec(k) = H;
    Ip_abs_vec(k) = abs(H);

    V1_store(k) = V1;
    VI_store(:,k) = VI;

    I_PVsum_detail_vec(k) = I_PVsum_detail;

    tripMask_store(:,k) = tripMask;
    tripIter_store(k) = tripIter;

    x0 = x_sol;

    %% ================= 等值模型求解 =================

    [VIeq, I_PVeq, tripEq, x_eq, exitflag_eq] = ...
        solve_eq_with_trip_iteration( ...
            Vp, ...
            Vp_abs_vec(k), ...
            Yeq_Ip, ...
            Yeq_II, ...
            pv_eq, ...
            x0_eq, ...
            opt ...
        );

    if exitflag_eq <= 0
        warning('等值模型：Vp = %.4f 可能未收敛。', Vp_abs_vec(k));
    end

    Heq = -(Yeq_pp * Vp + Yeq_pI * VIeq);

    eq_node_residual = Yeq_Ip * Vp + Yeq_II * VIeq - I_PVeq;

    I_PVeq_vec(k) = I_PVeq;
    VIeq_store(k) = VIeq;

    Ipeq_vec(k) = Heq;
    Ipeq_abs_vec(k) = abs(Heq);
    eq_node_residual_vec(k) = eq_node_residual;

    tripEq_store(k) = tripEq;

    x0_eq = x_eq;

    %% ================= 公共电压中间模型求解 =================

    [Vc, G_Vc, tripC, x_c, exitflag_c] = ...
        solve_common_voltage_with_trip_iteration( ...
            Vp, ...
            Vp_abs_vec(k), ...
            Yeq_Ip, ...
            Yeq_II, ...
            pv, ...
            x0_c, ...
            opt ...
        );

    if exitflag_c <= 0
        warning('公共电压模型：Vp = %.4f 可能未收敛。', Vp_abs_vec(k));
    end

    Hc = -(Yeq_pp * Vp + Yeq_pI * Vc);

    evd = H - Hc;
    efs = Hc - Heq;
    etot = H - Heq;

    [bcv, rI_aug] = compute_common_voltage_bias_and_residual( ...
        Vp, ...
        Vc, ...
        Ypp, ...
        YpI, ...
        YIp, ...
        YII, ...
        Yeq_pp, ...
        Yeq_pI, ...
        pv, ...
        tripC ...
    );

    %% ================= 电压分散误差式(50)/(53)近似 =================

    [evd_consistent_approx, evd_branch_approx, mI_aug, rI_alpha_aug, ...
        condMIAlpha, condMIAlphaStar, ...
        branchMismatchCount, branchCommon, branchTrue, ...
        KvdAlpha_real, KvdAlphaStar_real] = ...
        compute_inconsistent_branch_approx( ...
            Vp, ...
            Vc, ...
            U, ...
            VI, ...
            tripMask, ...
            tripC, ...
            YpI, ...
            YIp, ...
            YII, ...
            bcv, ...
            pv ...
        );

    %% ================= 函数结构误差式(60)/(63)近似 =================

    [efs_consistent_approx, efs_func_approx, delta_ab, me_beta, ...
        condMeBeta, condMeBetaStar, ...
        eqBranchMismatch, branchBeta, branchBetaStar, ...
        KfsBeta_real, KfsBetaStar_real] = ...
        compute_function_structure_approx( ...
            Vp, ...
            Vc, ...
            VIeq, ...
            tripEq, ...
            Yeq_pI, ...
            Yeq_II, ...
            pv, ...
            pv_eq, ...
            branchCommon, ...
            tripC ...
        );

    %% ================= 存储结果 =================

    Vc_vec(k) = Vc;
    Hc_vec(k) = Hc;
    G_Vc_vec(k) = G_Vc;

    evd_vec(k) = evd;
    efs_vec(k) = efs;
    etot_vec(k) = etot;

    bcv_vec(k) = bcv;
    rI_norm_vec(k) = norm(rI_aug);

    tripC_store(:,k) = tripC;

    evd_consistent_approx_vec(k) = evd_consistent_approx;
    evd_branch_approx_vec(k) = evd_branch_approx;

    % 分支自适应选择：同一分支用式(50)，不同分支用式(53)
    if branchMismatchCount == 0
        % 同一分支：式(50)
        % e_vd ≈ b_cv + Y_pI (M_I^alpha)^(-1) r_I^alpha
        evd_piecewise_approx_vec(k) = evd_consistent_approx;
        evdFormulaID_vec(k) = 50;
    else
        % 不同分支：式(53)
        % e_vd ≈ b_cv + Y_pI (M_I^alphaStar)^(-1)
        %                    (r_I^alpha + m_I^{alpha->alphaStar})
        evd_piecewise_approx_vec(k) = evd_branch_approx;
        evdFormulaID_vec(k) = 53;
    end

    rI_alpha_aug_store(:,k) = rI_alpha_aug;
    mI_aug_store(:,k) = mI_aug;

    rI_alpha_norm_vec(k) = norm(rI_alpha_aug);
    mI_norm_vec(k) = norm(mI_aug);

    branchMismatchCount_vec(k) = branchMismatchCount;

    condMIAlpha_vec(k) = condMIAlpha;
    condMIAlphaStar_vec(k) = condMIAlphaStar;

    % M_I 条件数分支自适应选择：
    % branchMismatchCount = 0 时使用 M_I^alpha
    % branchMismatchCount > 0 时使用 M_I^alphaStar
    if branchMismatchCount == 0
        condMI_piecewise_vec(k) = condMIAlpha;
    else
        condMI_piecewise_vec(k) = condMIAlphaStar;
    end

    % 融合原始侧传播算子 Y_pI M_I^(-1)
    KvdAlphaNorm_vec(k) = norm(KvdAlpha_real, 2);
    KvdAlphaStarNorm_vec(k) = norm(KvdAlphaStar_real, 2);

    if branchMismatchCount == 0
        Kvd_piecewise_real_store{k} = KvdAlpha_real;
        Kvd_piecewiseNorm_vec(k) = KvdAlphaNorm_vec(k);
    else
        Kvd_piecewise_real_store{k} = KvdAlphaStar_real;
        Kvd_piecewiseNorm_vec(k) = KvdAlphaStarNorm_vec(k);
    end

    branchCommon_store(:,k) = branchCommon;
    branchTrue_store(:,k) = branchTrue;

    efs_consistent_approx_vec(k) = efs_consistent_approx;
    efs_func_approx_vec(k) = efs_func_approx;

    % 分支自适应选择：同一分支用式(60)，不同分支用式(63)
    if eqBranchMismatch == 0
        efs_piecewise_approx_vec(k) = efs_consistent_approx;
        efsFormulaID_vec(k) = 60;
    else
        efs_piecewise_approx_vec(k) = efs_func_approx;
        efsFormulaID_vec(k) = 63;
    end

    delta_ab_vec(k) = delta_ab;
    me_beta_vec(k) = me_beta;

    delta_ab_norm_vec(k) = abs(delta_ab);
    me_norm_vec(k) = abs(me_beta);

    condMeBeta_vec(k) = condMeBeta;
    condMeBetaStar_vec(k) = condMeBetaStar;

    % M_e 条件数分支自适应选择：
    % eqBranchMismatch = 0 时使用 M_e^beta
    % eqBranchMismatch = 1 时使用 M_e^betaStar
    if eqBranchMismatch == 0
        condMe_piecewise_vec(k) = condMeBeta;
    else
        condMe_piecewise_vec(k) = condMeBetaStar;
    end

    % 融合等值侧传播算子 -Y_pe^eq M_e^(-1)
    KfsBetaNorm_vec(k) = norm(KfsBeta_real, 2);
    KfsBetaStarNorm_vec(k) = norm(KfsBetaStar_real, 2);

    if eqBranchMismatch == 0
        Kfs_piecewise_real_store{k} = KfsBeta_real;
        Kfs_piecewiseNorm_vec(k) = KfsBetaNorm_vec(k);
    else
        Kfs_piecewise_real_store{k} = KfsBetaStar_real;
        Kfs_piecewiseNorm_vec(k) = KfsBetaStarNorm_vec(k);
    end

    eqBranchMismatch_vec(k) = eqBranchMismatch;

    branchBeta_vec(k) = branchBeta;
    branchBetaStar_vec(k) = branchBetaStar;

    x0_c = x_c;

end

%% ============================================================
%  12. 按电压从小到大排序
% ============================================================

[Vp_plot, idxPlot] = sort(Vp_abs_vec);

Ip_plot = Ip_vec(idxPlot);
Ip_abs_plot = Ip_abs_vec(idxPlot);

V1_plot = V1_store(idxPlot);
VI_plot = VI_store(:, idxPlot);

Ipeq_plot = Ipeq_vec(idxPlot);
Ipeq_abs_plot = Ipeq_abs_vec(idxPlot);
VIeq_plot = VIeq_store(idxPlot);

I_PVsum_detail_plot = I_PVsum_detail_vec(idxPlot);
I_PVeq_plot = I_PVeq_vec(idxPlot);
eq_node_residual_plot = eq_node_residual_vec(idxPlot);

tripMask_plot = tripMask_store(:, idxPlot);
tripCount_plot = sum(tripMask_plot, 1);
tripIter_plot = tripIter_store(idxPlot);
tripEq_plot = tripEq_store(idxPlot);

Vc_plot = Vc_vec(idxPlot);
Hc_plot = Hc_vec(idxPlot);
G_Vc_plot = G_Vc_vec(idxPlot);

evd_plot = evd_vec(idxPlot);
efs_plot = efs_vec(idxPlot);
etot_plot = etot_vec(idxPlot);

bcv_plot = bcv_vec(idxPlot);
rI_norm_plot = rI_norm_vec(idxPlot);

tripC_plot = tripC_store(:, idxPlot);
tripC_count_plot = sum(tripC_plot, 1);

evd_consistent_approx_plot = evd_consistent_approx_vec(idxPlot);
evd_branch_approx_plot = evd_branch_approx_vec(idxPlot);
evd_piecewise_approx_plot = evd_piecewise_approx_vec(idxPlot);

rI_alpha_aug_plot = rI_alpha_aug_store(:, idxPlot);
mI_aug_plot = mI_aug_store(:, idxPlot);

rI_alpha_norm_plot = rI_alpha_norm_vec(idxPlot);
mI_norm_plot = mI_norm_vec(idxPlot);

branchMismatchCount_plot = branchMismatchCount_vec(idxPlot);
evdFormulaID_plot = evdFormulaID_vec(idxPlot);

condMIAlpha_plot = condMIAlpha_vec(idxPlot);
condMIAlphaStar_plot = condMIAlphaStar_vec(idxPlot);
condMI_piecewise_plot = condMI_piecewise_vec(idxPlot);

KvdAlphaNorm_plot = KvdAlphaNorm_vec(idxPlot);
KvdAlphaStarNorm_plot = KvdAlphaStarNorm_vec(idxPlot);
Kvd_piecewiseNorm_plot = Kvd_piecewiseNorm_vec(idxPlot);
Kvd_piecewise_real_plot = Kvd_piecewise_real_store(idxPlot);

% 兼容旧变量名：默认使用实际分支自适应选择后的条件数
condM_plot = condMI_piecewise_plot;

branchCommon_plot = branchCommon_store(:, idxPlot);
branchTrue_plot   = branchTrue_store(:, idxPlot);

efs_consistent_approx_plot = efs_consistent_approx_vec(idxPlot);
efs_func_approx_plot = efs_func_approx_vec(idxPlot);
efs_piecewise_approx_plot = efs_piecewise_approx_vec(idxPlot);

delta_ab_plot = delta_ab_vec(idxPlot);
me_beta_plot = me_beta_vec(idxPlot);

delta_ab_norm_plot = delta_ab_norm_vec(idxPlot);
me_norm_plot = me_norm_vec(idxPlot);

condMeBeta_plot = condMeBeta_vec(idxPlot);
condMeBetaStar_plot = condMeBetaStar_vec(idxPlot);
condMe_piecewise_plot = condMe_piecewise_vec(idxPlot);

KfsBetaNorm_plot = KfsBetaNorm_vec(idxPlot);
KfsBetaStarNorm_plot = KfsBetaStarNorm_vec(idxPlot);
Kfs_piecewiseNorm_plot = Kfs_piecewiseNorm_vec(idxPlot);
Kfs_piecewise_real_plot = Kfs_piecewise_real_store(idxPlot);
efsFormulaID_plot = efsFormulaID_vec(idxPlot);

% 兼容旧变量名：默认使用实际分支自适应选择后的条件数
condMe_plot = condMe_piecewise_plot;

eqBranchMismatch_plot = eqBranchMismatch_vec(idxPlot);

branchBeta_plot = branchBeta_vec(idxPlot);
branchBetaStar_plot = branchBetaStar_vec(idxPlot);

%% ============================================================
%  13. 电流换算
% ============================================================

Vp_actual_kV = Vp_plot * Vbase_kV;
Vp_pu_from_actual = Vp_actual_kV / Vbase_kV;

Ip_line_actual_kA = Ip_abs_plot * Ibase_kA;
Ip_line_pu_from_actual = Ip_line_actual_kA / Ibase_kA;

Ipeq_line_actual_kA = Ipeq_abs_plot * Ibase_kA;
Ipeq_line_pu_from_actual = Ipeq_line_actual_kA / Ibase_kA;

Ip_3ph_actual_kA = sqrt(3) * Ip_line_actual_kA;
Ip_3ph_pu_from_actual = Ip_3ph_actual_kA / Ibase_kA;

Ipeq_3ph_actual_kA = sqrt(3) * Ipeq_line_actual_kA;
Ipeq_3ph_pu_from_actual = Ipeq_3ph_actual_kA / Ibase_kA;

I_PVsum_detail_line_pu = abs(I_PVsum_detail_plot);
I_PVsum_detail_3ph_pu = sqrt(3) * I_PVsum_detail_line_pu;

I_PVeq_line_pu = abs(I_PVeq_plot);
I_PVeq_3ph_pu = sqrt(3) * I_PVeq_line_pu;

Ip_detail_complex_3ph = sqrt(3) * Ip_plot;
Ip_equiv_complex_3ph  = sqrt(3) * Ipeq_plot;

I_PVsum_detail_complex_3ph = sqrt(3) * I_PVsum_detail_plot;
I_PVeq_complex_3ph = sqrt(3) * I_PVeq_plot;

Hc_line_pu = abs(Hc_plot);
Hc_3ph_pu = sqrt(3) * Hc_line_pu;

evd_line_pu = abs(evd_plot);
efs_line_pu = abs(efs_plot);
etot_line_pu = abs(etot_plot);

evd_3ph_pu = sqrt(3) * evd_line_pu;
efs_3ph_pu = sqrt(3) * efs_line_pu;
etot_3ph_pu = sqrt(3) * etot_line_pu;

error_decomp_check = abs((evd_plot + efs_plot) - etot_plot);
error_decomp_check_3ph_pu = sqrt(3) * error_decomp_check;

evd_consistent_approx_3ph_pu = sqrt(3) * abs(evd_consistent_approx_plot);
evd_branch_approx_3ph_pu = sqrt(3) * abs(evd_branch_approx_plot);
evd_piecewise_approx_3ph_pu = sqrt(3) * abs(evd_piecewise_approx_plot);

efs_consistent_approx_3ph_pu = sqrt(3) * abs(efs_consistent_approx_plot);
efs_func_approx_3ph_pu = sqrt(3) * abs(efs_func_approx_plot);
efs_piecewise_approx_3ph_pu = sqrt(3) * abs(efs_piecewise_approx_plot);

% 总误差分支自适应结果：结果1 + 结果2
% 结果1 = evd_piecewise_approx，结果2 = efs_piecewise_approx
etot_piecewise_approx_plot = evd_piecewise_approx_plot + efs_piecewise_approx_plot;
etot_piecewise_approx_3ph_pu = sqrt(3) * abs(etot_piecewise_approx_plot);

bcv_line_pu = abs(bcv_plot);
bcv_3ph_pu = sqrt(3) * bcv_line_pu;

%% ============================================================
%  13.1 d/q 分解误差
%  说明：本文扫描中 theta_p = 0，因此复数量实部作为 d 轴分量，虚部作为 q 轴分量。
%  e_vd、e_fs、e、b_cv、delta_{alpha,beta} 为标量复电流误差；
%  r_I^alpha 为内部节点 KCL 残差向量。
%  为避免范数导致符号丢失，这里对各内部节点 d/q 分量做代数求和，
%  即保留正负号：sum(real(r_I^alpha)) 与 sum(imag(r_I^alpha))。
% ============================================================

evd_d_3ph_pu = sqrt(3) * real(evd_plot);
evd_q_3ph_pu = sqrt(3) * imag(evd_plot);

efs_d_3ph_pu = sqrt(3) * real(efs_plot);
efs_q_3ph_pu = sqrt(3) * imag(efs_plot);

etot_d_3ph_pu = sqrt(3) * real(etot_plot);
etot_q_3ph_pu = sqrt(3) * imag(etot_plot);

bcv_d_3ph_pu = sqrt(3) * real(bcv_plot);
bcv_q_3ph_pu = sqrt(3) * imag(bcv_plot);

rI_alpha_d_3ph_pu = sqrt(3) * sum(real(rI_alpha_aug_plot), 1);
rI_alpha_q_3ph_pu = sqrt(3) * sum(imag(rI_alpha_aug_plot), 1);

delta_ab_d_3ph_pu = sqrt(3) * real(delta_ab_plot);
delta_ab_q_3ph_pu = sqrt(3) * imag(delta_ab_plot);

Ip_line_pu_theory = pv.Id0_single * Ssum / Sbase_MVA;
Ip_3ph_pu_theory  = sqrt(3) * Ip_line_pu_theory;

[~, idx1] = min(abs(Vp_plot - 1.0));

fprintf('\n================ 稳态电流校验 ================\n');
fprintf('理论线电流 Iline_pu = %.6f\n', Ip_line_pu_theory);
fprintf('理论三相电流 I3ph_pu = %.6f\n', Ip_3ph_pu_theory);
fprintf('详细模型 Vp=1 三相电流 = %.6f\n', Ip_3ph_pu_from_actual(idx1));
fprintf('公共电压模型 Vp=1 三相电流 = %.6f\n', Hc_3ph_pu(idx1));
fprintf('等值模型 Vp=1 三相电流 = %.6f\n', Ipeq_3ph_pu_from_actual(idx1));
fprintf('Vp=1 时 |evd| = %.4e\n', evd_3ph_pu(idx1));
fprintf('Vp=1 时 |efs| = %.4e\n', efs_3ph_pu(idx1));
fprintf('Vp=1 时 |etot| = %.4e\n', etot_3ph_pu(idx1));
fprintf('Vp=1 时 |evd+efs-etot| = %.4e\n', error_decomp_check_3ph_pu(idx1));
fprintf('全电压范围误差分解校验最大值 = %.4e\n', max(error_decomp_check_3ph_pu));
fprintf('Vp=1 时 |evd_50-evd| = %.4e\n', abs(evd_consistent_approx_plot(idx1) - evd_plot(idx1)));
fprintf('Vp=1 时 |evd_53-evd| = %.4e\n', abs(evd_branch_approx_plot(idx1) - evd_plot(idx1)));
fprintf('Vp=1 时 |evd_piecewise-evd| = %.4e\n', abs(evd_piecewise_approx_plot(idx1) - evd_plot(idx1)));
fprintf('Vp=1 时 |efs_60-efs| = %.4e\n', abs(efs_consistent_approx_plot(idx1) - efs_plot(idx1)));
fprintf('Vp=1 时 |efs_63-efs| = %.4e\n', abs(efs_func_approx_plot(idx1) - efs_plot(idx1)));
fprintf('Vp=1 时 |efs_piecewise-efs| = %.4e\n', abs(efs_piecewise_approx_plot(idx1) - efs_plot(idx1)));
fprintf('Vp=1 时 cond(M_I^alpha) = %.4e\n', condMIAlpha_plot(idx1));
fprintf('Vp=1 时 cond(M_I^alphaStar) = %.4e\n', condMIAlphaStar_plot(idx1));
fprintf('Vp=1 时 cond(M_I_piecewise) = %.4e\n', condMI_piecewise_plot(idx1));
fprintf('Vp=1 时 cond(M_e^beta) = %.4e\n', condMeBeta_plot(idx1));
fprintf('Vp=1 时 cond(M_e^betaStar) = %.4e\n', condMeBetaStar_plot(idx1));
fprintf('Vp=1 时 cond(M_e_piecewise) = %.4e\n', condMe_piecewise_plot(idx1));
fprintf('Vp=1 时 |b_cv|_3ph = %.4e p.u.\n', bcv_3ph_pu(idx1));
fprintf('Vp=1 时 ||Y_pI M_I^(-1)||_2（融合） = %.4e\n', Kvd_piecewiseNorm_plot(idx1));
fprintf('Vp=1 时 ||-Y_pe^eq M_e^(-1)||_2（融合） = %.4e\n', Kfs_piecewiseNorm_plot(idx1));

%% ============================================================
%  14. Vp = 1 时电压
% ============================================================

[~, idx_vp1] = min(abs(Vp_plot - 1.0));

Vp1 = Vp_plot(idx_vp1);

V1_detail_vp1 = V1_plot(idx_vp1);
V1_detail_abs_vp1 = abs(V1_detail_vp1);
V1_detail_ang_vp1 = angle(V1_detail_vp1) * 180/pi;

VI_detail_vp1 = VI_plot(:, idx_vp1);
VI_detail_abs_vp1 = abs(VI_detail_vp1);
VI_detail_ang_vp1 = angle(VI_detail_vp1) * 180/pi;

VIeq_vp1 = VIeq_plot(idx_vp1);
VIeq_abs_vp1 = abs(VIeq_vp1);
VIeq_ang_vp1 = angle(VIeq_vp1) * 180/pi;

Vc_vp1 = Vc_plot(idx_vp1);
Vc_abs_vp1 = abs(Vc_vp1);
Vc_ang_vp1 = angle(Vc_vp1) * 180/pi;

node_id = (2:(nTotal-1)).';
trip_vp1 = tripMask_plot(:, idx_vp1);

T_detail = table( ...
    node_id, ...
    real(VI_detail_vp1), ...
    imag(VI_detail_vp1), ...
    VI_detail_abs_vp1, ...
    VI_detail_ang_vp1, ...
    trip_vp1, ...
    'VariableNames', {'Node', 'Real_VI', 'Imag_VI', 'Abs_VI', 'Angle_deg', 'Trip'} ...
);

T_common = table( ...
    real(Vc_vp1), ...
    imag(Vc_vp1), ...
    Vc_abs_vp1, ...
    Vc_ang_vp1, ...
    'VariableNames', {'Real_Vc', 'Imag_Vc', 'Abs_Vc', 'Angle_deg'} ...
);

T_eq = table( ...
    real(VIeq_vp1), ...
    imag(VIeq_vp1), ...
    VIeq_abs_vp1, ...
    VIeq_ang_vp1, ...
    'VariableNames', {'Real_VIeq', 'Imag_VIeq', 'Abs_VIeq', 'Angle_deg'} ...
);

fprintf('\n================ Vp = 1 时电压 ================\n');
fprintf('Vp = %.6f p.u.\n\n', Vp1);
disp('详细模型各设备端电压：');
disp(T_detail);
disp('公共电压 Vc：');
disp(T_common);
disp('等值节点电压 Ve：');
disp(T_eq);

%% ============================================================
%  15. 画图
% ============================================================

fontName = 'Times New Roman';

axisFontSize   = 16;
labelFontSize  = 18;
legendFontSize = 12;
titleFontSize  = 10;

%% 15.1 并网点电流：详细模型、公共电压模型、等值模型
% 如需恢复该图，取消本段注释即可。
%
% figure;
% plot(Vp_pu_from_actual, Ip_3ph_pu_from_actual, 'LineWidth', 1.8);
% hold on;
% plot(Vp_pu_from_actual, Hc_3ph_pu, '--', 'LineWidth', 1.8);
% plot(Vp_pu_from_actual, Ipeq_3ph_pu_from_actual, ':', 'LineWidth', 1.8);
% grid on;
%
% xlabel('$\vert V_p\vert({\rm p.u.})$', ...
%     'Interpreter', 'latex', ...
%     'FontSize', labelFontSize);
%
% ylabel('$\vert I_p\vert({\rm p.u.})$', ...
%     'Interpreter', 'latex', ...
%     'FontSize', labelFontSize);
%
% lgd = legend( ...
%     'Original cluster model', ...
%     'Common-voltage model', ...
%     'Aggregated equivalent model', ...
%     'Location', 'northeast');
%
% set(lgd, ...
%     'FontName', fontName, ...
%     'FontSize', legendFontSize);
%
% set(gca, ...
%     'FontName', fontName, ...
%     'FontSize', axisFontSize, ...
%     'LineWidth', 1.2);
%
% set(gcf, ...
%     'Color', 'w', ...
%     'Name', '详细模型、公共电压模型与等值模型PCC电流对比', ...
%     'NumberTitle', 'off');


%% 15.2 聚合误差分解

figure;
plot(Vp_pu_from_actual, etot_3ph_pu, 'LineWidth', 1.8);
hold on;
plot(Vp_pu_from_actual, evd_3ph_pu, '--', 'LineWidth', 1.8);
plot(Vp_pu_from_actual, efs_3ph_pu, ':', 'LineWidth', 1.8);
grid on;

xlabel('$\vert V_p\vert({\rm p.u.})$', ...
    'Interpreter', 'latex', ...
    'FontSize', labelFontSize);

ylabel('Current Error (p.u.)', ...
    'FontName', fontName, ...
    'FontSize', labelFontSize);
 lgd = legend( ...
    '$\vert \mathrm{e}\vert$', ...
    '$\vert \mathrm{e}_{\rm vd}\vert$', ...
    '$\vert \mathrm{e}_{\rm fs}\vert$', ...
    'Interpreter', 'latex', ...
    'Location', 'northeast');
ylim([0, 0.35]);


set(lgd, ...
    'FontName', fontName, ...
    'FontSize', legendFontSize);

set(gca, ...
    'FontName', fontName, ...
    'FontSize', axisFontSize, ...
    'LineWidth', 1.2);
set(gcf, ...
    'Color', 'w', ...
    'Name', '聚合误差分解', ...
    'NumberTitle', 'off');


%% 15.3 电压分散误差与函数结构误差

figure;
plot(Vp_pu_from_actual, evd_3ph_pu, 'LineWidth', 1.8);
hold on;
plot(Vp_pu_from_actual, efs_3ph_pu, '--', 'LineWidth', 1.8);
grid on;

xlabel('$\vert V_p\vert({\rm p.u.})$', ...
    'Interpreter', 'latex', ...
    'FontSize', labelFontSize);

ylabel('Current Error (p.u.)', ...
    'FontName', fontName, ...
    'FontSize', labelFontSize);

lgd = legend( ...
    '$\vert \mathrm{e}_{\rm vd}\vert$', ...
    '$\vert \mathrm{e}_{\rm fs}\vert$', ...
    'Interpreter', 'latex', ...
    'Location', 'northeast');

set(lgd, ...
    'FontName', fontName, ...
    'FontSize', legendFontSize);

set(gca, ...
    'FontName', fontName, ...
    'FontSize', axisFontSize, ...
    'LineWidth', 1.2);
text(0.95, 0.05, 'B', ...
    'Units', 'normalized', ...
    'HorizontalAlignment', 'right', ...
    'VerticalAlignment', 'bottom', ...
    'FontName', 'Times New Roman', ...
    'FontSize', 16, ...
    'FontWeight', 'bold', ...
    'Color', 'k');
set(gcf, ...
    'Color', 'w', ...
    'Name', '电压分散误差与函数结构误差', ...
    'NumberTitle', 'off');


%% 15.4 误差分解校验

figure;
plot(Vp_pu_from_actual, error_decomp_check_3ph_pu, 'LineWidth', 1.8);
grid on;

xlabel('$\vert V_p\vert({\rm p.u.})$', ...
    'Interpreter', 'latex', ...
    'FontSize', labelFontSize);

ylabel('$\vert \mathrm{e}_{\rm vd}+\mathrm{e}_{\rm fs}-\mathrm{e}\vert({\rm p.u.})$', ...
    'Interpreter', 'latex', ...
    'FontSize', labelFontSize);

set(gca, ...
    'FontName', fontName, ...
    'FontSize', axisFontSize, ...
    'LineWidth', 1.2);

set(gcf, ...
    'Color', 'w', ...
    'Name', '误差分解校验', ...
    'NumberTitle', 'off');


%% 15.5 单独绘制 |evd|

figure;
plot(Vp_pu_from_actual, evd_3ph_pu, 'LineWidth', 1.8);
grid on;

xlabel('$\vert V_p\vert({\rm p.u.})$', ...
    'Interpreter', 'latex', ...
    'FontSize', labelFontSize);

ylabel('$\vert \mathrm{e}_{\rm vd}\vert({\rm p.u.})$', ...
    'Interpreter', 'latex', ...
    'FontSize', labelFontSize);

set(gca, ...
    'FontName', fontName, ...
    'FontSize', axisFontSize, ...
    'LineWidth', 1.2);

set(gcf, ...
    'Color', 'w', ...
    'Name', '|evd|', ...
    'NumberTitle', 'off');


%% 15.6 单独绘制 |efs|

figure;
plot(Vp_pu_from_actual, efs_3ph_pu, 'LineWidth', 1.8);
grid on;

xlabel('$\vert V_p\vert({\rm p.u.})$', ...
    'Interpreter', 'latex', ...
    'FontSize', labelFontSize);

ylabel('$\vert \mathrm{e}_{\rm fs}\vert({\rm p.u.})$', ...
    'Interpreter', 'latex', ...
    'FontSize', labelFontSize);

set(gca, ...
    'FontName', fontName, ...
    'FontSize', axisFontSize, ...
    'LineWidth', 1.2);

set(gcf, ...
    'Color', 'w', ...
    'Name', '|efs|', ...
    'NumberTitle', 'off');


%% 15.7 单独绘制 |etot|

figure;
plot(Vp_pu_from_actual, etot_3ph_pu, 'LineWidth', 1.8);
grid on;

xlabel('$\vert V_p\vert({\rm p.u.})$', ...
    'Interpreter', 'latex', ...
    'FontSize', labelFontSize);

ylabel('$\vert \mathrm{e}\vert({\rm p.u.})$', ...
    'Interpreter', 'latex', ...
    'FontSize', labelFontSize);

set(gca, ...
    'FontName', fontName, ...
    'FontSize', axisFontSize, ...
    'LineWidth', 1.2);

set(gcf, ...
    'Color', 'w', ...
    'Name', '|e|', ...
    'NumberTitle', 'off');


%% 15.8 |evd| 与分支自适应结果1
% 结果1：同一分支用式(50)，不同分支用式(53)

figure;
plot(Vp_pu_from_actual, evd_3ph_pu, 'LineWidth', 1.8);
hold on;
plot(Vp_pu_from_actual, evd_piecewise_approx_3ph_pu, '--', 'LineWidth', 1.8);
grid on;

xlabel('$\vert V_p\vert({\rm p.u.})$', ...
    'Interpreter', 'latex', ...
    'FontSize', labelFontSize);

ylabel('$\vert \mathrm{e}_{\rm vd}\vert({\rm p.u.})$', ...
    'Interpreter', 'latex', ...
    'FontSize', labelFontSize);

lgd = legend( ...
    '$\vert \mathrm{e}_{\rm vd}\vert$', ...
    '$\vert \hat{\mathrm{e}}_{\rm vd}\vert$', ...
    'Interpreter', 'latex', ...
    'Location', 'northeast');

set(lgd, ...
    'FontName', fontName, ...
    'FontSize', legendFontSize);

set(gca, ...
    'FontName', fontName, ...
    'FontSize', axisFontSize, ...
    'LineWidth', 1.2);

set(gcf, ...
    'Color', 'w', ...
    'Name', '|evd|与其近似', ...
    'NumberTitle', 'off');


%% 15.9 |efs| 与分支自适应结果2
% 结果2：同一分支用式(60)，不同分支用式(63)

figure;
plot(Vp_pu_from_actual, efs_3ph_pu, 'LineWidth', 1.8);
hold on;
plot(Vp_pu_from_actual, efs_piecewise_approx_3ph_pu, '--', 'LineWidth', 1.8);
grid on;

xlabel('$\vert V_p\vert({\rm p.u.})$', ...
    'Interpreter', 'latex', ...
    'FontSize', labelFontSize);

ylabel('$\vert \mathrm{e}_{\rm fs}\vert({\rm p.u.})$', ...
    'Interpreter', 'latex', ...
    'FontSize', labelFontSize);

lgd = legend( ...
    '$\vert \mathrm{e}_{\rm fs}\vert$', ...
    '$\vert \hat{\mathrm{e}}_{\rm fs}\vert$', ...
    'Interpreter', 'latex', ...
    'Location', 'northeast');

set(lgd, ...
    'FontName', fontName, ...
    'FontSize', legendFontSize);

set(gca, ...
    'FontName', fontName, ...
    'FontSize', axisFontSize, ...
    'LineWidth', 1.2);

set(gcf, ...
    'Color', 'w', ...
    'Name', '|efs|与其近似', ...
    'NumberTitle', 'off');



%% 15.10 |etot| 与结果1+结果2
% 结果1 + 结果2 = evd_piecewise_approx + efs_piecewise_approx

figure;
plot(Vp_pu_from_actual, etot_3ph_pu, 'LineWidth', 1.8);
hold on;
plot(Vp_pu_from_actual, etot_piecewise_approx_3ph_pu, '--', 'LineWidth', 1.8);
grid on;

xlabel('$\vert V_p\vert({\rm p.u.})$', ...
    'Interpreter', 'latex', ...
    'FontSize', labelFontSize);

ylabel('$\vert \mathrm{e}\vert,\vert \hat{\mathrm{e}}_{\rm vd}+\hat{\mathrm{e}}_{\rm fs}\vert({\rm p.u.})$', ...
    'Interpreter', 'latex', ...
    'FontSize', labelFontSize);

lgd = legend( ...
    '$\vert \mathrm{e}\vert$', ...
    '$\vert \hat{\mathrm{e}}_{\rm vd}+\hat{\mathrm{e}}_{\rm fs}\vert$', ...
    'Interpreter', 'latex', ...
    'Location', 'northeast');

set(lgd, ...
    'FontName', fontName, ...
    'FontSize', legendFontSize);

set(gca, ...
    'FontName', fontName, ...
    'FontSize', axisFontSize, ...
    'LineWidth', 1.2);

set(gcf, ...
    'Color', 'w', ...
    'Name', '|etot|与其近似', ...
    'NumberTitle', 'off');


%% 15.11 KCL 残差与原始侧分支切换残差

figure;
plot(Vp_pu_from_actual, rI_alpha_norm_plot, 'LineWidth', 1.8);
hold on;
plot(Vp_pu_from_actual, mI_norm_plot, '--', 'LineWidth', 1.8);
grid on;

xlabel('$\vert V_p\vert({\rm p.u.})$', ...
    'Interpreter', 'latex', ...
    'FontSize', labelFontSize);

ylabel('Residual Norm (p.u.)', ...
    'FontName', fontName, ...
    'FontSize', labelFontSize);

lgd = legend( ...
    '$\Vert r_I^\alpha\Vert$', ...
    '$\Vert m_I^{\alpha\rightarrow\alpha^*}\Vert$', ...
    'Interpreter', 'latex', ...
    'Location', 'northeast');

set(lgd, ...
    'FontName', fontName, ...
    'FontSize', legendFontSize);

set(gca, ...
    'FontName', fontName, ...
    'FontSize', axisFontSize, ...
    'LineWidth', 1.2);

set(gcf, ...
    'Color', 'w', ...
    'Name', 'KCL 残差与原始侧分支不一致残差', ...
    'NumberTitle', 'off');


%% 15.12 函数结构残差与等值侧分支切换残差

figure;
plot(Vp_pu_from_actual, delta_ab_norm_plot, 'LineWidth', 1.8);
hold on;
plot(Vp_pu_from_actual, me_norm_plot, '--', 'LineWidth', 1.8);
grid on;

xlabel('$\vert V_p\vert({\rm p.u.})$', ...
    'Interpreter', 'latex', ...
    'FontSize', labelFontSize);

ylabel('Residual Magnitude (p.u.)', ...
    'FontName', fontName, ...
    'FontSize', labelFontSize);

lgd = legend( ...
    '$\vert\delta_{\alpha,\beta}\vert$', ...
    '$\vert m_{\rm e}^{\beta\rightarrow\beta^*}\vert$', ...
    'Interpreter', 'latex', ...
    'Location', 'northeast');

set(lgd, ...
    'FontName', fontName, ...
    'FontSize', legendFontSize);

set(gca, ...
    'FontName', fontName, ...
    'FontSize', axisFontSize, ...
    'LineWidth', 1.2);

set(gcf, ...
    'Color', 'w', ...
    'Name', '函数结构残差与等值侧分支不一致残差', ...
    'NumberTitle', 'off');


%% 15.13 分支不一致数量

figure;
stairs(Vp_pu_from_actual, branchMismatchCount_plot, 'LineWidth', 1.8);
hold on;
stairs(Vp_pu_from_actual, eqBranchMismatch_plot, '--', 'LineWidth', 1.8);
grid on;

xlabel('$\vert V_p\vert({\rm p.u.})$', ...
    'Interpreter', 'latex', ...
    'FontSize', labelFontSize);

ylabel('Number of Branch Mismatches', ...
    'FontName', fontName, ...
    'FontSize', labelFontSize);

lgd = legend( ...
    'Original-side branch mismatches', ...
    'Equivalent-side branch mismatch flag', ...
    'Location', 'northeast');

set(lgd, ...
    'FontName', fontName, ...
    'FontSize', legendFontSize);

set(gca, ...
    'FontName', fontName, ...
    'FontSize', axisFontSize, ...
    'LineWidth', 1.2);

set(gcf, ...
    'Color', 'w', ...
    'Name', '原始侧与等值侧分支不一致情况', ...
    'NumberTitle', 'off');


%% 15.14 原始侧分支自适应 M_I 条件数

figure;
semilogy(Vp_pu_from_actual, condMI_piecewise_plot, 'LineWidth', 1.8);
grid on;

xlabel('$\vert V_p\vert({\rm p.u.})$', ...
    'Interpreter', 'latex', ...
    'FontSize', labelFontSize);

ylabel('Condition Number', ...
    'FontName', fontName, ...
    'FontSize', labelFontSize);

lgd = legend( ...
    '$\mathrm{cond}(M_I)$', ...
    'Interpreter', 'latex', ...
    'Location', 'northeast');

set(lgd, ...
    'FontName', fontName, ...
    'FontSize', legendFontSize);

set(gca, ...
    'FontName', fontName, ...
    'FontSize', axisFontSize, ...
    'LineWidth', 1.2);

set(gcf, ...
    'Color', 'w', ...
    'Name', '原始侧分支自适应灵敏度矩阵条件数', ...
    'NumberTitle', 'off');


%% 15.15 等值侧分支自适应 M_e 条件数

figure;
semilogy(Vp_pu_from_actual, condMe_piecewise_plot, 'LineWidth', 1.8);
grid on;

xlabel('$\vert V_p\vert({\rm p.u.})$', ...
    'Interpreter', 'latex', ...
    'FontSize', labelFontSize);

ylabel('Condition Number', ...
    'FontName', fontName, ...
    'FontSize', labelFontSize);

lgd = legend( ...
    '$\mathrm{cond}(M_{\rm e})$', ...
    'Interpreter', 'latex', ...
    'Location', 'northeast');

set(lgd, ...
    'FontName', fontName, ...
    'FontSize', legendFontSize);

set(gca, ...
    'FontName', fontName, ...
    'FontSize', axisFontSize, ...
    'LineWidth', 1.2);

set(gcf, ...
    'Color', 'w', ...
    'Name', '等值侧分支自适应灵敏度矩阵条件数', ...
    'NumberTitle', 'off');


%% 15.16 无源网络偏差 |b_cv|

figure;
plot(Vp_pu_from_actual, bcv_3ph_pu, 'LineWidth', 1.8);
grid on;

xlabel('$\vert V_p\vert({\rm p.u.})$', ...
    'Interpreter', 'latex', ...
    'FontSize', labelFontSize);

ylabel('$\vert b_{\rm cv}\vert({\rm p.u.})$', ...
    'Interpreter', 'latex', ...
    'FontSize', labelFontSize);

set(gca, ...
    'FontName', fontName, ...
    'FontSize', axisFontSize, ...
    'LineWidth', 1.2);

set(gcf, ...
    'Color', 'w', ...
    'Name', '无源网络偏差bcv', ...
    'NumberTitle', 'off');


%% 15.17 原始侧分支自适应传播算子范数
% 同一分支：||Y_pI (M_I^alpha)^(-1)||_2
% 不同分支：||Y_pI (M_I^{alpha*})^(-1)||_2

figure;
semilogy(Vp_pu_from_actual, max(Kvd_piecewiseNorm_plot, eps), ...
    'LineWidth', 1.8);
grid on;

xlabel('$\vert V_p\vert({\rm p.u.})$', ...
    'Interpreter', 'latex', ...
    'FontSize', labelFontSize);

ylabel('$\Vert Y_{pI}M_I^{-1}\Vert_2$', ...
    'Interpreter', 'latex', ...
    'FontSize', labelFontSize);

lgd = legend( ...
    '$\Vert Y_{pI}M_I^{-1}\Vert_2$', ...
    'Interpreter', 'latex', ...
    'Location', 'northeast');

set(lgd, ...
    'FontName', fontName, ...
    'FontSize', legendFontSize);

set(gca, ...
    'FontName', fontName, ...
    'FontSize', axisFontSize, ...
    'LineWidth', 1.2);

set(gcf, ...
    'Color', 'w', ...
    'Name', '原始侧分支自适应传播算子范数', ...
    'NumberTitle', 'off');


%% 15.18 等值侧分支自适应传播算子范数
% 同一分支：||-Y_pe^eq (M_e^beta)^(-1)||_2
% 不同分支：||-Y_pe^eq (M_e^{beta*})^(-1)||_2

figure;
semilogy(Vp_pu_from_actual, max(Kfs_piecewiseNorm_plot, eps), ...
    'LineWidth', 1.8);
grid on;

xlabel('$\vert V_p\vert({\rm p.u.})$', ...
    'Interpreter', 'latex', ...
    'FontSize', labelFontSize);

ylabel('$\Vert-Y_{pe}^{\rm eq}M_{\rm e}^{-1}\Vert_2$', ...
    'Interpreter', 'latex', ...
    'FontSize', labelFontSize);

lgd = legend( ...
    '$\Vert-Y_{pe}^{\rm eq}M_{\rm e}^{-1}\Vert_2$ ', ...
    'Interpreter', 'latex', ...
    'Location', 'northeast');

set(lgd, ...
    'FontName', fontName, ...
    'FontSize', legendFontSize);

set(gca, ...
    'FontName', fontName, ...
    'FontSize', axisFontSize, ...
    'LineWidth', 1.2);

set(gcf, ...
    'Color', 'w', ...
    'Name', '等值侧分支自适应传播算子范数', ...
    'NumberTitle', 'off');


%% 15.19 脱网数量

figure;
stairs(Vp_pu_from_actual, tripCount_plot, 'LineWidth', 1.8);
hold on;
stairs(Vp_pu_from_actual, tripC_count_plot, '--', 'LineWidth', 1.8);
grid on;

xlabel('$\vert V_p\vert({\rm p.u.})$', ...
    'Interpreter', 'latex', ...
    'FontSize', labelFontSize);

ylabel('Number of Tripped IBR Units', ...
    'FontName', fontName, ...
    'FontSize', labelFontSize);

lgd = legend( ...
    'Original cluster model', ...
    'Common-voltage model', ...
    'Location', 'northeast');

set(lgd, ...
    'FontName', fontName, ...
    'FontSize', legendFontSize);

set(gca, ...
    'FontName', fontName, ...
    'FontSize', axisFontSize, ...
    'LineWidth', 1.2);

set(gcf, ...
    'Color', 'w', ...
    'Name', '脱网数量', ...
    'NumberTitle', 'off');


%% 15.20 e_vd 的 d/q 分解误差

figure;
plot(Vp_pu_from_actual, evd_d_3ph_pu, 'LineWidth', 1.8);
hold on;
plot(Vp_pu_from_actual, evd_q_3ph_pu, '--', 'LineWidth', 1.8);
grid on;

xlabel('$\vert V_p\vert({\rm p.u.})$', ...
    'Interpreter', 'latex', ...
    'FontSize', labelFontSize);

ylabel('$e_{{\rm vd},d}, e_{{\rm vd},q}({\rm p.u.})$', ...
    'Interpreter', 'latex', ...
    'FontSize', labelFontSize);

lgd = legend( ...
    '$e_{{\rm vd},d}$', ...
    '$e_{{\rm vd},q}$', ...
    'Interpreter', 'latex', ...
    'Location', 'best');

set(lgd, ...
    'FontName', fontName, ...
    'FontSize', legendFontSize);

set(gca, ...
    'FontName', fontName, ...
    'FontSize', axisFontSize, ...
    'LineWidth', 1.2);

set(gcf, ...
    'Color', 'w', ...
    'Name', 'evd的dq分解误差', ...
    'NumberTitle', 'off');


%% 15.21 e_fs 的 d/q 分解误差

figure;
plot(Vp_pu_from_actual, efs_d_3ph_pu, 'LineWidth', 1.8);
hold on;
plot(Vp_pu_from_actual, efs_q_3ph_pu, '--', 'LineWidth', 1.8);
grid on;

xlabel('$\vert V_p\vert({\rm p.u.})$', ...
    'Interpreter', 'latex', ...
    'FontSize', labelFontSize);

ylabel('$e_{{\rm fs},d}, e_{{\rm fs},q}({\rm p.u.})$', ...
    'Interpreter', 'latex', ...
    'FontSize', labelFontSize);

lgd = legend( ...
    '$e_{{\rm fs},d}$', ...
    '$e_{{\rm fs},q}$', ...
    'Interpreter', 'latex', ...
    'Location', 'best');

set(lgd, ...
    'FontName', fontName, ...
    'FontSize', legendFontSize);

set(gca, ...
    'FontName', fontName, ...
    'FontSize', axisFontSize, ...
    'LineWidth', 1.2);

set(gcf, ...
    'Color', 'w', ...
    'Name', 'efs的dq分解误差', ...
    'NumberTitle', 'off');


%% 15.22 e 的 d/q 分解误差

figure;
plot(Vp_pu_from_actual, etot_d_3ph_pu, 'LineWidth', 1.8);
hold on;
plot(Vp_pu_from_actual, etot_q_3ph_pu, '--', 'LineWidth', 1.8);
grid on;

xlabel('$\vert V_p\vert({\rm p.u.})$', ...
    'Interpreter', 'latex', ...
    'FontSize', labelFontSize);

ylabel('$e_d, e_q({\rm p.u.})$', ...
    'Interpreter', 'latex', ...
    'FontSize', labelFontSize);

lgd = legend( ...
    '$e_d$', ...
    '$e_q$', ...
    'Interpreter', 'latex', ...
    'Location', 'best');

set(lgd, ...
    'FontName', fontName, ...
    'FontSize', legendFontSize);

set(gca, ...
    'FontName', fontName, ...
    'FontSize', axisFontSize, ...
    'LineWidth', 1.2);

set(gcf, ...
    'Color', 'w', ...
    'Name', 'e的dq分解误差', ...
    'NumberTitle', 'off');


%% 15.23 b_cv 的 d/q 分解误差

figure;
plot(Vp_pu_from_actual, bcv_d_3ph_pu, 'LineWidth', 1.8);
hold on;
plot(Vp_pu_from_actual, bcv_q_3ph_pu, '--', 'LineWidth', 1.8);
grid on;

xlabel('$\vert V_p\vert({\rm p.u.})$', ...
    'Interpreter', 'latex', ...
    'FontSize', labelFontSize);

ylabel('$b_{{\rm cv},d}, b_{{\rm cv},q}({\rm p.u.})$', ...
    'Interpreter', 'latex', ...
    'FontSize', labelFontSize);

lgd = legend( ...
    '$b_{{\rm cv},d}$', ...
    '$b_{{\rm cv},q}$', ...
    'Interpreter', 'latex', ...
    'Location', 'best');

set(lgd, ...
    'FontName', fontName, ...
    'FontSize', legendFontSize);

set(gca, ...
    'FontName', fontName, ...
    'FontSize', axisFontSize, ...
    'LineWidth', 1.2);

set(gcf, ...
    'Color', 'w', ...
    'Name', 'bcv的dq分解误差', ...
    'NumberTitle', 'off');


%% 15.24 r_I^alpha 的 d/q 分解误差
% r_I^alpha 是内部节点 KCL 残差向量。
% 这里不取范数，而是对所有内部节点的 d/q 分量代数求和，保留正负号。

figure;
plot(Vp_pu_from_actual, rI_alpha_d_3ph_pu, 'LineWidth', 1.8);
hold on;
plot(Vp_pu_from_actual, rI_alpha_q_3ph_pu, '--', 'LineWidth', 1.8);
yline(0, 'k:', 'LineWidth', 1.0);
grid on;

xlabel('$\vert V_p\vert({\rm p.u.})$', ...
    'Interpreter', 'latex', ...
    'FontSize', labelFontSize);

ylabel('$r_{I,d}^{\alpha},r_{I,q}^{\alpha}({\rm p.u.})$', ...
    'Interpreter', 'latex', ...
    'FontSize', labelFontSize);

lgd = legend( ...
    '$r_{I,d}^{\alpha}$', ...
    '$r_{I,q}^{\alpha}$', ...
    'Interpreter', 'latex', ...
    'Location', 'best');

set(lgd, ...
    'FontName', fontName, ...
    'FontSize', legendFontSize);

set(gca, ...
    'FontName', fontName, ...
    'FontSize', axisFontSize, ...
    'LineWidth', 1.2);

set(gcf, ...
    'Color', 'w', ...
    'Name', 'r_alpha的dq分解误差', ...
    'NumberTitle', 'off');


%% 15.25 delta_{alpha,beta} 的 d/q 分解误差

figure;
plot(Vp_pu_from_actual, delta_ab_d_3ph_pu, 'LineWidth', 1.8);
hold on;
plot(Vp_pu_from_actual, delta_ab_q_3ph_pu, '--', 'LineWidth', 1.8);
grid on;

xlabel('$\vert V_p\vert({\rm p.u.})$', ...
    'Interpreter', 'latex', ...
    'FontSize', labelFontSize);

ylabel('$\delta_{\alpha,\beta,d},\delta_{\alpha,\beta,q}({\rm p.u.})$', ...
    'Interpreter', 'latex', ...
    'FontSize', labelFontSize);

lgd = legend( ...
    '$\delta_{\alpha,\beta,d}$', ...
    '$\delta_{\alpha,\beta,q}$', ...
    'Interpreter', 'latex', ...
    'Location', 'best');

set(lgd, ...
    'FontName', fontName, ...
    'FontSize', legendFontSize);

set(gca, ...
    'FontName', fontName, ...
    'FontSize', axisFontSize, ...
    'LineWidth', 1.2);

set(gcf, ...
    'Color', 'w', ...
    'Name', 'delta_ab的dq分解误差', ...
    'NumberTitle', 'off');


%% ============================================================
%  15.26 并网点电流详细模型、等值模型与 EMT 点对比
%  说明：本图来自第二个绘图程序的对比图，将原始模型、等值模型、
%  EMT 详细模型点和 EMT 等值模型点画在同一张图中。
% ============================================================

figure;

h_detail = plot(Vp_pu_from_actual, Ip_3ph_pu_from_actual, ...
    'LineWidth', 1.8, ...
    'DisplayName', 'Original');
hold on;

h_equiv = plot(Vp_pu_from_actual, Ipeq_3ph_pu_from_actual, ...
    '--', ...
    'LineWidth', 1.8, ...
    'DisplayName', 'Aggregated');

EMT_points_compare = [
    1.00, 0.287625;
    0.80, 0.36546;
    0.60, 0.56599;
    0.50, 0.6133;
    0.40, 0.6158;
    0.35, 0.30666;
    0.30, 0.30241;
    0.20, 0.016867
];

h_emt = plot(EMT_points_compare(:,1), EMT_points_compare(:,2), ...
    'ko', ...
    'LineStyle', 'none', ...
    'MarkerSize', 6, ...
    'MarkerFaceColor', 'none', ...
    'MarkerEdgeColor', 'k', ...
    'LineWidth', 1.2, ...
    'DisplayName', 'EMT');

EMTeq_points_compare = [
    1.00, 0.288246;
    0.80, 0.366337;
    0.60, 0.57303;
    0.50, 0.6203;
    0.40, 0.6158125;
    0.35, 0.6116301;
    0.30, 0.025028;
    0.20, 0.016678
];

h_emteq = plot(EMTeq_points_compare(:,1), EMTeq_points_compare(:,2), ...
    'k^', ...
    'LineStyle', 'none', ...
    'MarkerSize', 6, ...
    'MarkerFaceColor', 'none', ...
    'MarkerEdgeColor', 'k', ...
    'LineWidth', 1.2, ...
    'DisplayName', 'EMTeq');

grid on;

xlabel('$|V_p|({\rm p.u.})$', ...
    'Interpreter', 'latex', ...
    'FontSize', labelFontSize);

ylabel('$|I_p|({\rm p.u.})$', ...
    'Interpreter', 'latex', ...
    'FontSize', labelFontSize);

legend([h_detail, h_equiv, h_emt, h_emteq], ...
    {'Original', 'Aggregated', 'EMT', 'EMTeq'}, ...
    'Location', 'northeast');

ylim([-0.05, 0.65]);

text(0.95, 0.05, 'A', ...
    'Units', 'normalized', ...
    'HorizontalAlignment', 'right', ...
    'VerticalAlignment', 'bottom', ...
    'FontName', 'Times New Roman', ...
    'FontSize', 16, ...
    'FontWeight', 'bold', ...
    'Color', 'k');

set(gca, ...
    'FontName', 'Times New Roman', ...
    'FontSize', axisFontSize, ...
    'LineWidth', 1.2);

set(gcf, ...
    'Color', 'w', ...
    'Name', '并网点电流详细模型、等值模型与EMT点对比', ...
    'NumberTitle', 'off');


%% ============================================================
%  15.27 并网点电流 d/q 分量：详细模型与等值模型对比
%  说明：这里乘 sqrt(3)，采用三相电流标幺值口径。
% ============================================================

figure;

plot(Vp_pu_from_actual, sqrt(3) * real(Ip_plot), ...
    'LineWidth', 1.6);
hold on;

plot(Vp_pu_from_actual, sqrt(3) * real(Ipeq_plot), ...
    '--', ...
    'LineWidth', 1.6);

plot(Vp_pu_from_actual, sqrt(3) * imag(Ip_plot), ...
    'LineWidth', 1.6);

plot(Vp_pu_from_actual, sqrt(3) * imag(Ipeq_plot), ...
    '--', ...
    'LineWidth', 1.6);

grid on;

xlabel('$|V_p|({\rm p.u.})$', ...
    'Interpreter', 'latex', ...
    'FontSize', labelFontSize);

ylabel('$i_d,i_q({\rm p.u.})$', ...
    'Interpreter', 'latex', ...
    'FontSize', labelFontSize);

legend( ...
    '{\fontsize{13}\it i_d}{\fontsize{12}\rm Original}', ...
    '{\fontsize{13}\it i_{d,\rm eq}}{\fontsize{12}\rm Aggregated}', ...
    '{\fontsize{13}\it i_q}{\fontsize{12}\rm Original}', ...
    '{\fontsize{13}\it i_{q,\rm eq}}{\fontsize{12}\rm Aggregated}', ...
    'Interpreter', 'tex', ...
    'FontName', 'Times New Roman', ...
    'FontSize', 14, ...
    'Location', 'northeast', ...
    'Orientation', 'horizontal', ...
    'NumColumns', 2);

ylim([-0.7, 0.7]);

text(0.95, 0.05, 'B', ...
    'Units', 'normalized', ...
    'HorizontalAlignment', 'right', ...
    'VerticalAlignment', 'bottom', ...
    'FontName', 'Times New Roman', ...
    'FontSize', 16, ...
    'FontWeight', 'bold', ...
    'Color', 'k');

set(gca, ...
    'FontName', 'Times New Roman', ...
    'FontSize', axisFontSize, ...
    'LineWidth', 1.2);

set(gcf, ...
    'Color', 'w', ...
    'Name', '并网点电流dq分量详细模型与等值模型对比', ...
    'NumberTitle', 'off');


%% ============================================================
%  15.28 并网点电流详细模型与等值模型误差绝对值
% ============================================================

Ip_abs_error_3ph_pu = abs(Ip_3ph_pu_from_actual - Ipeq_3ph_pu_from_actual);

figure;
plot(Vp_pu_from_actual, Ip_abs_error_3ph_pu, 'LineWidth', 1.8);
grid on;

xlabel('$|V_p|({\rm p.u.})$', ...
    'Interpreter', 'latex', ...
    'FontSize', labelFontSize);

ylabel('$|I_p-I_p^{\rm eq}|({\rm p.u.})$', ...
    'Interpreter', 'latex', ...
    'FontSize', labelFontSize);

ylim([0, 0.35]);

text(0.95, 0.05, 'A', ...
    'Units', 'normalized', ...
    'HorizontalAlignment', 'right', ...
    'VerticalAlignment', 'bottom', ...
    'FontName', 'Times New Roman', ...
    'FontSize', 16, ...
    'FontWeight', 'bold', ...
    'Color', 'k');

set(gca, ...
    'FontName', 'Times New Roman', ...
    'FontSize', axisFontSize, ...
    'LineWidth', 1.2);

set(gcf, ...
    'Color', 'w', ...
    'Name', '并网点电流详细模型与等值模型误差绝对值', ...
    'NumberTitle', 'off');


%% ============================================================
%  15.29 各风机节点端电压随并网点电压变化
% ============================================================

figure;

voltage_abs_pv = abs(VI_plot);
voltage_abs_pv_plot = transpose(voltage_abs_pv);

plot(Vp_pu_from_actual, voltage_abs_pv_plot, ...
    'LineWidth', 1.5);

grid on;
hold on;

xlabel('$|V_p|({\rm p.u.})$', ...
    'Interpreter', 'latex', ...
    'FontSize', labelFontSize);

ylabel('$|V_I|({\rm p.u.})$', ...
    'Interpreter', 'latex', ...
    'FontSize', labelFontSize);

set(gca, ...
    'FontName', 'Times New Roman', ...
    'FontSize', axisFontSize, ...
    'LineWidth', 1.2);

set(gcf, ...
    'Color', 'w', ...
    'Name', '各风机节点端电压随并网点电压变化', ...
    'NumberTitle', 'off');



% ============================================================
%  统一设置所有图片字体和字号
%  注意：EMT 标注单独保持小字号
% ============================================================

% 字体设置
fontName = 'Times New Roman';
% 
% 字号设置
axisFontSize    = 16;   % 坐标轴刻度数字字号
labelFontSize   = 18;   % x/y 坐标轴标题字号
titleFontSize   = 10;   % 图标题字号
legendFontSize  = 12;   % 图例字号
emtTextFontSize = 12;    % EMT 标注字号，觉得还大可以改成 3.5

% 获取所有 figure
figHandles = findall(0, 'Type', 'figure');

for iFig = 1:length(figHandles)

    fig = figHandles(iFig);
% 
%     设置图背景为白色
    set(fig, 'Color', 'w');
% 
%     找到当前 figure 中所有坐标轴
    axList = findall(fig, 'Type', 'axes');

    for iAx = 1:length(axList)

        ax = axList(iAx);
% 
%         坐标轴刻度数字字体和字号
        set(ax, ...
            'FontName', fontName, ...
            'FontSize', axisFontSize, ...
            'LineWidth', 1.2);

%         x 轴标签
        ax.XLabel.FontName = fontName;
        ax.XLabel.FontSize = labelFontSize;

%         y 轴标签
        ax.YLabel.FontName = fontName;
        ax.YLabel.FontSize = labelFontSize;
% % 
%         标题
        ax.Title.FontName = fontName;
        ax.Title.FontSize = titleFontSize;

    end

%     修改图例字体
% 注意：Tag = LargeLegend 的图例保持大字号，不受统一 legendFontSize 影响
lgdList = findall(fig, 'Type', 'legend');

for iLgd = 1:length(lgdList)

    lgd = lgdList(iLgd);
    lgdTag = get(lgd, 'Tag');

    if strcmp(lgdTag, 'LargeLegend')

        set(lgd, ...
            'FontName', fontName, ...
            'FontSize', largeLegendFontSize);

    else

        set(lgd, ...
            'FontName', fontName, ...
            'FontSize', legendFontSize);

    end

end

%     只单独修改 EMT 标注，不再把所有 text 都改成 18 号
    textList = findall(fig, 'Type', 'text');

    for iTxt = 1:length(textList)

        txt = textList(iTxt);
        txtStr = get(txt, 'String');
        txtTag = get(txt, 'Tag');

%         情况1：前面 text() 里设置了 'Tag','EMTText'
%         情况2：没有设置 Tag，但文字里包含 EMT
        if strcmp(txtTag, 'EMTText') || contains(string(txtStr), 'EMT')

            set(txt, ...
                'FontName', fontName, ...
                'FontSize', emtTextFontSize);

        end

    end

end
% ============================================================
%  保存所有图片为 PNG：按 figure 的 Name 命名
% ============================================================
% 
% 图片保存文件夹：桌面\项目excel\论文图片\同输入
figSaveDir = fullfile(getenv('USERPROFILE'), ...
    'Desktop', '项目excel', '论文图片', '风电');
% % 
% 如果文件夹不存在，则自动创建
if ~exist(figSaveDir, 'dir')
    mkdir(figSaveDir);
end

% 获取当前所有 figure
figHandles = findall(0, 'Type', 'figure');

% 按 figure 编号排序
[~, idxFig] = sort([figHandles.Number]);
figHandles = figHandles(idxFig);

for iFig = 1:length(figHandles)

    fig = figHandles(iFig);

%     设置白色背景
    set(fig, 'Color', 'w');

%     读取 figure 的 Name
    figName = get(fig, 'Name');

%     如果没有设置 Name，就用默认编号
    if isempty(figName)
        figName = sprintf('Figure_%02d', iFig);
    end

%     把文件名中的非法字符替换掉
    figName = regexprep(figName, '[\\/:*?"<>|]', '_');

%     避免文件名太长
    if strlength(figName) > 120
        figName = extractBefore(figName, 121);
    end

%     完整保存路径
    filePath = fullfile(figSaveDir, [char(figName), '.png']);

%     保存为 PNG，300 dpi
    exportgraphics(fig, filePath, 'Resolution', 300);

end

fprintf('所有图片已按图名保存到文件夹：%s\n', figSaveDir);
%% ============================================================
%  16. 保存结果
% ============================================================

result.Sbase_MVA = Sbase_MVA;
result.Vbase_kV = Vbase_kV;
result.Vctrl_base_kV = Vctrl_base_kV;
result.Ilimit_base_ratio = Ilimit_base_ratio;
result.Ibase_kA = Ibase_kA;
result.Ibase_A = Ibase_A;

result.Y = Y;
result.Ypp = Ypp;
result.YpI = YpI;
result.YIp = YIp;
result.YII = YII;

result.s = s;
result.s_aug = s_aug;
result.Ssum = Ssum;
result.ctrlType = ctrlType;

result.Imax_single = pv.Imax_single;
result.Imax_single_vec = pv.Imax_single_vec;
result.kq_type1 = pv.kq_type1;
result.kq_type2 = pv.kq_type2;
result.vLVRT = pv.vLVRT;

result.tripMask = tripMask_plot;
result.tripCount = tripCount_plot;
result.tripIter = tripIter_plot;
result.tripEq = tripEq_plot;

result.Seq = Seq;
result.SP = SP;
result.SI = SI;
result.Aeq = Aeq;
result.Beq = Beq;
result.pv_eq = pv_eq;

result.Yred = Yred;
result.A = Avec;
result.B = Bmat;
result.a = a;
result.c = c;
result.Yeq = Yeq;

result.Vp_abs_calc = Vp_abs_vec;
result.Vp_abs = Vp_plot;
result.Vp_pu_from_actual = Vp_pu_from_actual;

result.V1 = V1_plot;
result.VI = VI_plot;
result.VIeq = VIeq_plot;
result.Vc = Vc_plot;

result.H = Ip_plot;
result.Hc = Hc_plot;
result.Heq = Ipeq_plot;

result.Ip_3ph_pu_from_actual = Ip_3ph_pu_from_actual;
result.Hc_3ph_pu = Hc_3ph_pu;
result.Ipeq_3ph_pu_from_actual = Ipeq_3ph_pu_from_actual;

result.G_Vc = G_Vc_plot;
result.I_PVsum_detail = I_PVsum_detail_plot;
result.I_PVeq = I_PVeq_plot;
result.eq_node_residual = eq_node_residual_plot;

result.evd = evd_plot;
result.efs = efs_plot;
result.etot = etot_plot;

result.evd_3ph_pu = evd_3ph_pu;
result.efs_3ph_pu = efs_3ph_pu;
result.etot_3ph_pu = etot_3ph_pu;
result.etot_piecewise_approx = etot_piecewise_approx_plot;
result.etot_piecewise_approx_3ph_pu = etot_piecewise_approx_3ph_pu;

result.error_decomp_check = error_decomp_check;
result.error_decomp_check_3ph_pu = error_decomp_check_3ph_pu;

result.bcv = bcv_plot;
result.bcv_3ph_pu = bcv_3ph_pu;
result.rI_norm = rI_norm_plot;

% d/q 分解误差结果
result.evd_d_3ph_pu = evd_d_3ph_pu;
result.evd_q_3ph_pu = evd_q_3ph_pu;
result.efs_d_3ph_pu = efs_d_3ph_pu;
result.efs_q_3ph_pu = efs_q_3ph_pu;
result.etot_d_3ph_pu = etot_d_3ph_pu;
result.etot_q_3ph_pu = etot_q_3ph_pu;
result.bcv_d_3ph_pu = bcv_d_3ph_pu;
result.bcv_q_3ph_pu = bcv_q_3ph_pu;
result.rI_alpha_d_3ph_pu = rI_alpha_d_3ph_pu;
result.rI_alpha_q_3ph_pu = rI_alpha_q_3ph_pu;
result.delta_ab_d_3ph_pu = delta_ab_d_3ph_pu;
result.delta_ab_q_3ph_pu = delta_ab_q_3ph_pu;

% 原始侧分支自适应传播算子 K_vd = Y_pI M_I^(-1)
result.KvdAlphaNorm = KvdAlphaNorm_plot;
result.KvdAlphaStarNorm = KvdAlphaStarNorm_plot;
result.Kvd_piecewiseNorm = Kvd_piecewiseNorm_plot;
result.Kvd_piecewise_real = Kvd_piecewise_real_plot;

result.tripC = tripC_plot;
result.tripC_count = tripC_count_plot;

result.evd_consistent_approx = evd_consistent_approx_plot;
result.evd_consistent_approx_3ph_pu = evd_consistent_approx_3ph_pu;
result.evd_branch_approx = evd_branch_approx_plot;
result.evd_branch_approx_3ph_pu = evd_branch_approx_3ph_pu;
result.evd_piecewise_approx = evd_piecewise_approx_plot;
result.evd_piecewise_approx_3ph_pu = evd_piecewise_approx_3ph_pu;

result.rI_alpha_aug = rI_alpha_aug_plot;
result.mI_aug = mI_aug_plot;

result.rI_alpha_norm = rI_alpha_norm_plot;
result.mI_norm = mI_norm_plot;

result.branchMismatchCount = branchMismatchCount_plot;
result.evdFormulaID = evdFormulaID_plot;
result.branchCommon = branchCommon_plot;
result.branchTrue = branchTrue_plot;

result.condMIAlpha = condMIAlpha_plot;
result.condMIAlphaStar = condMIAlphaStar_plot;
result.condMI_piecewise = condMI_piecewise_plot;

% 兼容旧变量：默认使用实际分支自适应选择后的条件数
result.condM = condMI_piecewise_plot;

result.efs_consistent_approx = efs_consistent_approx_plot;
result.efs_consistent_approx_3ph_pu = efs_consistent_approx_3ph_pu;
result.efs_func_approx = efs_func_approx_plot;
result.efs_func_approx_3ph_pu = efs_func_approx_3ph_pu;
result.efs_piecewise_approx = efs_piecewise_approx_plot;
result.efs_piecewise_approx_3ph_pu = efs_piecewise_approx_3ph_pu;

result.delta_ab = delta_ab_plot;
result.me_beta = me_beta_plot;

result.delta_ab_norm = delta_ab_norm_plot;
result.me_norm = me_norm_plot;

result.condMeBeta = condMeBeta_plot;
result.condMeBetaStar = condMeBetaStar_plot;
result.condMe_piecewise = condMe_piecewise_plot;

% 等值侧分支自适应传播算子 K_fs = -Y_pe^eq M_e^(-1)
result.KfsBetaNorm = KfsBetaNorm_plot;
result.KfsBetaStarNorm = KfsBetaStarNorm_plot;
result.Kfs_piecewiseNorm = Kfs_piecewiseNorm_plot;
result.Kfs_piecewise_real = Kfs_piecewise_real_plot;
result.efsFormulaID = efsFormulaID_plot;

% 兼容旧变量：默认使用实际分支自适应选择后的条件数
result.condMe = condMe_piecewise_plot;

result.eqBranchMismatch = eqBranchMismatch_plot;
result.branchBeta = branchBeta_plot;
result.branchBetaStar = branchBetaStar_plot;

result.Ip_detail_complex_3ph = Ip_detail_complex_3ph;
result.Ip_equiv_complex_3ph = Ip_equiv_complex_3ph;
result.I_PVsum_detail_complex_3ph = I_PVsum_detail_complex_3ph;
result.I_PVeq_complex_3ph = I_PVeq_complex_3ph;

result.Ip_line_pu_theory = Ip_line_pu_theory;
result.Ip_3ph_pu_theory = Ip_3ph_pu_theory;

result.idx_vp1 = idx_vp1;
result.Vp1 = Vp1;

result.V1_detail_vp1 = V1_detail_vp1;
result.V1_detail_abs_vp1 = V1_detail_abs_vp1;
result.V1_detail_ang_vp1 = V1_detail_ang_vp1;

result.VI_detail_vp1 = VI_detail_vp1;
result.VI_detail_abs_vp1 = VI_detail_abs_vp1;
result.VI_detail_ang_vp1 = VI_detail_ang_vp1;

result.Vc_vp1 = Vc_vp1;
result.Vc_abs_vp1 = Vc_abs_vp1;
result.Vc_ang_vp1 = Vc_ang_vp1;

result.VIeq_vp1 = VIeq_vp1;
result.VIeq_abs_vp1 = VIeq_abs_vp1;
result.VIeq_ang_vp1 = VIeq_ang_vp1;

result.T_detail_vp1 = T_detail;
result.T_common_vp1 = T_common;
result.T_eq_vp1 = T_eq;

assignin('base', 'Ip_Vp_evd_efs_gain_fused_result', result);

disp('Done. Result saved to workspace variable Ip_Vp_evd_efs_gain_fused_result.');

end

%% ========================================================================
%  构造导纳矩阵
% ========================================================================

function Y = build_Y_7bus(lineScale)

j = 1i;

Y = zeros(14,14);

branch = [
         0     1   0.0001       0.0003        0.000;
         1     2   0.020003948   0.047784128   0.01267331;
         1     8   0.01705122    0.040730512   0.01080245;
         2     3   0.00545986    0.010919732   0.00246726;
         3     4   0.008586328   0.01164848    0.00211732;
         4     5   0.014013452   0.012795688   0.00178855;
         5     6   0.021978196   0.013881012   0.00156475;
         6     7   0.0265598     0.016774688   0.00189094;
         8     9   0.015861224   0.031722824   0.00716768;
         9    10   0.009336844   0.01266666    0.00230240;
        10    11   0.015238348   0.013914144   0.00194488;
        11    12   0.023679288   0.014955396   0.00168586;
        12    13   0.023679288   0.014955396   0.00168586;
];

for kk = 1:size(branch,1)

    m = branch(kk,1) + 1;
    n = branch(kk,2) + 1;

    r = branch(kk,3);
    xline = branch(kk,4);
    B = branch(kk,5);

    z = lineScale * (r + j*xline);
    y = 1/z;

    Y(m,m) = Y(m,m) + y + j*B/2;
    Y(n,n) = Y(n,n) + y + j*B/2;

    Y(m,n) = Y(m,n) - y;
    Y(n,m) = Y(n,m) - y;

end

disp('Y matrix = ');
disp(Y);

end

%% ========================================================================
%  详细模型残差方程
% ========================================================================

function F = residual_equation_trip_iter_with_node0_in_Y(x, Vp, YIp, YII, pv, tripMask)

nPV = length(pv.s);

U = x(1:nPV+1) + 1j*x(nPV+2:end);

Vpv = U(2:end);

I_PV = fIBR_model_trip_iter(Vpv, pv, tripMask);

Iinj = [0; I_PV];

res = YIp * Vp + YII * U - Iinj;

F = [real(res); imag(res)];

end

%% ========================================================================
%  等值模型脱网迭代
% ========================================================================

function [VIeq, I_PVeq, tripEq, x_sol, exitflag_final] = ...
    solve_eq_with_trip_iteration(Vp, Vp_abs, Yeq_Ip, Yeq_II, pv_eq, x0_eq, opt)

tripEq = false;

maxTripIter = 5;
tripTol = 1e-10;

x_sol = x0_eq;
exitflag_final = 1;

for tripIter = 1:maxTripIter

    tripEq_old = tripEq;

    if tripEq

        I_PVeq = 0;
        VIeq = -(Yeq_Ip * Vp) / Yeq_II;

        x_sol = [real(VIeq); imag(VIeq)];
        exitflag_final = 1;

    else

        fun_eq = @(x) residual_equation_eq_online(x, Vp, Yeq_Ip, Yeq_II, pv_eq);

        [x_sol, fval, exitflag] = fsolve(fun_eq, x_sol, opt);

        VIeq = x_sol(1) + 1j*x_sol(2);

        I_PVeq = equivalent_AB_current_no_trip_gate(VIeq, Vp, pv_eq);

        exitflag_final = exitflag;

        if exitflag <= 0 && norm(fval) < 1e-8
            exitflag_final = 1;
        end

        if exitflag_final <= 0
            warning('等值模型：Vp = %.4f，脱网迭代 %d 可能未收敛。', ...
                Vp_abs, tripIter);
        end

        v_ctrl_eq = pv_voltage_control_pu(VIeq, pv_eq.Vbase_kV, pv_eq.Vctrl_base_kV);

        if v_ctrl_eq <= pv_eq.vtrip + tripTol
            tripEq = true;
        end

    end

    if isequal(tripEq, tripEq_old)
        break;
    end

end

if tripEq
    I_PVeq = 0;
    VIeq = -(Yeq_Ip * Vp) / Yeq_II;
    x_sol = [real(VIeq); imag(VIeq)];
else
    VIeq = x_sol(1) + 1j*x_sol(2);
    I_PVeq = equivalent_AB_current_no_trip_gate(VIeq, Vp, pv_eq);
end

end

%% ========================================================================
%  等值模型残差方程
% ========================================================================

function F = residual_equation_eq_online(x, Vp, Yeq_Ip, Yeq_II, pv_eq)

VIeq = x(1) + 1j*x(2);

Ieq = equivalent_AB_current_no_trip_gate(VIeq, Vp, pv_eq);

res = Yeq_Ip * Vp + Yeq_II * VIeq - Ieq;

F = [real(res); imag(res)];

end

%% ========================================================================
%  详细设备电流模型
% ========================================================================

function I = fIBR_model_trip_iter(VI, pv, tripMask)

s = pv.s(:);
typeVec = pv.ctrlType(:);

n = length(s);

I = zeros(n,1);

for kk = 1:n

    if tripMask(kk)
        I(kk) = 0;
    else
        I(kk) = single_pv_current_no_trip_gate(VI(kk), s(kk), typeVec(kk), kk, pv);
    end

end

end

%% ========================================================================
%  单台设备电流模型
% ========================================================================

function I = single_pv_current_no_trip_gate(V, s_k, type, k, pv)

v_phase = abs(V);
v_phase_safe = max(v_phase, 1e-6);
eV = V / v_phase_safe;

v = pv_voltage_control_pu(V, pv.Vbase_kV, pv.Vctrl_base_kV);
v_safe = max(v, 1e-6);

cap = s_k / pv.Sbase_MVA;

Id0 = pv.Id0_single * cap;
Iq0 = pv.Iq0_single * cap;

if isfield(pv, 'Imax_single_vec') && ~isempty(pv.Imax_single_vec)
    Imax_single_k = pv.Imax_single_vec(k);
else
    Imax_single_k = pv.Imax_single;
end

Imax = Imax_single_k * cap * pv.Ilimit_base_ratio;

p0 = pv.vpre * Id0;

[~, ~, vblock] = get_threshold_by_type(type, pv);

if v <= vblock

    u0 = [0; 0];

else

    if v >= pv.normalConstP.vmin && v <= pv.normalConstP.vmax
        id = p0 / v_safe;
    else
        switch type
            case 1
                id = p0 / v_safe;
            case 2
                id = Id0;
            otherwise
                error('未知控制类型。');
        end
    end

    switch type
        case 1
            iq = pv.kq_type1 * max(pv.vLVRT - v, 0) * cap + Iq0;
        case 2
            iq = pv.kq_type2 * max(pv.vLVRT - v, 0) * cap + Iq0;
        otherwise
            error('未知控制类型。');
    end

    u0 = [id; iq];

end

u = project_current_limit(u0, Imax, pv.priority);

id = u(1);
iq = u(2);

I_local = id - 1j*iq;

I = I_local * eV;

end

%% ========================================================================
%  等值设备 A/B 电流模型
% ========================================================================

function Ieq = equivalent_AB_current_no_trip_gate(Veq, Vp, pv_eq)

v_phase = abs(Veq);
v_phase_safe = max(v_phase, 1e-6);
eV = Veq / v_phase_safe;

v = pv_voltage_control_pu(Veq, pv_eq.Vbase_kV, pv_eq.Vctrl_base_kV);
v_safe = max(v, 1e-6);

vp_abs = pv_voltage_control_pu(Vp, pv_eq.Vbase_kV, pv_eq.Vctrl_base_kV);

cap = pv_eq.Seq / pv_eq.Sbase_MVA;

Id0 = pv_eq.Id0_single * cap;
Iq0 = pv_eq.Iq0_single * cap;

p0 = pv_eq.vpre * Id0;

Imax_constP = pv_eq.Imax_type1 * cap * pv_eq.Ilimit_base_ratio;
Imax_constI = pv_eq.Imax_type2 * cap * pv_eq.Ilimit_base_ratio;

iq_constP = pv_eq.kq_type1 * max(pv_eq.vLVRT - v, 0) * cap + Iq0;
iq_constI = pv_eq.kq_type2 * max(pv_eq.vLVRT - v, 0) * cap + Iq0;

u_constP_0 = [
    p0 / v_safe;
    iq_constP
];

u_constI_0 = [
    Id0;
    iq_constI
];

u_constP_lim = project_current_limit(u_constP_0, Imax_constP, pv_eq.priority);
u_constI_lim = project_current_limit(u_constI_0, Imax_constI, pv_eq.priority);

if vp_abs >= pv_eq.vp_normal_min && vp_abs <= pv_eq.vp_normal_max
    u_mix = pv_eq.A * u_constP_lim + pv_eq.B * u_constP_lim;
elseif vp_abs >= pv_eq.vp_min && vp_abs < pv_eq.vp_normal_min
    u_mix = pv_eq.A * u_constP_lim + pv_eq.B * u_constI_lim;
else
    u_mix = pv_eq.A * u_constP_lim + pv_eq.B * u_constI_lim;
end

id = u_mix(1);
iq = u_mix(2);

I_local = id - 1j*iq;

Ieq = I_local * eV;

end

%% ========================================================================
%  公共电压模型脱网迭代
% ========================================================================

function [Vc, G_Vc, tripC, x_sol, exitflag_final] = ...
    solve_common_voltage_with_trip_iteration(Vp, Vp_abs, Yeq_Ip, Yeq_II, pv, x0_c, opt)

nPV = length(pv.s);

tripC = false(nPV,1);

maxTripIter = nPV + 5;
tripTol = 1e-10;

x_sol = x0_c;
exitflag_final = 1;

for tripIter = 1:maxTripIter

    tripC_old = tripC;

    if all(tripC)

        G_Vc = 0;
        Vc = -(Yeq_Ip * Vp) / Yeq_II;
        x_sol = [real(Vc); imag(Vc)];
        exitflag_final = 1;
        break;

    end

    fun_c = @(x) residual_common_voltage_online(x, Vp, Yeq_Ip, Yeq_II, pv, tripC);

    [x_sol, fval, exitflag] = fsolve(fun_c, x_sol, opt);

    Vc = x_sol(1) + 1j*x_sol(2);

    G_Vc = common_voltage_current_sum_no_trip_gate(Vc, pv, tripC);

    exitflag_final = exitflag;

    if exitflag <= 0 && norm(fval) < 1e-8
        exitflag_final = 1;
    end

    if exitflag_final <= 0
        warning('公共电压模型：Vp = %.4f，脱网迭代 %d 可能未收敛。', ...
            Vp_abs, tripIter);
    end

    for ii = 1:nPV

        if ~tripC(ii)

            type_i = pv.ctrlType(ii);
            [~, vtrip_i, ~] = get_threshold_by_type(type_i, pv);

            v_ctrl_c = pv_voltage_control_pu(Vc, pv.Vbase_kV, pv.Vctrl_base_kV);

            if v_ctrl_c <= vtrip_i + tripTol
                tripC(ii) = true;
            end

        end

    end

    if isequal(tripC, tripC_old)
        break;
    end

end

if all(tripC)
    G_Vc = 0;
    Vc = -(Yeq_Ip * Vp) / Yeq_II;
    x_sol = [real(Vc); imag(Vc)];
else
    Vc = x_sol(1) + 1j*x_sol(2);
    G_Vc = common_voltage_current_sum_no_trip_gate(Vc, pv, tripC);
end

end

%% ========================================================================
%  公共电压模型残差方程
% ========================================================================

function F = residual_common_voltage_online(x, Vp, Yeq_Ip, Yeq_II, pv, tripC)

Vc = x(1) + 1j*x(2);

G_Vc = common_voltage_current_sum_no_trip_gate(Vc, pv, tripC);

res = Yeq_Ip * Vp + Yeq_II * Vc - G_Vc;

F = [real(res); imag(res)];

end

%% ========================================================================
%  同输入电流求和规律 G(Vc)
% ========================================================================

function G_Vc = common_voltage_current_sum_no_trip_gate(Vc, pv, tripC)

s = pv.s(:);
typeVec = pv.ctrlType(:);

nPV = length(s);

G_Vc = 0 + 0j;

for kk = 1:nPV

    if tripC(kk)
        I_k = 0;
    else
        I_k = single_pv_current_no_trip_gate(Vc, s(kk), typeVec(kk), kk, pv);
    end

    G_Vc = G_Vc + I_k;

end

end

%% ========================================================================
%  计算无源网络偏差 bcv 和公共电压 KCL 残差
% ========================================================================

function [bcv, rI_aug] = compute_common_voltage_bias_and_residual( ...
    Vp, Vc, Ypp, YpI, YIp, YII, Yeq_pp, Yeq_pI, pv, tripC)

nPV = length(pv.s);

Vpv_c = ones(nPV,1) * Vc;

V1_c = -(YIp(1) * Vp + YII(1,2:end) * Vpv_c) / YII(1,1);

Uc = [V1_c; Vpv_c];

I_PV_c = zeros(nPV,1);

for kk = 1:nPV

    if tripC(kk)
        I_PV_c(kk) = 0;
    else
        I_PV_c(kk) = single_pv_current_no_trip_gate(Vc, pv.s(kk), pv.ctrlType(kk), kk, pv);
    end

end

Iinj_c = [0; I_PV_c];

rI_aug = YIp * Vp + YII * Uc - Iinj_c;

H_common_original = -(Ypp * Vp + YpI * Uc);

Hc = -(Yeq_pp * Vp + Yeq_pI * Vc);

bcv = H_common_original - Hc;

end

%% ========================================================================
%  电压分散误差式(50)和式(53)近似计算
% ========================================================================

function [evd_consistent_approx, evd_branch_approx, mI_aug, rI_alpha_aug, ...
    condMIAlpha, condMIAlphaStar, ...
    branchMismatchCount, branchCommon, branchTrue, ...
    KvdAlpha_real, KvdAlphaStar_real] = ...
    compute_inconsistent_branch_approx( ...
        Vp, Vc, Utrue, VItrue, tripMask, tripC, ...
        YpI, YIp, YII, bcv, pv)

nPV = length(pv.s);

Vpv_c = ones(nPV,1) * Vc;

V1_c = -(YIp(1) * Vp + YII(1,2:end) * Vpv_c) / YII(1,1);
Uc = [V1_c; Vpv_c];

branchCommon = classify_all_branches(Vpv_c, pv, tripC);
branchTrue = classify_all_branches(VItrue, pv, tripMask);

branchMismatchCount = sum(branchCommon ~= branchTrue);

I_alpha_aug = forced_injection_aug(Uc, pv, branchCommon);
I_alphastar_aug = forced_injection_aug(Uc, pv, branchTrue);

mI_aug = I_alpha_aug - I_alphastar_aug;

rI_alpha_aug = YIp * Vp + YII * Uc - I_alpha_aug;

J_alpha_real = numerical_jacobian_forced_injection(Uc, pv, branchCommon);
J_alphaStar_real = numerical_jacobian_forced_injection(Uc, pv, branchTrue);

YII_real = complex_matrix_to_real(YII);

MI_alpha_real = YII_real - J_alpha_real;
MI_alphaStar_real = YII_real - J_alphaStar_real;

condMIAlpha = cond(MI_alpha_real);
condMIAlphaStar = cond(MI_alphaStar_real);

% 实数二轴坐标下的原始侧传播算子：
% K_vd^alpha     = Y_pI (M_I^alpha)^(-1)
% K_vd^alphaStar = Y_pI (M_I^alphaStar)^(-1)
YpI_real = complex_matrix_to_real(YpI);
KvdAlpha_real = YpI_real / MI_alpha_real;
KvdAlphaStar_real = YpI_real / MI_alphaStar_real;

% 式(50)：evd ≈ bcv + YpI * inv(M_I^alpha) * rI_alpha
rhs50_real = [real(rI_alpha_aug); imag(rI_alpha_aug)];

delta50_real = MI_alpha_real \ rhs50_real;

nInternal = length(Uc);
delta50_complex = delta50_real(1:nInternal) + 1j*delta50_real(nInternal+1:end);

evd_consistent_approx = bcv + YpI * delta50_complex;

% 式(53)：evd ≈ bcv + YpI * inv(M_I^alphaStar) * (rI_alpha + mI)
rhs53_complex = rI_alpha_aug + mI_aug;
rhs53_real = [real(rhs53_complex); imag(rhs53_complex)];

delta53_real = MI_alphaStar_real \ rhs53_real;

delta53_complex = delta53_real(1:nInternal) + 1j*delta53_real(nInternal+1:end);

evd_branch_approx = bcv + YpI * delta53_complex;

end

%% ========================================================================
%  函数结构误差式(60)/(63)近似计算
% ========================================================================

function [efs_consistent_approx, efs_func_approx, delta_ab, me_beta, ...
    condMeBeta, condMeBetaStar, ...
    eqBranchMismatch, branchBeta, branchBetaStar, ...
    KfsBeta_real, KfsBetaStar_real] = ...
    compute_function_structure_approx( ...
        Vp, Vc, Ve, tripEq, Yeq_pI, Yeq_II, ...
        pv, pv_eq, branchCommon, tripC)

nPV = length(pv.s);

Vpv_c = ones(nPV,1) * Vc;
Uc_dummy = [0; Vpv_c];

I_alpha_aug = forced_injection_aug(Uc_dummy, pv, branchCommon);

G_alpha = sum(I_alpha_aug(2:end));

v_ctrl_c = pv_voltage_control_pu(Vc, pv_eq.Vbase_kV, pv_eq.Vctrl_base_kV);
tripBeta = (v_ctrl_c <= pv_eq.vtrip + 1e-10);

branchBeta = classify_equiv_branch(Vc, Vp, pv_eq, tripBeta);
branchBetaStar = classify_equiv_branch(Ve, Vp, pv_eq, tripEq);

eqBranchMismatch = double(branchBeta ~= branchBetaStar);

F_beta_Vc = equivalent_current_forced_branch(Vc, Vp, pv_eq, branchBeta);
F_betaStar_Vc = equivalent_current_forced_branch(Vc, Vp, pv_eq, branchBetaStar);

delta_ab = G_alpha - F_beta_Vc;

me_beta = F_beta_Vc - F_betaStar_Vc;

JF_beta_real = numerical_jacobian_equiv_forced_branch(Vc, Vp, pv_eq, branchBeta);
JF_betaStar_real = numerical_jacobian_equiv_forced_branch(Vc, Vp, pv_eq, branchBetaStar);

Yee_real = complex_matrix_to_real(Yeq_II);

Me_beta_real = Yee_real - JF_beta_real;
Me_betaStar_real = Yee_real - JF_betaStar_real;

condMeBeta = cond(Me_beta_real);
condMeBetaStar = cond(Me_betaStar_real);

% 实数二轴坐标下的等值侧传播算子：
% K_fs^beta     = -Y_pe^eq (M_e^beta)^(-1)
% K_fs^betaStar = -Y_pe^eq (M_e^betaStar)^(-1)
Yeq_pI_real = complex_matrix_to_real(Yeq_pI);
KfsBeta_real = -Yeq_pI_real / Me_beta_real;
KfsBetaStar_real = -Yeq_pI_real / Me_betaStar_real;

% 式(60)：efs ≈ -Yeq_pI * inv(M_e^beta) * delta_ab
rhs60_real = [real(delta_ab); imag(delta_ab)];

deltaV60_real = Me_beta_real \ rhs60_real;

deltaV60_complex = deltaV60_real(1) + 1j * deltaV60_real(2);

efs_consistent_approx = -Yeq_pI * deltaV60_complex;

% 式(63)：efs ≈ -Yeq_pI * inv(M_e^betaStar) * (delta_ab + me_beta)
rhs63_complex = delta_ab + me_beta;
rhs63_real = [real(rhs63_complex); imag(rhs63_complex)];

deltaV63_real = Me_betaStar_real \ rhs63_real;

deltaV63_complex = deltaV63_real(1) + 1j * deltaV63_real(2);

efs_func_approx = -Yeq_pI * deltaV63_complex;

end

%% ========================================================================
%  原始侧分支识别
% ========================================================================

function branchID = classify_all_branches(Vpv, pv, tripMask)

nPV = length(pv.s);
branchID = zeros(nPV,1);

for kk = 1:nPV
    branchID(kk) = classify_single_branch(Vpv(kk), pv.s(kk), pv.ctrlType(kk), kk, pv, tripMask(kk));
end

end

%% ========================================================================
%  单台设备分支识别
% ========================================================================
% 1：脱网
% 2：封波
% 3：正常恒功率，未限幅
% 4：正常恒功率，限幅
% 5：低穿恒功率，未限幅
% 6：低穿恒功率，限幅
% 7：低穿恒电流，未限幅
% 8：低穿恒电流，限幅

function bid = classify_single_branch(V, s_k, type, k, pv, isTrip)

if isTrip
    bid = 1;
    return;
end

v = pv_voltage_control_pu(V, pv.Vbase_kV, pv.Vctrl_base_kV);
v_safe = max(v, 1e-6);

cap = s_k / pv.Sbase_MVA;

Id0 = pv.Id0_single * cap;
Iq0 = pv.Iq0_single * cap;

if isfield(pv, 'Imax_single_vec') && ~isempty(pv.Imax_single_vec)
    Imax_single_k = pv.Imax_single_vec(k);
else
    Imax_single_k = pv.Imax_single;
end

Imax = Imax_single_k * cap * pv.Ilimit_base_ratio;

p0 = pv.vpre * Id0;

[~, ~, vblock] = get_threshold_by_type(type, pv);

if v <= vblock
    bid = 2;
    return;
end

if v >= pv.normalConstP.vmin && v <= pv.normalConstP.vmax

    id = p0 / v_safe;

    switch type
        case 1
            iq = pv.kq_type1 * max(pv.vLVRT - v, 0) * cap + Iq0;
        case 2
            iq = pv.kq_type2 * max(pv.vLVRT - v, 0) * cap + Iq0;
        otherwise
            error('未知控制类型。');
    end

    u0 = [id; iq];
    baseID = 3;

else

    switch type

        case 1
            id = p0 / v_safe;
            iq = pv.kq_type1 * max(pv.vLVRT - v, 0) * cap + Iq0;
            baseID = 5;

        case 2
            id = Id0;
            iq = pv.kq_type2 * max(pv.vLVRT - v, 0) * cap + Iq0;
            baseID = 7;

        otherwise
            error('未知控制类型。');
    end

    u0 = [id; iq];

end

u_lim = project_current_limit(u0, Imax, pv.priority);

if norm(u_lim - u0) > 1e-9
    bid = baseID + 1;
else
    bid = baseID;
end

end

%% ========================================================================
%  固定分支下的内部节点注入电流
% ========================================================================

function Iinj_aug = forced_injection_aug(U, pv, branchID)

nPV = length(pv.s);
Vpv = U(2:end);

I_PV = zeros(nPV,1);

for kk = 1:nPV
    I_PV(kk) = single_pv_current_forced_branch( ...
        Vpv(kk), pv.s(kk), pv.ctrlType(kk), kk, pv, branchID(kk));
end

Iinj_aug = [0; I_PV];

end

%% ========================================================================
%  单台设备固定分支电流函数
% ========================================================================

function I = single_pv_current_forced_branch(V, s_k, type, k, pv, branchID)

v_phase = abs(V);
v_phase_safe = max(v_phase, 1e-6);
eV = V / v_phase_safe;

v = pv_voltage_control_pu(V, pv.Vbase_kV, pv.Vctrl_base_kV);
v_safe = max(v, 1e-6);

cap = s_k / pv.Sbase_MVA;

Id0 = pv.Id0_single * cap;
Iq0 = pv.Iq0_single * cap;

if isfield(pv, 'Imax_single_vec') && ~isempty(pv.Imax_single_vec)
    Imax_single_k = pv.Imax_single_vec(k);
else
    Imax_single_k = pv.Imax_single;
end

Imax = Imax_single_k * cap * pv.Ilimit_base_ratio;

p0 = pv.vpre * Id0;

switch branchID

    case 1
        u = [0; 0];

    case 2
        u = [0; 0];

    case {3,4}
        id = p0 / v_safe;

        switch type
            case 1
                iq = pv.kq_type1 * max(pv.vLVRT - v, 0) * cap + Iq0;
            case 2
                iq = pv.kq_type2 * max(pv.vLVRT - v, 0) * cap + Iq0;
            otherwise
                error('未知控制类型。');
        end

        u0 = [id; iq];

        if branchID == 4
            u = project_current_limit(u0, Imax, pv.priority);
        else
            u = u0;
        end

    case {5,6}
        id = p0 / v_safe;
        iq = pv.kq_type1 * max(pv.vLVRT - v, 0) * cap + Iq0;

        u0 = [id; iq];

        if branchID == 6
            u = project_current_limit(u0, Imax, pv.priority);
        else
            u = u0;
        end

    case {7,8}
        id = Id0;
        iq = pv.kq_type2 * max(pv.vLVRT - v, 0) * cap + Iq0;

        u0 = [id; iq];

        if branchID == 8
            u = project_current_limit(u0, Imax, pv.priority);
        else
            u = u0;
        end

    otherwise
        error('未知分支编号。');

end

id = u(1);
iq = u(2);

I_local = id - 1j*iq;

I = I_local * eV;

end

%% ========================================================================
%  等值侧分支识别
% ========================================================================

function branchID = classify_equiv_branch(V, Vp, pv_eq, isTrip)

if isTrip
    branchID = 1;
    return;
end

v = pv_voltage_control_pu(V, pv_eq.Vbase_kV, pv_eq.Vctrl_base_kV);
v_safe = max(v, 1e-6);

vp_abs = pv_voltage_control_pu(Vp, pv_eq.Vbase_kV, pv_eq.Vctrl_base_kV);

cap = pv_eq.Seq / pv_eq.Sbase_MVA;

Id0 = pv_eq.Id0_single * cap;
Iq0 = pv_eq.Iq0_single * cap;

p0 = pv_eq.vpre * Id0;

Imax_constP = pv_eq.Imax_type1 * cap * pv_eq.Ilimit_base_ratio;
Imax_constI = pv_eq.Imax_type2 * cap * pv_eq.Ilimit_base_ratio;

iq_constP = pv_eq.kq_type1 * max(pv_eq.vLVRT - v, 0) * cap + Iq0;
iq_constI = pv_eq.kq_type2 * max(pv_eq.vLVRT - v, 0) * cap + Iq0;

if v <= pv_eq.vblock
    branchID = 2;
    return;
end

u_constP_0 = [p0 / v_safe; iq_constP];
u_constI_0 = [Id0; iq_constI];

u_constP_lim = project_current_limit(u_constP_0, Imax_constP, pv_eq.priority);
u_constI_lim = project_current_limit(u_constI_0, Imax_constI, pv_eq.priority);

isLimP = norm(u_constP_lim - u_constP_0) > 1e-9;
isLimI = norm(u_constI_lim - u_constI_0) > 1e-9;

if vp_abs >= pv_eq.vp_normal_min && vp_abs <= pv_eq.vp_normal_max

    if isLimP
        branchID = 4;
    else
        branchID = 3;
    end

else

    if ~isLimP && ~isLimI
        branchID = 5;
    elseif isLimP && ~isLimI
        branchID = 6;
    elseif ~isLimP && isLimI
        branchID = 7;
    else
        branchID = 8;
    end

end

end

%% ========================================================================
%  等值设备固定分支电流函数
% ========================================================================

function Ieq = equivalent_current_forced_branch(V, Vp, pv_eq, branchID)

v_phase = abs(V);
v_phase_safe = max(v_phase, 1e-6);
eV = V / v_phase_safe;

v = pv_voltage_control_pu(V, pv_eq.Vbase_kV, pv_eq.Vctrl_base_kV);
v_safe = max(v, 1e-6);

cap = pv_eq.Seq / pv_eq.Sbase_MVA;

Id0 = pv_eq.Id0_single * cap;
Iq0 = pv_eq.Iq0_single * cap;

p0 = pv_eq.vpre * Id0;

Imax_constP = pv_eq.Imax_type1 * cap * pv_eq.Ilimit_base_ratio;
Imax_constI = pv_eq.Imax_type2 * cap * pv_eq.Ilimit_base_ratio;

iq_constP = pv_eq.kq_type1 * max(pv_eq.vLVRT - v, 0) * cap + Iq0;
iq_constI = pv_eq.kq_type2 * max(pv_eq.vLVRT - v, 0) * cap + Iq0;

u_constP_0 = [p0 / v_safe; iq_constP];
u_constI_0 = [Id0; iq_constI];

switch branchID

    case 1
        u_mix = [0; 0];

    case 2
        u_mix = [0; 0];

    case 3
        u_mix = pv_eq.A * u_constP_0 + pv_eq.B * u_constP_0;

    case 4
        u_constP_lim = project_current_limit(u_constP_0, Imax_constP, pv_eq.priority);
        u_mix = pv_eq.A * u_constP_lim + pv_eq.B * u_constP_lim;

    case 5
        u_mix = pv_eq.A * u_constP_0 + pv_eq.B * u_constI_0;

    case 6
        u_constP_lim = project_current_limit(u_constP_0, Imax_constP, pv_eq.priority);
        u_mix = pv_eq.A * u_constP_lim + pv_eq.B * u_constI_0;

    case 7
        u_constI_lim = project_current_limit(u_constI_0, Imax_constI, pv_eq.priority);
        u_mix = pv_eq.A * u_constP_0 + pv_eq.B * u_constI_lim;

    case 8
        u_constP_lim = project_current_limit(u_constP_0, Imax_constP, pv_eq.priority);
        u_constI_lim = project_current_limit(u_constI_0, Imax_constI, pv_eq.priority);
        u_mix = pv_eq.A * u_constP_lim + pv_eq.B * u_constI_lim;

    otherwise
        error('未知等值分支编号。');

end

id = u_mix(1);
iq = u_mix(2);

I_local = id - 1j*iq;

Ieq = I_local * eV;

end

%% ========================================================================
%  固定分支注入电流的数值雅可比
% ========================================================================

function Jreal = numerical_jacobian_forced_injection(U0, pv, branchID)

n = length(U0);
x0 = [real(U0); imag(U0)];

Jreal = zeros(2*n, 2*n);

h0 = 1e-6;

for col = 1:2*n

    h = h0 * max(1, abs(x0(col)));

    xp = x0;
    xm = x0;

    xp(col) = xp(col) + h;
    xm(col) = xm(col) - h;

    Up = xp(1:n) + 1j*xp(n+1:end);
    Um = xm(1:n) + 1j*xm(n+1:end);

    Fp = forced_injection_aug(Up, pv, branchID);
    Fm = forced_injection_aug(Um, pv, branchID);

    fp = [real(Fp); imag(Fp)];
    fm = [real(Fm); imag(Fm)];

    Jreal(:,col) = (fp - fm) / (2*h);

end

end

%% ========================================================================
%  等值设备固定分支电流的数值雅可比
% ========================================================================

function Jreal = numerical_jacobian_equiv_forced_branch(V0, Vp, pv_eq, branchID)

x0 = [real(V0); imag(V0)];

Jreal = zeros(2,2);

h0 = 1e-6;

for col = 1:2

    h = h0 * max(1, abs(x0(col)));

    xp = x0;
    xm = x0;

    xp(col) = xp(col) + h;
    xm(col) = xm(col) - h;

    Vp1 = xp(1) + 1j*xp(2);
    Vm1 = xm(1) + 1j*xm(2);

    Fp = equivalent_current_forced_branch(Vp1, Vp, pv_eq, branchID);
    Fm = equivalent_current_forced_branch(Vm1, Vp, pv_eq, branchID);

    fp = [real(Fp); imag(Fp)];
    fm = [real(Fm); imag(Fm)];

    Jreal(:,col) = (fp - fm) / (2*h);

end

end

%% ========================================================================
%  复数矩阵转换为实数二轴矩阵
% ========================================================================

function Ar = complex_matrix_to_real(A)

Ar = [
    real(A), -imag(A);
    imag(A),  real(A)
];

end

%% ========================================================================
%  控制电压计算
% ========================================================================

function v_pu = pv_voltage_control_pu(V_complex_pu, Vbase_kV, Vctrl_base_kV)

V_rms_kV = abs(V_complex_pu) * Vbase_kV;

v_pu = V_rms_kV / Vctrl_base_kV;

end

%% ========================================================================
%  按控制类型读取阈值
% ========================================================================

function [vL, vtrip, vblock] = get_threshold_by_type(type, pv)

switch type

    case 1
        vL     = pv.constP.vL;
        vtrip  = pv.constP.vtrip;
        vblock = pv.constP.vblock;

    case 2
        vL     = pv.constI.vL;
        vtrip  = pv.constI.vtrip;
        vblock = pv.constI.vblock;

    otherwise
        error('未知控制类型。');

end

end

%% ========================================================================
%  电流限幅函数
% ========================================================================

function u = project_current_limit(u0, Imax, priority)

id0 = u0(1);
iq0 = u0(2);

switch priority

    case 'equal'

        mag = sqrt(id0^2 + iq0^2);

        if mag <= Imax
            u = u0;
        else
            u = u0 / mag * Imax;
        end

    case 'q_first'

        iq = max(min(iq0, Imax), -Imax);
        id_lim = sqrt(max(Imax^2 - iq^2, 0));
        id = max(min(id0, id_lim), -id_lim);
        u = [id; iq];

    case 'p_first'

        id = max(min(id0, Imax), -Imax);
        iq_lim = sqrt(max(Imax^2 - id^2, 0));
        iq = max(min(iq0, iq_lim), -iq_lim);
        u = [id; iq];

    otherwise

        error('priority 只能取 equal、q_first 或 p_first。');

end

end