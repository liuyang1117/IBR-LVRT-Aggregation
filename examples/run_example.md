# Run Example / 运行示例

## 1. Open MATLAB / 打开 MATLAB

Open MATLAB in the root directory of this repository.

在本仓库根目录打开 MATLAB。

The repository structure should be similar to:

仓库结构应类似于：

```text
IBR-LVRT-Aggregation-Cases/
├── README.md
├── data/
├── docs/
├── examples/
├── matlab/
├── results/
└── tests/
```

---

## 2. Add MATLAB Path / 添加 MATLAB 路径

Run:

运行：

```matlab
addpath('matlab');
```

This allows MATLAB to find the main functions in the `matlab/` folder.

这样 MATLAB 就能找到 `matlab/` 文件夹中的主函数。

---

## 3. Run the Photovoltaic Case / 运行光伏算例

```matlab
photovoltaic_case;
```

This case corresponds to the six-PV benchmark.

该算例对应六光伏基准系统。

---

## 4. Run the Wind Farm Case / 运行风电场算例

```matlab
wind_farm_case;
```

This case corresponds to the offshore wind farm benchmark.

该算例对应海上风电场系统。

---

## 5. Run All Cases / 运行全部算例

If `run_all_cases.m` is available, run:

如果已有 `run_all_cases.m`，可以运行：

```matlab
run_all_cases;
```

This command runs both cases in sequence.

该命令会依次运行光伏算例和风电场算例。
