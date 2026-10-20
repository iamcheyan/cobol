# 代码格式化：conform.nvim

格式化的目标不是「好看」，是**让 diff 只反映真实的改动**。如果每次保存都重排空格，代码审查就变成噪音。

conform.nvim 按文件类型调用对应的格式化工具，并尊重一个全局开关。

---

## 1. 它解决什么问题

| 需求 | 没有 conform | 有 conform |
|---|---|---|
| 保存时自动格式化 | 各语言配不同插件 | 一个配置管所有语言 |
| 手动格式化 | 记 `:!stylua %` 之类 | `<leader>F` |
| 临时关闭格式化 | 改配置 | `<leader>uf` 切换 |
| 找可用格式化工具 | 自己查 | `:ConformInfo` |

## 2. 你的配置

`lua/plugins/conform.lua`：

```lua
keys = {
  {
    "<leader>F",
    function()
      require("conform").format({ async = true, lsp_fallback = true })
    end,
    mode = { "n", "x" },
    desc = "Format (conform)",
  },
},
```

### 各语言的格式化工具

| 文件类型 | 工具 |
|---|---|
| `lua` | `stylua` |
| `sh` / `bash` / `zsh` | `shfmt` |
| `python` | `ruff_fix` → `ruff_format` |
| `javascript` / `typescript` / `tsx` | `prettierd` → `prettier`（`stop_after_first`） |
| `css` / `html` / `json` / `yaml` / `markdown` | `prettierd` → `prettier` |
| `rust` | `rustfmt` |
| `go` | `gofumpt` → `goimports` |
| `c` / `cpp` | `clang_format` |

**注意：列表里没有 `cobol`。**

### 保存时自动格式化：默认关闭

```lua
format_on_save = function(bufnr)
  if vim.g.autoformat == false then
    return nil
  end
  return { timeout_ms = 500, lsp_fallback = true }
end,
```

```lua
init = function()
  vim.g.autoformat = false
end,
```

**默认 `autoformat = false`**，保存不会自动格式化。这是有意的——COBOL 对列位置敏感，自动格式化风险太大。

配置注释说明了为什么用函数形式：

```lua
-- The function form is evaluated on each save, so toggling takes effect
-- immediately instead of being frozen at startup.
```

函数在每次保存时求值，所以切换开关立即生效。

## 3. 使用

### 手动格式化

| 按键 | 作用 |
|---|---|
| `<leader>F` | 格式化当前 buffer（`n` / `x` 模式） |

可视模式下只格式化选中的范围。

### 查看可用工具

```vim
:ConformInfo
```

显示当前 buffer 用哪个格式化工具、是否安装、路径在哪。

### 开关自动格式化

| 按键 | 作用 |
|---|---|
| `<leader>uf` | 全局开关自动格式化 |
| `<leader>uF` | 当前 buffer 开关 |

（这两个键来自 LazyVim 风格的 UI 切换，配置里注明 conform 会尊重它们。）

## 4. COBOL 的情况

**没有 COBOL 格式化工具。** 原因：

1. 没有标准的 COBOL formatter（不像 `gofmt` 之于 Go）；
2. COBOL 的固定格式对列位置有硬性要求，自动重排极易破坏；
3. `cobol.nvim` 提供的是 `:CobolFormatCase`（只把保留字改大写），不做重排。

### COBOL 里的替代方案

| 想做的事 | 工具 |
|---|---|
| 保留字统一大写 | `:CobolFormatCase`（`cobol.nvim`） |
| 缩进对齐 | 手动，或 `cobol.nvim` 的智能 Tab |
| 列位置检查 | `cobol.nvim` 的越界高亮 + `awk` 检查 |
| 语法验证 | `cobc -fsyntax-only` |

**COBOL 代码的"格式化"本质上是手动工作。** 这是这门语言的现实。

### 检查列位置（替代格式化）

第 17 课给了三条 `awk` 命令，可以做成快捷方式：

```sh
LC_ALL=C awk '/^      \*/ {next} {if (length($0)>72) print "over72", NR, length($0)}' lesson.cob
LC_ALL=C awk '/^      \*/ {next} {i=match($0,/[^ ]/); if (i>0 && i<12 && i!=8 && i!=11) print "bad column", NR, i}' lesson.cob
```

## 5. 练习

### 练习 1：查看当前文件用什么格式化工具

```sh
cd ~/development/cobol
nvim lessons/17_fixed-length-files/lesson.cob
```

1. `:ConformInfo`
2. 观察输出

**验收**：COBOL buffer 显示没有可用的格式化工具。

### 练习 2：对比有工具的语言

1. 打开任意 `.lua` 文件
2. `:ConformInfo`

**验收**：显示 `stylua` 及其路径。

### 练习 3：手动格式化

在 Lua 文件里：

1. 故意打乱缩进
2. `<leader>F`
3. 观察缩进被修正

**验收**：文件恢复标准缩进。

### 练习 4：验证默认不自动格式化

1. 打开一个 `.lua` 文件
2. 改一处缩进
3. `:w`
4. 观察缩进是否被自动修正

**验收**：**没有被修正**，因为 `autoformat = false`。

### 练习 5：切换自动格式化

1. `<leader>uf` 打开自动格式化
2. 再改一处缩进
3. `:w`

**验收**：这次保存时自动格式化了。再按 `<leader>uf` 关回去。

### 练习 6：COBOL 格式化替代

1. 打开 COBOL 文件
2. `:CobolFormatCase`
3. 观察保留字是否变成大写

**验收**：`move`、`display` 等变成 `MOVE`、`DISPLAY`，但缩进和列位置不变。

## 6. 踩坑

### `<leader>F` 没反应

`ConformInfo` 看是否有工具可用。没有的话格式化会静默跳过（配置注释说明了：conform 自己会警告 `Formatter 'stylua' unavailable`）。

### 保存时没格式化

默认就是关闭的（`vim.g.autoformat = false`）。用 `<leader>uf` 打开，或手动 `<leader>F`。

### COBOL 里按 `<leader>F` 什么都没发生

没有 COBOL formatter。这是正常的，不是坏了。

### 格式化后 diff 变很大

可能是格式化工具与原有风格不一致。**先 `git diff` 看改了什么**，不接受就 `git checkout --` 恢复。

**这就是 `autoformat = false` 的价值**：避免意外的大范围重排。

### `prettierd` 找不到

`prettierd` 是 prettier 的守护进程版。没装的话会退回 `prettier`（配置里 `stop_after_first = true` 保证了这点）。

## 7. 官方文档

```vim
:h conform
:h conform-options
```

仓库：<https://github.com/stevearc/conform.nvim>

## 8. 边界

- 配置来自 `lua/plugins/conform.lua`：支持 12 类文件类型，**不含 COBOL**。
- **默认不自动格式化**（`vim.g.autoformat = false`）。这是刻意的选择，因为 COBOL 对列位置敏感。
- COBOL 的"格式化"只能用 `:CobolFormatCase`（保留字大写）+ 手动缩进 + `awk` 列位置检查。
- `format_on_save` 用函数形式，所以 `<leader>uf` 切换立即生效，不需要重启。
