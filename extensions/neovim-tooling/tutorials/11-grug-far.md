# 跨文件查找替换：grug-far.nvim

改一个字段名出现在 8 个文件、30 处，`:%s` 只能管一个文件，`argdo` 要先构造文件列表。**grug-far 把「搜什么、换成什么、范围多广」放在一个界面里，先看清楚再落盘。**

---

## 1. 它解决什么问题

| 做法 | 问题 |
|---|---|
| `:%s/old/new/g` | 只作用于当前文件 |
| `:argdo %s/.../g \| update` | 要先凑出文件列表，改完才发现搜错了 |
| 逐个文件手动改 | 30 处改到第 20 处就忘了前面改过哪些 |
| 外部 `sed -i` | 脱离编辑器，改错难撤销 |

grug-far 的做法：**先展示全部匹配（含行号、上下文），你确认无误后再执行替换**。而且替换前的预览可以逐条审查。

## 2. 你的实际配置

配置在 `lua/plugins/grug-far.lua`：

```lua
{
  "MagicDuck/grug-far.nvim",
  opts = { headerMaxWidth = 80 },
  cmd = { "GrugFar", "GrugFarWithin" },
  keys = {
    {
      "<leader>sr",
      function()
        local grug = require("grug-far")
        local ext = vim.bo.buftype == "" and vim.fn.expand("%:e")
        grug.open({
          transient = true,
          prefills = {
            filesFilter = ext and ext ~= "" and "*." .. ext or nil,
          },
        })
      end,
      mode = { "n", "x" },
      desc = "Search and Replace",
    },
  },
}
```

### 三个入口

| 入口 | 作用 |
|---|---|
| `<leader>sr` | 打开，并**自动把当前文件扩展名填进 Files Filter** |
| `:GrugFar` | 打开，不预填过滤 |
| `:GrugFarWithin` | 只在**视觉选中范围内**替换 |

**`<leader>sr` 的自动预填很关键**：你在编辑 `.cob` 文件时按它，Files Filter 会变成 `*.cob`，只搜 COBOL 源码，不会误改 `README.md` 里的同名文字。

在 `x`（可视）模式按 `<leader>sr`，会带上当前选区。

### 关键参数

`transient = true`：替换完成后自动关闭窗口，不留在界面里。

`headerMaxWidth = 80`：顶部标题栏最大宽度。

![搜索、过滤、看匹配数，这三步都在写入前完成。`matches in N files` 是决定「能不能执行」的唯一依据。](images/11-grug-far-flow.png)

搜索、过滤、看匹配数，这三步都在写入前完成。`matches in N files` 是决定「能不能执行」的唯一依据。

## 3. 界面结构

按 `<leader>sr` 后：

```text
┌─────────────────────────────────────────────────────────┐
│ Help g?   Replace \r   Sync All \s ...                  │
├──────────────────────────┬──────────────────────────────┤
│  Search:                 │  ← 输入搜索模式               │
│    e.g. foo              │                              │
│  Replace:                │  ← 输入替换内容               │
│    e.g. bar              │                              │
│  Files Filter:           │  ← 如 *.cob                  │
│  Flags:                  │  ← --ignore-case 等           │
│  Paths:                  │  ← 限定目录                   │
├──────────────────────────┴──────────────────────────────┤
│  ⟪ ripgrep ⟫                                            │
│  4 matches in 2 files                                   │
│    f.cob                                                │
│      5   01 WS-ALPHA PIC X(10) VALUE "AAAAAAAAAA".  [1] │
│      9       DISPLAY WS-ALPHA                       [2] │
│    g.cob                                                │
└─────────────────────────────────────────────────────────┘
```

**输入区和结果区在同一个缓冲区里**。用 `j` / `k` 在字段之间移动，`i` 进入插入模式编辑字段。

### 字段说明

| 字段 | 作用 | 示例 |
|---|---|---|
| Search | 搜索模式（支持正则） | `WS-ALPHA`、`foo([a-z0-9]*)` |
| Replace | 替换内容（支持捕获组） | `WS-FIRST`、`${1}_foo` |
| Files Filter | 限定文件类型或路径 | `*.cob`、`*.{cob,cpy}`、`**/docs/*.md` |
| Flags | 传给 ripgrep 的参数 | `--ignore-case`、`-i` |
| Paths | 限定搜索目录 | `./lessons/`、`../` |

### 常用 Flags

