# Docs Folder / 文档文件夹

This folder contains documentation for understanding and reproducing the LVRT aggregation cases.

本文件夹用于说明低电压穿越聚合等值算例的模型原理、代码结构、参数含义和复现方法。


## Error-Term Terminology / 误差项术语

The documentation uses the following updated error-term names:

本文档文件夹统一采用以下更新后的误差项名称：

| Symbol | English name | 中文名称 |
|---|---|---|
| `ecv` or `e_cv` | Common-Voltage-Reduction Error | 同电压压缩误差 |
| `eal` or `e_al` | Admissible-Law-Approximation Error | 允许函数类近似误差 |
| `e` | Total aggregation error | 总聚合误差 |

## Files / 文件说明

| File | Description | 中文说明 |
|---|---|---|
| `model_description.md` | Modeling framework and error decomposition | 模型框架和误差分解说明 |
| `case_description.md` | Case-study descriptions | 论文算例说明 |
| `parameter_description.md` | Parameter definitions and values | 参数定义和参数值说明 |
| `reproduction_guide.md` | How to run and reproduce the cases | 代码运行和复现说明 |
| `code_section_map.md` | Mapping between code sections and functions | 代码段落说明 |
| `function_reference.md` | Function-level reference | 函数索引说明 |

## Recommended Reading Order / 推荐阅读顺序

```text
1. model_description.md
2. case_description.md
3. parameter_description.md
4. code_section_map.md
5. function_reference.md
6. reproduction_guide.md
```

