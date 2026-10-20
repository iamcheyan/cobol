# Discovering Keybindings: which-key.nvim

You have 48 plugins and hundreds of keybindings configured. **You cannot remember them all, and you do not need to.**

which-key's job is to pause after you press `<leader>` and show you “what you can press next.” Keybindings are organized into groups and displayed with descriptions.

---

## 1. What Problem It Solves

| Need | Without which-key | With which-key |
|---|---|---|
| Forgot a key | Search the configuration or documentation | View the list for a prefix |
| Do not know what features are available | Read the entire configuration | Explore a level at a time |
| Learn the keys for a new plugin | Look up its README | Press keys and see hints |

**This is the plugin in this configuration that is most worth learning first**—because it helps you discover the keys for every other plugin.

## 2. Your Configuration

`lua/plugins/which-key.lua`:

```lua
opts = {
  preset = "helix",
  show_keys = false,
  win = {
    border = "single",
    title = false,
  },
  icons = {
    breadcrumb = "»",
    group = "",
    keys = {
      Space = "SPC ",
    },
  },
},
```

| Option | Value | Meaning |
|---|---|---|
| `preset` | `helix` | Use a Helix-style layout |
| `show_keys` | `false` | Hide the key column (show descriptions only) |
| `border` | `single` | Single-line border |
| `breadcrumb` | `»` | Hierarchy separator |
| `Space` | `SPC ` | Display the Space key as `SPC` |

## 3. Groups at a Glance

The configuration defines 15 groups:

| Prefix | Group name | Contents |
|---|---|---|
| `<leader>` | Leader | Top level |
| `<leader><tab>` | tabs | Tabs |
| `<leader>b` | buffer | Buffers (expanded dynamically) |
| `<leader>c` | code | Code actions, rename, formatting |
| `<leader>d` | debug | Debugging |
| `<leader>dp` | profiler | Profiling |
| `<leader>f` | file/find | Files and search |
| `<leader>g` | git | Git operations |
| `<leader>gh` | hunks | Git line-level operations |
| `<leader>q` | quit/session | Quit and sessions |
| `<leader>m` | bookmarks | Bookmarks |
| `<leader>s` | search | Search |
| `<leader>u` | ui | UI toggles |
| `<leader>w` | windows | Windows (proxy for `<C-w>`) |
| `<leader>x` | diagnostics/quickfix | Diagnostics and quickfix |

There are also several non-leader prefixes:

| Prefix | Group name |
|---|---|
| `g` | goto |
| `gs` | surround |
| `z` | fold |
| `<c-w>` | windows |

### Two Special Groups Expand Dynamically

```lua
{
  "<leader>b",
  group = "buffer",
  expand = function()
    return require("which-key.extras").expand.buf()
  end,
},
{
  "<leader>w",
  group = "windows",
  proxy = "<c-w>",
  expand = function()
    return require("which-key.extras").expand.win()
  end,
},
```

`<leader>b` **lists all currently open buffers** (not just static descriptions).
`<leader>w` **proxies the `<C-w>` subcommands**—so the operations in the `w` group are exactly the same as `<C-w>`.

## 4. How to Use It

### The Basics

1. Press `<leader>` (Space)
2. **Pause** (about 1 second, or the configured `delay`)
3. The list appears
4. Press the corresponding letter

### Explore One Level at a Time

```text
<leader>     → 看到所有组
<leader>g    → 看到 git 下的所有键
<leader>gh   → 看到 hunks 下的所有键
<leader>ghs  → 执行「暂存 hunk」
```

### What to Do When You Forget a Key

```text
<leader>?    打开帮助搜索
:WhichKey   手动触发
```

### View Only One Prefix

```vim
:WhichKey <leader>f
```

This directly lists all keys under `<leader>f`, without needing to press the keys first.

## 5. Learning Path

The configuration author recommends an order in `docs/plugins/PLUGINS.md`. Here it is organized around keybindings:

