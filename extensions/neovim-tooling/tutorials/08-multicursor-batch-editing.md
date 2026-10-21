# 多光标批量编辑：multicursor.nvim

COBOL 改字段名、统一 `PIC`、批量换状态码这类活，一行一行改既慢又容易漏。`multicursor.nvim` 让你把光标同时放在多个位置，一次操作改完。

本篇按本机 `lua/plugins/multicursor.lua` 的实际按键讲解：在插件基础上增加了 VS Code 风格的 `Ctrl-n`、`Ctrl+Shift+n`、`Ctrl-d`，并保留按行添加与跳过等映射。本篇不引入 `cobol.nvim` 之外的依赖。

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
- 给 6 个占位行分别填入不同序号；

单光标做法是"改一处、`n` 找下一处、再改"。多光标做法是"把光标一次性放到所有位置，改一次"。

**差别不在速度，在于你会不会漏。** 漏掉一处的 COBOL 程序通常能编译通过——只是那一个字段还是旧宽度，等到运行期才对不上。

---

## 2. 本机配置与按键

本机配置（`lua/plugins/multicursor.lua`）在插件默认行为上增加了 VS Code 风格键位，并使用 eager load 确保 `Ctrl+Shift+n` 首次按下也能生效：

| 按键 | 模式 | 操作 |
|---|---|---|
| `Ctrl-n` | Normal / Visual | 在当前词或选择上添加下一个匹配光标 |
| `Ctrl+Shift+n` | Normal / Visual | 为当前词或选择添加所有匹配光标 |
| `Ctrl-d` | Normal / Visual | 跳过下一个匹配，不添加光标 |
| `<up>` / `<down>` | Normal / Visual | 向上／向下添加光标 |
| `<leader><up>` / `<leader><down>` | Normal / Visual | 跳过一行再添加光标 |
| `ga` + motion | Normal / Visual | 按 motion 添加光标，例如 `gaip` |
| `<leader>a` | Normal | 对齐光标列 |
| `<leader>gv` | Normal | 恢复上一次光标集合 |
| `<C-q>` | Normal / Visual | 暂停或恢复其它光标 |
| `<Esc>` | 有活动光标时 | 清除光标；若光标被暂停则先恢复 |

插件示例配置中的 `<leader>n`、`<leader>s`、`<leader>N`、`<leader>S` 不是本机的匹配快捷键；本教程统一使用上表的本机按键。

---

## 3. 五个常用动作

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
| `c` | 当前选区 | 配合 `Ctrl+Shift+n` 批量替换匹配文本 |

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

### 动作四：用 `Ctrl+Shift+n` 一次选全部匹配

前面三个动作都先用 `gaip` 逐行加光标。若目标是一段重复文本（例如 `CUSTOMER`），用匹配选择更直接：

```text
在 CUSTOMER 上 Visual 选中 CUSTOMER
Ctrl+Shift+n    " 全文件所有 CUSTOMER 都选中
c               " 改掉所有选中
CLIENT
<Esc>
```

只想改其中几处时，用 `Ctrl-n` 逐个加入，用 `Ctrl-d` 跳过不想改的匹配。

### 动作五：引号内容批量替换（`ci"`）

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

本机配置里 `<Esc>` 是：

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

步骤：Visual 选中 `CUSTOMER` → `Ctrl+Shift+n` 选择全部匹配 → `c` → 输入 `CLIENT` → `<Esc>`。

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

### 练习 4：跳过不需要修改的匹配

`01-rename-field.cob` 中使用 Visual 选择和跳过操作：

1. 在 `WS-CUSTOMER` 的 `C` 上进入 Visual 模式，选中 `CUSTOMER`。
2. 按 `Ctrl-n` 加入下一个相同匹配。
3. 对不想改的匹配按 `Ctrl-d` 跳过。
4. 对其余匹配按 `c` 输入 `CLIENT`，再按 `<Esc>`。

**验收**：只有选中的 `CUSTOMER` 片段改为 `CLIENT`，被跳过的匹配不变。
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
| 下一个匹配加光标 | `Ctrl-n` | 按词/选区匹配 |
| 跳过下一个匹配 | `Ctrl-d` | 不加光标 |
| 全文件匹配加光标 | `Ctrl+Shift+n` | 一次到底 |
| 按 motion 逐行加 | `ga` + motion | `gaip` = 每行 |
| 切换主光标 | `<left>` / `<right>` | 只在多光标时生效 |
| 删掉当前光标 | `<leader>x` | 只在多光标时生效 |
| 冻结/恢复其他光标 | `<c-q>` | 主光标可单独移动 |
| 清除全部光标 | `<Esc>` | 正常状态下 |
| 鼠标加光标 | `<c-leftmouse>` | Ctrl + 左键 |

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

本篇只覆盖常用部分，按键以本机配置为准。完整动作列表（`splitCursors`、`transposeCursors`、`alignCursors`、`operator`、诊断相关等）见插件自带帮助：

```vim
:h multicursor
:h multicursor-actions
:h multicursor-api
```

插件仓库：<https://github.com/jake-stewart/multicursor.nvim>

---

## 9. 边界

- 本篇按键依据当前 `lua/plugins/multicursor.lua`。匹配键已自定义为 `Ctrl-n`、`Ctrl+Shift+n`、`Ctrl-d`；本机另有 `ga`、`<leader>a`、`<leader>gv` 映射。
- 文中"实测结果"来自 Neovim 0.10+ 真实终端操作，不是推测。不同版本的光标渲染符号（`│` / `┃`）可能略有差异。
- 多光标不改变 COBOL 的语义，它只是让同样的编辑动作作用到多个位置。**改完仍以 `cobc` 的编译结果为准。**
