# AGENTS.md - COBOL 实战工坊与插件共建智能体指南

本文档专为接手或参与本仓库的 AI Agent（以及维护者）编写。当新的智能体会话启动时，必须首先通读本文档，以快速对齐当前的研发上下文、核心目标、代码规范与多仓库协作边界。

---

## 1. 仓库定位与使命

- **仓库名称**：`iamcheyan/cobol`（GitHub 公开仓库）
- **本地路径**：`/home/tetsuya/development/cobol`
- **核心定位**：
  1. **COBOL 语言实战学习工坊**：提供生产级、可独立运行的 COBOL 85/2002 固定格式（Fixed-Format）代码样例，涵盖完整文件 I/O、Copybook 模块依赖、`UNSTRING`/`STRING` 数据处理以及复杂数据结构。
  2. **Neovim 现代化工具链协同演练场**：作为专有 Neovim 插件 `cobol.nvim` 与 `aerial.nvim` 的真实代码测试基准，通过“边学边做、边用边测”的方式持续推进 COBOL 现代化开发体验。

---

## 2. 仓库架构与多层仓库协作边界

本项目与系统中的其他仓库存在紧密的协同关系，智能体必须严格遵循仓库归属，切勿跨边界乱放代码：

| 仓库层级 | 本地路径 / 子模块路径 | 负责内容与协作边界 |
|---|---|---|
| **公开实战工坊（本仓库）** | `/home/tetsuya/development/cobol` | COBOL 示例代码（`INPUTCSV.COB`、`EMP-REC.CPY`）、输入测试数据、`Makefile` 构建脚本与新手实战教程。 |
| **公开插件仓库 (`cobol.nvim`)** | `~/chezmoi/dot_config/nvim-private/lua/cobol.nvim` | Neovim COBOL 插件 canonical source（细线标尺、Winbar、Aerial backend、导航、PIC 计算、诊断、折叠、格式化）。Chezmoi 只通过 submodule 指针部署它。 |
| **公开基础层 (`dotfiles`)** | `~/dotfiles/config/nvim/lua/` | 公开通用 Neovim 配置；COBOL 专属 Aerial backend 不再位于此处。 |
| **私有编排层 (`chezmoi`)** | `~/chezmoi` | 管理私有插件的部署接线（`dot_config/nvim-private/lua/plugins/cobol.lua`）及全局系统维护文档（`dot_config/docs/`）。 |

---

## 3. COBOL 80 列固定格式（Fixed-Format）核心准则

在编写或审查本仓库的 COBOL 代码时，必须时刻遵守 80 列穿孔卡物理规则：

```text
1-6 列: 序列号区 (Sequence Number) ── 通常填行号或留空
第 7 列: 指示符区 (Indicator)       ── '*' 为注释，'-' 为续行，'/' 为换页
8-11 列: Area A 顶格声明区          ── 必须顶格：DIVISION, SECTION, 段落名, 01/77 级, FD/SD
12-72列: Area B 语句与从属数据区     ── 必须在此或之后：MOVE/PERFORM/IF 等语句，02-49/88 级
73-80列: 识别区 (Identification)   ── 编译器彻底忽略！严禁代码溢出到此区域！
```

---

## 4. 当前研发进展与功能完成度清单

截至 2026-09-19，本套件已完成的功能与验收状态如下。配套练习章节位于 `docs/01` 至
`docs/07`，可按顺序边学边练：

- [x] **Phase 1: 穿孔卡安全标尺底座 (v0.1.0)**
  - 纯细线标尺（第 7、8、12、73 列绘制纤细 `│`，自动避让文字，空行贯穿全屏）。
  - Winbar 动态打孔卡刻度（依据 `textoff` 动态左补空格，100% 绝对垂直对齐代码列）。
  - 第 72 列越界红色波浪线告警（防代码掉入 73-80 列被编译器截断）。
  - 第 7 列智能注释切换（`<leader>c*` / `:CobolToggleComment`，支持单行与 Visual 多行，不破坏缩进）。
  - 智能 Tab 吸附（1-6 列直跳 8 列 Area A，7-11 列直跳 12 列 Area B）。
  - 列跳转快捷键：`g7`（跳 Col 7）、`g8`（跳 Col 8）、`g12`（跳 Col 12）、`g73`（跳 Col 73）。
  - 通用缩进线干扰屏蔽（自动静默 `indent-blankline.nvim`）。
- [x] **Phase 2.1: 结构大纲与面包屑 (v0.2.0)**
  - Winbar 实时架构面包屑（`[ PROCEDURE > SECTION > PARA ]`）。
  - `DATA DIVISION` 01 级亮蓝与 88 级条件名高亮。
  - 行尾数据层级宿主回溯虚拟文本（`← 05 PARENT (01 ROOT)`）。
  - **Aerial 侧边栏层级大纲**（`<leader>cs`，展现 3 层完整符号树，支持双向高亮与跳转）。