| Flag | 作用 |
|---|---|
| `-i` | 忽略大小写 |
| `-.` | 包含隐藏文件 |
| `--no-ignore` | 不理会 `.gitignore` |
| `--multiline` | 跨行匹配 |

## 4. 执行替换的三种方式

这是 grug-far 与普通 `:%s` 最大的区别：**替换不是一次全做，而是可以分级**。

| 按键 | 作用 | 什么时候用 |
|---|---|---|
| `\r` | **Replace**：执行替换 | 确认无误，全部替换 |
| `\s` | **Sync All**：把结果区文本同步回原文件 | 手动编辑过结果后再落盘 |
| `\l` | **Sync Line**：只同步当前这一条 | 逐条确认 |
| `\n` | **Sync Next**：同步当前条并移到下一条 | 边看边改 |
| `\p` | **Sync Prev**：同步当前条并移到上一条 | 反向 |
| `\v` | **Sync File**：同步当前文件的所有结果 | 按文件分步 |
| `g?` | 打开帮助窗口 | 忘了按键时 |

注意 `\` 是 `localleader`（你的配置里 `vim.g.maplocalleader = "\\"`）。

### `\r` 与 `\s` 的区别

- **`\r`（Replace）**：全量替换，支持多行替换。
- **`\s`（Sync All）**：把**结果区当前显示的文本**写回文件。

如果你手动删掉了结果区的某些行，`\s` 就只同步剩下的——这是**排除部分匹配**的办法。

## 5. 实测记录

在本仓库 COBOL 文件上按 `<leader>sr`，搜索 `WS-ALPHA`：

```text
4 matches in 2 files

   f.cob
     5        01 WS-ALPHA PIC X(10) VALUE "AAAAAAAAAA". [1]
     9            DISPLAY WS-ALPHA                      [2]

   g.cob
