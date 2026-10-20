# 英语词汇练习：VimQuest.nvim

这是你配置里唯一一个「不写代码」的插件：**它把你的代码库变成英语词汇测验**。

COBOL 和编程里的标识符、注释、错误信息大多是英语。VimQuest 从你的项目复制代码文件，把词汇题作为注释注入，让你在编辑器里练。

---

## 1. 它解决什么问题

| 需求 | 常规做法 | VimQuest |
|---|---|---|
| 学编程英语词汇 | 背单词表，脱离语境 | **在真实代码里练** |
| 练习不打断工作 | 切窗口去背单词 | 不离开 Neovim |
| 练完能记住 | 单词表容易忘 | 结合代码上下文 |

**它的定位是"学英语"，不是"写代码"。** 但既然你装了，值得知道怎么用。

## 2. 工作方式

```
1. 扫描项目，随机选代码文件
2. 复制到临时会话目录
3. 把词汇任务作为注释注入（填空、同义替换等）
4. 在任务下方加 Prev/Next 跳转和 Vim 操作提示
5. 你直接改答案行
6. 检查答案 → 开始新一轮或恢复原项目
```

**关键安全点**：它复制文件到临时目录，**不改动你的原文件**。做完 `:VimQuestStop` 恢复。

## 3. 题型

| 类型 | 内容 |
|---|---|
| **Fill** | 根据中文意思补全句子中缺的英文词 |
| **Replace** | 把同义词替换回核心词 |
| **Delete** | 删掉句子里多余的词 |
| **Meaning** | 根据中文释义写出英文词 |
| **Japanese Meaning** | 根据日文释义写出英文词 |
| **Example Translation** | 从日文例句猜词 |

## 4. 按键

配置里以 `cmd` 形式注册（不绑 `<leader>` 快捷键），所以**用命令调用**：

| 命令 | 作用 |
|---|---|
| `:VimQuestStart` | 开始新一轮 |
| `:VimQuestStop` | 停止并恢复原项目 |
| `:VimQuestNext` | 下一个任务 |
| `:VimQuestPrev` | 上一个任务 |
| `:VimQuestNextRound` | 在原项目里再来一轮 |
| `:VimQuestRestart` | 用新任务重开 |
| `:VimQuestTasks` | 搜索并跳到任意任务 |
| `:VimQuestList` | 所有任务进 quickfix |
| `:VimQuestCheck` | 检查整轮并显示报告 |
| `:VimQuestHint` | 显示当前任务的提示 |
| `:VimQuestStats` | 显示本轮统计 |
| `:VimQuestWords` | 打开连续单词输入练习 |

**注意**：插件 README 里写了默认 `<leader>qs` 等快捷键，但你的配置**只用 `cmd` 注册**，没绑键。所以用命令。

### 会话中的 `K`

在活动会话里按 `K` 显示提示；不在会话里 `K` 是 LSP hover。

## 5. 单词练习（`:VimQuestWords`）

底部弹出两行小窗：

```text
account
en: a record of money | ja: 口座 | zh: 账户
```

- 第一行显示要输入的词
- 第二行是英文、日文、中文
- 输入正确后记录到 `stdpath("data")/vimquest/words_seen.json`
- 练过的词用 `Comment` 高亮，但仍在随机池里
- 输入 `/exit` 关闭
- 右键拖动可移动窗口（位置在当前会话内记住）

## 6. 配置

```lua
require("vimquest").setup({
  task_count = 10,          -- 每轮任务数
  copy_file_count = 10,     -- 复制的文件数
  wordlist = "lua/vimquest/data/ogden-850-words.json",
  exclude_dirs = {
    [".git"] = true,
    ["node_modules"] = true,
  },
  code_extensions = { ... },
})
```

| 选项 | 值 | 含义 |
|---|---|---|
| `task_count` | 10 | 每轮 10 道题 |
| `copy_file_count` | 10 | 复制 10 个文件 |
| `wordlist` | Ogden 850 词 | 基础词汇表 |

词表用的是 **Ogden Basic English 850 词**——英语最核心的 850 个词。

## 7. 练习

### 练习 1：开始一轮

```sh
cd ~/development/cobol
nvim
```

1. `:VimQuestStart`
2. 等待复制和注入完成

**验收**：进入练习会话，代码里有注释形式的题目。

### 练习 2：答题与检查

1. 光标移到某个任务
2. 按提示在答案行输入
3. `:VimQuestCheck`

**验收**：显示整轮结果报告（对了几题）。

### 练习 3：跳转任务

1. `:VimQuestNext`
2. `:VimQuestPrev`

**验收**：在任务间移动。

### 练习 4：看提示

1. 光标在任务上
2. `:VimQuestHint`

**验收**：显示该任务的提示。

### 练习 5：单词练习

1. `:VimQuestWords`
2. 输入显示的词，回车
3. 输入 `/exit` 退出

**验收**：单词被验证，底部小窗关闭。

### 练习 6：恢复原项目（重要）

1. `:VimQuestStop`

**验收**：回到你原来的项目文件，**没有留下任何练习痕迹**。

## 8. 踩坑

### 命令不存在

插件以 `cmd` 形式注册，`VeryLazy` 加载。刚启动时可能还没加载：

```vim
:Lazy
```

看 VimQuest 状态。或等几秒再试。

### 没有 `<leader>qs` 快捷键

你的配置**只注册了命令，没绑键**（`cmd = {...}`，没有 `keys`）。用 `:VimQuestStart` 这类命令。

### 练完找不到自己的文件了

`:VimQuestStop` 会恢复。如果忘了，检查：

```vim
:pwd
```

看当前目录是不是临时目录。

### 词都太简单/太难

词表是 Ogden 850（基础词）。想换要改 `wordlist` 配置。

### 和 COBOL 代码混在一起看不懂

题目是**注释形式注入**的，原代码保留。COBOL 注释在第 7 列 `*`，所以题目会作为注释出现——不影响代码。

### 统计文件在哪

```vim
:echo stdpath("data") .. "/vimquest/words_seen.json"
```

## 9. 官方仓库

<https://github.com/iamcheyan/VimQuest>

（你自己开发的插件。）

## 10. 边界

- 本篇配置来自 `lua/plugins/vimquest.lua`：**只注册命令，不绑 `<leader>` 快捷键**。（README 里的默认键在你的配置里不存在。）
- 它在临时目录工作，**不改动原项目**；`:VimQuestStop` 恢复。
- 词表是 Ogden 850 基础英语词。
- 这是"学英语"工具，不影响 COBOL 开发工作流；不练也不会有任何功能缺失。
