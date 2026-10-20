# 按键发现：which-key.nvim

你配了 48 个插件、几百个按键。**记不全，也不需要记全。**

which-key 的作用：按 `<leader>` 后停一下，弹出「接下来可以按什么」。所有按键按组分类显示，带描述。

---

## 1. 它解决什么问题

| 需求 | 没有 which-key | 有 which-key |
|---|---|---|
| 忘了某个键 | 翻配置或文档 | 按前缀看列表 |
| 不知道有哪些功能 | 读全部配置 | 逐层展开 |
| 学新插件的键 | 查 README | 按键看提示 |

**它是这个配置里最值得先掌握的插件**——因为其它所有插件的键都靠它被发现。

## 2. 你的配置

`lua/plugins/which-key.lua`：

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

| 参数 | 值 | 含义 |
|---|---|---|
| `preset` | `helix` | 使用 Helix 风格布局 |
| `show_keys` | `false` | 不显示按键列（只显示描述） |
| `border` | `single` | 单线边框 |
| `breadcrumb` | `»` | 层级分隔符 |
| `Space` | `SPC ` | 空格键显示为 `SPC` |

## 3. 分组一览

配置定义了 15 个组：

| 前缀 | 组名 | 内容 |
|---|---|---|
| `<leader>` | Leader | 顶层 |
| `<leader><tab>` | tabs | 标签页 |
| `<leader>b` | buffer | 缓冲区（动态展开） |
| `<leader>c` | code | 代码动作、重命名、格式化 |
| `<leader>d` | debug | 调试 |
| `<leader>dp` | profiler | 性能分析 |
| `<leader>f` | file/find | 文件与搜索 |
| `<leader>g` | git | Git 操作 |
| `<leader>gh` | hunks | Git 行级操作 |
| `<leader>q` | quit/session | 退出与会话 |
| `<leader>m` | bookmarks | 书签 |
| `<leader>s` | search | 搜索 |
| `<leader>u` | ui | 界面切换 |
| `<leader>w` | windows | 窗口（代理 `<C-w>`） |
| `<leader>x` | diagnostics/quickfix | 诊断与 quickfix |

还有几个非 leader 前缀：

| 前缀 | 组名 |
|---|---|
| `g` | goto |
| `gs` | surround |
| `z` | fold |
| `<c-w>` | windows |

### 两个特殊组会动态展开

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

`<leader>b` 会**列出当前所有打开的缓冲区**（不只是静态描述）。
`<leader>w` 会**代理 `<C-w>` 的子命令**——所以 `w` 组的操作和 `<C-w>` 完全一致。

## 4. 使用方式

### 基本

1. 按 `<leader>`（空格）
2. **停一下**（约 1 秒，或配置的 `delay`）
3. 弹出列表
4. 按对应字母

### 逐层深入

```text
<leader>     → 看到所有组
<leader>g    → 看到 git 下的所有键
<leader>gh   → 看到 hunks 下的所有键
<leader>ghs  → 执行「暂存 hunk」
```

### 忘了按键怎么办

```text
<leader>?    打开帮助搜索
:WhichKey   手动触发
```

### 只看某个前缀

```vim
:WhichKey <leader>f
```

直接列出 `<leader>f` 下的所有键，不用先按键。

## 5. 学习路径

配置作者在 `docs/plugins/PLUGINS.md` 里给了推荐顺序，这里改成按键视角：

### 第一步：入口（`<leader>f`）

```text
<leader>ff     找文件
<leader>fg     搜内容
<leader>fe     文件树
<leader>fb     缓冲区
```

这四个覆盖 80% 的日常操作。

### 第二步：编辑（`g` 和 `gs`）

```text
g7 g8 g12 g73    COBOL 列跳转
gsa gsd gsr      加/删/换包围符号
gcc             注释
```

### 第三步：Git（`<leader>g`）

```text
<leader>gd      差异视图
<leader>gs      暂存 hunk
<leader>gb      blame
```

### 第四步：代码（`<leader>c`）

```text
<leader>ca      代码动作
<leader>cr      重命名
<leader>cl      LSP 状态
```

## 6. 练习

### 练习 1：探索顶层

1. 按 `<leader>`（空格）
2. 停 1 秒
3. 观察弹出的组列表

**验收**：能看到 15 个组名（file/find、git、code 等）。

### 练习 2：逐层深入

1. `<leader>` → 停 → 看列表
2. 按 `g`
3. 停 → 看到 git 组的键
4. 按 `h`
5. 停 → 看到 hunks 组

**验收**：能连续三层深入而不执行任何命令（只观察）。

### 练习 3：动态展开缓冲区

1. 打开 3 个文件
2. `<leader>b`，停
3. 观察列出的缓冲区

**验收**：列表里有你打开的 3 个文件，带文件名。

### 练习 4：查询命令

```vim
:WhichKey <leader>f
```

**验收**：直接列出 `<leader>f` 组的所有键，不需要按键。

### 练习 5：用 which-key 学一个新插件

1. 从 [教程目录](../README.md) 挑一个你没用过的插件
2. 用 which-key 找出它的键
3. 实际执行一次

**验收**：能不看文档就找到并执行一个陌生功能的键。

## 7. 踩坑

### 按 `<leader>` 没有弹出

which-key 是 `event = "VeryLazy"` 加载的，启动后需要一点时间才生效。等一两秒再试。

### 弹出太快或太慢

默认延迟约 1000ms。配置里没改这个值；想改的话加 `delay` 选项。

### `show_keys = false` 看不到键名

配置关掉了按键列，只看得到描述。想知道具体键：

```vim
:WhichKey <leader>f
```

输出里会带键名。

### 列表太长看不清

用 `<C-f>` / `<C-b>` 翻页（取决于 which-key 版本），或者直接用 `:WhichKey` 查询特定前缀。

### 某个键没出现在列表里

可能是：
1. 该键由插件动态注册，which-key 没捕获；
2. 该键被更高优先级的映射覆盖；
3. 该功能的 server 不支持（LSP 的键按能力注册）。

用 `:verbose nmap 键` 查真实来源。

## 8. 与其它插件的关系

which-key 是**元插件**——它不提供功能，只帮你发现其它插件的功能。

| 想知道 | 用什么 |
|---|---|
| 有哪些键 | which-key（`<leader>` + 停顿） |
| 这个键绑了什么 | `:verbose nmap 键` |
| 某功能怎么用 | `<leader>?` 搜帮助 |
| 完整文档 | 各篇教程 + `:help` |

## 9. 官方文档

```vim
:h which-key
:h which-key-configuration
```

仓库：<https://github.com/folke/which-key.nvim>

## 10. 边界

- 本篇配置来自 `lua/plugins/which-key.lua`：`preset = "helix"`，`show_keys = false`，15 个静态组。
- `<leader>b`（缓冲区）和 `<leader>w`（窗口）是**动态展开**的，内容随当前状态变化。
- `<leader>w` 用了 `proxy = "<c-w>"`，所以它的子命令与 `<c-w>` 完全等价。
- which-key 只显示**已注册**的映射。插件按能力动态注册的键（如 LSP）在缺少对应 server 时不会出现。
