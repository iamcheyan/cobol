# 多光标批量编辑：multicursor.nvim

COBOL 改字段名、统一 `PIC`、批量换状态码这类活，一行一行改既慢又容易漏。`multicursor.nvim` 让你把光标同时放在多个位置，一次操作改完。

本篇讲的是**官方配置**：不自定义、不魔改，所有按键和动作都来自插件作者的默认建议。本篇不引入 `cobol.nvim` 之外的依赖。

---

## 1. 为什么 COBOL 开发特别需要它

COBOL 的数据声明天生重复：

```cobol
       01  WS-ACCT-ID          PIC X(10).
       01  WS-ACCT-NAME        PIC X(20).
       01  WS-ACCT-BAL         PIC 9(7)V99.
       01  WS-ACCT-STATUS      PIC X(1).
```

四个字段，四行几乎相同的声明。当你要：

- 把 `WS-ACCT-*` 前缀改成 `WS-ACCOUNT-*`（4 处声明 + 3 处引用）；
- 把所有 `PIC X(...)` 统一成 `PIC X(100)`；
- 把三条记录的 `VALUE "A"` 改成 `VALUE "P"`；
- 给 6 个占位行填上 001–006 的序号；

单光标做法是"改一处、`n` 找下一处、再改"。多光标做法是"把光标一次性放到所有位置，改一次"。

**差别不在速度，在于你会不会漏。** 漏掉一处的 COBOL 程序通常能编译通过——只是那一个字段还是旧宽度，等到运行期才对不上。

---

## 2. 安装与配置

官方推荐配置（`lazy.nvim`）：

```lua
{
  "jake-stewart/multicursor.nvim",
  branch = "1.0",
  config = function()
    local mc = require("multicursor-nvim")
    mc.setup()

    local set = vim.keymap.set

    -- 上下加光标 / 跳过一行
    set({"n", "x"}, "<up>", function() mc.lineAddCursor(-1) end)
    set({"n", "x"}, "<down>", function() mc.lineAddCursor(1) end)
    set({"n", "x"}, "<leader><up>", function() mc.lineSkipCursor(-1) end)
    set({"n", "x"}, "<leader><down>", function() mc.lineSkipCursor(1) end)

    -- 按词/选区匹配加光标，或跳过
    set({"n", "x"}, "<leader>n", function() mc.matchAddCursor(1) end)
    set({"n", "x"}, "<leader>s", function() mc.matchSkipCursor(1) end)
    set({"n", "x"}, "<leader>N", function() mc.matchAddCursor(-1) end)
    set({"n", "x"}, "<leader>S", function() mc.matchSkipCursor(-1) end)

    -- 鼠标：Ctrl + 左键加/删光标，Ctrl + 拖动
    set("n", "<c-leftmouse>", mc.handleMouse)
    set("n", "<c-leftdrag>", mc.handleMouseDrag)
    set("n", "<c-leftrelease>", mc.handleMouseRelease)

    -- 临时禁用/启用光标
    set({"n", "x"}, "<c-q>", mc.toggleCursor)

    -- 只多光标时才生效的按键层
    mc.addKeymapLayer(function(layerSet)
      layerSet({"n", "x"}, "<left>", mc.prevCursor)
      layerSet({"n", "x"}, "<right>", mc.nextCursor)
      layerSet({"n", "x"}, "<leader>x", mc.deleteCursor)
      layerSet("n", "<esc>", function()
        if not mc.cursorsEnabled() then
          mc.enableCursors()
        else
          mc.clearCursors()
        end
      end)
    end)

    -- 光标外观
    local hl = vim.api.nvim_set_hl
    hl(0, "MultiCursorCursor", { reverse = true })
    hl(0, "MultiCursorVisual", { link = "Visual" })
    hl(0, "MultiCursorSign", { link = "SignColumn" })
    hl(0, "MultiCursorMatchPreview", { link = "Search" })
  end
}
```

### 本篇额外用到的三个动作

官方示例配置只给最小集。下面三个是官方文档"Advanced Actions"一节的内容，本篇会用到，建议一起加上：

```lua
-- 选中几行后，ga 加一个 motion 就能给每一行加光标：
-- gg vip gaip  → 段落每一行一个光标
set({"n", "x"}, "ga", mc.addCursorOperator)

-- 全文件匹配光标下的词/选区
set({"n", "x"}, "<leader>A", mc.matchAllAddCursors)

-- 连续序号：把所有光标的数字当成一条序列递增
set({"n", "x"}, "g<c-a>", mc.sequenceIncrement)
set({"n", "x"}, "g<c-x>", mc.sequenceDecrement)
```

