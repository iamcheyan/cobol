# 启动页：dashboard-nvim

不带参数启动 `nvim`，默认是一个空白 `[No Name]` 缓冲区。你还得自己找文件。

dashboard-nvim 把它换成启动页：显示最近文件、快捷入口，按一个键就能开始工作。

---

## 1. 它解决什么问题

| 需求 | 空白启动 | 有 dashboard |
|---|---|---|
| 打开最近的文件 | `:b` 或 `:e` 手打路径 | 列表里选 |
| 从哪开始 | 自己想 | 快捷入口提示 |
| 看最近在做什么 | 没有提示 | MRU 列表 |

## 2. 你的配置

`lua/plugins/dashboard.lua`：

| 选项 | 值 | 含义 |
|---|---|---|
| `theme` | `hyper` | Hyper 主题 |
| `change_to_vcs_root` | `false` | 不自动切到 Git 根目录 |
| `header` | ASCII art `NVIM` | 顶部大字 |
| `project.enable` | `false` | 不显示项目列表 |
| `mru.enable` | `true` | 显示最近文件 |
| `mru.limit` | `10` | 最多 10 个 |
| `mru.cwd_only` | `false` | 不限于当前目录 |

### 关键：加载时机

```lua
-- dashboard-nvim installs its startup hook on UIEnter. Load it before
-- that event so a no-argument launch never leaves the initial [No Name]
-- buffer on screen.
lazy = false,
```

`lazy = false` 是必须的——dashboard 在 `UIEnter` 装钩子，晚加载就会先闪一下空白缓冲区。

### Snacks 的 dashboard 被关掉了

```lua
{
  "folke/snacks.nvim",
  opts = {
    dashboard = { enabled = false },
  },
}
```

两个插件都能做启动页，你的配置**选了 dashboard-nvim**，把 snacks 的关掉了。

## 3. 快捷键

启动页上按单字母即可：

| 键 | 作用 |
|---|---|
| `n` | 新建文件 |
| `o` | 打开文件夹 |
| `f` | 找文件（Snacks picker） |
| `s` | 搜文本（Snacks picker） |
| `l` | 打开 Lazy（插件管理） |

### 最近文件列表

`mru` 显示最近 10 个文件，**不限于当前目录**。光标移到条目上回车即打开。

### 与会话的关系

启动时若 `auto-session` 找到该项目的会话，**会先恢复会话**；没有可恢复会话时才显示 dashboard。

所以如果你昨天在这个目录工作过，今天 `nvim` 大概率直接回到昨天的布局，看不到启动页。

想看启动页：

```vim
:Dashboard
```

## 4. 练习

### 练习 1：看到启动页

```sh
cd ~/development/cobol
nvim
```

**验收**：出现启动页，有 `NVIM` 大字和快捷入口。

**如果看到的是昨天的文件**：说明 auto-session 恢复了会话。换一个没有会话的目录试，或 `:Dashboard`。

### 练习 2：用快捷键找文件

1. 在启动页按 `f`
2. 观察

**验收**：打开 Snacks 的文件搜索器。

### 练习 3：打开最近文件

1. 在启动页用 `j` / `k` 移到某个最近文件
2. 回车

**验收**：打开该文件。

### 练习 4：确认 snacks dashboard 已关

1. 检查配置

```vim
:lua =require("snacks").config.dashboard
```

**验收**：`enabled = false`（由你的配置设置）。

### 练习 5：手动打开启动页

1. 打开任意文件
2. `:Dashboard`

**验收**：启动页出现（覆盖当前视图，但没关闭文件）。用 `:q` 或切缓冲区回去。

## 5. 踩坑

### 启动没看到 dashboard

两种可能：

1. **auto-session 恢复了会话**——先恢复，看不到启动页。
2. 带参数启动（如 `nvim file.cob`）——不会显示启动页。

用 `:Dashboard` 手动打开，或 `cd` 到一个没会话的目录。

### 启动闪一下空白

`lazy = false` 就是防这个的。如果仍闪，检查是否有其它插件在 `UIEnter` 之前抢了缓冲区。

### 项目列表不见了

配置 `project.enable = false`。这是你的配置主动关的（改用 MRU + 快捷入口）。

### 最近文件列表是空的

第一次用或清过 `vim.v.oldfiles`。用几次就有内容了。

### `change_to_vcs_root = false` 意味着什么

不自动切到 Git 根。你在 `~/development/cobol/lessons/17_xxx/` 启动，cwd 就是那个目录，不会跳到仓库根。想搜全仓库要用 `<leader>fF`（Git 根搜索）而非 `ff`。

### 按键 `f` / `s` 没反应

它们调用 `Snacks.picker`。如果 snacks 没加载，会失败。`:Lazy` 看 snacks 状态。

## 6. 与其它插件的关系

| 场景 | 谁负责 |
|---|---|
| 启动页 | dashboard-nvim（snacks 的已关） |
| 会话恢复 | auto-session（**优先于** dashboard） |
| 文件搜索 | snacks picker（dashboard 的 `f` 调用它） |
| 新建文件 | `config.file_actions.new_file()` |

**理解优先级**：auto-session 先恢复会话 → 没有会话才显示 dashboard。

## 7. 官方文档

```vim
:h dashboard-nvim
```

仓库：<https://github.com/nvimdev/dashboard-nvim>

## 8. 边界

- 本篇配置来自 `lua/plugins/dashboard.lua`：`theme = "hyper"`、MRU 上限 10、项目列表关闭、`lazy = false`。
- **snacks 的 dashboard 被关掉了**（`snacks.dashboard.enabled = false`），只用 dashboard-nvim。
- **auto-session 优先于 dashboard**：有会话时看不到启动页。
- `change_to_vcs_root = false`，启动时不自动切到 Git 根目录。
