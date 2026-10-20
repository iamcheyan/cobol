# 语言服务器：LSP 与代码智能

`cobol.nvim` 提供的是 COBOL 专用能力（标尺、结构、PIC 计算）。**LSP 提供的是通用的代码智能**：跳转定义、找引用、重命名、错误诊断、代码动作。

两者互补。COBOL 没有官方 LSP server，但你的配置用 GnuCOBOL 编译诊断补上了这一块——这就是 `cobol.nvim` 的 diagnostics 模块。

---

## 1. 它解决什么问题

| 需求 | 没有 LSP | 有 LSP |
|---|---|---|
| 跳到定义 | 全局搜索或 `ctags` | `gd` 一次跳转 |
| 查所有引用 | grep 后自己判断 | `gr` 列表 |
| 重命名 | 手动改所有位置 | `<leader>cr` 一次改完 |
| 看参数签名 | 翻文档 | `gK` 浮窗 |
| 修 lint 问题 | 手动查 | `<leader>ca` 代码动作 |
| 看错误 | 编译后翻输出 | 行内 mark 实时显示 |

## 2. 你的配置

`lua/plugins/lsp.lua`。键位按 **server 能力**动态注册——某个 server 不支持某功能时不会绑定那个键。

### 跳转

| 按键 | 作用 | 前提 |
|---|---|---|
| `gd` | 跳转定义 | 有 definitionProvider |
| `gr` | 查看引用列表 | 有 referencesProvider |
| `gy` | 跳转类型定义 | 有 typeDefinitionProvider |
| `gI` | 跳转实现 | 有 implementationProvider |
| `K` | 悬浮文档 | 有 hoverProvider |
| `gK` | 签名帮助 | 有 signatureHelpProvider |
| `<C-k>` | 签名帮助（插入模式） | 同上 |

### 编辑

| 按键 | 作用 | 前提 |
|---|---|---|
| `<leader>ca` | 代码动作（`n` / `x` 模式） | 有 codeActionProvider |
| `<leader>cr` | 重命名符号 | 有 renameProvider |
| `<leader>cR` | 重命名文件 | Snacks |
| `<leader>co` | 整理 import | — |

### 信息

| 按键 | 作用 |
|---|---|
| `<leader>cl` | 当前 buffer 的 LSP 配置信息（哪个 server 在跑） |
| `<leader>cm` | 打开 Mason（管理 server 和工具） |

### 引用跳转

| 按键 | 作用 |
|---|---|
| `]]` | 下一个引用 |
| `[[` | 上一个引用 |
| `<a-n>` | 下一个引用（瞬时高亮） |
| `<a-p>` | 上一个引用 |

这四个走 `Snacks.words`，比 LSP references 轻量，适合快速扫同名符号。

## 3. COBOL 的情况

**COBOL 没有 LSP server。** 所以：

| 功能 | COBOL 里怎么办 |
|---|---|
| 跳转定义 | `cobol.nvim` 的 `gd` / `:CobolGotoDef` |
| Copybook 跳转 | `cobol.nvim` 的 `gf` / `:CobolGotoCopybook` |
| 预览定义 | `cobol.nvim` 的 `K` / `:CobolPreview` |
| 语法诊断 | `cobol.nvim` 调用 `cobc -fsyntax-only` |
| 结构大纲 | `cobol.nvim` 提供 Aerial backend |
| 重命名 | **没有**，用 grug-far 或 grep + 多光标 |

**所以 COBOL 的 `gd` 和 `K` 是 `cobol.nvim` 实现的，不是 LSP。** 这点容易混淆——两个插件绑了同名键。

查看当前 buffer 到底谁在处理：

```vim
:lua =vim.lsp.get_clients({ bufnr = 0 })
```

COBOL buffer 里返回空表，说明没有 LSP 在跑，`gd` 走的是 `cobol.nvim`。

## 4. 哪些语言有 LSP

配置用 `mason-lspconfig` 自动安装。查看已装：

```vim
:Mason
```

常见的有 Lua、Python、TypeScript、Bash、JSON、YAML 等。**COBOL 不在列表里**，因为没有可用的 server。

### 检查某个文件类型是否有 LSP

```vim
:lua =vim.lsp.get_clients({ bufnr = 0 })
```

返回空表 → 没有。