### 关键区分：`n` 与 `<leader>n`

这里有个必须讲清的地方，否则会一直用错：

| 按键 | 作用 | 用于 |
|---|---|---|
| `n` | 原生 vim 搜索下一个 | 普通跳转 |
| `<leader>n` | **加一个光标**到下一个匹配 | 多光标 |
| `<leader>s` | 跳过下一个匹配，**不加**光标 | 多光标 |
| `<leader>A` | 一次给**全文件**所有匹配加光标 | 多光标 |

`<leader>A` 是最省事的：光标停在 `WS-ACCT` 上按一次，全文件所有 `WS-ACCT` 都有光标了。

---

## 3. 五个动作，覆盖 90% 场景

### 动作一：逐行加光标（`ga` + motion）

最常用。选中几行 → `ga` → 输入 motion。

```text
gg vip gaip
```

含义：回到文件首 → 选中文档 → `ga` 进入加光标状态 → `ip` 作为 motion（段落）→ **每一行一个光标**。

也可以只针对视觉选区：`V` 选中几行后按 `ga`（配合 `mc.addCursorOperator`）。

实测效果（练习文件 `02-unify-pic.cob` 的前四行）：

```text
before                          after gaip
│ 01 WS-ACCT-ID      PIC X(10). │ 01 WS-ACCT-ID      PIC X(10).
│ 01 WS-ACCT-NAME    PIC X(20). │ 01 WS-ACCT-NAME    PIC X(20).
│ 01 WS-ACCT-BAL     PIC 9(7)V99│ 01 WS-ACCT-BAL     PIC 9(7)V99
│ 01 WS-ACCT-STATUS  PIC X(1).  │ 01 WS-ACCT-STATUS  PIC X(1).
```

左侧 `│` 就是光标标记（`MultiCursorCursor`，反向显示）。

### 动作二：按列对齐操作（`f` + `C`）

光标加好后，所有光标会同步响应**同一个** vim 命令。这是最关键的心智模型：

> **不是"对每个光标分别执行"，而是"对每个光标执行同一条命令"。**

所以要让每个光标落在**语义相同**的位置上。`fP` 是"本行向前找到字母 P"，它会让每个光标各自跳到本行的 `PIC` 处：

```text
gg gaip        " 四行各一个光标（在第 1 列）
fP             " 每行各自向前找到 PIC 的 P
C              " 从光标改到行尾
PIC 9(9).      " 输入新内容
<Esc>          " 退出插入，光标保留
```

实测结果：

```text
       01  WS-ACCT-ID          PIC 9(9).
       01  WS-ACCT-NAME        PIC 9(9).
       01  WS-ACCT-BAL         PIC 9(9).
       01  WS-ACCT-STATUS      PIC 9(9).
```

四行原来的 `PIC` 长度各不相同（`X(10)`、`X(20)`、`9(7)V99`、`X(1)`），但 `C` 是"改到行尾"，所以**不论原内容多长都能完整替换**。

**这里有个坑必须记住**：如果用 `cw`（改一个词），只会改掉 `PIC` 这三个字符，后面的 `X(10).` 会原样留下。原文写 `PIC X(10).` 会被改成 `9(9) X(10).`——语法直接坏掉。

| 命令 | 改的范围 | 适合 |
|---|---|---|
| `cw` | 到词尾 | 替换单个标识符 |
| `ciW` | 整个空白分隔的词 | 替换 `WS-ACCT-NAME` 这种含连字符的标识符 |
| `C` | **到行尾** | 替换"从这里开始全部" |
| `ci"` | 引号内内容 | 替换字符串字面量 |
| `cc` | 整行 | 整行重写 |

### 动作三：整行替换标识符（`ciW`）

`WS-CUSTOMER-ID` 和 `WS-CUSTOMER-NAME` 长度不同，`cw` 会在 `-` 处停住。要完整替换整个标识符用 `ciW`：

```text
gg gaip            " 每行一个光标
w                  " 各自跳到本行第 2 个词（WS-CUSTOMER-xxx）
ciW                " 选中整个空白分隔的词
WS-CLIENT-XX       " 输入新名
<Esc>
```

实测：

```text
before                                    after
       01 WS-CUSTOMER-ID     PIC X(8).  →  01 WS-CLIENT-XX     PIC X(8).
       01 WS-CUSTOMER-NAME   PIC X(10). →  01 WS-CLIENT-XX   PIC X(10).
       01 WS-CUSTOMER-STATUS PIC X(1).  →  01 WS-CLIENT-XX PIC X(1).
```

