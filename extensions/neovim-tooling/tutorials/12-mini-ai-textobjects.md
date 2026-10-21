# 文本对象：mini.ai

`ciw`（改一个词）、`di(`（删括号内）是 vim 自带的文本对象。**mini.ai 把文本对象从「按字符边界」升级到「按语义边界」。**

COBOL 里最典型的场景：光标停在 `WS-ACCOUNT-STATUS` 中间，想改掉整个标识符。`ciw` 会在连字符处停下——因为 `-` 不是 `iskeyword` 的一部分。你需要的是 `cia`（改一个"参数"）或者 `cii`（改一个缩进块）。

---

## 1. 它解决什么问题

vim 原生的文本对象只有 `w`、`s`、`(`、`"` 等字符级边界。实际写代码要按**结构**选：

| 想选中 | 原生做法 | mini.ai |
|---|---|---|
| 整个函数调用 `foo(a, b)` | 手动 `f(` `%` | `au`（around usage） |
| 引号内内容（任意引号类型） | `ci"` 或 `ci'`，要试 | `ciq`（任何引号） |
| 整个文件 | `ggVG` | `a g`（`ag`） |
| 一个缩进块 | `vii` 不行 | `aii` / `iii` |
| 数字 | `diw` 后手改 | `did`（digit） |

mini.ai 的做法：**判断光标的语境，自动找到合适的边界**。

## 2. 你的配置

`lua/plugins/mini-ai.lua`，`n_lines = 500`（搜索范围上限 500 行）。

### 自定义文本对象