```

观察要点：

1. **输入即搜**，不用按回车。
2. 显示 **`N matches in M files`**——先看这个数字，确认范围对不对。
3. 每条结果带 **文件名 + 行号 + 上下文**，`[1]` `[2]` 是该文件内的匹配序号。
4. 打开的 `<leader>sr` 已把 Files Filter 预填成 `*.cob`（因为我在编辑 `.cob` 文件）。

**这一步是最重要的安全检查**：如果 `matches in N files` 里的文件数超出预期，说明过滤条件不够严，先改 Files Filter 再替换。

## 6. COBOL 开发中的四个场景

### 场景一：跨课统一改名

字段 `WS-ACCT-` 在 32 课里都有出现，要统一改成 `WS-ACCOUNT-`：

```text
Search:        WS-ACCT-
Replace:       WS-ACCOUNT-
Files Filter:  *.cob
```

**先看匹配数**。如果只想改某一课，在 Paths 里填 `./lessons/17_fixed-length-files/`。

### 场景二：Copybook 声明与所有引用一起改

`.CPY` 和 `.cob` 都要改：

```text
Files Filter: *.{cob,cpy}
```

grug-far 的 Files Filter 支持 glob 花括号。

### 场景三：把 `VALUE "A"` 全部改成 `VALUE "P"`

```text
Search:        VALUE "A"
Replace:       VALUE "P"
Files Filter:  *.cob
```

**注意**：这样会连注释里的 `VALUE "A"` 也改掉。搜索框支持正则，可以只匹配代码行：

```text
Search:        ^(?!      \*).*VALUE "A"
```

或者更简单：先替换，再用 `git diff` 检查有没有误改注释（见下文「配合 Git」）。

### 场景四：只改当前选中的几行

1. 用 `V` 选中几行
2. 按 `<leader>sr`（视觉模式下）
3. 搜索和替换只作用于选区

适合「这一段的 `WS-X` 改名，别的地方不动」。

## 7. 配合 Git 做安全检查

grug-far 改得很快，但改错也快。**替换前确保工作区干净，替换后立刻看 diff。**

```sh
cd ~/development/cobol
git status --short          # 应该只有一个文件有改动
git diff                    # 逐行看改了什么
```

如果改错了：

```sh
git checkout -- 文件路径      # 撤销单个文件
git restore .              # 撤销全部未提交改动
```

你的配置里还有 `<leader>gd`（diffview），能并排看改动。

## 8. 练习

### 练习 1：先观察，不执行

```sh
cd ~/development/cobol
nvim lessons/17_fixed-length-files/lesson.cob
```

1. `<leader>sr`
2. Search 填 `WS-RECORD-COUNT`
3. **只观察** `N matches in M files`，不执行替换
4. `<Esc>` 关闭

**验收**：能说出匹配数和涉及文件数。这一步不修改任何文件。

### 练习 2：验证 Files Filter 的作用

1. `<leader>sr`，Search 填 `FILE STATUS`
2. 观察 Files Filter 是否为 `*.cob`
3. 把 Files Filter 清空，再观察匹配数变化

**验收**：清空过滤后匹配数增加（因为搜到了 `.md` 文档里的 `FILE STATUS` 字样）。**这说明为什么不能随便清空过滤。**

### 练习 3：真实替换（在副本上）

```sh
cd /tmp && cp -r ~/development/cobol/lessons/17_fixed-length-files /tmp/grugtest
cd /tmp/grugtest && nvim lesson.cob
```

1. `<leader>sr`
2. Search: `WS-RECORD-COUNT`
3. Replace: `WS-WRITE-COUNT`
4. 确认 `matches in 1 files`
5. `\r` 执行
6. `:wq` 保存
7. `cobc -fsyntax-only lesson.cob` 验证

**验收**：编译通过。若失败，说明替换影响了不该改的地方。

### 练习 4：逐条确认

1. 在副本上搜一个出现 3 次的词
2. 填入替换值
3. 用 `\n` 逐条同步，每按一次看光标移到哪
4. 最后 `\s` 一次性同步剩下的

**验收**：能区分 `\n`（逐条）和 `\s`（全量）的效果。

### 练习 5：只用结果区

1. 搜出 5 条匹配
2. 在结果区**手动删掉 2 行**
3. 按 `\s`

**验收**：只有剩下的 3 行被同步回文件。这是排除部分匹配的方法。

## 9. 踩坑

### `\r` 按了没反应

`\` 是 `localleader`。确认你的配置里是 `vim.g.maplocalleader = "\\"`（一个反斜杠）。用 `:lua print(vim.g.maplocalleader)` 检查。

### 替换了自己不想改的地方

最常见的三个原因：

1. **Files Filter 没设**——把所有文件都搜了。
2. **没有先看匹配数**——直接按 `\r`。
3. **正则写太宽**——`WS-ACCT` 会匹配到 `WS-ACCT-OLD` 里的部分。

**对策**：永远先看 `N matches in M files`。数字不对就改过滤条件。

### 改了注释

`VALUE "A"` 这种模式在注释里也会出现。用 `git diff` 检查，或用正则锚定行首：

```text
Search:        ^(?!      \*).*VALUE "A"
```

（`^(?!      \*)` 排除第 7 列是 `*` 的注释行。）

### `\s` 之后文件乱了

`\s` 同步的是**结果区当前文本**。如果你在结果区误编辑了，`\s` 会把这些编辑一起写回。用 `u` 撤销，或者 `git checkout` 恢复。

### 跨行替换不生效

默认 ripgrep 不跨行。需要跨行时在 Flags 里加：

```text
--multiline
```

## 10. 与其它插件的关系

| 需求 | 工具 |
|---|---|
| 只找，不改 | `<leader>fg`（snacks picker） |
| 只改当前文件少量 | `:%s/old/new/g` |
| **跨文件批量改** | `<leader>sr`（grug-far） |
| 同一文件多行同时改 | 多光标（[教程 08](08-multicursor-batch-editing.md)） |
| 查看改了哪些 | `<leader>gd`（diffview）、`git diff` |

**选择逻辑**：改一处用常规命令；改同一文件的相邻几行用多光标；改跨文件的同一模式用 grug-far。

## 11. 官方文档

```vim
:h grug-far
:h grug-far-config
```

仓库：<https://github.com/MagicDuck/grug-far.nvim>

打开内置帮助（含完整按键表）：

```text
<leader>sr 然后按 g?
```

## 12. 边界

- 本篇按键来自你的本地配置（`lua/plugins/grug-far.lua`）：`<leader>sr`、`:GrugFar`、`:GrugFarWithin`。
- `<leader>sr` 会自动预填当前文件扩展名到 Files Filter，这是你的配置加的便捷行为，不是插件默认。
- 界面布局和键位（`\r`、`\s`、`\l`、`\n`、`\p`、`\v`、`g?`）来自插件默认键位表，已在本机核对。
- 实测记录只覆盖「打开界面、实时搜索、显示匹配数与位置」；**具体的替换执行步骤建议在副本上先练**（练习 3），因为你操作的可能是生产课程文件。
- 替换前务必确认工作区干净，替换后立即 `git diff` 检查。