注意 COBOL 标识符里的 `-` 不是 `iskeyword` 的一部分时，`ciw` 只选到连字符。`ciW` 用空白边界，才能覆盖整串。

### 动作四：引号内容批量替换（`ci"`）

改状态码、改分类值、改固定字面量，这是最高频的一类活：

```text
gg gaip      " 每行一个光标
f" l         " 各自跳到本行第一个引号，再右移一格进入内容
ci"          " 改掉引号内全部内容
N            " 输入新值
<Esc>
```

实测（练习 `03-split-selection.cob`）：

```text
before                          after ci" + N
01 WS-FLAG-A PIC X(1) VALUE "A".  →  ... VALUE "N".
01 WS-FLAG-B PIC X(1) VALUE "B".  →  ... VALUE "N".
01 WS-FLAG-C PIC X(1) VALUE "C".  →  ... VALUE "N".
01 WS-FLAG-D PIC X(1) VALUE "D".  →  ... VALUE "N".
```

四个不同的值 `"A" "B" "C" "D"` 一次变成同一个值。**因为 `ci"` 的作用范围是"引号内"，与内容长度无关。**

### 动作五：连续序号（`g<C-a>`）

给多条记录编号、生成测试数据时用：

```text
gg gaip      " 每行一个光标
f" l         " 进到引号内数字
g<C-a>       " 递增
```

实测：

```text
before                          after g<C-a>
01 WS-LINE-01 PIC X(40) VALUE "000".  →  VALUE "001".
01 WS-LINE-02 PIC X(40) VALUE "000".  →  VALUE "002".
01 WS-LINE-03 PIC X(40) VALUE "000".  →  VALUE "003".
01 WS-LINE-04 PIC X(40) VALUE "000".  →  VALUE "004".
```

`g<C-a>`（`mc.sequenceIncrement`）和原生 `Ctrl-a` 的区别：**把所有光标的数字当成一条连续序列**。原生 `Ctrl-a` 是每个数字各加 1，结果全是 `001`；`g<C-a>` 得到 `001 002 003 004`。

---

## 4. 光标的管理与排错

### 查看有几个光标

```vim
:lua require("multicursor-nvim.core").action(function(ctx) vim.print("cursors=" .. ctx:numCursors()) end)
```

### 常见状态

| 现象 | 含义 | 恢复 |
|---|---|---|
| 光标标记是 `│` | 光标已启用 | — |
| 光标标记是 `┃`（实心） | 光标被 `<c-q>` 禁用，只有主光标移动 | 再按 `<c-q>` 或 `<Esc>` |
| 标记消失，只剩主光标 | 光标已清除 | 重新加 |
| 结果只有一行变了 | 其他光标不在预期位置 | 用 `:call cursor(行,列)` 校准后重来 |

### `<c-q>` 的真正用途

它不是"关掉多光标"，而是**冻结其他光标，让主光标单独移动**。典型用法：先加了 3 个光标，发现第 4 行位置不对，按 `<c-q>` 冻结，把主光标移到正确位置，再按 `<Esc>` 恢复。

### `<Esc>` 的两种行为

官方配置里 `<Esc>` 是：

```lua
if not mc.cursorsEnabled() then
  mc.enableCursors()   -- 被禁用了 → 恢复
else
  mc.clearCursors()    -- 正常状态 → 清除所有光标
end
```

所以**按一次 `<Esc>` 会清掉所有光标**。改完想确认结果时别急着按，先看一眼。

---

## 5. 五个练习

练习文件在 [`exercises/multicursor/`](../exercises/multicursor/)，都已通过 `cobc -fsyntax-only`。

### 练习 1：改字段前缀

`01-rename-field.cob` — 把 `WS-CUSTOMER-*` 改成 `WS-CLIENT-*`（4 个声明 + 4 个 `DISPLAY` 引用，共 8 处）。

```sh
cd extensions/neovim-tooling/exercises/multicursor
nvim 01-rename-field.cob
```

步骤：光标停在某个 `WS-CUSTOMER` 上 → `<leader>A` → `ciW` → 输入新名 → `<Esc>`。

**验收**：8 处全部改变，`cobc -fsyntax-only 01-rename-field.cob` 仍通过。

### 练习 2：统一 PIC

`02-unify-pic.cob` — 四个不同长度的 `PIC` 统一成 `PIC 9(9).`

步骤：`gg` → `gaip` → `fP` → `C` → `PIC 9(9).` → `<Esc>`。

**验收**：四行都以 `PIC 9(9).` 结尾。