- [x] **Phase 2.2: 代码定义直达与 Copybook 预览 (v0.2.1)**
  - `gd` / `:CobolGotoDef`：直达段落（`PERFORM 1000-INIT`）或数据字段（`01/05/88/FD`）定义行。
  - `<C-o>` / `<C-t>`：跳转后无缝原路跳回（原生集成 Jumplist 与 Tagstack）。
  - `gf` / `:CobolGotoCopybook`：直接打开光标处 `COPY` 引用的 Copybook 实体文件。
  - `K` / `:CobolPreview`：居中弹出圆角浮动窗口（自带语法高亮），就地预览 Copybook 内容或目标过程定义片段，按 `q` 或 `<Esc>` 随手关闭。

---

## 5. 当前正在进行与后续目标（Next Steps）

当智能体接手后续任务时，请按以下预定路线图推进：

### 🎯 已完成：Phase 3 数据层级与 PIC 结构计算器
1. **单项 PIC 字节实时换算（Virtual Text / Float）**：
   - 文本型：`PIC X(20)` → `/* 20B */`
   - 数值型：`PIC 9(5)V99` → `/* 7B (5.2) */`
   - 压缩十进制：`PIC S9(7) COMP-3` → 换算公式 `ceil((N+1)/2)` → `/* 4B (COMP-3) */`
   - 二进制整数：`PIC S9(4) COMP` → `/* 2B (COMP) */`，`PIC S9(9) COMP` → `/* 4B (COMP) */`
2. **`01 RECORD` 自动递归向下求和**：
   - 光标停在 `01 RECORD-NAME.` 时，自动向下扫描所属的所有叶子子字段，递归累加总字节数；
   - 在行尾通过 Virtual Text 提示：`/* Record Size: 256 Bytes */`，或通过命令 `:CobolCalcRecord` 输出明细。

### 🎯 已完成：Phase 4 GnuCOBOL (`cobc`) 实时语法飞检
1. 在保存文件（`BufWritePost`）、文本变更防抖（`TextChanged`）或离开插入模式（`InsertLeave`）时，异步执行 `cobc -fsyntax-only`。
2. 将编译器输出（缺少句号 `.`、Area A/B 越界、未定义标识符）解析并映射为 Neovim Diagnostics（行内红色/黄色波浪线 + 悬浮提示）。

### 🎯 已完成：Phase 5 语法折叠与规范化
1. 基于 Division / Section / Paragraph 行号范围实现原生语法折叠（`za`/`zc`/`zo`）。
2. 提供 `:CobolFormatCase` 命令，将小写输入的 COBOL 保留字批量规整为大写。

---

## 6. 构建、测试与编译器注意事项

1. **编译器调用准则**：
   - 本项目使用 GnuCOBOL 3.2.0。
   - **严禁使用严格的 `-std=cobol85` 参数**：严格的 COBOL 85 标准不包含 IBM 扩展关键字 `COMP-3`（在严格85中叫 `PACKED-DECIMAL`）以及 COBOL 2002 引入的现代内建函数 `FUNCTION TRIM`。
   - 正确的构建方式：直接调用 `cobc -x -o PROG SRC.COB` 或静态检查 `cobc -fsyntax-only SRC.COB`（采用 GnuCOBOL 默认方言，兼容 IBM 大型机扩展与现代函数）。
2. **快捷验证命令**：
   ```bash
   cd /home/tetsuya/development/cobol
   make check    # 语法飞检
   make run      # 编译、运行并预览生成的 output.csv
   make clean    # 清理二进制产物
   ```
3. **自动化端到端测试准则**：
   - 任何对插件或导航的修改，必须在 headless Neovim 中对练习仓库的真实示例执行验证；插件仓库提供 `scripts/test.sh`，练习仓库提供 `make check`。
   - 验证通过后方可提交推送。

---

## 7. Git 提交与推送守则

1. **保持工作区干净**：任何变更完成后，必须运行 `git status` 确认没有遗留的临时文件或未暂存修改。
2. **子模块提交顺序**：
   - 若修改了 `cobol.nvim`，首先在其子仓库内 commit 并 push；
   - 随后在 `~/chezmoi` 中更新子模块 commit 指针并 commit/push；
   - 最后执行 `chezmoi apply ~/.config/nvim-private` 同步至本地环境。
3. **公开仓库同步**：
   - 本仓库（`iamcheyan/cobol`）为公开仓库，任何教程、样例或 Makefile 更新直接在此提交并 push 到 `origin/main`。
