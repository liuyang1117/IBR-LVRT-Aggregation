function photovoltaic_case


clc;
close all;

%% ============================================================
% 0. Per-unit base-value settings
%  0. 标幺基准值设置
% ============================================================

Sbase_MVA = 100;
Vbase_kV  = 10.5;
Vctrl_base_kV = 10.0;

Ilimit_base_ratio = Vbase_kV / Vctrl_base_kV;

Ibase_kA = Sbase_MVA / (sqrt(3) * Vbase_kV);
Ibase_A  = Ibase_kA * 1000;

% ================ Per-unit base values ================
disp('================ 标幺基准值 ================');
% System capacity base Sbase = %.4f MVA\n
fprintf('系统容量基准 Sbase = %.4f MVA\n', Sbase_MVA);
% Network voltage base Vbase = %.4f kV\n
fprintf('网络电压基准 Vbase = %.4f kV\n', Vbase_kV);
% Controller voltage base Vctrl_base = %.4f kV\n
fprintf('控制电压基准 Vctrl_base = %.4f kV\n', Vctrl_base_kV);
% Current-limit base conversion factor Ilimit_base_ratio = %.6f\n
fprintf('电流限幅换算系数 Ilimit_base_ratio = %.6f\n', Ilimit_base_ratio);
% Base current Ibase = %.6f kA\n
fprintf('基准电流 Ibase = %.6f kA\n', Ibase_kA);
% Base current Ibase = %.2f A\n
fprintf('基准电流 Ibase = %.2f A\n', Ibase_A);

%% ============================================================
% 1. Construct the system admittance matrix Y
%  1. 构造系统导纳矩阵 Y
% ============================================================

lineScale = 1;
Y = build_Y_7bus(lineScale);

nTotal = size(Y,1);
nPV = nTotal - 2;
nInternal = nTotal - 1;

%% ============================================================
% 2. PV capacity settings
%  2. 光伏容量设置
% ============================================================

s = [2;4;2;4;2;2];

if length(s) ~= nPV
    % The length of capacity vector s must equal the number of PV nodes.
    error('容量向量 s 的长度必须等于光伏节点数。');
end

Ssum = sum(s);
s_aug = [0; s];