**踩坑检查**：如果用了 `cw`，会看到 `9(9) X(10).` 这类坏结果，改回去用 `C`。

### 练习 3：批量改字面量

`03-split-selection.cob` — 四个 `VALUE "A"` `"B"` `"C"` `"D"` 全部改成 `"N"`。

步骤：`gg` → `gaip` → `f"` → `l` → `ci"` → `N` → `<Esc>`。

**验收**：四行都是 `VALUE "N".`

### 练习 4：填连续序号

`04-sequence-fill.cob` — 六个 `VALUE "000"` 变成 `"001"` 到 `"006"`。

步骤：`gg` → `gaip` → `f"` → `l` → `g<C-a>`。

**验收**：依次为 001、002、003、004、005、006。

**对比实验**：用原生 `Ctrl-a` 试一次，会发现全是 `001`——这就是 `g<C-a>` 存在的理由。

### 练习 5：综合

`05-fixed-format-batch.cob` — 两步分开做：

1. 三个 `VALUE "A"` 改成 `"P"`（用 `ci"`）；
2. 三个 `PIC X(1)` 改成 `PIC X(2)`（用 `C`）。

**为什么必须分两步**：两次操作的作用范围不同（引号内 vs 到行尾），混在一次里会互相干扰。这也是多光标最重要的习惯——**一次只做一件事**。

---

## 6. 与 COBOL 固定格式配合的注意事项

COBOL 源码有列规则，多光标操作要留意：

1. **`C`（改到行尾）会吃掉第 72 列之后的注释**。如果该行有行尾对齐的注释，先确认。
2. **`cc`（改整行）会破坏第 7 列指示符**。注释行（第 7 列是 `*`）不要用 `cc`。
3. **加光标时注意列对齐**。`gaip` 加的光标都在第 1 列，需要用 `f`/`w` 把各自移到目标；也可以用 `V` 做块选择后加光标，这样光标天然对齐。
4. **改完必须编译**。多光标改得快，但错得也快：

```sh
cobc -fsyntax-only 你的文件.cob
```

---

## 7. 速查表

| 操作 | 按键 | 说明 |
|---|---|---|
| 下面加光标 | `<down>` | 逐行向下 |
| 上面加光标 | `<up>` | 逐行向上 |
| 跳一行再加 | `<leader><down>` | 跳过当前行 |
| 下一个匹配加光标 | `<leader>n` | 按词/选区匹配 |
| 上一个匹配加光标 | `<leader>N` | 反向 |
| 跳过下一个匹配 | `<leader>s` | 不加光标 |
| 全文件匹配加光标 | `<leader>A` | 一次到底 |
| 按 motion 逐行加 | `ga` + motion | `gaip` = 每行 |
| 切换主光标 | `<left>` / `<right>` | 只在多光标时生效 |
| 删掉当前光标 | `<leader>x` | 只在多光标时生效 |
| 冻结/恢复其他光标 | `<c-q>` | 主光标可单独移动 |
| 清除全部光标 | `<Esc>` | 正常状态下 |
| 鼠标加光标 | `<c-leftmouse>` | Ctrl + 左键 |
| 连续序号 | `g<C-a>` / `g<C-x>` | 所有光标算一条序列 |

### 文本对象选择

| 命令 | 范围 | COBOL 场景 |
|---|---|---|
| `cw` | 到词尾 | 单词 |
| `ciw` | 整个词 | 标识符（不含 `-` 时） |
| `ciW` | 空白分隔的整词 | `WS-ACCT-NAME`（含 `-`） |
| `C` | 到行尾 | 整条 `PIC` 子句 |
| `ci"` | 引号内 | 字面量、状态码 |
| `cc` | 整行 | 整行重写（勿用于注释行） |

---

## 8. 官方文档

本篇只覆盖常用部分。完整动作列表（`splitCursors`、`transposeCursors`、`alignCursors`、`operator`、诊断相关等）见插件自带帮助：

```vim
:h multicursor
:h multicursor-actions
:h multicursor-api
```

插件仓库：<https://github.com/jake-stewart/multicursor.nvim>

---

## 9. 边界

- 本篇的按键全部来自**官方示例配置**，没有自定义。你的本地配置可能不同，以 `:map <leader>n` 等实际查询为准。
- 文中"实测结果"来自 Neovim 0.10+ 真实终端操作，不是推测。不同版本的光标渲染符号（`│` / `┃`）可能略有差异。
- 多光标不改变 COBOL 的语义，它只是让同样的编辑动作作用到多个位置。**改完仍以 `cobc` 的编译结果为准。**
