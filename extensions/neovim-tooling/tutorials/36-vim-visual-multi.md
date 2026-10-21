# 另一套多光标：vim-visual-multi

你的配置里有**两个多光标插件**：`multicursor.nvim`（第 08 篇）和 `vim-visual-multi`。

这篇讲后者，以及**你的配置为它做的特殊改造**——这是理解两者分工的关键。

---

## 1. 为什么有两套

| 插件 | 定位 |
|---|---|
| `multicursor.nvim` | 现代实现，配合 Treesitter，`gaip` 逐行加光标 |
| `vim-visual-multi` | 老牌插件，`Ctrl-n` 选词加光标，功能更"传统" |

两者都在 `lazy-lock.json` 里。`multicursor-line.nvim` 把 `vim-visual-multi` 列为依赖：

```lua
dependencies = { "mg979/vim-visual-multi" },
```

所以它不是多余的——`multicursor-line` 的行首/行尾光标功能建立在它之上。

## 2. 你的配置做了什么

`lua/plugins/vim-visual-multi.lua` 不是简单加载插件，而是**重定义了 `Ctrl-n` 的行为**。

### 核心逻辑

```lua
local last_linewise_mode = nil

vim.api.nvim_create_autocmd("InsertLeave", {
  callback = function()
    last_linewise_mode = nil
  end,
})
```

退出插入模式时清空记忆的模式。

```lua
local function insert_ctrl_n()
  local vm = vim.g.Vm
  local vm_active = type(vm) == "table" and (tonumber(vm.buffer) or 0) > 0
  local extending = vm_active and tonumber(vm.extend_mode) == 1

  local cur_col = vim.fn.col(".")
  local end_col = vim.fn.col("$")
  local at_line_end = (cur_col >= end_col) or (cur_col == end_col - 1 and cur_col > 1)
  local at_line_start = (cur_col <= 1)
  ...
```

### 它判断的三件事

| 变量 | 含义 |
|---|---|
| `vm_active` | vim-visual-multi 是否已有活跃选区 |
| `at_line_end` | 光标是否在行尾 |
| `at_line_start` | 光标是否在行首 |

### 行尾模式（eol）

光标在行尾时按 `Ctrl-n`：

```lua
if is_eol_mode then
  last_linewise_mode = "eol"
  vim.cmd("stopinsert")
  vim.cmd("normal! $")
  vim.fn["vm#commands#add_cursor_at_pos"](08-multicursor-batch-editing.md)
  vim.cmd("normal! j$")
  vim.fn["vm#commands#add_cursor_at_pos"](08-multicursor-batch-editing.md)
  vim.cmd("call b:VM_Selection.Insert.key('A')")
end
```

含义：

1. 当前行末尾加一个光标
2. 下一行末尾再加一个
3. 进入 `A`（行尾追加）插入模式

**典型用途**：连续多行末尾追加相同内容。

### 行首模式（bol）

光标在行首时按 `Ctrl-n`：

```lua
if is_bol_mode then
  last_linewise_mode = "bol"
  ...
  vim.cmd("call b:VM_Selection.Insert.key('A')")
end
```

类似，但在行首（`I` 的行为）。

**注意**：代码里 `bol` 分支也用了 `Insert.key('A')`，实际行为以你的使用为准——可能是笔误，也可能是刻意（`A` 在行尾追加）。

### 普通模式（不在行首尾）

走 vim-visual-multi 的默认 `Ctrl-n`：选中光标下的词，继续按则选下一个相同词。

## 3. 与 multicursor.nvim 的分工

| 场景 | 用哪个 |
|---|---|
| 按词/选区加光标 | `multicursor.nvim`（`<leader>n`） |
| 逐行加光标（段落里每行） | `multicursor.nvim`（`gaip`） |
| **行尾连续追加** | `vim-visual-multi`（`Ctrl-n` 在行尾） |
| 行首批量插入 | `vim-visual-multi`（`Ctrl-n` 在行首） |
| 通过 `multicursor-line` 按行加 | `multicursor-line`（`<leader>mh` 等） |

**`multicursor-line.nvim` 的 `<leader>mh`/`mt`/`ma` 等键**是基于 `vim-visual-multi` 实现的"按行加光标"，比手工 `Ctrl-n` 更方便。

## 4. 基础用法（vim-visual-multi 原生）

即使不谈你的定制，它本身也有完整功能：

