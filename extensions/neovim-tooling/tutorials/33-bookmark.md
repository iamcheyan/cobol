# 书签：bookmark.nvim

Aerial 看结构，grep 找内容，**但「我昨天改到一半的那个位置」怎么记？**

bookmark 让你在任意行打书签，下次一键跳回去。

---

## 1. 它解决什么问题

| 需求 | 没有书签 | 有 bookmark |
|---|---|---|
| 记住某个位置 | 靠记忆或 `:marks` | 打书签 |
| 在多个位置间跳 | `Ctrl-o` / `Ctrl-i` 历史 | `]b` / `[b` |
| 列所有标记点 | 没有 | `<leader>mm` |
| 按项目保存 | 否 | 是（项目级） |

## 2. 你的配置

`lua/plugins/bookmark.lua`：

```lua
opts = {
  sign = " ",
  sign_color = "#e0af68",
  mouse = true,
},
```

| 选项 | 值 | 含义 |
|---|---|---|
| `sign` | ``  `` | 左侧栏的书签图标 |
| `sign_color` | `#e0af68` | 黄色 |
| `mouse` | `true` | 支持鼠标点击 |

### 按键

| 按键 | 命令 | 作用 |
|---|---|---|
| `<leader>mt` | `:BookmarkToggle` | 开关当前行的书签 |
| `<leader>mm` | `:BookmarkList` | 列出所有书签 |
| `]b` | `:BookmarkNext` | 下一个书签 |
| `[b` | `:BookmarkPrev` | 上一个书签 |
| `<leader>mc` | `:BookmarkClear!` | 清除**当前缓冲区**的书签 |
| `<leader>mC` | `:BookmarkClear` | 清除**整个项目**的书签 |

### 注意 `<leader>m` 组

which-key 配置里 `<leader>m` 是 **bookmarks** 组；`mh`、`mH`、`mt`、`m0`、`ma`、`mA` 等键都由本插件使用。

## 3. 使用场景

### 场景一：跨天继续工作

改到第 27 课一半，明天要接着做：

1. 光标移到那行
2. `<leader>mt`（打书签）
3. 第二天打开文件
4. `<leader>mm`（列书签）或直接 `]b`

### 场景二：在长文件里标记多个点

第 32 课几百行，要关注三处：

1. 每处 `<leader>mt`
2. `]b` / `[b` 在三处间跳

比记行号（`:120`）可靠——行号会变，书签跟着行移动。

### 场景三：代码审查时标记疑点

读别人代码发现三处可疑：

1. 每处打书签
2. 看完后 `<leader>mm` 回顾
3. 处理完 `<leader>mc` 清空

## 4. 练习

### 练习 1：打书签

```sh
cd ~/development/cobol
nvim lessons/32_bank-reconciliation-project/lesson.cob
```

1. 光标移到某个段落（如 `1000-INIT`）
2. `<leader>mt`
3. 观察左侧

**验收**：左侧出现 `` 图标。

### 练习 2：跳转

1. 移到文件另一处
2. `]b`

**验收**：跳回书签位置。再按 `[b` 也能来回。

### 练习 3：列书签

1. 在两处打书签
2. `<leader>mm`
3. 观察列表

**验收**：列出两个书签，能点选跳转。

### 练习 4：清除当前缓冲区

1. `<leader>mc`

**验收**：当前文件的书签清空，其它文件的保留。

### 练习 5：清除项目

1. `<leader>mC`

**验收**：**整个项目**的书签都清空。**这个操作范围更大**，注意。

### 练习 6：鼠标

1. 在左侧栏书签图标上点击（`mouse = true`）

**验收**：跳转或触发相关操作。

## 5. 踩坑

### 书签在关闭文件后还在吗

取决于插件的存储方式（项目级持久化）。通常下次打开还在。**以实际测试为准**——打一个书签、重启 Neovim、看还在不在。

### `<leader>mC` 清得太狠

`BookmarkClear` 是**整个项目**。只想清当前文件用 `<leader>mc`（`BookmarkClear!`）。

### 图标是方块

`sign = " "` 需要图标字体。终端不支持就显示方块。

### 书签跟着行移动吗

书签记的是行。插入/删除行后，书签会跟着那一行移动（大多数实现如此）。**但如果行被删了，书签可能消失。**

### 和 vim 自带的 `m` 标记冲突

vim 原生 `ma` 是设置标记。插件用 `<leader>m*`，不冲突（前缀不同）。

## 6. 与其它插件的关系

| 需求 | 工具 |
|---|---|
| 记住"改到一半的位置" | bookmark（`<leader>mt`） |
| 看文件结构 | aerial（`<leader>cs`） |
| 跳到定义 | `gd`（`cobol.nvim` / LSP） |
| 搜内容 | `<leader>fw`（snacks） |
| 回到上次编辑位置 | `Ctrl-o` / `gi` |

**bookmark 是「手动标记」，其它是「自动定位」。**

## 7. 官方文档

仓库：<https://github.com/iamcheyan/bookmark.nvim>

## 8. 边界

- 本篇配置来自 `lua/plugins/bookmark.lua`：`<leader>mt`/`mm`/`mc`/`mC`、`]b`/`[b`，`mouse = true`。
- `<leader>mC` 清除范围是**整个项目**，比 `<leader>mc`（当前缓冲区）大得多。
- 书签持久化行为以实际测试为准；这是你自己开发的插件（`iamcheyan/`）。
