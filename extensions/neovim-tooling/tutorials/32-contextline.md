# 面包屑下拉：contextline.nvim

Winbar 上的面包屑是**一行**，层级多了会被截断。而且它只能「看」，不能「操作」。

contextline 给面包屑加一个下拉菜单：列出当前文件的完整结构，可以点选跳转。

---

## 1. 它解决什么问题

| 需求 | 只有 Winbar 面包屑 | 加 contextline |
|---|---|---|
| 看完整层级 | 一行，长的被截断 | 下拉里全列出 |
| 跳到某个节点 | 只能滚动找 | 菜单里点选 |
| 看文件路径/文件名 | 取决于配置 | 菜单里可显示 |

## 2. 你的配置

`lua/plugins/contextline.lua`：

| 选项 | 值 | 含义 |
|---|---|---|
| `separator` | ``  `` | 层级分隔符 |
| `show_path` | `false` | 不显示文件路径 |
| `show_file` | `false` | 不显示文件名 |
| `show_icons` | `true` | 显示图标 |
| `use_lsp` | `true` | 用 LSP 符号（如可用） |
| `use_navic` | `true` | 用 navic |
| `use_treesitter` | `true` | 用 Treesitter |

### 按键

| 按键 | 命令 | 作用 |
|---|---|---|
| `<leader>cb` | `:ContextlineMenu` | 打开结构下拉菜单 |

### 数据来源优先级

三个源都启用：`use_lsp`、`use_navic`、`use_treesitter`。

实际生效哪个取决于**当前文件类型有没有对应能力**：

| 文件类型 | 可用源 |
|---|---|
| 有 LSP 的语言 | LSP 符号 |
| 有 Treesitter parser | Treesitter |
| COBOL | **取决于 `cobol.nvim` 是否提供** |

COBOL 没有 LSP 也没有 parser，所以 contextline 在 COBOL 里**可能拿不到结构**——这时下拉是空的。

## 3. 与 `cobol.nvim` 的面包屑对比

`cobol.nvim` 自带 Winbar 面包屑（第 02 篇讲过），显示 `[ PROCEDURE DIVISION > 2000-PROCESS-SECTION > 2100-PROCESS-RECORD ]`。

| | `cobol.nvim` | contextline |
|---|---|---|
| 显示位置 | Winbar（一直可见） | 下拉菜单（按需打开） |
| 数据 | 自己解析 COBOL | LSP / Treesitter / navic |
| COBOL 支持 | **有** | 无（除非插件提供） |

**在 COBOL 里，用 `cobol.nvim` 的面包屑和 Aerial 大纲就够**；contextline 主要服务其它语言。

## 4. 练习

### 练习 1：打开菜单

1. 打开任意文件
2. `<leader>cb`

**验收**：弹出结构菜单（有内容则显示层级，无内容则为空或提示）。

### 练习 2：COBOL 里看结果

```sh
cd ~/development/cobol
nvim lessons/32_bank-reconciliation-project/lesson.cob
```

1. `<leader>cb`
2. 观察

**验收**：**COBOL 大概率为空**（无 LSP 无 parser）。这不是坏了——用 Aerial（`<leader>cs`）代替。

### 练习 3：有 LSP 的语言

1. 打开一个 Lua 文件
2. `<leader>cb`

**验收**：能看到 LSP 提供的符号层级（函数、变量等）。

### 练习 4：确认配置

```vim
:lua =require("contextline").config or vim.inspect(_G)
```

（具体 API 以插件为准。）至少确认 `separator`、`show_icons` 的值。

### 练习 5：对比 Aerial

1. `<leader>cb` 看下拉
2. `<leader>cs` 看 Aerial 侧栏

**验收**：两者结构来源不同；COBOL 下 Aerial 有内容、contextline 为空。

## 5. 踩坑

### 菜单是空的

两种可能：

1. 当前文件类型没有 LSP / Treesitter 支持（**COBOL 就是这种情况**）；
2. 插件还没拿到数据（等一下再试）。

### 和 `cobol.nvim` 的 Winbar 重复

两者都显示层级，但位置不同（一个常驻 Winbar，一个按需下拉）。**COBOL 里以 `cobol.nvim` 的为准。**

### `show_path` / `show_file` 关了

配置设成 `false`，所以菜单里不显示路径和文件名。想看要改配置。

### 图标显示成方块

`show_icons = true` 但需要图标字体。终端字体不支持的话显示为方块。

### 与 navic 的关系

`use_navic = true` 会用 navic 提供的 LSP 面包屑数据。如果没装 navic，这个选项无效果（但不报错）。

## 6. 官方文档

仓库：<https://github.com/iamcheyan/contextline.nvim>

## 7. 边界

- 本篇配置来自 `lua/plugins/contextline.lua`：`<leader>cb` 打开菜单，路径/文件名显示已关闭。
- 数据来自 LSP / navic / Treesitter。**COBOL 三者皆无**，所以 COBOL 里菜单通常为空。
- **COBOL 用 `cobol.nvim` 的 Winbar 面包屑和 Aerial 大纲**，不要用 contextline。
- 这是你自己开发的插件（`iamcheyan/`），行为可能随版本变化。
