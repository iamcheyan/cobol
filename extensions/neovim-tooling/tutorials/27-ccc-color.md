# 颜色编辑：ccc.nvim

在 CSS、Lua、终端配色文件里看到 `#3b82f6`，想知道它是什么颜色、想调亮一点、想转成 `rgb()`——手改十六进制很痛苦。

ccc.nvim 提供颜色选择器和格式转换。

---

## 1. 它解决什么问题

| 需求 | 手改 | ccc |
|---|---|---|
| 看 `#3b82f6` 是什么色 | 脑补或开外部工具 | 直接高亮显示 |
| 调亮/调暗 | 手算 RGB | 滑块拖动 |
| 转 `rgb()` / `hsl()` | 手算或用网站 | `<leader>cC` |
| 选一个新颜色 | 记色值 | 拾色器 |

## 2. 你的配置

`lua/plugins/ccc.lua`：

```lua
cmd = { "CccPick", "CccConvert" },
keys = {
  { "<leader>cp", "<cmd>CccPick<cr>", desc = "Color Picker (ccc)" },
  { "<leader>cC", "<cmd>CccConvert<cr>", desc = "Color Convert (ccc)" },
},
opts = {
  highlighter = {
    auto_enable = false, -- 禁用自带的 buffer 高亮
    lsp = false,
  },
},
```

| 按键 | 命令 | 作用 |
|---|---|---|
| `<leader>cp` | `:CccPick` | 打开拾色器 |
| `<leader>cC` | `:CccConvert` | 转换颜色格式 |

### 关键：关闭了自动高亮

```lua
highlighter = {
  auto_enable = false,
  lsp = false,
},
```

配置注释说明了原因：

```lua
-- 禁用自带的 buffer 高亮，避免与极速的 mini.hipatterns 争抢高亮组
```

**ccc 会自动给 buffer 里的色值加背景色**，但你的配置用 `mini.hipatterns` 做这件事（见 [mini.hipatterns 那篇](29-rainbow-delimiters.md)），两者会抢同一个高亮组。所以这里关掉了。

**结果**：你在 buffer 里看到的颜色高亮来自 mini.hipatterns，不是 ccc。ccc 只在你主动按 `<leader>cp` / `<leader>cC` 时工作。

## 3. 拾色器（`<leader>cp`）

光标放到色值上（如 `#3b82f6`），按 `<leader>cp`：

```text
┌─────────────────────────────┐
│  #3b82f6                    │
│  R ████████░░  59           │
│  G █████████░░░ 130         │
│  B █████████████ 246        │
│  ─────────────────────────  │
│  [hex] [rgb] [hsl] ...      │
└─────────────────────────────┘
```

### 操作

| 按键 | 作用 |
|---|---|
| `h` / `l` | 切换要调整的通道（R/G/B 或 H/S/L） |
| `j` / `k` 或 `↑` `↓` | 增减数值 |
| `0`–`9` | 直接输入数值 |
| `<CR>` | 确认 |
| `q` 或 `<Esc>` | 取消 |

### 切换色彩空间

拾色器支持多种表示法，`Tab` 或方向键切换：

- `hex`：`#3b82f6`
- `rgb`：`rgb(59, 130, 246)`
- `hsl`：`hsl(217, 91%, 60%)`
- 以及更多（取决于配置）

## 4. 转换格式（`<leader>cC`）

光标在色值上，按 `<leader>cC`，选择目标格式：

```text
将 #3b82f6 转换为：
  > rgb
    hsl
    ...
```

选中后原地替换。

## 5. COBOL 场景

COBOL 源码里**基本用不到颜色**。但以下场景有用：

### 场景一：改终端配色或状态栏主题

你在 `~/nvim/colors/` 或 `lua/config/ui_highlights.lua` 里定义颜色时，用 `<leader>cp` 调一个合适的色值。

### 场景二：改课程站点的 CSS

`site-src/site.css` 里有颜色定义。想改主题色：

1. 光标放到色值
2. `<leader>cp` 调
3. 确认

**注意**：课程站点的 CSS 用的是设计 token（`var(--purple)` 等），直接改色值会破坏主题切换。改之前先看 [第 32 课](../../../lessons/32_bank-reconciliation-project/README.md) 附近关于主题的说明。

### 场景三：看 mini.hipatterns 高亮的颜色

因为 ccc 的自动高亮关了，buffer 里的颜色块来自 mini.hipatterns。想知道具体色值，用 `<leader>cp` 打开它。

## 6. 练习

### 练习 1：打开拾色器

1. 打开一个含色值的文件（比如 `~/nvim/lua/config/ui_highlights.lua`）
2. 光标放到 `#` 开头的色值上
3. `<leader>cp`

**验收**：拾色器打开，显示当前色值。

### 练习 2：调整颜色

1. 在拾色器里按 `j` / `k` 调整某个通道
2. 观察 buffer 里的色值实时变化
3. `<CR>` 确认

**验收**：色值被修改。

### 练习 3：取消

1. `<leader>cp`
2. 调几下
3. `q` 或 `<Esc>`

**验收**：色值没变（取消生效）。

### 练习 4：转换格式

1. 光标在 `#3b82f6` 上
2. `<leader>cC`
3. 选 `rgb`

**验收**：变成 `rgb(59, 130, 246)` 之类。

### 练习 5：确认高亮来自 mini.hipatterns

1. 打开一个 CSS 文件，观察颜色是否有背景色块
2. 检查配置

```vim
:lua =require("ccc").config.highlighter
```

**验收**：`auto_enable = false`，说明背景色块不是 ccc 给的。

## 7. 踩坑

### `<leader>cp` 没反应

光标必须**在色值上**（如 `#3b82f6`）。不在色值上打开会提示没找到颜色。

### buffer 里没有颜色高亮

配置关掉了 ccc 的自动高亮（`auto_enable = false`），高亮由 mini.hipatterns 提供。这是有意的，不是坏了。

**想让 ccc 也高亮**：改配置 `auto_enable = true`，但会和 mini.hipatterns 抢高亮组。

### 转换后格式不对

`<leader>cC` 让你选目标格式。选错了用 `u` 撤销再试。

### 拾色器里的按键不灵

拾色器有自己的一套按键（`h`/`l` 切通道，`j`/`k` 调值）。不是普通 vim 模式。按 `?` 看帮助（如果可用）。

### COBOL 文件里 `<leader>cp` 找不到颜色

正常——COBOL 源码不含色值。这个插件对 COBOL 开发价值有限，主要用于配置/CSS 文件。

## 8. 官方文档

```vim
:h ccc
:h ccc-options
```

仓库：<https://github.com/uga-rosa/ccc.nvim>

## 9. 边界

- 本篇配置来自 `lua/plugins/ccc.lua`：`<leader>cp`（拾色器）、`<leader>cC`（转换）。
- **自动高亮被关闭**（`auto_enable = false`），buffer 里的颜色高亮来自 mini.hipatterns。这是配置为避免高亮组冲突做的选择。
- COBOL 源码基本不含色值，本插件主要用于配置文件和 CSS。
- 课程站点的 CSS 使用设计 token，直接改色值可能破坏明暗主题切换。
