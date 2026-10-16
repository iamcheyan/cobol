# PIC 与记录布局估算

COBOL 的 `PIC` 子句描述字段格式。定长文件和 Copybook 接口经常需要核对字段宽度与偏移；`cobol.nvim` 可将常见声明转换成便于阅读的大小估算。

## 插件提供什么

- 光标位于数据声明时，显示当前字段的 PIC 与字节估算。
- 01 记录行可显示可识别字段的汇总估算。
- `<leader>cr` / `:CobolCalcRecord` 打开布局表，显示字段层级、偏移、PIC/用法和估算大小。

![COBOL PIC 字段与记录布局估算](images/record-layout.png)

图中布局表展示 `WS-TRANSACTION-RECORD` 下各字段的偏移和估算大小。这个画面来自 Neovim 中实际运行的 `:CobolCalcRecord`。

## 简单示例

```cobol
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-TRANSACTION-RECORD.
          10 WS-CUSTOMER-ID PIC X(8).
          10 WS-AMOUNT PIC 9(5)V99.
          10 WS-STATUS PIC X.
```

将光标放在 `WS-TRANSACTION-RECORD` 上运行 `:CobolCalcRecord`。表格按源码声明列出可识别字段及估算的字节偏移；字段行旁也会显示局部大小提示。

常见的初步心算规则：`PIC X(n)` 和显示型 `PIC 9(n)` 通常按每字符一字节估算；隐含小数点 `V` 不占存储；`COMP-3` 常按数字半字节及符号半字节估算。二进制 `COMP` 的大小取决于精度、编译器与目标 ABI。

## 估算边界

布局结果适合阅读和初步核对，不能代替目标环境编译器。对齐、符号存储、方言、编译选项及平台都可能改变实际布局。当前计算器不会将组级 `OCCURS` 的次数乘到所有子字段上；较大的 `REDEFINES` 覆盖项也不会增加累计总长度。遇到这些声明时，应以目标编译器和接口规范为准。

## 快捷操作

| 操作 | 作用 |
| --- | --- |
| `<leader>cr` / `:CobolCalcRecord` | 打开当前字段或 01 记录的布局估算 |
| 光标位于数据声明 | 查看字段 PIC / 字节估算提示 |
| `q` / `<Esc>` | 关闭布局浮窗 |
