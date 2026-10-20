# Git 行级操作：gitsigns.nvim

改完代码打开 `git diff` 看整文件，是件很粗的事。**你想知道的是「我刚加的那 3 行对不对」，不是整个文件的历史差异。**

gitsigns 把 Git 差异放在行级别：左边栏标出哪行新增、哪行修改、哪行删除，还能直接暂存或撤销**单个 hunk**（连续的一段改动）。

---

## 1. 它解决什么问题

| 需求 | 没有 gitsigns | 有 gitsigns |
|---|---|---|
| 看这行改了没 | 跑 `git diff` | 左边栏有标记 |
| 只提交部分改动 | `git add -p` 走交互 | 光标在 hunk 上按一次 |
| 撤销某段改动 | 手动删 | `<leader>gr` 重置 |
| 知道谁写的这行 | `git blame` 全文件 | `<leader>gb` 只显示当前行 |
| 预览这段改了什么 | 切窗口 | `<leader>gp` 浮窗 |

## 2. 你的配置

`lua/plugins/gitsigns.lua`，`version = "v2.1.0"`，`event = "LazyFile"`。

### 符号

```lua
signs = {
  add = { text = "▎" },
  change = { text = "▎" },
  delete = { text = "" },
  topdelete = { text = "" },
  changedelete = { text = "▎" },
  untracked = { text = "▎" },
},
```

左侧用竖条 `▎` 表示。删除用 `` 箭头。颜色区分类型（由 highlight group 决定）。

`signs_staged` 也有相同配置——暂存后的改动另有颜色。

## 3. 全部按键

### 跳转

| 按键 | 作用 |
|---|---|
| `]h` | 下一个 hunk |
| `[h` | 上一个 hunk |
| `]H` | 最后一个 hunk |
| `[H` | 第一个 hunk |

### 暂存（`<leader>gh` 系列）

| 按键 | 作用（`n` / `x` 模式） |
|---|---|
| `<leader>ghs` | 暂存当前 hunk |
| `<leader>ghr` | 重置当前 hunk（丢弃改动） |
| `<leader>ghS` | 暂存整个 buffer |
| `<leader>ghR` | 重置整个 buffer |
| `<leader>ghu` | 撤销上一次暂存 |
| `<leader>ghp` | 内联预览当前 hunk |
| `<leader>ghb` | 显示当前行的 blame |
| `<leader>ghB` | 显示整个 buffer 的 blame |
| `<leader>ghd` | 与索引 diff |
| `<leader>ghD` | 与 HEAD（`~`）diff |

### 简写（`<leader>g` 系列）

配置注释说明这是 LazyVim 风格的快捷键，**不带 `h`**：

| 按键 | 作用 |
|---|---|
| `<leader>gs` | 暂存当前 hunk |
| `<leader>gr` | 重置当前 hunk |
| `<leader>gS` | 暂存整个 buffer |
| `<leader>gR` | 重置整个 buffer |
| `<leader>gu` | 撤销暂存 |
| `<leader>gp` | 预览当前 hunk |
| `<leader>gb` | 当前行 blame |
| `<leader>gB` | 整个 buffer 的 blame |
| `<leader>gy` | 复制当前 hunk（`n` / `v`） |

### 选中 hunk 作为文本对象

| 按键 | 作用 |
|---|---|
| `ih` | **文本对象**：选中当前 hunk（`o` / `x` 模式） |

`ih` 很实用：`dih` 删除整个 hunk，`yih` 复制，`vih` 选中。可以和其它操作符组合。

### 开关符号显示

| 按键 | 作用 |
|---|---|
| `<leader>uG` | 开/关 Git 符号 |

## 4. 典型工作流

### 工作流一：只提交一部分改动

改了三处，只想提交其中两处：

1. `]h` 跳到第一个 hunk
2. `<leader>gs` 暂存
3. `]h` 跳到第二个
4. `<leader>gs` 暂存
5. `<leader>gr` 重置第三个（不想要）
6. `:!git commit -m "..."`

**这就是 `git add -p` 的图形版**，但不用在终端里回答 y/n。

### 工作流二：改错了想撤销一段

1. 光标移到改错的地方
2. `<leader>gp` 预览确认是这段
3. `<leader>gr` 重置

**`<leader>gr` 不可撤销**（除了 `u`），重置前一定先预览。

### 工作流三：看这行是谁写的

1. 光标放到可疑的行
2. `<leader>gb`
3. 浮窗显示 commit、作者、日期、commit message

