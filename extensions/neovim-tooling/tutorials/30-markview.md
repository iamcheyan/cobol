# Markdown 渲染：markview.nvim

Markdown 文件默认只显示源码：`# 标题` 就是带 `#` 的一行字，表格是原始 `|` 管道符。

markview 把它渲染成接近最终效果的样子：标题变大、表格对齐、代码块有背景、复选框可点。

---

## 1. 它解决什么问题

| 需求 | 源码模式 | markview |
|---|---|---|
| 看标题层级 | 数 `#` 个数 | 字号/颜色区分 |
| 看表格 | 对齐 `|` 看 | 渲染成表格 |
| 看代码块 | 只有等宽字体 | 有背景和语言标记 |
| 看任务列表 | `- [ ]` 文本 | 可勾选的复选框 |

## 2. 你的配置

`lua/plugins/markview.lua`：

| 选项 | 值 | 含义 |
|---|---|---|
| `lazy` | `false` | 立即加载（不等 LazyFile） |
| `ft` | `markdown` 等 4 种 | 只在 Markdown 相关文件生效 |
| `preview.enable` | `true` | 启用渲染 |
| `icon_provider` | `internal` | 用内置图标（不装额外图标库） |

配置注释说明了 `lazy = false` 的原因：

```lua
-- Markview manages its own preview attachment; keep it available after the
-- colorscheme has initialized so Markdown opens with rendered elements.
```

markview 自己管理预览的挂载时机；在配色初始化之后保持可用，这样打开 Markdown 就能看到渲染效果。

### 生效的文件类型

```lua
ft = { "markdown", "markdown.mdx", "quarto", "rmd" },
```

### 切换预览

| 按键 | 作用 |
|---|---|
| `<leader>um` | 开关 Markdown 渲染 |

**只在 Markdown buffer 里生效**（配置里 `ft` 限定了）。

## 3. 渲染什么

| 元素 | 渲染效果 |
|---|---|
| 标题 `#` `##` | 不同字号/颜色 |
| 表格 | 对齐的表格线 |
| 代码块 ``` | 背景块 + 语言标签 |
| 引用 `>` | 左侧竖线 |
| 列表 `-` | 项目符号 |
| 任务列表 `- [ ]` | 可点的复选框 |
| 链接 | 颜色区分 |
| 粗体/斜体 | 字重/斜体 |

## 4. COBOL 课程里的实际价值

这个仓库有大量 Markdown：32 课的 README、`extensions/` 的教程、本套教程本身。

### 场景一：读课程文档

```sh
cd ~/development/cobol
nvim lessons/17_fixed-length-files/README.md
```

渲染后：
- 标题层级清楚
- 表格（比如偏移表）对齐成真正的表格
- 代码块有背景

**比对着源码读舒服得多**，尤其是那些有大量表格的课（第 17 课的 200 字节偏移表）。

### 场景二：写文档时检查排版

写 README 时开渲染，能立刻看出表格是否对齐、标题层级是否正确。

改完按 `<leader>um` 关掉看源码，确认没有语法错误。

### 场景三：核对表格

第 17 课的偏移表有 14 行。渲染成表格后，一眼看出哪一行的列没对齐。

## 5. 练习

### 练习 1：打开渲染

```sh
cd ~/development/cobol
nvim lessons/17_fixed-length-files/README.md
```

**验收**：标题有层级样式，表格渲染成表格，代码块有背景。

### 练习 2：切换

1. `<leader>um`

**验收**：回到源码模式（能看到 `#` 和 `|`）。再按一次恢复渲染。

### 练习 3：看表格

1. 找到 README 里的偏移表
2. 观察渲染后的对齐

**验收**：表格列对齐，比源码模式易读。

### 练习 4：确认只在 Markdown 生效

1. 打开一个 `.cob` 文件
2. 按 `<leader>um`

**验收**：**没反应**（配置限定了 `ft`，只在 Markdown 里绑定）。

### 练习 5：看任务列表

1. 打开一个含 `- [ ]` 的 Markdown（如果仓库里有）
2. 观察渲染

**验收**：显示为复选框样式（可能可点，取决于配置）。

## 6. 踩坑

### 打开 Markdown 没有渲染

检查：
1. 文件类型是否是 `markdown`：`set ft?`
2. markview 是否加载：`:Lazy` 看状态

配置 `lazy = false`，所以启动后就该可用。

### `<leader>um` 没反应

只在 Markdown buffer 绑定（`ft` 限定）。在 `.cob` 里按没用。

### 渲染后看不清代码

代码块用等宽字体渲染，但如果主题对比度低，可能发灰。检查：

```vim
:hi MarkviewCode
```

### 编辑时光标位置怪

渲染模式下光标仍在源码字符上，只是显示被美化。**编辑逻辑不变**——`x`、`dd`、插入都照常。

### 想临时看源码

`<leader>um` 切换。或者用 `:set ft=` 去掉文件类型（不推荐，会丢高亮）。

### 大文件卡

Markdown 很长（比如本教程）时渲染会慢一点。必要时关掉。

## 7. 与其它插件的关系

| 需求 | 工具 |
|---|---|
| 渲染 Markdown | markview（`<leader>um`） |
| 编辑 Markdown 结构 | 常规 vim 操作 |
| 大纲跳转 | aerial（`<leader>cs`，支持 markdown backend） |
| 格式化 Markdown | LSP 或外部格式化工具 |

**markview 只改显示，不改文件内容。** 关掉它文件还是原样。

## 8. 官方文档

```vim
:h markview
```

仓库：<https://github.com/OXY2DEV/markview.nvim>

## 9. 边界

- 本篇配置来自 `lua/plugins/markview.nvim`：`lazy = false`，`ft` 限定 4 种，`icon_provider = "internal"`。
- `<leader>um` **只在 Markdown buffer 生效**。
- markview 只改显示，不修改文件内容；关掉渲染文件仍是原样。
- COBOL 开发本身用不到它，但**读课程文档时很有用**——这个仓库有 30+ 个 Markdown 文件。
