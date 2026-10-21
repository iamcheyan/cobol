# 完整差异与历史：diffview.nvim

gitsigns 解决「这行改了没」，diffview 解决「**这次提交整体改了什么**」和「**这个文件历史上怎么变的**」。

它把 diff 做成并排视图（左边旧、右边新），带文件树、逐文件导航。

---

## 1. 它解决什么问题

| 需求 | 没有 diffview | 有 diffview |
|---|---|---|
| 看整次提交的改动 | `git show` 挤在终端 | 并排视图 + 文件树 |
| 逐文件审查 | 滚动长 diff | 文件树点选 |
| 看某文件的历史 | `git log -p 文件` | 侧栏列出所有版本 |
| 三路合并 | 手动 | 内置三路视图 |

## 2. 你的配置

`lua/plugins/diffview.lua`：

```lua
opts = {
  enhanced_diff_hl = true,
  view = {
    default = {
      layout = "diff2_horizontal",
    },
  },
  hooks = {
    diff_buf_read = function(bufnr)
      vim.opt_local.swapfile = false
    end,
    diff_buf_win_enter = function(bufnr, winid, ctx)
      vim.opt_local.swapfile = false
    end,
  },
}
```

| 参数 | 值 | 含义 |
|---|---|---|
| `enhanced_diff_hl` | `true` | 更精细的差异高亮（词级） |
| `layout` | `diff2_horizontal` | 并排、左右分栏 |
| `swapfile` | `false` | 不写交换文件（diff buffer 是只读视图） |

## 3. 按键

| 按键 | 命令 | 作用 |
|---|---|---|
| `<leader>gd` | `:DiffviewOpen` | 打开当前工作区差异 |
| `<leader>gv` | `:DiffviewOpen` | 同上（同义键） |
| `<leader>gD` | `:DiffviewFileHistory %` | **当前文件**的历史 |
| `<leader>gV` | `:DiffviewFileHistory` | 整个分支的历史 |
| `<leader>gq` | `:DiffviewClose` | 关闭 |

### 常用命令（无键绑定）

| 命令 | 作用 |
|---|---|
| `:DiffviewOpen HEAD~3` | 与 3 个提交前比较 |
| `:DiffviewOpen main...feature` | 两个分支比较 |
| `:DiffviewOpen <commit>` | 与某个提交比较 |
| `:DiffviewToggleFiles` | 开关文件面板 |
| `:DiffviewFocusFiles` | 焦点移到文件面板 |
| `:DiffviewRefresh` | 刷新 |


![`DiffviewOpen` 的实际画面：左侧文件面板、中间旧版本、右侧新版本，改动行高亮。](images/20-diffview.png)

`DiffviewOpen` 的实际画面：左侧文件面板、中间旧版本、右侧新版本，改动行高亮。

## 4. 界面结构

打开 `:DiffviewOpen` 后：

```text
┌────────────────┬──────────────────────────────────────────┐
│ 文件树          │  差异视图（并排）                         │
│                │                                          │
│ M lessons/...  │  旧版本            │  新版本              │
│ M extensions/  │  ────────────────  │  ────────────────    │
│                │  - 旧行            │  + 新行              │
└────────────────┴──────────────────────────────────────────┘
```

### 视图内按键

| 按键 | 作用 |
|---|---|
| `<Tab>` | 在文件树和 diff 间切换焦点 |
| `]c` / `[c` | 下一个 / 上一个改动块 |
| `do` | 取旧版本（get from other） |
| `dp` | 放新版本（put to other） |
| `g?` | 显示帮助 |
| `q` | 关闭 |

`do` / `dp` 在解决冲突时很有用：把某一侧的内容应用到另一侧。

## 5. COBOL 场景

### 场景一：审查一次批量替换

用 grug-far 改了 8 个文件后：

1. `<leader>gd`
2. 文件树里逐个点选
3. `]c` 在每个文件里逐个跳改动块

**比 `git diff` 滚屏强的地方**：文件树能一眼看出改了哪些文件，不会漏。

### 场景二：看某个字段名是怎么演变的

```text
<leader>gD    当前文件的历史
```