| 按键 | 作用 |
|---|---|
| `Ctrl-n` | 选中光标下的词（再按选下一个） |
| `Ctrl-Down` / `Ctrl-Up` | 垂直方向加光标 |
| `Ctrl-x` | 跳过当前选中 |
| `Ctrl-p` | 移除当前光标 |
| `Tab` | 在"光标模式"和"扩展模式"间切换 |
| `\\a` | 选中所有匹配 |
| `q` | 退出多光标 |

可视模式下 `Ctrl-n` 会基于选区加光标。


![在第一条 COBOL 声明末尾按配置的 `Ctrl-n` 后，vim-visual-multi 在下一条声明末尾增加了第二个光标（底栏显示 `2 / 2`）。](images/36-vimvisualmulti-context.png)

此实拍画面展示自定义行尾模式：光标位于第一条声明末尾，按 `Ctrl-n` 后，下一个光标落在第二条声明末尾。

## 5. COBOL 场景

### 场景一：多行末尾加相同后缀

```cobol
01 WS-FLAG-A PIC X(1) VALUE "A".
01 WS-FLAG-B PIC X(1) VALUE "B".
01 WS-FLAG-C PIC X(1) VALUE "C".
```

想都加上 ` - DONE`：

1. 光标在第一行行尾
2. `Ctrl-n`（进入行尾模式，加两个光标）
3. 输入 ` - DONE`
4. `Esc`

**这比 multicursor 的 `gaip` + `A` 更快**——因为不用先选行。

### 场景二：连续行首加注释

光标在行首，`Ctrl-n` 进入行首模式，输入 `*`（COBOL 注释符）。

**注意**：会把整批行变成注释。COBOL 注释必须在第 7 列，所以行首模式的实际位置要确认。

### 场景三：批量改标识符

光标在 `WS-ACCT` 上，`Ctrl-n` 选中，再 `Ctrl-n` 加下一个，然后 `c` 改。

这和 `multicursor.nvim` 的 `<leader>n` 功能重叠，选一个顺手的用。

## 6. 练习

### 练习 1：行尾追加

```sh
cd ~/development/cobol
nvim lessons/17_fixed-length-files/lesson.cob
```

1. 找连续几行（比如几个 `01` 声明）
2. 光标移到第一行**行尾**
3. `Ctrl-n`
4. 输入点内容
5. `Esc`

**验收**：多行末尾都加上了内容。

### 练习 2：行首模式

1. 光标移到某行**行首**
2. `Ctrl-n`
3. 输入内容
4. `Esc`

**验收**：多行行首都加上了内容。

### 练习 3：按词选中

1. 光标在 `WS-` 开头的一个词上
2. `Ctrl-n`（不在行首尾时）
3. 再 `Ctrl-n` 加下一个

**验收**：多个相同词被选中。

### 练习 4：对比 multicursor

1. 用 `multicursor.nvim` 的 `<leader>n` 做同样的事
2. 比较手感

**验收**：能说出两者的差别（`<leader>n` 更"现代"，`Ctrl-n` 行尾模式更直接）。

### 练习 5：退出

1. 在多光标状态下按 `q` 或 `Esc`

**验收**：回到单光标。

## 7. 踩坑

### `Ctrl-n` 在插入模式没反应

你的定制函数判断 `vm_active`。如果 vim-visual-multi 状态异常，可能不触发。用 `:echo g:Vm` 检查。

### 行尾模式只加了一个光标

代码里判断 `at_line_end`。如果光标不在真正的行尾（后面还有空格），不会进入行尾模式。先 `$` 到行尾。

### 和补全菜单冲突

`Ctrl-n` 原本是补全的"下一项"。插入模式下可能被 blink.cmp 占用。**实际归属以测试为准。**

### 两个多光标插件打架

`multicursor.nvim` 和 `vim-visual-multi` 同时存在时，某些按键可能有冲突。建议**明确分工**：按词用 `<leader>n`，行尾用 `Ctrl-n`。

### `last_linewise_mode` 残留

退出插入模式会清空（`InsertLeave` 自动命令）。如果行为异常，手动 `:lua last_linewise_mode = nil` 不适用（是局部变量）——重新进入插入模式即可。

## 8. 官方文档

仓库：<https://github.com/mg979/vim-visual-multi>

```vim
:h vim-visual-multi
```

## 9. 边界

- 本篇配置来自 `lua/plugins/vim-visual-multi.lua`，它**重定义了 `Ctrl-n`**：行尾/行首有特殊模式，其它位置走原生逻辑。
- 它是 `multicursor-line.nvim` 的依赖，不是多余插件。
- 与 `multicursor.nvim` 功能有重叠，建议明确分工避免混淆。
- `Ctrl-n` 在插入模式可能与 blink.cmp 的补全快捷键争夺，实际生效者以测试为准。
