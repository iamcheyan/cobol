# cobol.nvim 插件功能演练

本篇使用 `extensions/standalone-examples/` 中的 COBOL 示例，演示插件功能如何配合日常源码阅读。插件不是 GnuCOBOL 的替代品；语法检查和项目构建仍由 `cobc` 或项目命令完成。

## 准备

在 Neovim 中打开示例：

```sh
nvim extensions/standalone-examples/INPUTCSV.COB
```

插件支持 `cobol`、`cbl`、`cob` filetype。固定格式案例可先看列标尺；如果解析器不可用，Tree-sitter 的配对标记、面包屑和文本对象不会显示。Aerial 与 blink.cmp 是可选依赖。

## 列标尺与编辑

1. `g7`、`g8`、`g12`、`g73` 跳到固定格式的重要列。
2. 在行首空白处进入 Insert，试按 `<Tab>` / `<S-Tab>`，观察 7、8、12 列停靠。
3. `:CobolGuideToggle` 切换列标尺及 Winbar；`:CobolGuideEnable` / `:CobolGuideDisable` 可显式启用或停用提示与诊断附着。
4. 用 `gcc`、Visual `gc` 或 `<leader>c*` 切换注释；用 `:CobolFormatCase` 格式化保留字。命令无范围时处理整个缓冲区，有范围时只处理该范围。

## 结构导航、大纲与 Copybook

1. 在 `PERFORM 1000-INITIALIZE` 的段落名上按 `gd`，再按 `<C-o>` 返回；`<C-i>` 沿 jumplist 前进。
2. 在 `COPY "EMP-REC.CPY".` 上按 `gf` 打开 Copybook，按 `K` 预览。
3. 解析器可用时，将光标放在 IF 块内观察最内层结构的彩色起止标记、连接线与 ELSE/WHEN 标记；按 `%` 在结构起止词间移动，`vaf` / `vif` 选择 IF 外部/内部。
4. Aerial 需要单独安装并启用本插件提供的 COBOL backend。用 `:AerialToggle` 打开；插件本身不默认绑定 `<leader>cs`。

## PIC 估算、诊断与折叠

1. 在 01 记录上运行 `<leader>cr` / `:CobolCalcRecord` 查看字段偏移和大小估算。组级 `OCCURS` 不会乘算子字段合计，较大的 `REDEFINES` 覆盖也不会扩大合计，因此不要将结果当作 ABI 保证。
2. 用 `<leader>cl` / `:CobolLint` 立即运行 GnuCOBOL 检查；`<leader>cq` / `:CobolQuickfix` 打开 Quickfix。诊断也可在保存、编辑防抖和离开 Insert 时自动触发。
3. `za`、`zc`、`zo` 操作 Division、Section、Paragraph 和数据项折叠。原生折叠不自行创建 IF/EVALUATE 折叠；若其它 fold provider 建立控制块折叠，插件可提供结构摘要。

## 快捷键与命令

| 操作 | 功能 |
| --- | --- |
| `g7` / `g8` / `g12` / `g73` | 跳到固定格式列 |
| `gd` / `gf` / `K` | 定义跳转 / 打开 Copybook / 预览 |
| `%`、`af`/`if`、`ae`/`ie`、`ap`/`ip` | Tree-sitter 配对移动与结构文本对象 |
| `<leader>cr` / `<leader>cl` / `<leader>cq` | 记录估算 / 立即诊断 / Quickfix |
| `:CobolGuideToggle` | 切换列标尺和 Winbar |
| `:CobolLint` / `:CobolBuild` / `:CobolRun` / `:CobolTest` | 检查、构建、运行与项目测试 |

完整配置和命令见插件仓库 README 与 Neovim 帮助 `:help cobol.nvim`。