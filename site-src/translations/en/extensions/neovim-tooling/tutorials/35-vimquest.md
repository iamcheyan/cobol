# English Vocabulary Practice: VimQuest.nvim

This is the only plugin in your configuration that doesn't involve writing code: **it turns your codebase into an English vocabulary quiz**.

Identifiers, comments, and error messages in COBOL and programming are mostly in English. VimQuest copies code files from your project, injects vocabulary questions as comments, and lets you practice in the editor.

---

## 1. What Problem It Solves

| Need | Usual approach | VimQuest |
|---|---|---|
| Learn programming vocabulary | Memorize word lists out of context | **Practice with real code** |
| Practice without interrupting work | Switch windows to study words | Stay in Neovim |
| Remember what you practice | Easy to forget a word list | Use the code context |

**Its purpose is “learning English,” not “writing code.”** But since it's installed, it's useful to know how to use it.

## 2. How It Works

```
1. 扫描项目，随机选代码文件
2. 复制到临时会话目录
3. 把词汇任务作为注释注入（填空、同义替换等）
4. 在任务下方加 Prev/Next 跳转和 Vim 操作提示
5. 你直接改答案行
6. 检查答案 → 开始新一轮或恢复原项目
```

**Key safety point**: It copies files into a temporary directory and **doesn't modify your original files**. Run `:VimQuestStop` when you're done to restore the original project.

## 3. Question Types

| Type | Content |
|---|---|
| **Fill** | Complete a sentence with the missing English word based on its Chinese meaning |
| **Replace** | Replace a synonym with the core word |
| **Delete** | Remove an extra word from a sentence |
| **Meaning** | Write an English word based on its Chinese definition |
| **Japanese Meaning** | Write an English word based on its Japanese definition |
| **Example Translation** | Guess the word from a Japanese example sentence |

## 4. Commands

The configuration registers commands with `cmd` and doesn't bind `<leader>` shortcuts, so **invoke it with commands**:

| Command | Action |
|---|---|
| `:VimQuestStart` | Start a new round |
| `:VimQuestStop` | Stop and restore the original project |
| `:VimQuestNext` | Go to the next task |
| `:VimQuestPrev` | Go to the previous task |
| `:VimQuestNextRound` | Start another round in the original project |
| `:VimQuestRestart` | Restart with new tasks |
| `:VimQuestTasks` | Search for and jump to any task |
| `:VimQuestList` | Send all tasks to quickfix |
| `:VimQuestCheck` | Check the whole round and show a report |
| `:VimQuestHint` | Show a hint for the current task |
| `:VimQuestStats` | Show statistics for this round |
| `:VimQuestWords` | Open continuous word-entry practice |

**Note**: The plugin README lists default shortcuts such as `<leader>qs`, but your configuration **registers commands only** and doesn't bind keys. Use commands instead.

### `K` During a Session

Press `K` during an active session to show a hint; outside a session, `K` is LSP hover.

## 5. Word Practice (`:VimQuestWords`)

A small two-line window appears at the bottom:

```text
account
en: a record of money | ja: 口座 | zh: 账户
```

- The first line shows the word to enter
- The second line gives its English, Japanese, and Chinese meaning
- Correctly entered words are recorded in `stdpath("data")/vimquest/words_seen.json`
- Practiced words are highlighted with `Comment`, but remain in the random pool
- Enter `/exit` to close
- Drag with the right mouse button to move the window (its position is remembered for the current session)

## 6. Configuration

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

| Option | Value | Meaning |
|---|---|---|
| `task_count` | 10 | 10 questions per round |
| `copy_file_count` | 10 | Copy 10 files |
| `wordlist` | Ogden 850 words | Basic vocabulary list |

The word list uses the **Ogden Basic English 850 words**—the 850 core words of English.

## 7. Exercises

### Exercise 1: Start a Round

```sh
cd ~/development/cobol
nvim
```

1. Run `:VimQuestStart`
2. Wait for copying and injection to finish

**Check**: A practice session opens, with questions inserted into the code as comments.

### Exercise 2: Answer and Check

1. Move the cursor to a task
2. Enter an answer on the answer line as prompted
3. Run `:VimQuestCheck`

**Check**: A report shows the results for the whole round (including how many answers were correct).

### Exercise 3: Navigate Between Tasks

1. Run `:VimQuestNext`
2. Run `:VimQuestPrev`

**Check**: You can move between tasks.

### Exercise 4: View a Hint

1. Place the cursor on a task
2. Run `:VimQuestHint`

**Check**: A hint for that task appears.

### Exercise 5: Practice Words

1. Run `:VimQuestWords`
2. Enter the displayed word and press Enter
3. Enter `/exit` to quit

**Check**: The word is checked, and the small window at the bottom closes.

### Exercise 6: Restore the Original Project (Important)

1. Run `:VimQuestStop`

**Check**: You return to your original project files, **with no practice material left behind**.

## 8. Common Issues

### The Command Doesn't Exist

The plugin registers commands with `cmd` and loads at `VeryLazy`. It may not have loaded immediately after startup:

```vim
:Lazy
```

Check the VimQuest status, or wait a few seconds and try again.

### There Is No `<leader>qs` Shortcut

Your configuration **registers commands only and doesn't bind keys** (`cmd = {...}`, with no `keys`). Use commands such as `:VimQuestStart`.

### You Can't Find Your Files After Practicing

`:VimQuestStop` restores the original project. If you forget, check:

```vim
:pwd
```

See whether the current directory is a temporary directory.

### The Words Are Too Easy or Too Hard

The word list is Ogden 850 (basic words). Change the `wordlist` configuration to use another list.

### It's Hard to Read Mixed in with COBOL Code

Questions are injected **as comments**, and the original code is preserved. COBOL comments use `*` in column 7, so questions appear as comments and don't affect the code.

### Where Is the Statistics File?

```vim
:echo stdpath("data") .. "/vimquest/words_seen.json"
```

## 9. Official Repository

<https://github.com/iamcheyan/VimQuest>

(It's a plugin you develop.)

## 10. Boundaries

- This tutorial describes the configuration in `lua/plugins/vimquest.lua`: **it registers commands only, with no `<leader>` shortcuts**. (The default keys in the README aren't present in your configuration.)
- It works in a temporary directory and **doesn't modify the original project**; `:VimQuestStop` restores it.
- The word list is Ogden 850 Basic English.
- This is an English learning tool and doesn't affect the COBOL development workflow; no functionality is lost if you don't use it.
