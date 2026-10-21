# 屏幕内快速跳转：flash.nvim

`snacks picker` 是「我知道要找什么，用文字搜」。**flash 是「我看见了，但数不过去」。**

一行 72 列的 COBOL 语句、一屏 50 行代码，光标在第 8 行第 12 列，目标在第 45 行第 60 列。数行数、数空格，或者 `45G` + `60|`——都要先知道编号。

flash 让你**看着目标打字**：按 `s`，输入目标附近的一个字符，屏幕上所有匹配位置会标上字母，按那个字母就跳过去。

---

## 1. 它解决什么问题

三种低效跳转：

| 做法 | 问题 |
|---|---|
| `j` / `k` 一行行挪 | 跨度大时要按几十次 |
| `45G` | 得先数行号 |
| `/pattern` + `<CR>` | 要有可搜的唯一字符串；只搜下一个 |

flash 的优势：**一次输入，多个候选，按标签直达**。不比正则弱，但比正则快。

## 2. 你的实际配置

配置在 `lua/plugins/flash.lua`，只有三个键：

```lua
{ "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash" },
{ "S", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash Jump (Shift)" },
{ "<c-s>", mode = { "c" }, function() require("flash").toggle() end, desc = "Toggle Flash Search" },
```

| 按键 | 模式 | 作用 |
|---|---|---|
| `s` | n / x / o | 跳转到任意位置 |
| `S` | n / x / o | 与 `s` 一样进行 Flash 字符跳转 |
| `<C-s>` | 命令行 | 搜索时切换 flash 提示 |

**注意 `r` 和 `R` 被移除了**（配置里注释掉了），原因写在配置里：避免与 `substitute.nvim` 冲突。所以网上教程里的 `r`（remote flash）在你的环境里**不可用**。

`o` 模式就是 operator-pending：`d` `s` 这种组合，见下文。

![三步：光标在原处 → 按 `s` 输入目标字符 → 按屏幕上出现的标签。中间不用数行，也不用构造正则。](images/10-flash-flow.png)

三步：光标在原处 → 按 `s` 输入目标字符 → 按屏幕上出现的标签。中间不用数行，也不用构造正则。

## 3. 基本用法：`s` + 字符 + 标签

### 三步

```text
1. 按 s
2. 输入目标位置上的一个字符
3. 按屏幕上显示的标签字母
```

实测（`DEV` 出现在多行时输入 `A`）：

```text
   IDENTIFICAaION DIVISION.
   PROGRAM-ID. FLAdHTEST.
   DAfAgDIVISION.
   WORKING-STORAhE SECTION.
   01 WS-AjPHAkPIC X(10) VAlUE "Aqwertyuiop.
```

每个 `A`（不区分大小写）后面都跟了一个小写字母标签：

| 标签 | 位置 |
|---|---|
| `a` | 第 1 行 `IDENTIFICATION` 里的 `A` |
| `d` | 第 2 行 `FLASHTEST` 里的 `A` |
| `f` | 第 3 行 `DATA` 里的 `A` |
| `h` | 第 4 行 `WORKING-STORAGE` 里的 `A` |
| `j` | 第 5 行 `WS-ALPHA` 里的 `A` |
| `k` | 第 5 行 `PIC` 后的 `A` |

按 `j` 就跳到第 5 行 `WS-ALPHA` 的 `A`（实测 `col(".")` 返回 `14`）。

### 候选太多怎么办

标签用完了（通常 26 个），flash 会要求你再输入一个字符缩小范围。**继续打字即可**，不用重新开始。

### 取消

`<Esc>` 退出，光标不动。

## 4. `s` 配合操作符：跳过去并执行

因为 `s` 在 `o`（operator-pending）模式也生效，所以能和 `d`、`c`、`y`、`v` 组合：

| 组合 | 含义 |
|---|---|
| `d` `s` `)` | 删除到下一个 `)` |
| `c` `s` `X` | 改到下一个 `X` 之前 |
| `y` `s` `;` | 复制到下一个 `;` |
| `v` `s` `}` | 从当前位置选到下一个 `}` |

实测思路：光标在行首，`ds"` 然后按标签选中某个引号 —— 删到那个引号为止。**这比 `dt"`（删除到下一个引号）更强**，因为 `dt"` 只能到最近的那个，flash 能选任意一个。

### COBOL 里的实用组合

```text
d s )      删除到某个括号 —— 处理 PIC X(10) 时有用
v s "      选到某个引号 —— 选中字符串字面量
c s .      改到某个句点 —— 替换半个句子
```

## 5. `S`：Flash 跳转的备用键

`S` 与 `s` 调用同一个 Flash 字符跳转功能。使用大小写不同的按键可在终端或键位冲突时作为备用入口；它不再执行 Treesitter 节点选择，也不会触发 Neovim 原生的整行替换。