侧栏列出所有涉及这个文件的提交，点开看每次改了什么。

排查「`WS-RECORD-COUNT` 什么时候从 `PIC 9(2)` 变成 `PIC 9(3)` 的」这类问题。

### 场景三：对比两个分支

```vim
:DiffviewOpen main...feature
```

看特性分支相对主线改了什么。适合审查 PR。

### 场景四：审查课程改动

```sh
cd ~/development/cobol
git log --oneline -3
```

```
ea537fc docs(tutorial): add search, jump and batch-replace guides
1e44647 docs(tutorial): add multicursor batch-editing guide with exercises
19a6f36 docs(lesson-17): verify fixed-length offsets with a column ruler
```

```vim
:DiffviewOpen 1e44647~1
```

看那个提交整体改了什么。

## 6. 练习

### 练习 1：打开工作区差异

```sh
cd ~/development/cobol
nvim lessons/17_fixed-length-files/lesson.cob
```

1. 改一行
2. `<leader>gd`

**验收**：打开并排 diff，左边是 HEAD 版本，右边是当前（含你的改动）。

### 练习 2：在 diff 里跳改动块

1. 在 diff 视图里按 `]c`
2. 观察光标跳到下一个改动

**验收**：光标在改动块间移动。

### 练习 3：看文件历史

1. `<leader>gD`（当前文件）
2. 观察左侧的提交列表
3. 点选一个提交

**验收**：能看到该文件在那个提交时的 diff。

### 练习 4：看某个提交的整体改动

```vim
:DiffviewOpen 19a6f36~1
```

**验收**：显示那条 commit 的全部改动。

### 练习 5：关闭

1. `<leader>gq`

**验收**：diffview 关闭，回到普通编辑。

### 练习 6：文件树导航

1. `<leader>gd`
2. `<Tab>` 切到文件树
3. `j` / `k` 移动，`Enter` 打开某个文件

**验收**：能在多文件 diff 间切换。

## 7. 踩坑

### `<leader>gd` 和 `gd` 不是一回事

- `gd`（无 leader）= 跳转定义（`cobol.nvim` 或 LSP）
- `<leader>gd` = diffview open

**一个字母之差，功能完全不同。** 打错会打开一个意外的窗口。

### 打开后一片空白

说明当前工作区没有未提交改动。用 `:DiffviewOpen HEAD~1` 或 `<leader>gD` 看历史。

### diff 里不能编辑

diffview 的 buffer 是**只读视图**。要改代码得回到原文件。

### `do` / `dp` 按了没反应

它们只在**冲突解决**场景（`diff3` 布局）下有意义。普通 diff 视图里改了也没用。

### 关闭后窗口布局变了

diffview 会重排窗口。`<leader>gq` 后可能需要 `<C-w>=` 重新等分。

### 大仓库打开慢

`:DiffviewOpen` 要计算全部差异。改动多时等几秒正常。

## 8. 与 gitsigns 的分工

| 想知道 | 用什么 |
|---|---|
| 这行改了没 | gitsigns 左边栏符号 |
| 这段改动是什么 | `<leader>gp`（gitsigns 预览） |
| 只暂存这一段 | `<leader>gs`（gitsigns） |
| **整次提交改了什么** | `<leader>gd`（diffview） |
| **这个文件的历史** | `<leader>gD`（diffview） |
| 谁写的这行 | `<leader>gb`（gitsigns blame） |

**行级用 gitsigns，文件级和历史用 diffview。**

## 9. 官方文档

```vim
:h diffview
:h diffview-configuration
```

仓库：<https://github.com/sindrets/diffview.nvim>

## 10. 边界

- 本篇按键来自 `lua/plugins/diffview.lua`：`<leader>gd`、`<leader>gv`、`<leader>gD`、`<leader>gV`、`<leader>gq`。
- 布局固定为 `diff2_horizontal`（左右并排）。想要上下布局需改配置。
- diff buffer 是只读的，`swapfile = false` 是配置刻意的设置（避免为只读视图写交换文件）。
- `:DiffviewOpen` 无参数时比较**工作区与索引**；看历史要显式给 revision 或用 `<leader>gD`。
