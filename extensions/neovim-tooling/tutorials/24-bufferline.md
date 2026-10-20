# 缓冲区标签栏：bufferline.nvim

打开十几个文件，`:ls` 只能看到编号，看不出哪个是当前、哪个改了没保存。

bufferline 把缓冲区变成窗口顶部的标签栏：当前的高亮、改过的有圆点、文件类型有图标。

---

## 1. 它解决什么问题

| 需求 | 没有标签栏 | 有 bufferline |
|---|---|---|
| 看打开了哪些文件 | `:ls` + 猜编号 | 顶部一行全看到 |
| 知道哪个是当前 | 靠 Winbar 或记忆 | 当前标签高亮 |
| 知道哪个改了没存 | `:ls` 看 `+` | 标签上有圆点 |
| 切换 | `:b3` | 点标签或用 `<leader>bb` |

## 2. 你的配置

`lua/plugins/bufferline.lua`：

| 选项 | 值 | 含义 |
|---|---|---|
| `mode` | `buffers` | 显示缓冲区（不是标签页） |
| `diagnostics` | `false` | 不显示 LSP 诊断图标 |
| `color_icons` | `false` | 图标继承标签文字颜色，不用文件类型色 |
| `show_tab_indicators` | `false` | 不显示标签编号 |
| `show_buffer_close_icons` | `true` | 每个标签有关闭按钮 |
| `separator_style` | `""` | 无缝紧凑布局 |
| `buffer_padding` | `1` | 标签左右各留 1 格 |

### 与侧栏的配合

```lua
offsets = {
  { filetype = "neo-tree", text = "", padding = 1 },
  { filetype = "aerial", text = "", padding = 1 },
  { filetype = "snacks_layout_box" },
}
```

打开 Neo-tree 或 Aerial 时，标签栏会**让出对应的宽度**，不会压在它们上面。`padding = 1` 是为了让第一个标签对齐编辑区的 winbar。

### 条件启用

```lua
enabled = vim.env.WDIFF_NVIM ~= "1"
```

`WDIFF_NVIM=1` 时不加载（用于特定的 diff 场景）。一般不设置这个变量，所以默认启用。

## 3. 按键

缓冲区操作都在 `<leader>b` 组（which-key 会动态列出当前缓冲区）：

| 按键 | 作用 |
|---|---|
| `<leader>bb` | 切到上一个缓冲区（alternate） |
| `<leader>bd` | 删除当前缓冲区 |
| `<leader>bo` | 删除其它所有缓冲区 |
| `<leader>bi` | 删除不可见的缓冲区 |
| `<leader>bD` | 删除缓冲区并关闭窗口 |
| `<leader>bl` / `<leader>bn` | 下一个缓冲区 |
| `<leader>bh` / `<leader>bp` | 上一个缓冲区 |

**`<leader>bb` 最常用**：在两个文件间来回切。

### 鼠标

| 操作 | 作用 |
|---|---|
| 左键点标签 | 切换过去 |
| 点关闭图标 | 关闭该缓冲区 |
| 点标签栏末尾的 `+` | 新建文件 |
| 点列表图标 | 打开缓冲区列表（snacks picker） |

## 4. 标签栏上能看出什么

| 标记 | 含义 |
|---|---|
| 高亮背景 | 当前缓冲区 |
| 左侧圆点 | 有未保存改动 |
| 文件图标 | 按文件类型 |
| 关闭按钮 | 鼠标可点 |

**诊断图标被关掉了**（`diagnostics = false`），所以 LSP 错误不会显示在标签上——那部分看 gitsigns 和行内 mark。

## 5. 练习

### 练习 1：观察标签栏

```sh
cd ~/development/cobol
nvim
```

1. `:e lessons/17_fixed-length-files/lesson.cob`
2. `:vsplit lessons/20_file-matching/lesson.cob`
3. 观察顶部标签栏

**验收**：能看到两个标签，当前那个高亮。

### 练习 2：观察改动标记

1. 在当前文件里改一个字符（不保存）
2. 观察该标签

**验收**：标签上出现圆点（未保存标记）。`:w` 后圆点消失。

### 练习 3：切换

1. `<leader>bb`

**验收**：在两个缓冲区之间来回切。

### 练习 4：删除其它

1. 打开 3 个文件
2. `<leader>bo`

**验收**：只剩当前一个，其它被删除。

### 练习 5：侧栏让位

1. `<leader>fe` 打开 Neo-tree
2. 观察标签栏是否让出了左侧宽度

**验收**：标签栏从 Neo-tree 右侧开始，不重叠。

## 6. 踩坑

### 标签栏不显示

`enabled = vim.env.WDIFF_NVIM ~= "1"`。检查环境变量：

```vim
:echo $WDIFF_NVIM
```

非空会是 `1`，此时 bufferline 不加载。

### 标签太多挤成一行

标签栏宽度有限。用 `<leader>bo` 删掉不用的，或用 `<leader>fb`（snacks）切换。

### 点 `+` 没反应

新建文件走 `config.file_actions.new_file()`，而关闭图标是原生的。如果点了没反应，检查是否误触了其它元素。

### 颜色跟主题不搭

高亮由 `config.ui_highlights.bufferline_highlights()` 统一生成。改主题会跟着变。

### 看不到诊断

配置关掉了（`diagnostics = false`）。想看诊断用行内 mark 或 `<leader>xq`。

## 7. 官方文档

```vim
:h bufferline
:h bufferline-configuration
```

仓库：<https://github.com/akinsho/bufferline.nvim>

## 8. 边界

- 本篇配置来自 `lua/plugins/bufferline.lua`：`mode = "buffers"`、诊断关闭、`color_icons = false`、无缝分隔。
- `WDIFF_NVIM=1` 时不加载。
- `<leader>b*` 的按键实际由 snacks 的 bufdelete 提供，不是 bufferline 自带。
- 标签栏显示的是**缓冲区**，不是标签页（`:tabnew` 开的标签页不在这里）。
