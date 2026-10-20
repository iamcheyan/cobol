# 彩虹括号：rainbow-delimiters.nvim

嵌套的 `IF ... END-IF` 里再套 `EVALUATE`，光靠缩进很难看清哪层对哪层。

rainbow-delimiters 给**每一层括号/关键字不同的颜色**，嵌套关系一眼可见。

---

## 1. 它解决什么问题

| 需求 | 单色括号 | 彩虹括号 |
|---|---|---|
| 看清嵌套层级 | 数空格 | 颜色区分 |
| 找某层的结尾 | `%` 逐个试 | 同色即配对 |
| 判断括号是否匹配 | 靠 LSP 报错 | 颜色突变就能看出 |

## 2. 你的配置

`lua/plugins/rainbow-delimiters.lua`：

```lua
vim.g.rainbow_delimiters = {
  strategy = {
    [""] = rainbow.strategy["global"],
    vim = rainbow.strategy["local"],
  },
  query = {
    [""] = "rainbow-delimiters",
    lua = "rainbow-blocks",
  },
  highlight = {
    "RainbowDelimiterYellow",
    "RainbowDelimiterCyan",
    "RainbowDelimiterBlue",
    "RainbowDelimiterOrange",
    "RainbowDelimiterGreen",
    "RainbowDelimiterViolet",
    "RainbowDelimiterRed",
  },
}
```

| 选项 | 含义 |
|---|---|
| `strategy[""]` | `global`：全 buffer 统一计算层级 |
| `strategy.vim` | vim 文件用 `local`（按局部作用域） |
| `query[""]` | 默认用 `rainbow-delimiters` 查询 |
| `query.lua` | Lua 用 `rainbow-blocks`（按块而非括号） |
| `highlight` | 7 种颜色循环 |

### 7 色循环

```
Yellow → Cyan → Blue → Orange → Green → Violet → Red → (回到 Yellow)
```

第 8 层和第 1 层同色——但深度到 8 层的嵌套本身就该重构了。

## 3. COBOL 里的实际情况

**重要**：rainbow-delimiters 依赖 Treesitter 查询。COBOL 没有 parser（见 [Treesitter 那篇](16-treesitter-and-folding.md)），所以：

| 语言 | 彩虹括号 |
|---|---|
| Lua、Python、JS 等 | **生效** |
| COBOL | **不生效** |

COBOL 的结构配对由 `cobol.nvim` 提供（第 02 篇讲过的 `%` 跳转和结构标记），不是彩虹括号。

**在 COBOL buffer 里看不到彩色括号是正常的**，不是配置坏了。

### 验证

```vim
:InspectTree
```

COBOL buffer 会提示没有 parser。

## 4. 在哪能看到效果

打开任意 Lua 文件（比如 `~/nvim/lua/plugins/flash.lua`）：

```lua
return {
  {                                    ← 第 1 层（Yellow）
    "folke/flash.nvim",
    keys = {
      { "s", function()                 ← 第 2 层（Cyan）
        require("flash").jump()          ← 第 3 层（Blue）
      end, desc = "Flash" },
    },
  },
}
```

每一层的 `{` `}` 颜色不同。

## 5. 练习

### 练习 1：确认 COBOL 里不生效

```sh
cd ~/development/cobol
nvim lessons/32_bank-reconciliation-project/lesson.cob
```

1. 观察 `IF ... END-IF` 的颜色

**验收**：括号/关键字**没有**彩虹色（因为无 COBOL parser）。这是预期行为。

### 练习 2：看 Lua 里的效果

1. 打开 `~/nvim/lua/plugins/flash.lua`
2. 观察嵌套的 `{` `}`

**验收**：不同层级的括号颜色不同，7 色循环。

### 练习 3：数层数

1. 在 Lua 文件里找一个 4 层嵌套
2. 数一下颜色是否循环了 4 种

**验收**：能按颜色数出层级。

### 练习 4：对比 vim 文件

1. 打开一个 `.vim` 文件（如果有）

**验收**：用 `local` 策略，层级按局部作用域算（与 Lua 的 `rainbow-blocks` 不同）。

### 练习 5：确认查询配置

```vim
:lua =vim.g.rainbow_delimiters.query
```

**验收**：`[""] = "rainbow-delimiters"`，`lua = "rainbow-blocks"`。

## 6. 踩坑

### COBOL 里完全没效果

正常。没有 Treesitter 的 COBOL parser。结构配对用 `cobol.nvim` 的 `%` 和 Aerial 大纲。

### 颜色不够用（超过 7 层）

7 色循环，第 8 层回到第 1 色。嵌套超过 7 层建议重构代码。

### 和 Treesitter 高亮冲突

两者都改括号颜色。如果颜色怪异，检查主题是否覆盖了 `RainbowDelimiter*` 组：

```vim
:hi RainbowDelimiterYellow
```

### 想关掉

删除或注释 `lua/plugins/rainbow-delimiters.lua` 的加载，或加 `enabled = false`。

### Lua 里按块而非括号

你的配置 `query.lua = "rainbow-blocks"`，所以 Lua 的 `function ... end` 是按块着色的，不只是 `{}`。

## 7. 官方文档

```vim
:h rainbow-delimiters
```

仓库：<https://github.com/HiPhish/rainbow-delimiters.nvim>

## 8. 边界

- 本篇配置来自 `lua/plugins/rainbow-delimiters.lua`：7 色循环，Lua 用 `rainbow-blocks`，vim 用 `local` 策略。
- **依赖 Treesitter**。COBOL 没有 parser，所以 **COBOL buffer 里不生效**。
- COBOL 的结构配对用 `cobol.nvim`（`%` 跳转、Aerial 大纲、结构标记），不是本插件。
- 超过 7 层嵌套颜色会循环重复。
