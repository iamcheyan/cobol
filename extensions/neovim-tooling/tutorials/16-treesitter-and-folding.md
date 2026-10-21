# 语法解析与折叠：nvim-treesitter

正则高亮只认得「这行有 `IF`」，Treesitter 认得「这个 `IF` 到哪结束」。这个差别决定了折叠、文本对象、结构跳转能不能做对。

---

## 1. 它解决什么问题

| 需求 | 正则方案 | Treesitter |
|---|---|---|
| 语法高亮 | 关键词匹配，嵌套会错 | 按语法树，准确 |
| 折叠 | 按缩进猜 | 按 `IF ... END-IF` 真实范围 |
| 文本对象 | 只能按字符边界 | 按语法节点 |
| 结构跳转 | 搜索关键词 | 遍历语法树 |

COBOL 的 `IF` / `END-IF` 可以跨几十行、可以嵌套多层。正则折叠在这里完全不可靠。

## 2. 你的配置

`lua/plugins/treesitter.lua`，`ensure_installed` 列表里有 28 种语言：

```text
bash c diff go html javascript java jsdoc json lua luadoc luap
markdown markdown_inline printf python query regex ruby sql
toml tsx typescript vim vimdoc xml yaml
```

**注意：列表里没有 `cobol`。**

### COBOL 的实际情况

| 能力 | COBOL 是否可用 |
|---|---|
| 语法高亮 | 部分（靠 `cobol.nvim` 的正则高亮） |
| 折叠 | **可用**（`cobol.nvim` 自己实现 Division/Section/Paragraph 折叠） |
| Treesitter 文本对象 | **不可用**（mini.ai 配置里主动返回空） |
| Flash 的 `S` 按键 | 可用；当前映射是普通字符跳转，不依赖 Treesitter 节点 |

`cobol.nvim` 在配置里说明了：

```lua
function M.attach(bufnr)
  setup_comment_syntax(bufnr)
  setup_folding(bufnr)
  ...
```

折叠由插件自己的 `folding.lua` 提供，不依赖 Treesitter。

### 装 COBOL parser 会怎样

插件仓库带 `tree-sitter-cobol` 子目录，可以自己编译：

```sh
cd ~/development/cobol.nvim/tree-sitter-cobol
make
```

安装后可供 Treesitter 查询使用；Flash 的 `S` 当前映射为普通字符跳转，mini.ai 的部分 Treesitter 文本对象仍受 COBOL filetype 防护。

## 3. 折叠（nvim-ufo）

`lua/plugins/ufo.lua`，provider 是 `{ "treesitter", "indent" }`：

1. 优先用 Treesitter 的折叠范围；
2. 没有 Treesitter 时退回按缩进折叠。

对 COBOL，`cobol.nvim` 会先接管折叠，`foldtext` 设为 `"auto"`：n-ufo 管着 buffer 时让它自己渲染，否则用插件的摘要格式。

### 折叠按键

| 按键 | 作用 |
|---|---|
| `za` | 开关当前折叠 |
| `zc` | 关闭 |
| `zo` | 打开 |
| `zR` | 全部打开 |
| `zM` | 全部关闭 |
| `zr` / `zm` | 逐层展开/收起 |

### 折叠显示

n-ufo 的自定义摘要形如：

```text
+-- 12 lines 󰁂
```

显示被折叠的行数。

## 4. 语法高亮

### 开启/关闭

```vim
:TSBufEnable highlight
:TSBufDisable highlight
```

一般不用手动管，打开文件自动启用。

### 查看当前 buffer 的 parser 状态

```vim
:InspectTree
```

显示语法树。COBOL buffer 里如果没有 parser 会提示。

### 安装新 parser

```vim
:TSInstall python
:TSUpdate
```

`ensure_installed` 列表里的会自动装；列表外的手动装。

## 5. COBOL 的实际体验

### 能用

- **折叠**（`cobol.nvim` 的 Division/Section/Paragraph 三级）
- **语法高亮**（`cobol.nvim` 的关键词高亮 + 层级高亮）
- **第 72 列越界告警**

### 不能用

- Treesitter 文本对象（`iao`、`iaf`、`iac`）
- Flash 的 Treesitter 节点选择（当前 `S` 映射是普通字符跳转，不使用此功能）
- `%` 的语法配对（`cobol.nvim` 有自己的 `%` 实现，跳 `IF`/`END-IF`）

**所以 COBOL 的结构能力来自 `cobol.nvim`，不是 Treesitter。** 理解这点能避免很多"为什么文档说能用我这里不行"的困惑。

## 6. 练习

### 练习 1：对比折叠质量

```sh
cd ~/development/cobol
nvim lessons/26_error-handling/lesson.cob
```

1. 找到一个 `IF ... END-IF` 块
2. `zc` 关闭
3. 观察折叠范围是否正好是 `IF` 到 `END-IF`

**验收**：折叠边界与 `END-IF` 对齐，不是按缩进猜的。

### 练习 2：检查 COBOL 是否有 parser

1. `:InspectTree`
2. 观察输出

**验收**：提示找不到 cobol parser（因为 `ensure_installed` 里没有），或显示不完整的树。

### 练习 3：对比有 parser 的语言

1. 打开任意 `.lua` 文件
2. `:InspectTree`

**验收**：完整语法树，能展开节点。

### 练习 4：装一个 parser 试试

```vim
:TSInstall python
```

然后用 `:InspectTree` 看 Python 文件的语法树。

**验收**：能看到完整的语法结构。这能帮助你理解「有 parser 和没 parser」的差别。

### 练习 5：折叠全部

1. 打开一个长 COBOL 文件
2. `zM` 全部折叠
3. 观察每个折叠的摘要行

**验收**：摘要显示行数（`⋯ N lines`），能快速看清文件结构。

## 7. 踩坑

### COBOL 里的 Flash 按键

`S` 和 `s` 都执行 Flash 字符跳转。`S` 不再调用 Treesitter 节点选择，因此不会因语法节点范围而表现为整块选择。

### 语法高亮不对

COBOL 的高亮来自 `cobol.nvim` 的正则实现，不是 Treesitter。某些结构可能高亮不完整。这是已知限制。

### `:TSInstall` 失败

需要编译工具链（`tree-sitter-cli` 或 C 编译器）。检查：

```sh
cc --version
```

### 折叠被 ufo 和 cobol.nvim 抢

`cobol.nvim` 的 `foldtext = "auto"` 会检测 ufo 是否在管。如果折叠显示不对，检查：

```vim
:set foldmethod?
```

COBOL buffer 里应该是 `expr`（由插件设置）。

### 装完 parser 后要重启

新装的 parser 需要重新打开 buffer 才生效。或者：

```vim
:edit
```

## 8. 官方文档

```vim
:h treesitter
:h nvim-ufo
```

- `nvim-treesitter`：<https://github.com/nvim-treesitter/nvim-treesitter>
- `nvim-ufo`：<https://github.com/kevinhwang91/nvim-ufo>

## 9. 边界

- `ensure_installed` 列表（`lua/plugins/treesitter.lua`）不含 `cobol`；本机 parser 由 `cobol.nvim` 构建脚本安装。COBOL 的折叠和高亮主要来自 `cobol.nvim`。
- mini.ai 的 Treesitter 文本对象仍对 COBOL filetype 返回空值；Flash 的 `S` 是普通字符跳转，不依赖该 parser。
- 本篇不覆盖手工编译 parser 的完整步骤；那属于插件开发范畴，见 `cobol.nvim` 仓库的 `scripts/build_parser.sh`。
