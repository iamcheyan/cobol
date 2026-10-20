# 代码大纲：aerial.nvim

COBOL 程序动辄几百行、几十个段落。**要改 `2200-POST-TRANSACTION`，得先找到它。** 滚动、搜索、还是看大纲？

Aerial 在大纲侧栏里列出整个结构树：DIVISION → SECTION → PARAGRAPH。点一下就跳过去。

---

## 1. 它解决什么问题

| 需求 | 没有大纲 | 有 Aerial |
|---|---|---|
| 找某个段落 | 搜 `PERFORM` 再反查定义 | 侧栏里直接看到所有段落名 |
| 了解文件结构 | 滚一遍 | 一眼看到层级 |
| 跳转 | `:行号` 或搜索 | 光标移动 + 回车 |
| 知道光标在哪层 | 看 Winbar 面包屑 | 侧栏自动高亮当前项 |

## 2. 你的配置

`lua/plugins/aerial.lua`：

```lua
layout = {
  default_direction = "left",
  placement = "window",
  width = 32,
  min_width = 32,
  max_width = 32,
  resize_to_content = false,
  win_opts = {
    foldcolumn = "1",
    statuscolumn = " ",
  },
},
show_guides = true,
manage_folds = true,
link_tree_to_folds = true,
link_tree_to_window = true,
```

### 关键参数

| 参数 | 值 | 含义 |
|---|---|---|
| `default_direction` | `left` | 左侧打开 |
| `width` | 32 | 固定宽度 32 列 |
| `resize_to_content` | `false` | 不随内容变宽 |
| `show_guides` | `true` | 显示层级引导线 |
| `link_tree_to_folds` | `true` | 折叠与大纲联动 |
| `link_tree_to_window` | `true` | 光标移动时高亮跟随 |

### 后端配置（关键）

```lua
backends = {
  ["_"] = { "treesitter", "lsp", "markdown", "asciidoc", "man" },
  cobol = { "cobol" },
  cbl = { "cobol" },
  cob = { "cobol" },
  dosbatch = { "batch" },
  batch = { "batch" },
  sh = { "treesitter", "lsp" },
},
```

**COBOL 用的是 `cobol.nvim` 提供的专用 backend**，不是 Treesitter。这很关键——COBOL 没有 Treesitter parser，但 Aerial 照样能工作，因为 `cobol.nvim` 自己解析结构。

## 3. 打开与操作

### 开关

| 按键 / 命令 | 作用 |
|---|---|
| `<leader>cs` | 开关大纲侧栏 |
| `:AerialToggle` | 同上 |
| `:AerialOpen` | 打开 |
| `:AerialInfo` | 显示当前 buffer 用的 backend |

### 侧栏内操作

| 按键 | 作用 |
|---|---|
| `Enter` | 跳到选中项 |
| `j` / `k` | 上下移动 |
| `o` / `zo` | 展开节点 |
| `c` / `zc` | 收起节点 |
| `>` | 切到下一个符号组 |
| `<` | 切到上一个符号组 |
| `?` | 显示侧栏帮助 |
| `q` | 关闭 |

在你配置里 `<` 和 `>` 被重新绑定为「切换符号组」（`sidebar_tabs.cycle`），用于在多个文件的符号之间切换。

## 4. COBOL 大纲里能看到什么

`cobol.nvim` 的 backend 解析出三层：

```text
▾ IDENTIFICATION DIVISION
▾ DATA DIVISION
  ▾ WORKING-STORAGE SECTION
      01 WS-ACCOUNT-TABLE
      01 WS-BATCH-COUNTS
▾ PROCEDURE DIVISION
  ▾ 0000-MAIN
  ▾ 1000-READ-AND-WRITE
  ▾ 1100-WRITE-BALANCE-RECORD
  ▾ 9000-CLOSE-FILES
```

**段落名（`0000-MAIN`）是最有用的部分**——COBOL 的 `PERFORM` 全靠段落组织流程，从大纲能直接看出整个程序的骨架。

### 与 Winbar 面包屑的配合

`cobol.nvim` 的 Winbar 显示 `[ PROCEDURE DIVISION > 2000-PROCESS-SECTION > 2100-PROCESS-RECORD ]`，Aerial 侧栏显示全局结构。