| 对象 | 含义 | 说明 |
|---|---|---|
| `o` | block / conditional / loop | Treesitter 块 |
| `f` | function | 函数 |
| `c` | class | 类 |
| `t` | tag | HTML/XML 标签 |
| `d` | digit | 数字 |
| `e` | CamelCase / snake_case | 复合词 |
| `g` | entire buffer | 整个文件 |
| `u` | usage / 函数调用 | 函数调用括号内 |
| `U` | usage（不含点） | 同上，函数名不含 `.` |
| `a` | argument | 参数 |
| `i` | indent | 缩进块 |
| `q` | quote | 任何引号（`"` `'` `` ` ``） |
| `b` | 任意括号对 | `()` `[]` `{}` |
| ` ` | whitespace | 连续空白 |

### 前缀

`i`（inner，不含边界）和 `a`（around，含边界）：

```text
ia   一个参数
aa   参数及其逗号
ii   缩进块内部（不含首尾行）
ai   缩进块整体
iq   引号内内容
aq   连同引号
```

## 3. COBOL 里的实用组合

### 场景一：改整个标识符

光标在 `WS-ACCOUNT-STATUS` 中任意位置：

```text
cia      改一个参数（整个 word，包含连字符）
```

**用 `ciw` 会怎样**：`-` 不是 keyword 字符，`ciw` 只选到 `WS`，结果变成 `新名-ACCOUNT-STATUS`。

**注意**：`a`（argument）依赖 mini.ai 对"参数"的判定。在 `PIC X(10)` 里它可能选到 `X(10)` 而不是整个标识符。**最可靠的是先目视确认，或直接用 `viW`**（vimgrep 的 W 是空白分隔词）。

### 场景二：选中整个 PIC 子句

```text
vi(      选括号内（10）
va(      连同括号（X(10)）
```

### 场景三：选中整个字符串字面量

```text
viq      引号内内容（不管单双引号）
vaq      连同引号
```

`ciq` 就是「改掉引号里的一切，不管原来是什么值」——比 `ci"` 更强，因为不用先判断是单引号还是双引号。

### 场景四：选中整个 DIVISION 块

需要 Treesitter 的 COBOL parser。配置里明确写了：

```lua
-- COBOL currently has no Treesitter parser in this configuration.
-- Keep mini.ai's Treesitter objects available for other languages,
-- but make them a no-op instead of raising an error in COBOL buffers.
if vim.tbl_contains({ "cobol", "cbl", "cob" }, vim.bo.filetype) then
  return {}
end
```

**所以在 COBOL buffer 里 `iao`、`iaf`、`iac` 都不起作用**——这是配置作者有意的降级，避免报错。非 COBOL 文件（Lua、Python、JS）可用。

## 4. 常用对象速查

| 命令 | 作用 |
|---|---|
| `cia` | 改一个参数 |
| `ciq` / `caq` | 改引号内 / 连同引号 |
| `vii` / `vai` | 选缩进块内 / 整体 |
| `di(` / `da(` | 删括号内 / 连括号 |
| `yig` / `dag` | 复制整个文件 / 删除整个文件 |
| `cid` | 改数字 |
| `cie` | 改 CamelCase 或 snake_case 词 |
| `viu` | 选函数调用括号内 |

### `ig` 的特殊性

`ig`（inner entire buffer）会跳过首尾空行，`ag` 包含全部。批量处理整个文件时有用：

```text
ggdag    删除整个文件内容
```
⚠️ 危险操作，先 `u` 确认可撤销。

## 5. 与 which-key 的集成

配置把 27 个文本对象注册进了 which-key。按 `a` 或 `i` 后**停顿一下**，会弹出可用对象列表：

```text
 a  around
 i  inner
```

再按对象字母。忘了具体字母时这是最快的方式。

## 6. 练习

### 练习 1：对比 `ciw` 和 `cia`

```sh
cd ~/development/cobol
nvim lessons/25_using-parameters/lesson.cob
```

1. 光标放到 `AMOUNT-ARGUMENT` 中间
2. 按 `ciw`，输入 `X`，`<Esc>` —— 观察结果
3. `u` 撤销
4. 再按 `cia`，输入 `X`，`<Esc>` —— 观察结果

**验收**：`ciw` 只改了一段（在 `-` 处断开），`cia` 改掉整个词。这次对比是理解 mini.ai 价值的最快方式。

### 练习 2：`ciq` 改引号内容

1. 找到 `VALUE "C0001042"` 这样的行
2. 光标落在引号内
3. `ciq` → 输入新值

**验收**：不用先确认是单引号还是双引号，直接改掉了内容。

### 练习 3：`yig` 复制整个文件

1. `yig`
2. `:new` 打开新缓冲区
3. `p`

**验收**：整个文件内容被复制过去，且首尾没有多余空行（`ig` 会跳过空行）。

### 练习 4：缩进块

在任意有缩进的代码块（比如 `IF ... END-IF`）里：

1. `vii` 选中内部
2. `d` 删除
3. `u` 撤销

**验收**：选中范围是从 `IF` 下一行到 `END-IF` 上一行。

### 练习 5：which-key 探索

1. 按 `a`，停 1 秒
2. 观察弹出列表
3. 按 `<Esc>` 退出

**验收**：能看到 27 个文本对象的名字和描述。

## 7. 踩坑

### COBOL 里 `iao` 无效

配置对 COBOL filetype 返回空表（因为没装 Treesitter 的 COBOL parser）。**这不是 bug**，是避免报错的处理。用 `vii` 代替。

### `cia` 选错范围

`a`（argument）的边界判定依赖具体语境。在 `PIC X(10)` 里可能只选到 `X(10)`。**不确定时先按 `v` 进入可视模式，看到选中范围再决定。**

### `ig` 删掉整个文件后慌了

`u` 能撤销。vim 的撤销树很可靠，只要没退出 Neovim。

### `n_lines = 500` 超出后失效

mini.ai 只向上/下搜索 500 行。超大文件里跳太远可能找不到边界。这是性能保护，不是缺陷。

## 8. 官方文档

```vim
:h mini.ai
:h mini.ai-examples
```

仓库：<https://github.com/nvim-mini/mini.ai>

查看当前文本对象列表：

```vim
:lua print(vim.inspect(require("mini.ai").config.custom_textobjects))
```

## 9. 边界

- 本篇按键来自你的配置（`lua/plugins/mini-ai.lua`）：27 个文本对象，`n_lines = 500`。
- **COBOL buffer 里 `o`、`f`、`c` 三个 Treesitter 对象被配置主动禁用**（无 COBOL parser），不要期待它们生效。
- `a`（argument）的边界判定依赖语境，不同位置结果可能不同；`W`（空白分隔词）在 COBOL 里更可预测。
- 建议配合 [multicursor 那篇](08-multicursor-batch-editing.md)：`viq` 选中后加多光标，可以批量改多个字符串。