### 安装新 server

```vim
:Mason
```

在界面里搜索、按 `i` 安装。装完重启 Neovim 生效。

## 5. 诊断

LSP 诊断和 GnuCOBOL 诊断是两套机制，显示方式相同（行内 mark）：

| 来源 | 触发 | 内容 |
|---|---|---|
| LSP server | 实时 | 类型错误、未定义符号 |
| `cobol.nvim` diagnostics | 保存、编辑防抖、退出插入 | `cobc` 的语法和警告 |

### 诊断相关按键

| 按键 | 作用 |
|---|---|
| `]d` / `[d` | 下一个 / 上一个诊断 |
| `<leader>cd` | 显示当前行诊断（浮窗） |
| `<leader>xq` | 诊断进 quickfix |

COBOL 里诊断来自 `cobc`。跑一次看效果：

```vim
:CobolLint
```

## 6. 练习

### 练习 1：确认 COBOL 没有 LSP

```sh
cd ~/development/cobol
nvim lessons/17_fixed-length-files/lesson.cob
```

1. `:lua =vim.lsp.get_clients({ bufnr = 0 })`
2. 观察返回值

**验收**：返回空表 `{}`，说明 COBOL 没有 LSP。

### 练习 2：有 LSP 的语言对比

1. 打开任意 `.lua` 文件（比如 `~/.config/nvim/lua/plugins/flash.lua`）
2. `:lua =vim.lsp.get_clients({ bufnr = 0 })`
3. 观察返回值

**验收**：能看到 `lua_ls` 之类的 server 信息。对比练习 1 就能理解差异。

### 练习 3：LSP 跳转

在 Lua 文件里：

1. 光标放到某个函数调用上
2. `gd`

**验收**：跳到函数定义处，`<C-o>` 能返回。

### 练习 4：重命名

在 Lua 文件里：

1. 光标放到一个变量上
2. `<leader>cr`
3. 输入新名字，回车

**验收**：所有引用位置都改了。**在 COBOL 里这个键不可用**——因为没有 renameProvider。

### 练习 5：看 COBOL 诊断

1. 打开一个 COBOL 文件
2. 故意删掉一个句点
3. 保存（`:w`）
4. 看是否有诊断标记

**验收**：出现错误标记，`<leader>cd` 能看到 `cobc` 的报错信息。`u` 撤销。

## 7. 踩坑

### COBOL 里 `gd` 行为像 LSP 但不是

它是 `cobol.nvim` 的 `:CobolGotoDef`。两者行为相似但实现不同。**遇到跳转失败时，先确认是哪个插件在处理**：

```vim
:verbose nmap gd
```

输出会显示映射来源。

### `<leader>cr` 在 COBOL 里无效

没有 renameProvider，键不会注册。用 grug-far（`<leader>sr`）或 grep + 多光标代替。

**注意**：`cobol.nvim` 里 `<leader>cr` 是"记录布局计算"（`:CobolCalcRecord`），和 LSP 的 rename 撞键了。在 COBOL buffer 里按到的是 `cobol.nvim` 的版本。

### Mason 装不上某个 server

网络问题或系统依赖缺失。`:Mason` 界面里按 `?` 看帮助，或看 `:MasonLog`。

### 诊断不更新

LSP 诊断是异步的，改完要等一会。COBOL 的诊断由 `cobol.nvim` 在保存/防抖后触发，`on_change = true`、`debounce_ms = 600`。

## 8. 官方文档

```vim
:h lsp
:h lsp-config
:h vim.lsp.buf
```

- `nvim-lspconfig`：<https://github.com/neovim/nvim-lspconfig>
- `mason.nvim`：<https://github.com/mason-org/mason.nvim>

## 9. 边界

- 本篇按键来自你的配置（`lua/plugins/lsp.lua`），且**按 server 能力动态注册**——server 不支持的功能不会绑键。
- **COBOL 没有 LSP server**。COBOL 的 `gd`、`K`、`gf`、诊断都来自 `cobol.nvim`，不是 LSP。
- `<leader>cr` 在 COBOL buffer 里被 `cobol.nvim` 占用（记录布局），与 LSP 的 rename 不同名同键但不同功能。
- LSP 诊断和 `cobc` 诊断是两套独立机制，COBOL 只用后者。