### Step 1: Entry Points (`<leader>f`)

```text
<leader>ff     找文件
<leader>fg     搜内容
<leader>fe     文件树
<leader>fb     缓冲区
```

These four cover 80% of everyday operations.

### Step 2: Editing (`g` and `gs`)

```text
g7 g8 g12 g73    COBOL 列跳转
gsa gsd gsr      加/删/换包围符号
gcc             注释
```

### Step 3: Git (`<leader>g`)

```text
<leader>gd      差异视图
<leader>gs      暂存 hunk
<leader>gb      blame
```

### Step 4: Code (`<leader>c`)

```text
<leader>ca      代码动作
<leader>cr      重命名
<leader>cl      LSP 状态
```

## 6. Exercises

### Exercise 1: Explore the Top Level

1. Press `<leader>` (Space)
2. Pause for 1 second
3. Observe the group list

**Check**: You can see 15 group names (file/find, git, code, and others).

### Exercise 2: Explore Deeper

1. `<leader>` → pause → view the list
2. Press `g`
3. Pause → view the keys in the git group
4. Press `h`
5. Pause → view the hunks group

**Check**: You can explore three levels without executing any commands (just observe).

### Exercise 3: Dynamically Expand Buffers

1. Open 3 files
2. Press `<leader>b`, then pause
3. Observe the listed buffers

**Check**: The list includes the 3 files you opened, with their filenames.

### Exercise 4: Look Up a Command

```vim
:WhichKey <leader>f
```

**Check**: It directly lists all keys in the `<leader>f` group, without pressing them.

### Exercise 5: Use which-key to Learn a New Plugin

1. Pick a plugin you have not used from the [tutorial index](../README.md)
2. Use which-key to find its keys
3. Run one of them

**Check**: You can find and run a key for an unfamiliar feature without reading the documentation.

## 7. Common Pitfalls

### Nothing Appears After Pressing `<leader>`

which-key is loaded with `event = "VeryLazy"`, so it takes a little time to become active after startup. Wait a second or two and try again.

### The Popup Appears Too Quickly or Too Slowly

The default delay is about 1000ms. This configuration does not change that value; to adjust it, add a `delay` option.

### `show_keys = false` Hides the Key Names

The configuration hides the key column, so you only see descriptions. To find the exact keys:

```vim
:WhichKey <leader>f
```

The output includes the key names.

### The List Is Too Long to Read

Use `<C-f>` / `<C-b>` to page through it (depending on the which-key version), or query a specific prefix with `:WhichKey`.

### A Key Does Not Appear in the List

Possible reasons:
1. The key is registered dynamically by a plugin, and which-key did not capture it;
2. The mapping was overridden by one with higher priority;
3. The feature's server does not support it (LSP keys are registered according to capabilities).

Use `:verbose nmap key` to find the actual source.

## 8. How It Relates to Other Plugins

which-key is a **meta-plugin**—it does not provide features itself; it helps you discover features in other plugins.

| What you want to know | Use |
|---|---|
| What keys are available | which-key (`<leader>` + pause) |
| What a key is mapped to | `:verbose nmap key` |
| How to use a feature | Search help with `<leader>?` |
| Full documentation | Individual tutorials + `:help` |

## 9. Official Documentation

```vim
:h which-key
:h which-key-configuration
```

Repository: <https://github.com/folke/which-key.nvim>

## 10. Scope

- The configuration in this tutorial comes from `lua/plugins/which-key.lua`: `preset = "helix"`, `show_keys = false`, and 15 static groups.
- `<leader>b` (buffers) and `<leader>w` (windows) **expand dynamically**; their contents change with the current state.
- `<leader>w` uses `proxy = "<c-w>"`, so its subcommands are exactly equivalent to `<c-w>`.
- which-key only shows **registered** mappings. Keys registered dynamically according to plugin capabilities (such as LSP) will not appear if the corresponding server is unavailable.