按 `S` 后输入目标字符，Flash 会为匹配位置显示标签，选择标签即可跳转。

```text
abcIDENTIFICATION DIVISION.
PROGRAM-ID. FLASHTEST.a
```

行为与 `s` 相同；标签对应目标字符的匹配位置，不依赖 COBOL Treesitter 节点。

### 什么时候用 `S`

| 想跳到 | 用 |
|---|---|
| 某个具体字符 | `s` |
| 需要第二个 Flash 跳转入口或终端对 `s` 的处理有冲突 | `S` |
| 某个括号/引号 | `s` |
| 按字符定位任意位置 | `s` 或 `S` |

`S` 不按 COBOL 语法结构筛选位置；要跳到段落或 Division，可输入该结构独有的字符后选对应标签。

该映射只调用 Flash 的普通跳转，不依赖 Treesitter parser。

```vim
:lua print(vim.treesitter.language.add("cobol"))
```

## 6. `<C-s>`：命令行里的 flash

在命令行模式下按 `<C-s>`，把 `/` 搜索变成 flash 模式：搜索时屏幕上实时标出所有匹配，并按标签跳。

```text
/WS-RECORD<C-s>
```

适合：搜索词很长、匹配很多，想直接跳到第 N 个而不是按 N 次 `n`。

## 7. 实测记录

| 操作 | 观察结果 |
|---|---|
| 按 `s` | 进入等待输入状态，无标签 |
| 输入 `A` | 所有 `A` 后出现小写字母标签 |
| 按 `j` | 跳到第 5 行 `WS-ALPHA`，`col()` = 14 |
| 按 `S` 并输入字符 | 与 `s` 一样显示字符匹配标签 |
| 按 `<Esc>` | 退出，光标不动 |

## 8. 练习

### 练习 1：基本跳转

```sh
cd ~/development/cobol
nvim lessons/17_fixed-length-files/lesson.cob
```

1. 按 `s`
2. 输入 `D`
3. 观察标签分布，按其中一个

**验收**：光标落在你按的标签所在的 `D` 上。用 `:echo line(".").":".col(".")` 确认位置。

### 练习 2：跨屏跳转

1. `gg` 回到文件头
2. 按 `s`，输入 `PIC`
3. 选一个在文件后半部分的标签

**验收**：一次按键跳过后半部分，不用数行。

### 练习 3：配合操作符删除

在一个可撤销的副本上：

1. 光标放在某行行首
2. `d` `s`，输入 `"`，按标签选一个引号
3. `u` 撤销

**验收**：删除范围是从光标到**你选的那个**引号，不是最近的那个。

### 练习 4：用 `S` 进行 Flash 跳转

1. `gg`
2. 按 `S`
3. 观察标签只出现在语法节点边界

**验收**：标签数量明显少于 `s` 同字符时的数量。

**对比实验**：用 `s` 输入 `D` 再数一次标签，能看出 `S` 和 `s` 的差别。

### 练习 5：命令行 flash

1. `/WS-RECORD-COUNT<C-s>`
2. 观察匹配被标标签
3. 按标签跳转

**验收**：不用按 `n` 就跳到了指定那一处。

## 9. 踩坑

### `r` / `R` 不起作用

你的配置**故意移除了**这两个映射（避免与 `substitute.nvim` 冲突）。网上教程演示的 remote flash / treesitter search 用不了。**这不是 bug。**

想用的话得自己加回来，但要先解决冲突：

```lua
{ "r", mode = "o", function() require("flash").remote() end },
```

### `s` 把原来的 `s` 覆盖了

vim 原生 `s` 是「删除字符并进入插入」。flash 占用了它。需要原生行为时用 `c` `l` 或者 `<C-s>`（在你的配置里 `<C-s>` 只在命令行模式生效，普通模式没被占）。

### 标签看不清

高亮由 `FlashLabel` 组控制。看当前值：

```vim
:hi FlashLabel
```

### 中文/日文跳转不准

flash 按字节定位，多字节字符（日文注释里的假名）可能标记位置偏移一位。在纯 ASCII 的代码行里没有这个问题。COBOL 源码的代码区都是 ASCII，所以实际影响很小。

## 10. 官方文档

```vim
:h flash.nvim
:h flash-jump
```

仓库：<https://github.com/folke/flash.nvim>

查看当前映射：

```vim
:verbose nmap s
:verbose nmap S
```

## 11. 边界

- 本篇按键来自你的本地配置（`lua/plugins/flash.lua`），只有 `s`、`S`、`<C-s>` 三个，且 `r`/`R` 已被移除。
- `S` 与 `s` 一样调用 Flash 字符跳转，不依赖 Treesitter parser。
- 实测记录来自真实终端会话；标签字母的具体分配由 flash 内部算法决定，同一文件两次按 `s` 可能给出不同的标签排布。
