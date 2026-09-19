# 第 7 课：cobol.nvim 综合练习与回归清单

本课把前 6 课的 COBOL 示例和 `cobol.nvim` 的编辑器功能串起来。目标不是只
“看见插件有效”，而是每完成一个 COBOL 练习，就用插件检查结构、数据布局、
Copybook 和编译器反馈。

## 1. 环境准备

在本仓库根目录执行：

```bash
make check
nvim INPUTCSV.COB
```

插件通过 lazy.nvim 安装：

```lua
{
  "iamcheyan/cobol.nvim",
  ft = { "cobol", "cbl", "cob" },
  opts = {},
}
```

Aerial 是一个为 Neovim 提供代码结构 Outline 侧边栏的插件；在这里它负责显示
`cobol.nvim` 识别出的 Division、Section、Paragraph 和数据记录。它只是可选依赖，
插件核心功能不依赖 Aerial。

如果 Neovim 不是从本仓库目录启动，建议设置项目根目录：

```lua
opts = {
  project_root = vim.fn.expand("~/cobol-practice"),
  copybook_paths = { ".", "./cpy", "./copybooks", "./include" },
}
```

## 2. 按示例练习

| 文件 | 学习重点 | 建议操作 |
|---|---|---|
| `INPUTCSV.COB` + `EMP-REC.CPY` | Division、层级数据、Copybook、PIC | `g8`/`g12`、`gd`、`gf`、`K`、`<leader>cr` |
| `FIXEDREC.COB` + `TX-REC.CPY` | 固定格式、`REDEFINES`、`88` 条件名 | 标尺、Aerial、`gd`、记录布局计算 |
| `TBLSRCH.COB` | `OCCURS`、数组和 `SEARCH ALL` | Aerial、`<leader>cr`、诊断 |
| `BATCHRPT.COB` | Section、Paragraph、Control Break | 大纲、折叠、格式化、编译运行 |

每个文件都建议先执行 `make check`，再从编辑器内按 `<leader>cl` 检查同一份代码。

## 3. 插件功能练习

### 3.1 固定格式与结构

在 `INPUTCSV.COB` 中依次练习：

1. 用 `g7`、`g8`、`g12`、`g73` 在穿孔卡列之间移动。
2. 在空行使用 `<Tab>`，观察 Area A（第 8 列）和 Area B（第 12 列）的吸附。
3. 使用 `<leader>uc` 开关标尺和 Winbar。
4. 在 `DATA DIVISION`、Section 和 Paragraph 上按 `za`，验证结构折叠；用 `zc`/`zo`
   分别关闭/打开折叠。
5. 在第 7 列使用 `<leader>c*`，验证单行和 Visual 多行注释切换。

### 3.2 大纲、跳转和 Copybook

1. 安装 Aerial 后按 `<leader>cs`，从 Division 找到 `2000-PROCESS-FILE`。
2. 在 `PERFORM 2000-PROCESS-FILE` 上按 `gd`，再按 `<C-o>` 返回调用点。
3. 在 `COPY "EMP-REC.CPY".` 上按 `gf` 打开 Copybook，按 `K` 只预览内容。
4. 在 `FIXEDREC.COB` 中重复上述操作，确认 `TX-REC.CPY` 可被找到。

### 3.3 PIC、数组和重定义

1. 在 `INPUTCSV.COB` 的 `01 WS-INPUT-FIELDS` 上观察行尾总字节提示。
2. 按 `<leader>cr` 或运行 `:CobolCalcRecord`，检查字段偏移量。
3. 在 `FIXEDREC.COB` 中观察 `REDEFINES` 字段共享偏移量。
4. 在 `TBLSRCH.COB` 中观察 `OCCURS` 的重复大小。
5. 额外练习 `COMP-1`、`COMP-2`、`COMP-3`、`BINARY` 和 `SIGN IS SEPARATE`，注意计算器
   是常见 ABI 下的估算值，不替代目标平台编译器的最终布局。

### 3.4 格式化与诊断

在临时副本或可恢复的 Git 分支中进行：

1. 把一行中的 `move`、`if`、`end-if` 改成小写，运行 `:CobolFormatCase`。
2. 用 Visual 选中多行再次运行命令；不应修改变量名、字符串或注释。
3. 故意把 `PERFORM` 改成不存在的段落，运行 `<leader>cl` 或 `:CobolLint`。
4. 使用 `<leader>cq` / `:CobolQuickfix` 查看错误并回到代码。
5. 不保存时修改代码，等待约 600ms 或离开插入模式，确认 `TextChanged`/`InsertLeave`
   诊断仍然能工作。
6. 修复错误并保存，确认旧诊断消失。如果全局关闭了 Neovim diagnostics，插件会提示
   编译结果不可见；重新启用后再检查。

## 4. 完成标准

完成本课后，应能回答：

- 为什么 Division、Section、Paragraph 可以折叠？
- 为什么 `PIC S9(7)V99 COMP-3` 是 5 字节？
- `REDEFINES` 为什么不一定增加总长度？
- `COPY` 文件如何被 `gf` 找到？
- 为什么没有 LSP 也能获得 `cobc` 的实时诊断？
- `:CobolFormatCase` 为什么不会改字符串和变量名？

插件源码仓库中的 `docs/TASKS.md` 和本仓库的 `Makefile` 分别负责插件回归测试和
COBOL 示例编译检查。完成练习后建议运行：

```bash
make check
make run
```
