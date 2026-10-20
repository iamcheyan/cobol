# 边缘滚动标记：satellite.nvim

原生 Neovim 的滚动条只有一条细线，看不出「文件里哪里改了、哪里有错误、哪里是搜索结果」。

satellite 在滚动条位置画一张**缩略图**：把光标、搜索结果、诊断、Git 改动都标在上面。

---

## 1. 它解决什么问题

| 想知道 | 原生滚动条 | satellite |
|---|---|---|
| 改动集中在哪 | 看不出 | Git 标记 |
| 错误在第几行 | 滚动找 | 诊断标记 |
| 搜索结果分布 | 逐个 `n` | 一次看到全部位置 |
| 光标在文件哪 | 滚动条位置 | 高亮标记 |

## 2. 你的配置

`lua/plugins/scrollbar.lua`（文件名是 scrollbar，装的是 satellite）：

| 选项 | 值 | 含义 |
|---|---|---|
| `current_only` | `false` | 所有窗口都显示标记 |
| `winblend` | `0` | 不透明 |
| `zindex` | `40` | 层级 |

### 排除的文件类型

```lua
excluded_filetypes = {
  "contextline_menu", "dropbar_menu", "dropbar_menu_fzf",
  "DressingInput", "cmp_docs", "cmp_menu", "blink-cmp-menu",
  "noice", "prompt", "TelescopePrompt",
  "neo-tree", "aerial", "help", "lazy", "mason",
}
```

 Neo-tree、Aerial、help、lazy、mason 等界面**不显示标记**——避免干扰。

### 四类标记

```lua
handlers = {
  cursor = { enable = true, overlap = true, priority = 100 },
  search = { enable = true },
  diagnostic = { enable = true },
  gitsigns = { enable = true },
}
```

| 标记 | 来源 | 含义 |
|---|---|---|
| `cursor` | 光标位置 | 优先级最高（100），覆盖其它标记 |
| `search` | 搜索结果 | 所有匹配位置 |
| `diagnostic` | LSP / `cobc` | 错误和警告 |
| `gitsigns` | Git 差异 | 改动、新增、删除 |

`overlap = true` 允许标记重叠；`priority = 100` 保证光标标记在最上层。

## 3. 怎么看

标记出现在**窗口右侧**（滚动条位置）：

```text
内容行 1                    │
内容行 2                    ▎  ← Git 改动
内容行 3                    │
  ...                       ▪  ← 错误
内容行 40                   ┃  ← 光标
```

不用滚动就能知道：这个文件有 3 处改动、1 个错误在第 5 行附近。

## 4. COBOL 场景

### 场景一：改完一批代码看影响范围

用多光标或 grug-far 改了多处后：

1. 看右侧的 Git 标记
2. 标记密集的区域就是改动集中的地方
3. 不用 `:Gitsigns` 逐个跳

### 场景二：找语法错误

`cobc` 诊断出现后：

1. 看右侧的诊断标记
2. 直接滚到那个位置

**COBOL 编译错误往往集中在某几行**——标记能立刻指出范围。

### 场景三：搜索结果分布

`<leader>fg` 搜 `WS-RECORD-COUNT` 后，虽然用了 picker，但如果用 `/` 搜索：

1. 看右侧的搜索标记
2. 一眼看到 30 处分布在哪

### 场景四：长文件的光标定位

在第 32 课那种几百行的程序里：

1. 看光标标记在缩略图的哪个位置
2. 知道自己在文件的哪一段

## 5. 练习

### 练习 1：观察 Git 标记

```sh
cd ~/development/cobol
nvim lessons/17_fixed-length-files/lesson.cob
```

1. 改几行（不保存）
2. 观察右侧

**验收**：改动行对应的位置出现 Git 标记。

### 练习 2：观察诊断标记

1. 故意删掉一个句点
2. `:w` 触发诊断
3. 观察右侧

**验收**：出现诊断标记。`u` 撤销后消失。

### 练习 3：搜索标记

1. `/WS-RECORD-COUNT`
2. 观察右侧

**验收**：所有匹配位置都有标记。

### 练习 4：光标标记

1. 在长文件里跳到第 100 行
2. 观察光标标记的位置

**验收**：标记位置对应文件的大致位置。

### 练习 5：确认排除

1. `<leader>fe` 打开 Neo-tree
2. 观察 Neo-tree 窗口右侧

**验收**：**没有** satellite 标记（因为在 `excluded_filetypes` 里）。

## 6. 踩坑

### 标记不显示

检查当前文件类型是否被排除：

```vim
:echo &filetype
```

对照 `excluded_filetypes` 列表。`help`、`mason`、`lazy`、`neo-tree`、`aerial` 都排除了。

### 标记颜色和主题不搭

标记颜色来自对应的 highlight group（`DiagnosticError`、`GitSignsAdd` 等）。改主题会跟着变。

### 想关掉某类标记

改 `handlers` 里对应的 `enable = false`。比如不要搜索标记：

```lua
search = { enable = false },
```

### 和其他滚动条插件冲突

你的配置用 satellite，把 snacks 的 scroll 关掉了（见 snacks 那篇）。不要同时启用两个。

### 窗口很窄时看不到

窗口太窄时滚动条被挤压。加宽窗口或接受不显示。

### `current_only = false` 的含义

所有窗口都显示标记（不只当前窗口）。如果只想当前窗口有，改成 `true`。

## 7. 与其它插件的分工

| 标记内容 | 数据来自 |
|---|---|
| Git 改动 | gitsigns |
| 诊断 | LSP 或 `cobc`（经 `cobol.nvim`） |
| 搜索结果 | vim 的 `/` 搜索 |
| 光标 | satellite 自己 |

**satellite 不产生数据**，它只是把其它插件的数据画到滚动条上。想改标记行为要去对应插件的配置。

## 8. 官方文档

```vim
:h satellite
:h satellite-configuration
```

仓库：<https://github.com/lewis6991/satellite.nvim>

## 9. 边界

- 本篇配置来自 `lua/plugins/scrollbar.lua`（文件名是 scrollbar，装的是 satellite）。
- 四类标记：`cursor`、`search`、`diagnostic`、`gitsigns`。
- 排除了 15 种文件类型（Neo-tree、Aerial、help、mason、lazy 等**不显示**标记）。
- satellite 不产生数据，只显示其它插件的数据。
- snacks 的 scroll 功能已关闭，滚动标记由 satellite 提供。
