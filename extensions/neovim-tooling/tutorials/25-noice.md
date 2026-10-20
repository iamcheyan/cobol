# 消息与命令行美化：noice.nvim

Neovim 默认把消息、命令行、确认框挤在底部的同一行：**`-- INSERT --`、错误提示、`:` 命令、确认框全挤在一起**，还经常被其它插件的浮窗盖住。

noice.nvim 把它们分开、美化、放到合适的位置。

---

## 1. 它解决什么问题

| 需求 | 默认 Neovim | noice |
|---|---|---|
| 看命令行 | 底部一行，被浮窗盖 | 独立命令行视图 |
| 确认对话框（`:q` 未保存） | 底部一行，容易被忽略 | 居中浮窗，带边框 |
| 看复制了什么 | 底部一闪 | 底部独立视图，停留 2.2 秒 |
| 看报错 | 底部一行，可能被覆盖 | 分类路由 |

## 2. 你的配置

`lua/plugins/noice.lua`，配置顶部注释说明了意图：

```lua
-- Keep Ex command entry at the bottom, but render Neovim's blocking confirm
-- prompts (for example :q with unsaved changes) in Noice's centered popup.
```

### 命令行

| 选项 | 值 | 含义 |
|---|---|---|
| `cmdline.enabled` | `true` | 接管命令行 |
| `view` | `cmdline` | 底部视图 |
| `format.cmdline.icon` | `false` | 保留原生 `:` 提示符 |
| `format.input.view` | `cmdline` | 输入框也放底部 |

**保留原生 `:` 而不是 noice 默认的 `>` 图标**——这是刻意的，避免刚上手时不认识。

### 消息

```lua
messages = {
  enabled = true,
  view = "cmdline",
  view_error = "cmdline",
  view_warn = "cmdline",
  view_search = "cmdline",
  view_history = "messages",
}
```

普通消息、错误、警告、搜索都走底部命令行视图。`view_history` 走 messages（`:messages` 能翻）。

### 复制确认（yank）

```lua
routes = {
  {
    filter = { event = "msg_show", find = "yanked into" },
    view = "yank",
    opts = { stop = true },
  },
},
views = {
  yank = {
    backend = "popup",
    position = { row = "100%", col = 0 },
    size = { height = "auto", width = "100%" },
    timeout = 2200,
  },
},
```

复制后会显示一个**底部横条**，停留 2.2 秒。配置注释说明：

```lua
-- Keep yank confirmations in their own bottom view. They can stack while
-- copying, then the whole message group hides after the last yank.
```

连续复制会堆叠，最后一次复制后整组消失。

### 确认对话框

```lua
confirm = {
  position = { row = "50%", col = "50%" },
  size = { max_width = 64 },
  border = { style = "rounded", padding = { 1, 2 }, text = { top = " Confirm " } },
}
```

`:q` 遇到未保存改动时，弹出**居中圆角浮窗**，标题是 `Confirm`。

### 明确关闭的功能

```lua
popupmenu = { enabled = false },
notify = { enabled = false },
lsp = {
  progress = { enabled = false },
  message = { enabled = false },
  hover = { enabled = false },
  signature = { enabled = false },
},
```

| 关闭项 | 原因 |
|---|---|
| `popupmenu` | 补全菜单交给 blink.cmp |
| `notify` | 通知交给 snacks |
| `lsp.`* | LSP 悬浮/签名/进度保留原生行为 |

**所以 noice 在你这里只管三件事**：命令行、复制提示、确认框。

## 3. 使用

### 确认框

1. 改一个文件不保存
2. `:q`
3. 弹出居中浮窗：`[Y]es [N]o [C]ancel`

按 `y` / `n` / `c` 选择。

### 复制提示

1. `yy` 复制一行
2. 底部出现横条显示复制内容
3. 2.2 秒后消失

连续 `yy` 会堆叠，最后一次后才隐藏。

### 命令行

1. 按 `:`
2. 命令行在底部显示，带原生 `:` 提示符

和原生体验接近，但不会被浮窗盖住。

## 4. 练习

### 练习 1：确认框

```sh
cd ~/development/cobol
nvim
```

1. 打开任意文件，改一个字符（不保存）
2. `:q`
3. 观察弹出的浮窗

**验收**：居中圆角浮窗，标题 `Confirm`，三个选项。

### 练习 2：复制提示

1. `yy`
2. 观察底部

**验收**：出现横条显示复制内容，约 2.2 秒后消失。

### 练习 3：连续复制堆叠

1. 快速按 5 次 `yy`
2. 观察提示

**验收**：提示堆叠（显示多次），最后一次后整组消失。

### 练习 4：命令行

1. 按 `:`
2. 输入 `echo "test"` 回车

**验收**：命令行在底部，用原生 `:` 提示符（不是 noice 默认的 `>`）。

### 练习 5：确认 noice 没管通知

1. 触发一个通知（比如 `:lua vim.notify("hi")`）
2. 观察

**验收**：通知由 snacks 显示（因为 `notify.enabled = false`），不是 noice。

## 5. 踩坑

### 命令行不见了

noice 接管了命令行。如果异常退出可能残留状态，用 `:NoiceEnable` / `:NoiceDisable` 切一下。

### 确认框不居中

配置写死 `position = { row = "50%", col = "50%" }`。如果不居中，检查是否有其它插件（如 snacks）也在改浮窗位置。

### 复制提示一闪而过

`timeout = 2200`（2.2 秒）。想更长要改配置。

### 想让 noice 接管 LSP 悬浮

配置**明确关掉了**：

```lua
lsp = {
  hover = { enabled = false },
  signature = { enabled = false },
},
```

LSP 的 hover（`<leader>K`）保留原生行为。想用 noice 的美化版要改配置。

### 通知不是 noice 显示的

`notify = { enabled = false }`，通知归 snacks。**这是配置有意的**，不是 bug。

### 补全菜单不对

`popupmenu = { enabled = false }`，补全菜单由 blink.cmp 提供。

## 6. 与其它插件的分工

| 界面元素 | 归谁管 |
|---|---|
| 命令行 | noice |
| 复制提示 | noice |
| 确认框 | noice |
| 通知 | **snacks** |
| LSP hover / 签名 | **原生 vim** |
| 补全菜单 | **blink.cmp** |

理解这个分工，就不会奇怪"为什么 noice 文档里的功能我这里没有"。

## 7. 官方文档

```vim
:h noice
:h noice-config
```

仓库：<https://github.com/folke/noice.nvim>

## 8. 边界

- 本篇配置来自 `lua/plugins/noice.lua`。**noice 在这里只管命令行、复制提示、确认框三件事**。
- `notify`、`lsp.*`、`popupmenu` 全部关闭，分别归 snacks、原生 vim、blink.cmp。
- 命令行保留原生 `:` 提示符（不是 noice 默认的 `>`）。
- 复制提示 `timeout = 2200` 毫秒，连续复制会堆叠。
