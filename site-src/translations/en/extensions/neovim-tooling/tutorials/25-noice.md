# Messages and Command Line, Restyled: noice.nvim

By default, Neovim squeezes messages, the command line, and confirmation prompts into the same line at the bottom: **`-- INSERT --`, error messages, `:` commands, and confirmation prompts all compete for space**, and other plugins' floating windows often cover them.

noice.nvim separates them, improves their appearance, and places them where they belong.

---

## 1. What Problem It Solves

| Need | Default Neovim | noice |
|---|---|---|
| See the command line | One line at the bottom, covered by floating windows | A dedicated command-line view |
| Confirmation prompt (`:q` with unsaved changes) | One line at the bottom, easy to miss | Centered floating window with a border |
| See what was yanked | Briefly at the bottom | Separate view at the bottom, shown for 2.2 seconds |
| See errors | One line at the bottom, possibly covered | Routed by category |

## 2. Your Configuration

`lua/plugins/noice.lua`; the comments at the top explain the intent:

```lua
-- Keep Ex command entry at the bottom, but render Neovim's blocking confirm
-- prompts (for example :q with unsaved changes) in Noice's centered popup.
```

### Command Line

| Option | Value | Meaning |
|---|---|---|
| `cmdline.enabled` | `true` | Take over the command line |
| `view` | `cmdline` | Use the bottom view |
| `format.cmdline.icon` | `false` | Keep the native `:` prompt |
| `format.input.view` | `cmdline` | Place input prompts at the bottom too |

**The native `:` prompt is kept instead of noice's default `>` icon** deliberately, so it remains familiar when you are getting started.

### Messages

```lua
messages = {
  enabled = true,
  view = "cmdline",
  view_error = "cmdline",
  view_warn = "cmdline",
  view_search = "cmdline",
  view_history = "messages",
}
```

Regular messages, errors, warnings, and search messages use the bottom command-line view. `view_history` uses messages, which can be browsed with `:messages`.

### Yank Confirmation

```lua
routes = {
  {
    filter = { event = "msg_show", find = "yanked into" },
    view = "yank",
    opts = { stop = true },
  },
},
views = {
  yank = {
    backend = "popup",
    position = { row = "100%", col = 0 },
    size = { height = "auto", width = "100%" },
    timeout = 2200,
  },
},
```

After yanking, a **bar appears across the bottom** for 2.2 seconds. The configuration comments explain:

```lua
-- Keep yank confirmations in their own bottom view. They can stack while
-- copying, then the whole message group hides after the last yank.
```

Repeated yanks stack up, and the whole group disappears after the last one.

### Confirmation Prompts

```lua
confirm = {
  position = { row = "50%", col = "50%" },
  size = { max_width = 64 },
  border = { style = "rounded", padding = { 1, 2 }, text = { top = " Confirm " } },
}
```

When `:q` encounters unsaved changes, a **centered floating window with rounded corners** appears, titled `Confirm`.

### Features Explicitly Disabled

```lua
popupmenu = { enabled = false },
notify = { enabled = false },
lsp = {
  progress = { enabled = false },
  message = { enabled = false },
  hover = { enabled = false },
  signature = { enabled = false },
},
```

| Disabled feature | Reason |
|---|---|
| `popupmenu` | Completion menus are handled by blink.cmp |
| `notify` | Notifications are handled by snacks |
| `lsp.`* | Keep native behavior for LSP hover, signature, and progress |

**So in this setup, noice handles just three things**: the command line, yank notifications, and confirmation prompts.

## 3. Usage

### Confirmation Prompt

1. Modify a file without saving it.
2. Run `:q`.
3. A centered floating window appears: `[Y]es [N]o [C]ancel`.

Press `y`, `n`, or `c` to choose.

### Yank Notification

1. Press `yy` to yank a line.
2. A bar appears at the bottom with the yanked text.
3. It disappears after 2.2 seconds.

Repeated `yy` commands stack up, and the group hides after the last one.

### Command Line

1. Press `:`.
2. The command line appears at the bottom with the native `:` prompt.

It feels close to the native experience, but floating windows will not cover it.

## 4. Exercises

### Exercise 1: Confirmation Prompt

```sh
cd ~/development/cobol
nvim
```

1. Open any file and change one character without saving.
2. Run `:q`.
3. Observe the floating window.

**Check**: A centered floating window with rounded corners, the title `Confirm`, and three choices.

### Exercise 2: Yank Notification

1. Press `yy`.
2. Observe the bottom of the screen.

**Check**: A bar appears with the yanked text and disappears after about 2.2 seconds.

### Exercise 3: Stack Repeated Yanks

1. Quickly press `yy` five times.
2. Observe the notification.

**Check**: Notifications stack (multiple messages are shown), then the group disappears after the last one.

### Exercise 4: Command Line

1. Press `:`.
2. Type `echo "test"` and press Enter.

**Check**: The command line is at the bottom with the native `:` prompt (not noice's default `>`).

### Exercise 5: Confirm Notifications Are Not Handled by noice

1. Trigger a notification (for example, `:lua vim.notify("hi")`).
2. Observe it.

**Check**: snacks displays the notification (because `notify.enabled = false`), not noice.

## 5. Troubleshooting

### The Command Line Is Missing

noice takes over the command line. If it is in an abnormal state, toggle it with `:NoiceEnable` / `:NoiceDisable`.

### The Confirmation Prompt Is Not Centered

The configuration sets `position = { row = "50%", col = "50%" }`. If the prompt is off-center, check whether another plugin (such as snacks) is also changing floating window positions.

### The Yank Notification Disappears Too Quickly

`timeout = 2200` (2.2 seconds). Increase it in the configuration to keep the notification visible longer.

### You Want noice to Handle LSP Hover

The configuration explicitly disables it:

```lua
lsp = {
  hover = { enabled = false },
  signature = { enabled = false },
},
```

LSP hover (`<leader>K`) keeps its native behavior. Change the configuration to use noice's styled version.

### Notifications Are Not Displayed by noice

`notify = { enabled = false }`, so snacks handles notifications. **This is intentional configuration**, not a bug.

### The Completion Menu Is Not Right

`popupmenu = { enabled = false }`, so blink.cmp provides the completion menu.

## 6. How It Works with Other Plugins

| UI element | Handled by |
|---|---|
| Command line | noice |
| Yank notification | noice |
| Confirmation prompt | noice |
| Notifications | **snacks** |
| LSP hover / signature | **native vim** |
| Completion menu | **blink.cmp** |

Understanding this division explains why some features in the noice documentation are not present in this setup.

## 7. Official Documentation

```vim
:h noice
:h noice-config
```

Repository: <https://github.com/folke/noice.nvim>

## 8. Scope

- This page describes `lua/plugins/noice.lua`. **Here noice handles only the command line, yank notifications, and confirmation prompts**.
- `notify`, `lsp.*`, and `popupmenu` are all disabled; they are handled by snacks, native vim, and blink.cmp, respectively.
- The command line keeps the native `:` prompt (not noice's default `>`).
- Yank notifications use `timeout = 2200` milliseconds and stack during repeated yanks.
