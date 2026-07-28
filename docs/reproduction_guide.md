# Reproduction Guide / 复现说明

## MATLAB Environment / MATLAB 环境

Required:

需要：

```text
MATLAB R2020b or later
Optimization Toolbox
```

## Run Photovoltaic Case / 运行光伏算例

```matlab
addpath('matlab');
photovoltaic_case;
```

## Run Wind Farm Case / 运行风电场算例

```matlab
addpath('matlab');
wind_farm_case;
```

## Run All Cases / 运行全部算例

```matlab
addpath('matlab');
run_all_cases;
```

## Output / 输出

The scripts directly generate figures and save main numerical variables in the MATLAB workspace. The generated PNG figures are saved by their figure names in the script-defined output directory.

程序会直接生成图像，并将主要数值变量保存在 MATLAB 工作区中。生成的 PNG 图像会按照 figure 名称保存到代码指定的输出文件夹。
