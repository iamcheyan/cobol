# Startup Page: dashboard-nvim

When you start `nvim` without arguments, you get a blank `[No Name]` buffer by default. You still have to find a file yourself.

dashboard-nvim replaces it with a startup page showing recent files and shortcuts, so you can start working with a single keystroke.

---

## 1. What Problem It Solves

| Need | Blank startup | With dashboard |
|---|---|---|
| Open a recent file | Type a path with `:b` or `:e` | Choose from a list |
| Decide where to start | Figure it out yourself | See shortcut hints |
| See what you worked on recently | No indication | MRU list |

## 2. Your Configuration

`lua/plugins/dashboard.lua`:

| Option | Value | Meaning |
|---|---|---|
| `theme` | `hyper` | Hyper theme |
| `change_to_vcs_root` | `false` | Do not automatically switch to the Git root |
| `header` | ASCII art `NVIM` | Large text at the top |
| `project.enable` | `false` | Do not show a project list |
| `mru.enable` | `true` | Show recent files |
| `mru.limit` | `10` | Show at most 10 files |
| `mru.cwd_only` | `false` | Do not limit files to the current directory |

### Key Detail: Load Timing

```lua
-- dashboard-nvim installs its startup hook on UIEnter. Load it before
-- that event so a no-argument launch never leaves the initial [No Name]
-- buffer on screen.
lazy = false,
```

`lazy = false` is required: dashboard installs its hook on `UIEnter`, and if it loads late, the blank buffer flashes first.

### The Snacks Dashboard Is Disabled

```lua
{
  "folke/snacks.nvim",
  opts = {
    dashboard = { enabled = false },
  },
}
```

Both plugins can provide a startup page. This configuration **chooses dashboard-nvim** and disables the snacks dashboard.

## 3. Shortcuts

Press a single letter on the startup page:

| Key | Action |
|---|---|
| `n` | Create a file |
| `o` | Open a folder |
| `f` | Find files (Snacks picker) |
| `s` | Search text (Snacks picker) |
| `l` | Open Lazy (plugin manager) |

### Recent Files

`mru` shows the 10 most recent files, **regardless of the current directory**. Move the cursor to an entry and press Enter to open it.

### How It Relates to Sessions

If `auto-session` finds a session for the project at startup, **it restores that session first**. The dashboard appears only when there is no session to restore.

So if you worked in this directory yesterday, `nvim` will probably restore yesterday's layout, and you will not see the startup page.

To open the startup page:

```vim
:Dashboard
```

## 4. Exercises

### Exercise 1: See the Startup Page

```sh
cd ~/development/cobol
nvim
```

**Check**: The startup page appears with large `NVIM` text and shortcuts.

**If you see yesterday's files instead**: auto-session restored a session. Try a directory without a session, or run `:Dashboard`.

### Exercise 2: Find a File with a Shortcut

1. Press `f` on the startup page.
2. Observe the result.

**Check**: The Snacks file picker opens.

### Exercise 3: Open a Recent File

1. On the startup page, move to a recent file with `j` / `k`.
2. Press Enter.

**Check**: The file opens.

### Exercise 4: Confirm the Snacks Dashboard Is Disabled

1. Check the configuration.

```vim
:lua =require("snacks").config.dashboard
```

**Check**: `enabled = false` (set by your configuration).

### Exercise 5: Open the Startup Page Manually

1. Open any file.
2. Run `:Dashboard`.

**Check**: The startup page appears over the current view without closing the file. Use `:q` or switch buffers to return.

## 5. Troubleshooting

### The Dashboard Does Not Appear at Startup

There are two possibilities:

1. **auto-session restored a session** — the session is restored first, so the startup page is not shown.
2. Neovim was started with an argument (such as `nvim file.cob`) — the startup page is not shown.

Open it manually with `:Dashboard`, or change to a directory without a session.

### A Blank Buffer Flashes at Startup

`lazy = false` prevents this. If the flash continues, check whether another plugin takes over the buffer before `UIEnter`.

### The Project List Is Missing

The configuration has `project.enable = false`. It is deliberately disabled (the setup uses MRU and shortcuts instead).

### The Recent File List Is Empty

This can happen on first use or after clearing `vim.v.oldfiles`. Use Neovim for a while and the list will fill up.

### What `change_to_vcs_root = false` Means

Neovim does not automatically switch to the Git root. If you start it from `~/development/cobol/lessons/17_xxx/`, that directory remains the cwd; it will not jump to the repository root. To search the whole repository, use `<leader>fF` (Git root search) instead of `ff`.

### The `f` / `s` Shortcuts Do Nothing

They call `Snacks.picker`. If snacks is not loaded, they will fail. Check the snacks status with `:Lazy`.

## 6. How It Relates to Other Plugins

| Scenario | Handled by |
|---|---|
| Startup page | dashboard-nvim (snacks dashboard is disabled) |
| Session restoration | auto-session (**takes priority over** dashboard) |
| File search | snacks picker (called by dashboard's `f` shortcut) |
| Create a file | `config.file_actions.new_file()` |

**Remember the priority**: auto-session restores a session first; the dashboard appears only when there is no session.

## 7. Official Documentation

```vim
:h dashboard-nvim
```

Repository: <https://github.com/nvimdev/dashboard-nvim>

## 8. Scope

- This page describes `lua/plugins/dashboard.lua`: `theme = "hyper"`, an MRU limit of 10, project list disabled, and `lazy = false`.
- **The snacks dashboard is disabled** (`snacks.dashboard.enabled = false`); dashboard-nvim is the only startup page in use.
- **auto-session takes priority over dashboard**: with a session, the startup page does not appear.
- `change_to_vcs_root = false` means startup does not automatically switch to the Git root.