一个看当前在哪，一个看整体在哪。`link_tree_to_window = true` 让侧栏自动高亮光标所在的段落。

## 5. 练习

### 练习 1：打开大纲看结构

```sh
cd ~/development/cobol
nvim lessons/32_bank-reconciliation-project/lesson.cob
```

1. `<leader>cs`
2. 观察左侧结构树

**验收**：能看到 DIVISION → SECTION → PARAGRAPH 三层，段落名可见。

### 练习 2：跳转到段落

1. 大纲里移到某个段落名（如 `1000-READ-AND-WRITE`）
2. `Enter`

**验收**：光标跳到该段落在源码中的位置。

### 练习 3：光标跟随

1. 在大纲打开的状态下，在源码里往下滚
2. 观察侧栏高亮

**验收**：侧栏高亮跟随当前光标所在的段落（`link_tree_to_window = true`）。

### 练习 4：折叠联动

1. 源码里 `zM` 全部折叠
2. 观察大纲

**验收**：大纲的展开/收起与源码折叠联动（`link_tree_to_folds = true`）。

### 练习 5：确认 backend

1. `:AerialInfo`
2. 观察 backends 一行

**验收**：COBOL buffer 显示用的是 `cobol` backend，不是 `treesitter`。

### 练习 6：对比有 LSP 的语言

1. 打开一个 `.lua` 文件
2. `<leader>cs`
3. `:AerialInfo`

**验收**：Lua 文件用的是 `treesitter`/`lsp` backend。对比能看出 COBOL 的特殊处理。

## 6. 踩坑

### COBOL 里大纲是空的

检查：

```vim
:AerialInfo
```

如果 backend 显示 `cobol` 但列表空，说明 `cobol.nvim` 的结构解析没拿到内容。确认 `cobol.nvim` 已加载：

```vim
:lua =require("cobol")
```

### `<leader>cs` 打开的不是 Aerial

你的配置里 `<leader>cs` 走 `config.sidebar_tabs.toggle_symbols()`，这是自定义的切换逻辑（支持多标签）。行为应该与 `:AerialToggle` 一致，但如果有异常，直接用命令排查。

### 侧栏宽度改不了

配置写死了 `width = 32`、`min_width = 32`、`max_width = 32`、`resize_to_content = false`。想改要改配置，不是拖动。

### 与 Neo-tree 抢位置

两个都是左侧栏（`default_direction = "left"`）。同时开会挤在一起。用 `sidebar_tabs` 的 `<` / `>` 切换。

### 会话恢复后大纲消失

`auto-session` 的配置专门处理了这个（`config/sidebar_session.lua`）。如果恢复后没有，`:AerialToggle` 重新打开即可。

## 7. 与其它插件的分工

| 想知道 | 用什么 |
|---|---|
| 文件结构骨架 | Aerial（`<leader>cs`） |
| 当前在哪个段落 | Winbar 面包屑（自动显示） |
| 目录结构 | Neo-tree（`<leader>fe`） |
| 某个名字在哪定义 | `gd`（`cobol.nvim`） |
| 某个名字在哪用到 | `<leader>fw`（snacks grep） |

**Aerial 是结构视图，不是搜索工具。** 找具体名字用 grep 更快。

## 8. 官方文档

```vim
:h aerial
:h aerial-usage
```

仓库：<https://github.com/stevearc/aerial.nvim>

COBOL backend 来自 `cobol.nvim`：<https://github.com/iamcheyan/cobol.nvim>

## 9. 边界

- 本篇配置来自 `lua/plugins/aerial.lua`：宽度写死 32 列，方向固定左侧，`<` / `>` 被重绑为切换符号组。
- **COBOL 走 `cobol.nvim` 提供的专用 backend**，不依赖 Treesitter。所以 COBOL 能有大纲但 `S` 节点跳转不可用（见 [Treesitter 那篇](16-treesitter-and-folding.md)）。
- Aerial 是**可选依赖**：没装它 `cobol.nvim` 的其他功能照常工作。
- 会话恢复时侧栏的保存/还原由 `auto-session` 的 `sidebar_session` 模块处理，不是 Aerial 自己做的。