% ================ PV capacity ================
disp('================ 光伏容量 ================');
% PV capacity vector s = [
fprintf('光伏容量向量 s = [');
fprintf(' %.4f', s);
fprintf(' ] MW\n');
% Augmented capacity vector s_aug = [
fprintf('扩展容量向量 s_aug = [');
fprintf(' %.4f', s_aug);
fprintf(' ] MW\n');
% Total PV capacity Ssum = %.4f MW\n
fprintf('光伏总容量 Ssum = %.4f MW\n', Ssum);
% Total PV capacity / system capacity base = %.6f p.u.\n
fprintf('光伏总容量 / 系统容量基准 = %.6f p.u.\n', Ssum / Sbase_MVA);

%% ============================================================
% 3. PV control-type settings
%  3. 光伏控制类型设置
% ============================================================
% type = 1: constant-power active-current control
% type = 1：恒功率型有功电流控制
% type = 2: constant-current active-current control
% type = 2：恒电流型有功电流控制

ctrlType = [1;1;1;2;2;2];

if length(ctrlType) ~= nPV
    % The length of ctrlType must equal the number of PV nodes.
    error('ctrlType 的长度必须等于光伏节点数。');
end

%% ============================================================
% 4. Admittance-matrix partitioning
%  4. 导纳矩阵分块
% ============================================================
% Original network equation:
% 原始网络方程：
%
%   [Ip]   [Ypp  YpI] [Vp]
%   [II] = [YIp  YII] [U ]
%
% where:
% 其中：
% Vp is the PCC voltage;
%   Vp 为并网点电压；
%   U = [V1; V2; ...; V7]；
% V1 is the passive intermediate node;
%   V1 为无源中间节点；
% V2 to V7 are PV terminal voltages.
%   V2~V7 为光伏端电压。

Ypp = Y(1,1);
YpI = Y(1,2:end);
YIp = Y(2:end,1);
YII = Y(2:end,2:end);

if length(s_aug) ~= nInternal
    % The length of s_aug must equal the number of internal nodes.
    error('s_aug 的长度必须等于内部节点数量。');
end

%% ============================================================
% 5. Construct the equivalent admittance matrix Yeq
%  5. 构造等值导纳矩阵 Yeq
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

% ================ Equivalent network parameters ================
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
% 6. Detailed-model PV control parameters
%  6. 详细模型光伏控制参数
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

% type = 1：恒功率型，限幅 1.1
pv.Imax_single_vec(ctrlType == 1) = 1.0;

% type = 2：恒电流型，限幅 1.0
pv.Imax_single_vec(ctrlType == 2) = 1.1;

if length(pv.Imax_single_vec) ~= nPV
    % The length of Imax_single_vec must equal the number of PV nodes.
    error('Imax_single_vec 的长度必须等于光伏节点数。');
end

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

% Current-limiting priority:
% 电流限幅方式：
% equal   : proportional current limiting;
% equal   ：等比例限幅；
% q_first : reactive-current priority;
% q_first ：无功优先；
% p_first : active-current priority.
% p_first ：有功优先。
pv.priority = 'q_first';

%% ============================================================
% 7. Detailed-model tripping-iteration parameters
%  7. 详细模型脱网迭代参数
% ============================================================

tripLatchAcrossVp = false;
tripMask_global = false(nPV,1);

maxTripIter = nPV + 5;
tripTol = 1e-10;

%% ============================================================
% 8. Equivalent PV parameters
%  8. 等值光伏参数
% ============================================================

idxP = (ctrlType == 1);
idxI = (ctrlType == 2);

SP = sum(s(idxP));
SI = sum(s(idxI));
Seq = Ssum;

Aeq = SP / Seq;
Beq = SI / Seq;

if abs(Aeq + Beq - 1) > 1e-10
    % Aeq + Beq is not equal to 1.
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

pv_eq.vpre = Vbase_kV / Vctrl_base_kV;

pv_eq.Imax_single = 1.05;

pv_eq.vL     = 0.90;
pv_eq.vtrip  = 0.35;
pv_eq.vblock = 0.19;

pv_eq.vp_normal_min = 0.90;
pv_eq.vp_normal_max = 1.20;
pv_eq.vp_min = 0.20;

pv_eq.gateWidth = pv.gateWidth;
pv_eq.priority  = pv.priority;

if ~(pv_eq.vblock < pv_eq.vtrip && pv_eq.vtrip < pv_eq.vL)
    % The equivalent PV thresholds are invalid and should satisfy vblock < vtrip < vL.
    error('等值光伏阈值设置错误，应满足 vblock < vtrip < vL。');
end

% \n================ Equivalent PV parameters ================\n
fprintf('\n================ 等值光伏参数 ================\n');
% Constant-power PV capacity SP = %.6f MW\n
fprintf('恒功率光伏容量 SP = %.6f MW\n', SP);
% Constant-current PV capacity SI = %.6f MW\n
fprintf('恒电流光伏容量 SI = %.6f MW\n', SI);
% Equivalent PV capacity Seq = %.6f MW\n
fprintf('等值光伏容量 Seq = %.6f MW\n', Seq);
% Constant-power capacity ratio Aeq = %.6f\n
fprintf('恒功率容量占比 Aeq = %.6f\n', Aeq);
% Constant-current capacity ratio Beq = %.6f\n
fprintf('恒电流容量占比 Beq = %.6f\n', Beq);
fprintf('Aeq + Beq = %.6f\n', Aeq + Beq);
% Initial active current of the equivalent PV model Id_eq_single = %.6f p.u.\n
fprintf('等值光伏初始有功电流 Id_eq_single = %.6f p.u.\n', pv_eq.Id0_single);
% Initial reactive current of the equivalent PV model Iq_eq_single = %.6f p.u.\n
fprintf('等值光伏初始无功电流 Iq_eq_single = %.6f p.u.\n', pv_eq.Iq0_single);
% Current limit of the equivalent PV model Imax_eq_single = %.6f p.u.\n
fprintf('等值光伏限幅值 Imax_eq_single = %.6f p.u.\n', pv_eq.Imax_single);
% Current-limit conversion factor of the equivalent PV model = %.6f\n
fprintf('等值光伏限幅换算系数 = %.6f\n', pv_eq.Ilimit_base_ratio);
% Pre-fault voltage of the equivalent PV model vpre_eq = %.6f p.u.\n
fprintf('等值光伏预故障电压 vpre_eq = %.6f p.u.\n', pv_eq.vpre);
% Trip threshold of the equivalent PV model vtrip_eq = %.6f p.u.\n
fprintf('等值光伏脱网阈值 vtrip_eq = %.6f p.u.\n', pv_eq.vtrip);
% Blocking threshold of the equivalent PV model vblock_eq = %.6f p.u.\n
fprintf('等值光伏封波阈值 vblock_eq = %.6f p.u.\n', pv_eq.vblock);

%% ============================================================
% 9. Sweep the PCC voltage
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

%% ============================================================
% 9.1 Common-voltage intermediate model and branch-mismatch analysis variables
%  9.1 公共电压中间模型和分支不一致分析变量
% ============================================================
% The common-voltage model is used for error decomposition:
% 公共电压模型用于误差分解：
%
%   H - Heq = evd + efs
%
% where:
% 其中：
% evd = H - Hc, denotes the voltage-dispersion error;
%   evd = H - Hc，表示电压分散误差；
% efs = Hc - Heq, denotes the function-structure error.
%   efs = Hc - Heq，表示函数结构误差。

Vc_vec = zeros(size(Vp_abs_vec));
Hc_vec = zeros(size(Vp_abs_vec));
G_Vc_vec = zeros(size(Vp_abs_vec));

evd_vec = zeros(size(Vp_abs_vec));
efs_vec = zeros(size(Vp_abs_vec));
etot_vec = zeros(size(Vp_abs_vec));

bcv_vec = zeros(size(Vp_abs_vec));
rI_norm_vec = zeros(size(Vp_abs_vec));

tripC_store = false(nPV, length(Vp_abs_vec));

% Consistent-branch approximation of the voltage-dispersion error
% 一致分支电压分散误差近似
% evd_50 = bcv + YpI * inv(M_I^alpha) * rI_alpha
evd_consistent_approx_vec = zeros(size(Vp_abs_vec));

% Inconsistent-branch approximation of the voltage-dispersion error
% 不一致分支电压分散误差近似
% evd_53 = bcv + YpI * inv(M_I^alphaStar) * (rI_alpha + mI)
evd_branch_approx_vec = zeros(size(Vp_abs_vec));

% Branch-adaptive approximation of the voltage-dispersion error:
% 分支自适应电压分散误差近似：

evd_piecewise_approx_vec = zeros(size(Vp_abs_vec));

mI_norm_vec = zeros(size(Vp_abs_vec));
rI_alpha_norm_vec = zeros(size(Vp_abs_vec));
branchMismatchCount_vec = zeros(size(Vp_abs_vec));
condM_vec = zeros(size(Vp_abs_vec));

% Condition numbers of M_I^alpha and M_I^alphaStar
% M_I^alpha 和 M_I^alphaStar 的条件数
% M_I^alpha     = YII - Jf_alpha(1Vc)
% M_I^alphaStar = YII - Jf_alphaStar(1Vc)
condMIAlpha_vec = zeros(size(Vp_abs_vec));
condMIAlphaStar_vec = zeros(size(Vp_abs_vec));

% Condition number of M_I after branch-adaptive selection:
% 分支自适应选择后的 M_I 条件数：
% Use M_I^alpha for the same branch and M_I^alphaStar for different branches
% 同一分支用 M_I^alpha，不同分支用 M_I^alphaStar
condMI_piecewise_vec = zeros(size(Vp_abs_vec));

% Original-side propagation operator: K_vd = YpI * M_I^(-1)
% 原始侧传播算子：K_vd = YpI * M_I^(-1)
% K_vd is a real two-axis matrix; its matrix 2-norm is used for plotting.
% K_vd 为实数二轴矩阵，绘图采用矩阵二范数。
KvdAlphaNorm_vec = zeros(size(Vp_abs_vec));
KvdAlphaStarNorm_vec = zeros(size(Vp_abs_vec));
Kvd_piecewiseNorm_vec = zeros(size(Vp_abs_vec));
Kvd_piecewise_real_store = cell(size(Vp_abs_vec));

branchCommon_store = zeros(nPV, length(Vp_abs_vec));
branchTrue_store   = zeros(nPV, length(Vp_abs_vec));

%% ============================================================
% 9.2 Function-structure error approximation variables
%  9.2 函数结构误差近似变量
% ============================================================
% Function-structure error:
% 函数结构误差：
%
%   efs = Hc - Heq

% Consistent-branch approximation of the function-structure error
% 一致分支函数结构误差近似
% efs_60 = -Yeq_pI * inv(M_e^beta) * delta_ab
efs_consistent_approx_vec = zeros(size(Vp_abs_vec));

% Inconsistent-branch approximation of the function-structure error
% 不一致分支函数结构误差近似
% efs_63 = -Yeq_pI * inv(M_e^betaStar) * (delta_ab + me)
efs_func_approx_vec = zeros(size(Vp_abs_vec));

% Branch-adaptive approximation of the function-structure error:
% 分支自适应函数结构误差近似：
efs_piecewise_approx_vec = zeros(size(Vp_abs_vec));

delta_ab_norm_vec = zeros(size(Vp_abs_vec));
me_norm_vec = zeros(size(Vp_abs_vec));
condMe_vec = zeros(size(Vp_abs_vec));

% New: separately store the condition numbers of M_e^beta and M_e^betaStar
% 新增：分别保存 M_e^beta 和 M_e^betaStar 的条件数
% M_e^beta     = Yeq_ee - JF_beta(Vc)
% M_e^betaStar = Yeq_ee - JF_betaStar(Vc)
condMeBeta_vec = zeros(size(Vp_abs_vec));
condMeBetaStar_vec = zeros(size(Vp_abs_vec));

% Condition number of M_e after branch-adaptive selection:
% 分支自适应选择后的 M_e 条件数：
% Use M_e^beta for the same branch and M_e^betaStar for different branches
% 同一分支用 M_e^beta，不同分支用 M_e^betaStar
condMe_piecewise_vec = zeros(size(Vp_abs_vec));

% Equivalent-side propagation operator: K_fs = -Yeq_pI * M_e^(-1)
% 等值侧传播算子：K_fs = -Yeq_pI * M_e^(-1)
% K_fs is a real two-axis matrix; its matrix 2-norm is used for plotting.
% K_fs 为实数二轴矩阵，绘图采用矩阵二范数。
KfsBetaNorm_vec = zeros(size(Vp_abs_vec));
KfsBetaStarNorm_vec = zeros(size(Vp_abs_vec));
Kfs_piecewiseNorm_vec = zeros(size(Vp_abs_vec));
Kfs_piecewise_real_store = cell(size(Vp_abs_vec));

eqBranchMismatch_vec = zeros(size(Vp_abs_vec));

branchBeta_vec = zeros(size(Vp_abs_vec));
branchBetaStar_vec = zeros(size(Vp_abs_vec));

%% ============================================================
% 10. fsolve solver settings
%  10. fsolve 求解器设置
% ============================================================

if exist('fsolve','file') ~= 2
    % fsolve from Optimization Toolbox is required.
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
% 11. Solve the detailed model, equivalent model, and common-voltage model
%  11. 求解详细模型、等值模型和公共电压模型
% ============================================================

for k = 1:length(Vp_abs_vec)

    Vp = Vp_abs_vec(k) * exp(1j*theta_p);

    %% ================= Detailed-model solution =================
    %% ================= 详细模型求解 =================

    if tripLatchAcrossVp
        tripMask = tripMask_global;
    else
        tripMask = false(nPV,1);
    end

    x_sol = x0;

    U = x_sol(1:nInternal) + 1j*x_sol(nInternal+1:end);
    V1 = U(1);
    VI = U(2:end);

    for tripIter = 1:maxTripIter

        tripMask_old = tripMask;

        fun = @(x) residual_equation_trip_iter_with_node0_in_Y( ...
            x, Vp, YIp, YII, pv, tripMask);

        [x_sol, ~, exitflag] = fsolve(fun, x0, opt);

        if exitflag <= 0
            % English note: detailed model: Vp = %.4f, tripped迭代 %d 时 fsolve may not have converged.
            warning('详细模型：Vp = %.4f，脱网迭代 %d 时 fsolve 可能未收敛。', ...
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
        % detailed model: Vp = %.4f reached the maximum number of tripping iterations.
        warning('详细模型：Vp = %.4f 达到最大脱网迭代次数。', Vp_abs_vec(k));
    end

    if tripLatchAcrossVp
        tripMask_global = tripMask;
    end

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

    %% ================= Equivalent-model solution =================
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
        % English note: equivalent model: Vp = %.4f 时may not have converged.
        warning('等值模型：Vp = %.4f 时可能未收敛。', Vp_abs_vec(k));
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

    %% ================= Common-voltage intermediate-model solution =================
    %% ================= 公共电压中间模型求解 =================
    % Common-voltage model:
    % 公共电压模型：
    %
    %   Yeq_Ip*Vp + Yeq_II*Vc = G(Vc)
    %
    %   G(Vc) = sum_i f_i(Vc)
    %
    % This assumes all PV terminal voltages are equal to Vc and then sums the current of each PV unit.
    % 即假设所有光伏端电压都等于 Vc，然后把每台光伏电流相加。

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
        % English note: Common-voltage model: Vp = %.4f 时may not have converged.
        warning('公共电压模型：Vp = %.4f 时可能未收敛。', Vp_abs_vec(k));
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

    %% ================= Approximation of voltage-dispersion error using Eq. (50)/(53) =================
    %% ================= 电压分散误差式（50）/（53）近似 =================

    [evd_consistent_approx, evd_branch_approx, mI_aug, rI_alpha_aug, condM, ...
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

    %% ================= Approximation of function-structure error using Eq. (60)/(63) =================
    %% ================= 函数结构误差式（60）/（63）近似 =================

    [efs_consistent_approx, efs_func_approx, delta_ab, me_beta, condMe, ...
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

    % Branch-adaptive selection
    % 分支自适应选择
    if branchMismatchCount == 0
        evd_piecewise_approx_vec(k) = evd_consistent_approx;
    else
        evd_piecewise_approx_vec(k) = evd_branch_approx;
    end

    mI_norm_vec(k) = norm(mI_aug);
    rI_alpha_norm_vec(k) = norm(rI_alpha_aug);
    branchMismatchCount_vec(k) = branchMismatchCount;
    condM_vec(k) = condM;
    condMIAlpha_vec(k) = condMIAlpha;
    condMIAlphaStar_vec(k) = condMIAlphaStar;

    % M_I condition numberBranch-adaptive selection:
    % M_I 条件数分支自适应选择：
    % branchMismatchCount = 0 use M_I^alpha
    % branchMismatchCount = 0 时使用 M_I^alpha
    % branchMismatchCount > 0 use M_I^alphaStar
    % branchMismatchCount > 0 时使用 M_I^alphaStar
    if branchMismatchCount == 0
        condMI_piecewise_vec(k) = condMIAlpha;
    else
        condMI_piecewise_vec(k) = condMIAlphaStar;
    end

    % fused YpI(M_I^alpha)^(-1) and YpI(M_I^alphaStar)^(-1)
    % 融合 YpI(M_I^alpha)^(-1) 与 YpI(M_I^alphaStar)^(-1)
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

    % Branch-adaptive selection
    % 分支自适应选择
    if eqBranchMismatch == 0
        efs_piecewise_approx_vec(k) = efs_consistent_approx;
    else
        efs_piecewise_approx_vec(k) = efs_func_approx;
    end

    delta_ab_norm_vec(k) = abs(delta_ab);
    me_norm_vec(k) = abs(me_beta);
    condMe_vec(k) = condMe;
    condMeBeta_vec(k) = condMeBeta;
    condMeBetaStar_vec(k) = condMeBetaStar;

    % M_e condition numberBranch-adaptive selection:
    % M_e 条件数分支自适应选择：
    % eqBranchMismatch = 0 use M_e^beta
    % eqBranchMismatch = 0 时使用 M_e^beta
    % eqBranchMismatch = 1 use M_e^betaStar
    % eqBranchMismatch = 1 时使用 M_e^betaStar
    if eqBranchMismatch == 0
        condMe_piecewise_vec(k) = condMeBeta;
    else
        condMe_piecewise_vec(k) = condMeBetaStar;
    end

    % fused -Yeq_pI(M_e^beta)^(-1) and -Yeq_pI(M_e^betaStar)^(-1)
    % 融合 -Yeq_pI(M_e^beta)^(-1) 与 -Yeq_pI(M_e^betaStar)^(-1)
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
% 12. Sort by voltage in ascending order
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
mI_norm_plot = mI_norm_vec(idxPlot);
rI_alpha_norm_plot = rI_alpha_norm_vec(idxPlot);
branchMismatchCount_plot = branchMismatchCount_vec(idxPlot);
condM_original_plot = condM_vec(idxPlot);
condMIAlpha_plot = condMIAlpha_vec(idxPlot);
condMIAlphaStar_plot = condMIAlphaStar_vec(idxPlot);
condMI_piecewise_plot = condMI_piecewise_vec(idxPlot);

KvdAlphaNorm_plot = KvdAlphaNorm_vec(idxPlot);
KvdAlphaStarNorm_plot = KvdAlphaStarNorm_vec(idxPlot);
Kvd_piecewiseNorm_plot = Kvd_piecewiseNorm_vec(idxPlot);
Kvd_piecewise_real_plot = Kvd_piecewise_real_store(idxPlot);

% Compatibility with the old variable name: use the condition number after actual branch-adaptive selection by default
% 兼容旧变量名：默认使用实际分支自适应选择后的条件数
condM_plot = condMI_piecewise_plot;

branchCommon_plot = branchCommon_store(:,idxPlot);
branchTrue_plot   = branchTrue_store(:,idxPlot);

efs_consistent_approx_plot = efs_consistent_approx_vec(idxPlot);
efs_func_approx_plot = efs_func_approx_vec(idxPlot);
efs_piecewise_approx_plot = efs_piecewise_approx_vec(idxPlot);
delta_ab_norm_plot = delta_ab_norm_vec(idxPlot);
me_norm_plot = me_norm_vec(idxPlot);
condMe_original_plot = condMe_vec(idxPlot);
condMeBeta_plot = condMeBeta_vec(idxPlot);
condMeBetaStar_plot = condMeBetaStar_vec(idxPlot);
condMe_piecewise_plot = condMe_piecewise_vec(idxPlot);

KfsBetaNorm_plot = KfsBetaNorm_vec(idxPlot);
KfsBetaStarNorm_plot = KfsBetaStarNorm_vec(idxPlot);
Kfs_piecewiseNorm_plot = Kfs_piecewiseNorm_vec(idxPlot);
Kfs_piecewise_real_plot = Kfs_piecewise_real_store(idxPlot);

% Compatibility with the old variable name: use the condition number after actual branch-adaptive selection by default
% 兼容旧变量名：默认使用实际分支自适应选择后的条件数
condMe_plot = condMe_piecewise_plot;

eqBranchMismatch_plot = eqBranchMismatch_vec(idxPlot);

branchBeta_plot = branchBeta_vec(idxPlot);
branchBetaStar_plot = branchBetaStar_vec(idxPlot);

%% ============================================================
% 13. Current conversion
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

% Branch-adaptive result of the total error: Result 1 + Result 2
% 总误差分支自适应结果：结果1 + 结果2
% Result 1 = evd_piecewise_approx, Result 2 = efs_piecewise_approx
% 结果1 = evd_piecewise_approx，结果2 = efs_piecewise_approx
% Note: first add in the complex domain, then take the magnitude.
% 注意：这里先在复数域相加，再取模。
etot_piecewise_approx_plot = evd_piecewise_approx_plot + efs_piecewise_approx_plot;
etot_piecewise_approx_3ph_pu = sqrt(3) * abs(etot_piecewise_approx_plot);

bcv_line_pu = abs(bcv_plot);
bcv_3ph_pu = sqrt(3) * bcv_line_pu;

Ip_line_pu_theory = pv.Id0_single * Ssum / Sbase_MVA;
Ip_3ph_pu_theory  = sqrt(3) * Ip_line_pu_theory;

[~, idx1] = min(abs(Vp_plot - 1.0));

% \n================ Steady-state current check ================\n
fprintf('\n================ 稳态电流校验 ================\n');
% Theoretical line-current per-unit value Iline_pu = 0.5*Ssum/Sbase = %.6f\n
fprintf('理论线电流标幺值 Iline_pu = 0.5*Ssum/Sbase = %.6f\n', Ip_line_pu_theory);
% Theoretical three-phase combined per-unit value I3ph_pu = sqrt(3)*Iline_pu = %.6f\n
fprintf('理论三相合成标幺值 I3ph_pu = sqrt(3)*Iline_pu = %.6f\n', Ip_3ph_pu_theory);
% Line-current per-unit value of detailed-model H at Vp=1 = %.6f\n
fprintf('详细模型 H 在 Vp=1 时线电流标幺值 = %.6f\n', Ip_line_pu_from_actual(idx1));
% Three-phase combined per-unit value of detailed-model H at Vp=1 = %.6f\n
fprintf('详细模型 H 在 Vp=1 时三相合成标幺值 = %.6f\n', Ip_3ph_pu_from_actual(idx1));
% Three-phase combined per-unit value of common-voltage model Hc at Vp=1 = %.6f\n
fprintf('公共电压模型 Hc 在 Vp=1 时三相合成标幺值 = %.6f\n', Hc_3ph_pu(idx1));
% Line-current per-unit value of equivalent-model Heq at Vp=1 = %.6f\n
fprintf('等值模型 Heq 在 Vp=1 时线电流标幺值 = %.6f\n', Ipeq_line_pu_from_actual(idx1));
% Three-phase combined per-unit value of equivalent-model Heq at Vp=1 = %.6f\n
fprintf('等值模型 Heq 在 Vp=1 时三相合成标幺值 = %.6f\n', Ipeq_3ph_pu_from_actual(idx1));
% Number of tripped units in the detailed model at Vp=1 = %d\n
fprintf('详细模型 Vp=1 时脱网数量 = %d\n', tripCount_plot(idx1));
% Number of tripped units in the common-voltage model at Vp=1 = %d\n
fprintf('公共电压模型 Vp=1 时脱网数量 = %d\n', tripC_count_plot(idx1));
% Tripping state of the equivalent model at Vp=1 = %d\n
fprintf('等值模型 Vp=1 时脱网状态 = %d\n', tripEq_plot(idx1));
% English note: Error-decomposition check |(evd+efs)-etot| 在 Vp=1 时 = %.4e\n
fprintf('误差分解校验 |(evd+efs)-etot| 在 Vp=1 时 = %.4e\n', ...
    abs((evd_plot(idx1) + efs_plot(idx1)) - etot_plot(idx1)));
% English note: Number of voltage-dispersion branch mismatches Vp=1 时 = %d\n
fprintf('电压分散分支不一致数量 Vp=1 时 = %d\n', branchMismatchCount_plot(idx1));
% English note: 式(50)approximation error |evd_50-evd| Vp=1 时 = %.4e\n
fprintf('式(50)近似误差 |evd_50-evd| Vp=1 时 = %.4e\n', ...
    abs(evd_consistent_approx_plot(idx1) - evd_plot(idx1)));
% English note: 式(53)approximation error |evd_53-evd| Vp=1 时 = %.4e\n
fprintf('式(53)近似误差 |evd_53-evd| Vp=1 时 = %.4e\n', ...
    abs(evd_branch_approx_plot(idx1) - evd_plot(idx1)));
% English note: Equivalent-branch mismatch flag Vp=1 时 = %d\n
fprintf('等值分支不一致标志 Vp=1 时 = %d\n', eqBranchMismatch_plot(idx1));
% English note: Function-structure residual |delta_alpha_beta| Vp=1 时 = %.4e\n
fprintf('函数结构残差 |delta_alpha_beta| Vp=1 时 = %.4e\n', delta_ab_norm_plot(idx1));
% English note: Equivalent-side branch-switching residual |me| Vp=1 时 = %.4e\n
fprintf('等值分支切换残差 |me| Vp=1 时 = %.4e\n', me_norm_plot(idx1));
% English note: 式(60)approximation error |efs_60-efs| Vp=1 时 = %.4e\n
fprintf('式(60)近似误差 |efs_60-efs| Vp=1 时 = %.4e\n', ...
    abs(efs_consistent_approx_plot(idx1) - efs_plot(idx1)));
% English note: 式(63)approximation error |efs_63-efs| Vp=1 时 = %.4e\n
fprintf('式(63)近似误差 |efs_63-efs| Vp=1 时 = %.4e\n', ...
    abs(efs_func_approx_plot(idx1) - efs_plot(idx1)));
% English note: cond(M_I^alpha) Vp=1 时 = %.4e\n
fprintf('cond(M_I^alpha) Vp=1 时 = %.4e\n', condMIAlpha_plot(idx1));
% English note: cond(M_I^alphaStar) Vp=1 时 = %.4e\n
fprintf('cond(M_I^alphaStar) Vp=1 时 = %.4e\n', condMIAlphaStar_plot(idx1));
% English note: cond(M_e^beta) Vp=1 时 = %.4e\n
fprintf('cond(M_e^beta) Vp=1 时 = %.4e\n', condMeBeta_plot(idx1));
% English note: cond(M_e^betaStar) Vp=1 时 = %.4e\n
fprintf('cond(M_e^betaStar) Vp=1 时 = %.4e\n', condMeBetaStar_plot(idx1));
% English note: branch自适应 |evd_piecewise-evd| Vp=1 时 = %.4e\n
fprintf('分支自适应 |evd_piecewise-evd| Vp=1 时 = %.4e\n', ...
    abs(evd_piecewise_approx_plot(idx1) - evd_plot(idx1)));
% English note: branch自适应 |efs_piecewise-efs| Vp=1 时 = %.4e\n
fprintf('分支自适应 |efs_piecewise-efs| Vp=1 时 = %.4e\n', ...
    abs(efs_piecewise_approx_plot(idx1) - efs_plot(idx1)));
% English note: cond(M_I_piecewise) Vp=1 时 = %.4e\n
fprintf('cond(M_I_piecewise) Vp=1 时 = %.4e\n', condMI_piecewise_plot(idx1));
% English note: cond(M_e_piecewise) Vp=1 时 = %.4e\n
fprintf('cond(M_e_piecewise) Vp=1 时 = %.4e\n', condMe_piecewise_plot(idx1));
% English note: Vp=1 时 |b_cv|_3ph = %.4e p.u.\n
fprintf('Vp=1 时 |b_cv|_3ph = %.4e p.u.\n', bcv_3ph_pu(idx1));
% English note: Vp=1 时 ||YpI M_I^(-1)||_2(fused) = %.4e\n
fprintf('Vp=1 时 ||YpI M_I^(-1)||_2（融合） = %.4e\n', Kvd_piecewiseNorm_plot(idx1));
% English note: Vp=1 时 ||-Ype^eq M_e^(-1)||_2(fused) = %.4e\n
fprintf('Vp=1 时 ||-Ype^eq M_e^(-1)||_2（融合） = %.4e\n', Kfs_piecewiseNorm_plot(idx1));
% Error-decomposition checkmaximum value = %.4e\n
fprintf('误差分解校验最大值 = %.4e\n', max(error_decomp_check_3ph_pu));

%% ============================================================
% English note: 14. Vp = 1 时 of voltage information
%  14. Vp = 1 时的电压信息
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
    'VariableNames', {'Real_Veq', 'Imag_Veq', 'Abs_Veq', 'Angle_deg'} ...
);

% English note: \n================ Vp = 1 时 of voltage information ================\n
fprintf('\n================ Vp = 1 时的电压信息 ================\n');
fprintf('Vp = %.6f p.u.\n\n', Vp1);

% Passive node of the detailed model V1: %.6f + j%.6f, abs = %.6f, angle = %.4f deg\n\n
fprintf('详细模型无源节点 V1：%.6f + j%.6f, abs = %.6f, angle = %.4f deg\n\n', ...
    real(V1_detail_vp1), imag(V1_detail_vp1), ...
    V1_detail_abs_vp1, V1_detail_ang_vp1);

% Voltages of all PV nodes in the detailed model:
disp('详细模型各光伏节点电压：');
disp(T_detail);

% Common-voltage model Vc:
disp('公共电压模型 Vc：');
disp(T_common);

% Equivalent-model voltage Ve:
disp('等值模型电压 Ve：');
disp(T_eq);

%% ============================================================
% 15. Plotting
%  15. 画图
% ============================================================

fontName = 'Times New Roman';

axisFontSize   = 16;
labelFontSize  = 18;
legendFontSize = 12;
titleFontSize  = 10;
largeLegendFontSize = 14;
emtTextFontSize = 12;


%% 15.1 Aggregation error decomposition
%% 15.1 聚合误差分解

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
ylim([0, 0.18]);
set(lgd, ...
    'FontName', fontName, ...
    'FontSize', legendFontSize);

set(gca, ...
    'FontName', fontName, ...
    'FontSize', axisFontSize, ...
    'LineWidth', 1.2);
% Add the letter B in the lower-right corner inside the axes
% 在坐标区内部右下角添加字母 B
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
    'Name', '聚合误差分解', ...
    'NumberTitle', 'off');


% ============================================================
%  15.2 CaseIa-Comparison of PCC current among the detailed model, equivalent model, EMT, and EMTeq
%  15.2 CaseIa-并网点电流详细模型、等值模型与 EMT/EMTeq 对比
% ============================================================


figure;

h_detail = plot(Vp_pu_from_actual, Ip_3ph_pu_from_actual, ...
    'LineWidth', 1.8, ...
    'DisplayName', 'Original Cluster Model');
hold on;

h_equiv = plot(Vp_pu_from_actual, Ipeq_3ph_pu_from_actual, ...
    '--', ...
    'LineWidth', 1.8, ...
    'DisplayName', 'Aggregated Equivalent Model');

EMT_points_compare = [
    1.00, 0.1413024;
    0.80, 0.175191;
    0.60, 0.23137163;
    0.50, 0.2784;
    0.40, 0.29214;
    0.20, 0.00567
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
    1.00, 0.1413022;
    0.80, 0.174507;
    0.60, 0.23226;
    0.50, 0.2777;
    0.40, 0.29164;
    0.20, 0.0057
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

ylim([-0.05, 0.35]);

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
    'Name', '并网点电流详细模型、等值模型与EMT对比', ...
    'NumberTitle', 'off');

% ============================================================
% 15.3 CaseIb-Comparison of PCC current among the detailed model, equivalent model, EMT, and EMTeq
%  15.3 CaseIb-并网点电流详细模型、等值模型与 EMT/EMTeq 对比
% ============================================================

% 
% figure;
% 
% h_detail = plot(Vp_pu_from_actual, Ip_3ph_pu_from_actual, ...
%     'LineWidth', 1.8, ...
%     'DisplayName', 'Original Cluster Model');
% hold on;
% 
% h_equiv = plot(Vp_pu_from_actual, Ipeq_3ph_pu_from_actual, ...
%     '--', ...
%     'LineWidth', 1.8, ...
%     'DisplayName', 'Aggregated Equivalent Model');
% 
% EMT_points_compare = [
%     1.00, 0.1413024;
%     0.80, 0.1577401;
%     0.60, 0.18586;
%     0.50, 0.20876;
%     0.40, 0.2155;
%     0.20, 0.00567
% ];
% 
% h_emt = plot(EMT_points_compare(:,1), EMT_points_compare(:,2), ...
%     'ko', ...
%     'LineStyle', 'none', ...
%     'MarkerSize', 6, ...
%     'MarkerFaceColor', 'none', ...
%     'MarkerEdgeColor', 'k', ...
%     'LineWidth', 1.2, ...
%     'DisplayName', 'EMT');
% 
% EMTeq_points_compare = [
%     1.00, 0.1413024;
%     0.80, 0.15749;
%     0.60, 0.18586;
%     0.50, 0.2081466;
%     0.40, 0.2155;
%     0.20, 0.005677
% ];
% 
% h_emteq = plot(EMTeq_points_compare(:,1), EMTeq_points_compare(:,2), ...
%     'k^', ...
%     'LineStyle', 'none', ...
%     'MarkerSize', 6, ...
%     'MarkerFaceColor', 'none', ...
%     'MarkerEdgeColor', 'k', ...
%     'LineWidth', 1.2, ...
%     'DisplayName', 'EMTeq');
% 
% grid on;
% 
% xlabel('$|V_p|({\rm p.u.})$', ...
%     'Interpreter', 'latex', ...
%     'FontSize', labelFontSize);
% 
% ylabel('$|I_p|({\rm p.u.})$', ...
%     'Interpreter', 'latex', ...
%     'FontSize', labelFontSize);
% 
% legend([h_detail, h_equiv, h_emt, h_emteq], ...
%     {'Original', 'Aggregated', 'EMT', 'EMTeq'}, ...
%     'Location', 'northeast');
% 
% ylim([-0.05, 0.27]);
% 
% text(0.95, 0.05, 'B', ...
%     'Units', 'normalized', ...
%     'HorizontalAlignment', 'right', ...
%     'VerticalAlignment', 'bottom', ...
%     'FontName', 'Times New Roman', ...
%     'FontSize', 16, ...
%     'FontWeight', 'bold', ...
%     'Color', 'k');
% 
% set(gcf, ...
%     'Color', 'w', ...
%     'Name', '并网点电流详细模型、等值模型与EMT对比', ...
%     'NumberTitle', 'off');


%% ============================================================
% 15.4 CaseII-Comparison of PCC current among the detailed model, equivalent model, EMT, and EMTeq
%  15.4 CaseII-并网点电流详细模型、等值模型与 EMT/EMTeq 对比
% ============================================================

figure;

h_detail = plot(Vp_pu_from_actual, Ip_3ph_pu_from_actual, ...
    'LineWidth', 1.8, ...
    'DisplayName', 'Original Cluster Model');
hold on;

h_equiv = plot(Vp_pu_from_actual, Ipeq_3ph_pu_from_actual, ...
    '--', ...
    'LineWidth', 1.8, ...
    'DisplayName', 'Aggregated Equivalent Model');

EMT_points_compare = [
    1.00, 0.1413024;
    0.80, 0.1577401;
    0.60, 0.18586;
    0.50, 0.20876;
    0.40, 0.2155;
    0.35,0.0701;
    0.20, 0.00567
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
    1.00, 0.1413024;
    0.80, 0.157731;
    0.60, 0.1858559;
    0.50, 0.2088438;
    0.40, 0.2219;
    0.35,0.2221;
    0.20, 0.005689
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

ylim([-0.05, 0.27]);

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
    'Name', '并网点电流详细模型、等值模型与EMT对比', ...
    'NumberTitle', 'off');

% %% ============================================================
% %  15.2 CaseIII-Comparison of PCC current among the detailed model, equivalent model, EMT, and EMTeq
% %  15.2 CaseIII-并网点电流详细模型、等值模型与 EMT/EMTeq 对比
% % ============================================================
% figure;
% 
% h_detail = plot(Vp_pu_from_actual, Ip_3ph_pu_from_actual, ...
%     'LineWidth', 1.8, ...
%     'DisplayName', 'Original Cluster Model');
% hold on;
% 
% h_equiv = plot(Vp_pu_from_actual, Ipeq_3ph_pu_from_actual, ...
%     '--', ...
%     'LineWidth', 1.8, ...
%     'DisplayName', 'Aggregated Equivalent Model');
% EMT_points_compare = [
%     1.00, 0.1394488;
%     0.80, 0.1550288;
%     0.60, 0.1809686;
%     0.50, 0.2012946;
%     0.40, 0.2142338;
%     0.30, 0.0084786;
%     0.20, 0.0056589
% ];
% 
% h_emt = plot(EMT_points_compare(:,1), EMT_points_compare(:,2), ...
%     'ko', ...
%     'LineStyle', 'none', ...
%     'MarkerSize', 6, ...
%     'MarkerFaceColor', 'none', ...
%     'MarkerEdgeColor', 'k', ...
%     'LineWidth', 1.2, ...
%     'DisplayName', 'EMT');
% 
% EMTeq_points_compare = [
%     1.00, 0.1394429;
%     0.80, 0.1548385;
%     0.60, 0.1813318;
%     0.50, 0.2023876;
%     0.40, 0.2136689;
%     0.30, 0.008553;
%     0.20, 0.0057237
% ];
% 
% h_emteq = plot(EMTeq_points_compare(:,1), EMTeq_points_compare(:,2), ...
%     'k^', ...
%     'LineStyle', 'none', ...
%     'MarkerSize', 6, ...
%     'MarkerFaceColor', 'none', ...
%     'MarkerEdgeColor', 'k', ...
%     'LineWidth', 1.2, ...
%     'DisplayName', 'EMTeq');
% 
% grid on;
% 
% xlabel('$|V_p|({\rm p.u.})$', ...
%     'Interpreter', 'latex', ...
%     'FontSize', labelFontSize);
% 
% ylabel('$|I_p|({\rm p.u.})$', ...
%     'Interpreter', 'latex', ...
%     'FontSize', labelFontSize);
% 
% legend([h_detail, h_equiv, h_emt, h_emteq], ...
%     {'Original', 'Aggregated', 'EMT', 'EMTeq'}, ...
%     'Location', 'northeast');
% 
% ylim([-0.05, 0.27]);
% 
% 
% text(0.95, 0.05, 'B', ...
%     'Units', 'normalized', ...
%     'HorizontalAlignment', 'right', ...
%     'VerticalAlignment', 'bottom', ...
%     'FontName', 'Times New Roman', ...
%     'FontSize', 16, ...
%     'FontWeight', 'bold', ...
%     'Color', 'k');
% 
% set(gcf, ...
%     'Color', 'w', ...
%     'Name', '并网点电流详细模型、等值模型与EMT对比', ...
%     'NumberTitle', 'off');



y_etot = etot_3ph_pu;
y_evd  = evd_3ph_pu;
y_efs  = efs_3ph_pu;

% If the horizontal-axis samples are equally spaced, use the ordinary RMS
% 如果横坐标采样点等间距，用普通 RMS
rms_etot = sqrt(mean(y_etot.^2));
rms_evd  = sqrt(mean(y_evd.^2));
rms_efs  = sqrt(mean(y_efs.^2));

fprintf('|e_tot| RMS = %.6e p.u.\n', rms_etot);
fprintf('|e_vd | RMS = %.6e p.u.\n', rms_evd);
fprintf('|e_fs | RMS = %.6e p.u.\n', rms_efs);
%% ============================================================
% Uniformly set the font family and font size for all figures
%  统一设置所有图片字体和字号
% Note: EMT annotations keep a separate smaller font size
%  注意：EMT 标注单独保持小字号
% ============================================================

% Font settings
% 字体设置
fontName = 'Times New Roman';

% Font-size settings
% 字号设置
% axisFontSize    = 16;   % font size of axis tick labels
axisFontSize    = 16;   % 坐标轴刻度数字字号
% labelFontSize   = 18;   % x/y font size of x/y axis labels
labelFontSize   = 18;   % x/y 坐标轴标题字号
% titleFontSize   = 10;   % font size of figure titles
titleFontSize   = 10;   % 图标题字号
% legendFontSize  = 12;   % font size of legends
legendFontSize  = 12;   % 图例字号
% emtTextFontSize = 12;    % font size of EMT annotations; reduce to 3.5 if it is still too large
emtTextFontSize = 12;    % EMT 标注字号，觉得还大可以改成 3.5

% Get all figures
% 获取所有 figure
figHandles = findall(0, 'Type', 'figure');

for iFig = 1:length(figHandles)

    fig = figHandles(iFig);

    % Set the figure background to white
    % 设置图背景为白色
    set(fig, 'Color', 'w');

    % Find all axes in the current figure
    % 找到当前 figure 中所有坐标轴
    axList = findall(fig, 'Type', 'axes');

    for iAx = 1:length(axList)

        ax = axList(iAx);

        % Font family and font size of axis tick labels
        % 坐标轴刻度数字字体和字号
        set(ax, ...
            'FontName', fontName, ...
            'FontSize', axisFontSize, ...
            'LineWidth', 1.2);

        % x-axis label
        % x 轴标签
        ax.XLabel.FontName = fontName;
        ax.XLabel.FontSize = labelFontSize;

        % y-axis label
        % y 轴标签
        ax.YLabel.FontName = fontName;
        ax.YLabel.FontSize = labelFontSize;

        % title
        % 标题
        ax.Title.FontName = fontName;
        ax.Title.FontSize = titleFontSize;

    end

    % Modify legend font
    % 修改图例字体
% English note: 注意: Legends with Tag = LargeLegend keep a large font size and are not affected by the unified legendFontSize
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

    % Only modify EMT annotations separately; do not change all text objects to size 18
    % 只单独修改 EMT 标注，不再把所有 text 都改成 18 号
    textList = findall(fig, 'Type', 'text');

    for iTxt = 1:length(textList)

        txt = textList(iTxt);
        txtStr = get(txt, 'String');
        txtTag = get(txt, 'Tag');

        % Case 1: Tag was set in the previous text() call 'Tag','EMTText'
        % 情况1：前面 text() 里设置了 'Tag','EMTText'
        % Case 2: Tag is not set, but the text contains EMT
        % 情况2：没有设置 Tag，但文字里包含 EMT
        if strcmp(txtTag, 'EMTText') || contains(string(txtStr), 'EMT')

            set(txt, ...
                'FontName', fontName, ...
                'FontSize', emtTextFontSize);

        end

    end
end
% % % ============================================================
% %  Save all figures as PNG files using each figure Name
% %  保存所有图片为 PNG：按 figure 的 Name 命名
% % ============================================================
% 
% English note: % Figure save folder: 桌面\项目excel\论文figure\同输入
% % 图片保存文件夹：桌面\项目excel\论文图片\同输入
% if ispc && ~isempty(getenv('USERPROFILE'))
%     figSaveDir = fullfile(getenv('USERPROFILE'), ...
% English note: 'Desktop', '项目excel', '论文figure', '同输入','含shunt','不同质, 其余不同');
%         'Desktop', '项目excel', '论文图片', '同输入','含shunt','不同质，其余不同');
% else
%     figSaveDir = fullfile(pwd, 'results');
% end
% 
% % Create the folder automatically if it does not exist
% % 如果文件夹不存在，则自动创建
% if ~exist(figSaveDir, 'dir')
%     mkdir(figSaveDir);
% end
% 
% English note: % 获取当前所有 figure
% % 获取当前所有 figure
% figHandles = findall(0, 'Type', 'figure');
% 
% % Sort by figure number
% % 按 figure 编号排序
% [~, idxFig] = sort([figHandles.Number]);
% figHandles = figHandles(idxFig);
% 
% for iFig = 1:length(figHandles)
% 
%     fig = figHandles(iFig);
% 
% English note: % settings白色背景
%     % 设置白色背景
%     set(fig, 'Color', 'w');
% 
% % Read the figure Name
%     % 读取 figure 的 Name
%     figName = get(fig, 'Name');
% 
% % Use a default number if Name is not set
%     % 如果没有设置 Name，就用默认编号
%     if isempty(figName)
%         figName = sprintf('Figure_%02d', iFig);
%     end
% 
% % Replace invalid characters in the file name
%     % 把文件名中的非法字符替换掉
%     figName = regexprep(figName, '[\\/:*?"<>|]', '_');
% 
% % Avoid an overly long file name
%     % 避免文件名太长
%     if strlength(figName) > 120
%         figName = extractBefore(figName, 121);
%     end
% 
% % Full save path
%     % 完整保存路径
%     filePath = fullfile(figSaveDir, [char(figName), '.png']);
% 
% % Save as PNG at 300 dpi
%     % 保存为 PNG，300 dpi
%     exportgraphics(fig, filePath, 'Resolution', 300);
% 
% end
% 
% fprintf('All figures have been saved to the folder using figure names: %s\n', figSaveDir);
% fprintf('所有图片已按图名保存到文件夹：%s\n', figSaveDir);
%% ============================================================
% 16. Save results to the workspace
%  16. 保存结果到工作区
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

result.tripLatchAcrossVp = tripLatchAcrossVp;
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

result.V1 = V1_plot;
result.VI = VI_plot;
result.VIeq = VIeq_plot;

result.H = Ip_plot;
result.Heq = Ipeq_plot;

result.Ip_abs_line_pu = Ip_abs_plot;
result.Ipeq_abs_line_pu = Ipeq_abs_plot;

result.I_PVsum_detail = I_PVsum_detail_plot;
result.I_PVeq = I_PVeq_plot;
result.eq_node_residual = eq_node_residual_plot;

result.Vp_actual_kV = Vp_actual_kV;
result.Vp_pu_from_actual = Vp_pu_from_actual;

result.Ip_line_actual_kA = Ip_line_actual_kA;
result.Ipeq_line_actual_kA = Ipeq_line_actual_kA;

result.Ip_line_pu_from_actual = Ip_line_pu_from_actual;
result.Ipeq_line_pu_from_actual = Ipeq_line_pu_from_actual;

result.Ip_3ph_actual_kA = Ip_3ph_actual_kA;
result.Ipeq_3ph_actual_kA = Ipeq_3ph_actual_kA;

result.Ip_3ph_pu_from_actual = Ip_3ph_pu_from_actual;
result.Ipeq_3ph_pu_from_actual = Ipeq_3ph_pu_from_actual;

result.I_PVsum_detail_3ph_pu = I_PVsum_detail_3ph_pu;
result.I_PVeq_3ph_pu = I_PVeq_3ph_pu;

result.Ip_detail_complex_3ph = Ip_detail_complex_3ph;
result.Ip_equiv_complex_3ph = Ip_equiv_complex_3ph;
result.I_PVsum_detail_complex_3ph = I_PVsum_detail_complex_3ph;
result.I_PVeq_complex_3ph = I_PVeq_complex_3ph;

result.Vc = Vc_plot;
result.Hc = Hc_plot;
result.G_Vc = G_Vc_plot;

result.evd = evd_plot;
result.efs = efs_plot;
result.etot = etot_plot;

result.evd_3ph_pu = evd_3ph_pu;
result.efs_3ph_pu = efs_3ph_pu;
result.etot_3ph_pu = etot_3ph_pu;

result.bcv = bcv_plot;
result.bcv_3ph_pu = bcv_3ph_pu;
result.rI_norm = rI_norm_plot;

% English note: 原始侧branch自适应propagation operator K_vd = YpI M_I^(-1)
% 原始侧分支自适应传播算子 K_vd = YpI M_I^(-1)
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
result.etot_piecewise_approx = etot_piecewise_approx_plot;
result.etot_piecewise_approx_3ph_pu = etot_piecewise_approx_3ph_pu;
result.error_decomp_check = error_decomp_check;
result.error_decomp_check_3ph_pu = error_decomp_check_3ph_pu;
result.mI_norm = mI_norm_plot;
result.rI_alpha_norm = rI_alpha_norm_plot;
result.branchMismatchCount = branchMismatchCount_plot;
result.condM_original = condM_original_plot;
result.condM = condM_plot;
result.condMIAlpha = condMIAlpha_plot;
result.condMIAlphaStar = condMIAlphaStar_plot;
result.condMI_piecewise = condMI_piecewise_plot;
result.branchCommon = branchCommon_plot;
result.branchTrue = branchTrue_plot;

result.efs_consistent_approx = efs_consistent_approx_plot;
result.efs_consistent_approx_3ph_pu = efs_consistent_approx_3ph_pu;
result.efs_func_approx = efs_func_approx_plot;
result.efs_func_approx_3ph_pu = efs_func_approx_3ph_pu;
result.efs_piecewise_approx = efs_piecewise_approx_plot;
result.efs_piecewise_approx_3ph_pu = efs_piecewise_approx_3ph_pu;
result.delta_ab_norm = delta_ab_norm_plot;
result.me_norm = me_norm_plot;
result.condMe_original = condMe_original_plot;
result.condMe = condMe_plot;
result.condMeBeta = condMeBeta_plot;
result.condMeBetaStar = condMeBetaStar_plot;
result.condMe_piecewise = condMe_piecewise_plot;

% English note: 等值侧branch自适应propagation operator K_fs = -Ype^eq M_e^(-1)
% 等值侧分支自适应传播算子 K_fs = -Ype^eq M_e^(-1)
result.KfsBetaNorm = KfsBetaNorm_plot;
result.KfsBetaStarNorm = KfsBetaStarNorm_plot;
result.Kfs_piecewiseNorm = Kfs_piecewiseNorm_plot;
result.Kfs_piecewise_real = Kfs_piecewise_real_plot;

result.eqBranchMismatch = eqBranchMismatch_plot;
result.branchBeta = branchBeta_plot;
result.branchBetaStar = branchBetaStar_plot;

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

assignin('base', 'Ip_Vp_trip_iter_node0_result_modified_branch_fusion', result);

% Computation completed. Results have been saved to the workspace variable Ip_Vp_trip_iter_node0_result_modified_branch_fusion.
disp('计算完成。结果已保存到工作区变量 Ip_Vp_trip_iter_node0_result_modified_branch_fusion。');

end

%% ========================================================================
% Construct the admittance matrix
%  构造导纳矩阵
% ========================================================================

function Y = build_Y_7bus(lineScale)

j = 1i;
% Same input voltage
% 同输入电压
Y = zeros(8,8);

branch = [
    0   1   0.0001   0.0003   0.000;

    1   2   0.002    0.0035   0.002;
    1   3   0.001    0.00175  0.004;
    1   4   0.002    0.0035   0.002;
    1   5   0.001    0.00175  0.004;
    1   6   0.002    0.0035   0.002;
    1   7   0.002    0.0035   0.002;
];
% Different input voltage
% 不同输入电压
% branch = [
%     0   1   0.0001   0.0003   0.000;
% 
%     1   2   1.2        1.8     0.002;
%     1   3   0.8      0.81     0.004;
%     1   4   0.61     0.9     0.002;
%     1   5   0.75      0.9     0.004;
%     1   6   0.42     0.66     0.002;
%     1   7   0.9      1.1     0.002;
% ];

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

% System admittance matrix Y =
disp('系统导纳矩阵 Y = ');
disp(Y);

end

%% ========================================================================
% Residual equation of the detailed model
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
% Tripping iteration of the equivalent model
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
            % English note: equivalent model: Vp = %.4f, tripped迭代 %d 时may not have converged.
            warning('等值模型：Vp = %.4f，脱网迭代 %d 时可能未收敛。', ...
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

if tripIter >= maxTripIter
    % equivalent model: Vp = %.4f reached the maximum number of tripping iterations.
    warning('等值模型：Vp = %.4f 达到最大脱网迭代次数。', Vp_abs);
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
% Residual equation of the equivalent model
%  等值模型残差方程
% ========================================================================

function F = residual_equation_eq_online(x, Vp, Yeq_Ip, Yeq_II, pv_eq)

VIeq = x(1) + 1j*x(2);

Ieq = equivalent_AB_current_no_trip_gate(VIeq, Vp, pv_eq);

res = Yeq_Ip * Vp + Yeq_II * VIeq - Ieq;

F = [real(res); imag(res)];

end

%% ========================================================================
% Detailed PV current model
%  详细光伏电流模型
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
% Single-PV current model
%  单台光伏电流模型
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

    if k > length(pv.Imax_single_vec)
        % Imax_single_vec has insufficient length.
        error('Imax_single_vec 长度不足。');
    end

    Imax_single_k = pv.Imax_single_vec(k);

else

    Imax_single_k = pv.Imax_single;

end

Imax = Imax_single_k * cap * pv.Ilimit_base_ratio;

p0 = pv.vpre * Id0;
q0 = pv.vpre * Iq0;

[~, ~, vblock] = get_threshold_by_type(type, pv);

if v <= vblock

    u0 = [0; 0];

else

    if v >= pv.normalConstP.vmin && v <= pv.normalConstP.vmax

        u0 = [
            p0 / v_safe;
            q0 / v_safe
        ];

    else

        switch type

            case 1
                u0 = [
                    p0 / v_safe;
                    q0 / v_safe
                ];

            case 2
                u0 = [
                    Id0;
                    Iq0
                ];

            otherwise
                % Unknown control type.
                error('未知控制类型。');

        end

    end

end

u = project_current_limit(u0, Imax, pv.priority);

id = u(1);
iq = u(2);

% Here id - j*iq is used to keep the dq-coordinate positive direction consistent with EMT
% 这里使用 id - j*iq，是为了与 EMT 中 dq 坐标正方向保持一致
I_local = id - 1j*iq;

I = I_local * eV;

end

%% ========================================================================
% Equivalent PV current model
%  等值光伏电流模型
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

Imax = pv_eq.Imax_single * cap * pv_eq.Ilimit_base_ratio;

p0 = pv_eq.vpre * Id0;
q0 = pv_eq.vpre * Iq0;

u_constP_0 = [
    p0 / v_safe;
    q0 / v_safe
];

u_constI_0 = [
    Id0;
    Iq0
];

u_constP_lim = project_current_limit(u_constP_0, Imax, pv_eq.priority);
u_constI_lim = project_current_limit(u_constI_0, Imax, pv_eq.priority);

if vp_abs >= pv_eq.vp_normal_min && vp_abs <= pv_eq.vp_normal_max

    u_mix = pv_eq.A * u_constP_lim + pv_eq.B * u_constP_lim;

elseif vp_abs >= pv_eq.vp_min && vp_abs < pv_eq.vp_normal_min

    u_mix = pv_eq.A * u_constP_lim + pv_eq.B * u_constI_lim;

else

    u_mix = pv_eq.A * u_constP_lim + pv_eq.B * u_constI_lim;

end

id = u_mix(1);
iq = u_mix(2);

% Here id - j*iq is used to keep the dq-coordinate positive direction consistent with EMT
% 这里使用 id - j*iq，是为了与 EMT 中 dq 坐标正方向保持一致
I_local = id - 1j*iq;

Ieq = I_local * eV;

end

%% ========================================================================
% Tripping iteration of the common-voltage model
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
        % English note: Common-voltage model: Vp = %.4f, tripped迭代 %d 时may not have converged.
        warning('公共电压模型：Vp = %.4f，脱网迭代 %d 时可能未收敛。', ...
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

if tripIter >= maxTripIter
    % Common-voltage model: Vp = %.4f reached the maximum number of tripping iterations.
    warning('公共电压模型：Vp = %.4f 达到最大脱网迭代次数。', Vp_abs);
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
% Residual equation of the common-voltage model
%  公共电压模型残差方程
% ========================================================================

function F = residual_common_voltage_online(x, Vp, Yeq_Ip, Yeq_II, pv, tripC)

Vc = x(1) + 1j*x(2);

G_Vc = common_voltage_current_sum_no_trip_gate(Vc, pv, tripC);

res = Yeq_Ip * Vp + Yeq_II * Vc - G_Vc;

F = [real(res); imag(res)];

end

%% ========================================================================
% Current summation rule under the same input voltage G(Vc)
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
% Compute passive-network bias bcv and common-voltage KCL residual rI
%  计算无源网络偏差 bcv 和公共电压 KCL 残差 rI
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
% Approximate calculation of the voltage-dispersion error formula
%  电压分散误差式近似计算
% ========================================================================

function [evd_consistent_approx, evd_branch_approx, mI_aug, rI_alpha_aug, condM, ...
    condMIAlpha, condMIAlphaStar, ...
    branchMismatchCount, branchCommon, branchTrue, ...
    KvdAlpha_real, KvdAlphaStar_real] = ...
    compute_inconsistent_branch_approx( ...
        Vp, Vc, Utrue, VItrue, tripMask, tripC, ...
        YpI, YIp, YII, bcv, pv)

nPV = length(pv.s);

% ------------------------------------------------------------
% 1. Construct the common-voltage state Uc = [V1_c; 1Vc]
% 1. 构造公共电压状态 Uc = [V1_c; 1Vc]
% ------------------------------------------------------------

Vpv_c = ones(nPV,1) * Vc;
V1_c = -(YIp(1) * Vp + YII(1,2:end) * Vpv_c) / YII(1,1);
Uc = [V1_c; Vpv_c];

% ------------------------------------------------------------
% 2. Identify the common-voltage branch alpha and the true branch alphaStar
% 2. 判断公共电压分支 alpha 和真实分支 alphaStar
% ------------------------------------------------------------

branchCommon = classify_all_branches(Vpv_c, pv, tripC);
branchTrue = classify_all_branches(VItrue, pv, tripMask);

branchMismatchCount = sum(branchCommon ~= branchTrue);

% ------------------------------------------------------------
% 3. Compute f_alpha(1Vc), f_alphaStar(1Vc), mI, and rI_alpha
% 3. 计算 f_alpha(1Vc)、f_alphaStar(1Vc)、mI 和 rI_alpha
% ------------------------------------------------------------

I_alpha_aug = forced_injection_aug(Uc, pv, branchCommon);
I_alphastar_aug = forced_injection_aug(Uc, pv, branchTrue);

% m_I^{alpha->alphaStar} = f_alpha(1Vc) - f_alphaStar(1Vc)
mI_aug = I_alpha_aug - I_alphastar_aug;

% r_I^alpha = YIp*Vp + YII*Uc - f_alpha(1Vc)
rI_alpha_aug = YIp * Vp + YII * Uc - I_alpha_aug;

% ------------------------------------------------------------
% 4. Compute Jf_alpha(1Vc) and Jf_alphaStar(1Vc) separately
% 4. 分别计算 Jf_alpha(1Vc) 和 Jf_alphaStar(1Vc)
% ------------------------------------------------------------

J_alpha_real = numerical_jacobian_forced_injection(Uc, pv, branchCommon);
J_alphaStar_real = numerical_jacobian_forced_injection(Uc, pv, branchTrue);

YII_real = complex_matrix_to_real(YII);

% M_I^alpha = YII - Jf_alpha(1Vc)
MI_alpha_real = YII_real - J_alpha_real;

% M_I^alphaStar = YII - Jf_alphaStar(1Vc)
MI_alphaStar_real = YII_real - J_alphaStar_real;

condMIAlpha = cond(MI_alpha_real);
condMIAlphaStar = cond(MI_alphaStar_real);

% Keep the original variable condM, meaning cond(M_I^{alphaStar})
% 保留原变量 condM，含义为 cond(M_I^{alphaStar})
condM = condMIAlphaStar;

% Original-side propagation operator in real two-axis coordinates
% 实数二轴坐标下的原始侧传播算子
% K_vd^alpha     = YpI(M_I^alpha)^(-1)
% K_vd^alphaStar = YpI(M_I^alphaStar)^(-1)
YpI_real = complex_matrix_to_real(YpI);
KvdAlpha_real = YpI_real / MI_alpha_real;
KvdAlphaStar_real = YpI_real / MI_alphaStar_real;

% ------------------------------------------------------------
% 5. Eq. (50) consistent-branch approximation
% 5. 式（50）一致分支近似
% ------------------------------------------------------------
% evd_50 ≈ bcv + YpI * inv(M_I^alpha) * rI_alpha

rhs50_real = [real(rI_alpha_aug); imag(rI_alpha_aug)];
delta50_real = MI_alpha_real \ rhs50_real;

nInternal = length(Uc);
delta50_complex = delta50_real(1:nInternal) + 1j*delta50_real(nInternal+1:end);

evd_consistent_approx = bcv + YpI * delta50_complex;

% ------------------------------------------------------------
% 6. Eq. (53) inconsistent-branch approximation
% 6. 式（53）不一致分支近似
% ------------------------------------------------------------
% evd_53 ≈ bcv + YpI * inv(M_I^alphaStar) * (rI_alpha + mI)

rhs53_complex = rI_alpha_aug + mI_aug;
rhs53_real = [real(rhs53_complex); imag(rhs53_complex)];

delta53_real = MI_alphaStar_real \ rhs53_real;

delta53_complex = delta53_real(1:nInternal) + 1j*delta53_real(nInternal+1:end);

evd_branch_approx = bcv + YpI * delta53_complex;

end

%% ========================================================================
% Approximate calculation of function-structure error using Eq. (60) and Eq. (63)
%  函数结构误差式（60）和式（63）近似计算
% ========================================================================

function [efs_consistent_approx, efs_func_approx, delta_ab, me_beta, condMe, ...
    condMeBeta, condMeBetaStar, ...
    eqBranchMismatch, branchBeta, branchBetaStar, ...
    KfsBeta_real, KfsBetaStar_real] = ...
    compute_function_structure_approx( ...
        Vp, Vc, Ve, tripEq, Yeq_pI, Yeq_II, ...
        pv, pv_eq, branchCommon, tripC)

nPV = length(pv.s);

% ------------------------------------------------------------
% 1. Compute G_alpha(Vc) = sum_i f_i(Vc)
% 1. 计算 G_alpha(Vc) = sum_i f_i(Vc)
% ------------------------------------------------------------

Vpv_c = ones(nPV,1) * Vc;
Uc_dummy = [0; Vpv_c];

I_alpha_aug = forced_injection_aug(Uc_dummy, pv, branchCommon);

G_alpha = sum(I_alpha_aug(2:end));

% ------------------------------------------------------------
% 2. Identify the equivalent common branch beta and equivalent true branch betaStar
% 2. 识别等值公共分支 beta 和等值真实分支 betaStar
% ------------------------------------------------------------

v_ctrl_c = pv_voltage_control_pu(Vc, pv_eq.Vbase_kV, pv_eq.Vctrl_base_kV);
tripBeta = (v_ctrl_c <= pv_eq.vtrip + 1e-10);

branchBeta = classify_equiv_branch(Vc, Vp, pv_eq, tripBeta);
branchBetaStar = classify_equiv_branch(Ve, Vp, pv_eq, tripEq);

eqBranchMismatch = double(branchBeta ~= branchBetaStar);

% ------------------------------------------------------------
% 3. Compute F_beta(Vc) and F_betaStar(Vc) at the same Vc
% 3. 在同一个 Vc 下计算 F_beta(Vc) 和 F_betaStar(Vc)
% ------------------------------------------------------------

F_beta_Vc = equivalent_current_forced_branch(Vc, Vp, pv_eq, branchBeta);
F_betaStar_Vc = equivalent_current_forced_branch(Vc, Vp, pv_eq, branchBetaStar);

% delta_{alpha,beta} = G_alpha(Vc) - F_beta(Vc)
delta_ab = G_alpha - F_beta_Vc;

% m_e^{beta->betaStar} = F_beta(Vc) - F_betaStar(Vc)
me_beta = F_beta_Vc - F_betaStar_Vc;

% ------------------------------------------------------------
% 4. Compute JF_beta(Vc) and JF_betaStar(Vc) separately
% 4. 分别计算 JF_beta(Vc) 和 JF_betaStar(Vc)
% ------------------------------------------------------------

JF_beta_real = numerical_jacobian_equiv_forced_branch(Vc, Vp, pv_eq, branchBeta);
JF_betaStar_real = numerical_jacobian_equiv_forced_branch(Vc, Vp, pv_eq, branchBetaStar);

Yee_real = complex_matrix_to_real(Yeq_II);

% M_e^beta = Yeq_ee - JF_beta(Vc)
Me_beta_real = Yee_real - JF_beta_real;

% M_e^betaStar = Yeq_ee - JF_betaStar(Vc)
Me_betaStar_real = Yee_real - JF_betaStar_real;

condMeBeta = cond(Me_beta_real);
condMeBetaStar = cond(Me_betaStar_real);

% Keep the original variable condMe, meaning cond(M_e^{betaStar})
% 保留原变量 condMe，含义为 cond(M_e^{betaStar})
condMe = condMeBetaStar;

% Equivalent-side propagation operator in real two-axis coordinates
% 实数二轴坐标下的等值侧传播算子
% K_fs^beta     = -Ype^eq(M_e^beta)^(-1)
% K_fs^betaStar = -Ype^eq(M_e^betaStar)^(-1)
Yeq_pI_real = complex_matrix_to_real(Yeq_pI);
KfsBeta_real = -Yeq_pI_real / Me_beta_real;
KfsBetaStar_real = -Yeq_pI_real / Me_betaStar_real;

% ------------------------------------------------------------
% 5. Eq. (60) consistent-branch approximation
% 5. 式（60）一致分支近似
% ------------------------------------------------------------
% efs_60 ≈ -Yeq_pI * inv(M_e^beta) * delta_ab

rhs60_real = [real(delta_ab); imag(delta_ab)];

deltaV60_real = Me_beta_real \ rhs60_real;
deltaV60_complex = deltaV60_real(1) + 1j * deltaV60_real(2);

efs_consistent_approx = -Yeq_pI * deltaV60_complex;

% ------------------------------------------------------------
% 6. Eq. (63) inconsistent-branch approximation
% 6. 式（63）不一致分支近似
% ------------------------------------------------------------
% efs_63 ≈ -Yeq_pI * inv(M_e^betaStar) * (delta_ab + me_beta)

rhs63_complex = delta_ab + me_beta;
rhs63_real = [real(rhs63_complex); imag(rhs63_complex)];

deltaV63_real = Me_betaStar_real \ rhs63_real;
deltaV63_complex = deltaV63_real(1) + 1j * deltaV63_real(2);

efs_func_approx = -Yeq_pI * deltaV63_complex;

end

%% ========================================================================
% Identify the branch according to PV voltage and tripping state
%  根据光伏电压和脱网状态识别分支
% ========================================================================

function branchID = classify_all_branches(Vpv, pv, tripMask)

nPV = length(pv.s);
branchID = zeros(nPV,1);

for kk = 1:nPV
    branchID(kk) = classify_single_branch(Vpv(kk), pv.s(kk), pv.ctrlType(kk), kk, pv, tripMask(kk));
end

end

%% ========================================================================
% Single-PV branch identification
%  单台光伏分支识别
% ========================================================================
% Branch index:
% 分支编号：
% 1: tripped
% 1：脱网
% 2: blocked
% 2：封波
% 3: normal constant-power, not current-limited
% 3：正常恒功率，未限幅
% 4: normal constant-power, current-limited
% 4：正常恒功率，限幅
% 5: LVRT constant-power, not current-limited
% 5：低穿恒功率，未限幅
% 6: LVRT constant-power, current-limited
% 6：低穿恒功率，限幅
% 7: LVRT constant-current, not current-limited
% 7：低穿恒电流，未限幅
% 8: LVRT constant-current, current-limited
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
q0 = pv.vpre * Iq0;

[~, ~, vblock] = get_threshold_by_type(type, pv);

if v <= vblock
    bid = 2;
    return;
end

if v >= pv.normalConstP.vmin && v <= pv.normalConstP.vmax
    u0 = [p0 / v_safe; q0 / v_safe];
    baseID = 3;
else
    switch type
        case 1
            u0 = [p0 / v_safe; q0 / v_safe];
            baseID = 5;
        case 2
            u0 = [Id0; Iq0];
            baseID = 7;
        otherwise
            % Unknown control type.
            error('未知控制类型。');
    end
end

u_lim = project_current_limit(u0, Imax, pv.priority);

if norm(u_lim - u0) > 1e-9
    bid = baseID + 1;
else
    bid = baseID;
end

end

%% ========================================================================
% English note: 等值PVbranch识别
%  等值光伏分支识别
% ========================================================================
% Branch index:
% 分支编号：
% 1: tripped
% 1：脱网
% 2: blocked
% 2：封波
% 3: normal region, constant-power equivalent, not current-limited
% 3：正常区，恒功率等值，未限幅
% 4: normal region, constant-power equivalent, current-limited
% 4：正常区，恒功率等值，限幅
% 5: LVRT region, mixed constant-power and constant-current, neither current-limited
% 5：低穿区，恒功率+恒电流混合，均未限幅
% 6: LVRT region, constant-power current-limited and constant-current not current-limited
% 6：低穿区，恒功率限幅，恒电流未限幅
% 7: LVRT region, constant-power not current-limited and constant-current current-limited
% 7：低穿区，恒功率未限幅，恒电流限幅
% 8: LVRT region, both constant-power and constant-current are current-limited
% 8：低穿区，恒功率和恒电流均限幅

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

Imax = pv_eq.Imax_single * cap * pv_eq.Ilimit_base_ratio;

p0 = pv_eq.vpre * Id0;
q0 = pv_eq.vpre * Iq0;

if v <= pv_eq.vblock
    branchID = 2;
    return;
end

u_constP_0 = [p0 / v_safe; q0 / v_safe];
u_constI_0 = [Id0; Iq0];

u_constP_lim = project_current_limit(u_constP_0, Imax, pv_eq.priority);
u_constI_lim = project_current_limit(u_constI_0, Imax, pv_eq.priority);

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
% Node injection current under a fixed original-side branch
%  固定原始侧分支下的节点注入电流
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
% Single-PV current under a fixed branch
%  固定分支下的单台光伏电流
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
q0 = pv.vpre * Iq0;

switch branchID

    case 1
        u = [0; 0];

    case 2
        u = [0; 0];

    case {3,4}
        u0 = [p0 / v_safe; q0 / v_safe];

        if branchID == 4
            u = project_current_limit(u0, Imax, pv.priority);
        else
            u = u0;
        end

    case {5,6}
        u0 = [p0 / v_safe; q0 / v_safe];

        if branchID == 6
            u = project_current_limit(u0, Imax, pv.priority);
        else
            u = u0;
        end

    case {7,8}
        u0 = [Id0; Iq0];

        if branchID == 8
            u = project_current_limit(u0, Imax, pv.priority);
        else
            u = u0;
        end

    otherwise
        % Unknown branch index.
        error('未知分支编号。');

end

id = u(1);
iq = u(2);

I_local = id - 1j*iq;

I = I_local * eV;

end

%% ========================================================================
% Equivalent PV current under a fixed equivalent-side branch
%  固定等值侧分支下的等值光伏电流
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

Imax = pv_eq.Imax_single * cap * pv_eq.Ilimit_base_ratio;

p0 = pv_eq.vpre * Id0;
q0 = pv_eq.vpre * Iq0;

u_constP_0 = [p0 / v_safe; q0 / v_safe];
u_constI_0 = [Id0; Iq0];

u_constP_lim = project_current_limit(u_constP_0, Imax, pv_eq.priority);
u_constI_lim = project_current_limit(u_constI_0, Imax, pv_eq.priority);

switch branchID

    case 1
        u_mix = [0; 0];

    case 2
        u_mix = [0; 0];

    case 3
        u_mix = pv_eq.A * u_constP_0 + pv_eq.B * u_constP_0;

    case 4
        u_mix = pv_eq.A * u_constP_lim + pv_eq.B * u_constP_lim;

    case 5
        u_mix = pv_eq.A * u_constP_0 + pv_eq.B * u_constI_0;

    case 6
        u_mix = pv_eq.A * u_constP_lim + pv_eq.B * u_constI_0;

    case 7
        u_mix = pv_eq.A * u_constP_0 + pv_eq.B * u_constI_lim;

    case 8
        u_mix = pv_eq.A * u_constP_lim + pv_eq.B * u_constI_lim;

    otherwise
        % Unknown equivalent branch index.
        error('未知等值分支编号。');

end

id = u_mix(1);
iq = u_mix(2);

I_local = id - 1j*iq;

Ieq = I_local * eV;

end

%% ========================================================================
% Numerical Jacobian of original-side injection current under a fixed branch
%  固定分支原始侧注入电流数值雅可比
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
% Numerical Jacobian of equivalent-side current under a fixed branch
%  固定等值侧分支电流数值雅可比
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
% Convert a complex matrix into a real two-axis matrix
%  复数矩阵转换为实数二轴矩阵
% ========================================================================

function Ar = complex_matrix_to_real(A)

Ar = [
    real(A), -imag(A);
    imag(A),  real(A)
];

end

%% ========================================================================
% PV control-logic voltage: RMS per-unit value
%  光伏控制逻辑电压：RMS 标幺值
% ========================================================================

function v_pu = pv_voltage_control_pu(V_complex_pu, Vbase_kV, Vctrl_base_kV)

V_rms_kV = abs(V_complex_pu) * Vbase_kV;

v_pu = V_rms_kV / Vctrl_base_kV;

end

%% ========================================================================
% Read thresholds according to control type
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
        % Unknown control type.
        error('未知控制类型。');

end

end

%% ========================================================================
% Current-limiting function
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

        % priority can only be equal, q_first, or p_first.
        error('priority 只能取 equal、q_first 或 p_first。');

end

end