排查「这个奇怪的判断是什么时候加的、谁加的」时非常有用。

### 工作流四：按 hunk 复制给别人

1. `vih` 或 `yih` 选中/复制整个 hunk
2. 粘贴到聊天窗口

不用手动选取范围。

## 5. COBOL 场景

### 场景一：批量改字段后逐个 hunk 审查

用 grug-far 改了 8 个文件。回到一个文件：

1. `]h` 逐个跳 hunk
2. 每个用 `<leader>gp` 预览
3. 确认无误后一起提交

**这比 `git diff` 滚一遍更可靠**——不会漏看。

### 场景二：撤销一次失败的替换

grug-far 的 `\r` 替换错了：

1. `]h` 找到错误 hunk
2. `<leader>gr` 重置

**注意**：只有**未暂存**的改动能这样撤销。已经 commit 的要 `git revert`。

### 场景三：确认自己没有破坏列位置

改完 COBOL 后：

1. `]h` 看每个 hunk
2. 注意改动是否影响了行首缩进

COBOL 对列敏感，`<leader>gp` 的内联预览能直接看出缩进是否被破坏。

### 场景四：查 bug 引入点

某个字段处理出错：

1. 光标到出问题的行
2. `<leader>gb` 看 blame
3. 找到引入改动的 commit

## 6. 练习

### 练习 1：观察符号

```sh
cd ~/development/cobol
nvim lessons/17_fixed-length-files/lesson.cob
```

1. 在任意行改动几个字符
2. 观察左边栏出现的符号
3. `u` 撤销，符号消失

**验收**：改动行出现 `▎` 标记，撤销后消失。

### 练习 2：预览 hunk

1. 改一处
2. `<leader>gp`

**验收**：浮窗显示这处改动的 diff（`-` 旧行、`+` 新行）。

### 练习 3：重置单个 hunk

1. 改两处（相隔较远）
2. `]h` 跳到第一处
3. `<leader>gr` 重置
4. 观察第二处改动还在

**验收**：只有第一处被撤销，第二处保留。

### 练习 4：`ih` 文本对象

1. 改一处
2. `vih`
3. 观察选中范围

**验收**：选中的正好是这个 hunk 的所有改动行。

### 练习 5：blame

1. 光标放在某个较早的提交里的行
2. `<leader>gb`

**验收**：浮窗显示 commit hash、作者、时间。

### 练习 6：部分暂存（重要）

**⚠️ 在副本仓库上做，不要在本仓库操作。**

1. 改两处
2. `<leader>gs` 暂存第一处
3. `:!git diff --cached` 确认只有第一处在暂存区
4. `:!git reset` 撤销暂存

**验收**：能区分「暂存」和「未暂存」的改动。

## 7. 踩坑

### 左边栏没有符号

可能原因：

1. 文件不在 Git 仓库里；
2. 改动已提交（没有未提交的差异）；
3. `<leader>uG` 把符号关了。

检查：

```vim
:Gitsigns toggle_signs
```

### `<leader>gr` 重置后找不回来

`<leader>gr` 是**丢弃改动**，只受 vim 的撤销栈保护。`u` 能撤销，但退出 Neovim 后就没了。

**先 `<leader>gp` 预览，再 `<leader>gr` 重置。**

### `<leader>gs` 和 `<leader>gS` 搞混

`gs` = stage **hunk**（当前这一块），`gS` = stage **buffer**（整个文件）。小写是局部，大写是整体。

### blame 显示的信息太短

`<leader>gb` 用的是 `blame_line({ full = true })`，已经是最详细的单行版本。想看全文件用 `<leader>gB`。

### 符号颜色和主题不搭

符号本身由配置固定（`▎`），颜色来自 highlight group（`GitSignsAdd` 等）。主题改了颜色会跟着变。

## 8. 官方文档

```vim
:h gitsigns
:h gitsigns-usage
```

仓库：<https://github.com/lewis6991/gitsigns.nvim>

## 9. 边界

- 本篇按键来自 `lua/plugins/gitsigns.lua`：`<leader>gh*` 和 `<leader>g*` 两套（后者是简写），都可用。
- `version = "v2.1.0"` 锁定版本，行为以该版本为准。
- **`<leader>gr` / `<leader>gR` 会丢弃改动**，只有 vim 撤销栈保护。重置前务必 `<leader>gp` 预览。
- 暂存操作只影响 Git 索引，**不会自动 commit**；提交仍需 `git commit`。
