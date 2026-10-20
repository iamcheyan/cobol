# 文件与内容搜索：snacks.nvim picker

你在一个 32 课的仓库里找一个字段名、翻一个 Copybook、跳到某个 `PERFORM` 段落。**搜索的效率直接决定你读代码的速度。**

`snacks.nvim` 的 picker 是当前配置的主力入口：找文件、搜内容、切缓冲区、翻帮助，都走同一个界面。学会它，剩下的插件才有意义。

本篇按你本地的实际配置写，不是通用教程。

---

## 1. 它解决什么问题

不用搜索时的三种低效做法：

| 做法 | 问题 |
|---|---|
| `:e path/to/file` | 路径要背，目录深了根本记不住 |
| `:vimgrep /pattern/ **/*` | 阻塞编辑器，结果挤在 quickfix |
| Neo-tree 一层层点 | 只看得见目录结构，看不见内容 |

picker 的做法：**输入几个字，实时过滤，右侧立刻显示预览**。不离开当前窗口就知道「是不是这个」。

## 2. 你的实际按键

配置在 `lua/config/keymaps-defaults.lua`，`<leader>` 是**空格**。

### 找文件

| 按键 | 作用 | 何时用 |
|---|---|---|
| `<leader><space>` | 找文件（项目根目录） | 最常用，肌肉记忆这一个就够 |
| `<leader>ff` | 找文件（当前 cwd） | 在子目录里工作，只想看这一片 |
| `<leader>fF` | 找文件（Git 根目录） | 在深层子目录，但想找全仓库的文件 |

**三者的区别只在搜索起点。** `<leader>fF` 会向上找 `.git` 再从那开始，所以在 `lessons/17_xxx/` 里也能搜到 `extensions/` 下的文件。

### 搜内容（grep）

| 按键 | 作用 |
|---|---|
| `<leader>fg` | 全仓库搜内容 |
| `<leader>fG` | 同上（配置里两个键指向同一实现） |
| `<leader>/` | 同上，另一个入口 |
| `<leader>fw` | **搜光标下的词**（cwd 范围） |
| `<leader>fW` | 搜光标下的词（根目录范围） |
| `<leader>fc` | 搜光标下的词 |

`<leader>fw` 是最省事的：光标停在 `WS-RECORD-COUNT` 上直接按，不用手打。

### 缓冲区与其它

| 按键 | 作用 |
|---|---|
| `<leader>fb` 或 `<leader>,` | 切换已打开的缓冲区 |
| `<leader>fr` | 最近打开的文件 |
| `<leader>fR` | **恢复上次的 picker**（结果还在） |
| `<leader>fh` 或 `<leader>?` | 搜帮助文档 |
| `<leader>fS` | 当前文件的 Treesitter 符号 |

`<leader>fR` 容易被忽略但很实用：搜了一半去改代码，回来按它，上次的搜索词和结果都还在。

## 3. picker 内部怎么操作

打开 picker 后，你面对三个区域：

```text
┌──────────────────────────────────────────────┐
│  输入框（输入即过滤）                          │
├────────────────────────┬─────────────────────┤
│  结果列表               │  预览（自动跟随）    │
│  ↑↓ 选择               │  带语法高亮          │
└────────────────────────┴─────────────────────┘
```

### 移动与打开

| 按键 | 作用 |
|---|---|
| 继续输入 | 实时过滤，结果立即变化 |
| `<C-n>` / `<C-p>` 或 `↑` `↓` | 上下移动选择 |
| `<CR>` | 打开（替换当前窗口） |
| `<C-s>` | 水平分割打开 |
| `<C-v>` | 垂直分割打开 |
| `<C-t>` | 新标签页打开 |
| `<Esc>` | 关闭 |

### 调整界面

| 按键 | 作用 |
|---|---|
| `<a-p>` | 开关预览窗 |
| `<a-m>` | 最大化 / 还原 |
| `<a-w>` | 在输入框和结果列表间切换焦点 |
| `/` | 切换焦点 |
| `<a-h>` | 显示/隐藏隐藏文件 |
| `<a-i>` | 显示/隐藏 gitignore 的文件 |
| `<a-r>` | 正则模式开/关 |
| `<a-f>` | 跟随（follow）模式 |
| `<C-d>` / `<C-u>` | 结果列表翻页 |
| `<C-f>` / `<C-b>` | 预览窗翻页 |
| `<a-d>` | 查看当前项的内部数据（调试用） |

### 把结果送到别处

| 按键 | 作用 |
|---|---|
| `<C-q>` | 全部结果送进 quickfix 列表 |
| `<Tab>` | 选中当前项并移到下一个（多选） |
| `<S-Tab>` | 选中并移回上一个 |
| `<c-a>` | 全选 |

`<C-q>` 值得单独练：把 grep 结果送进 quickfix 后，可以用 `:cnext` / `:cprev` 逐条跳，也能配合 `quicker.nvim` 展开上下文。

## 4. 实测记录

以下是在本仓库真实会话中的观察，不是推测。

### 找文件

按 `<leader>ff` 打开后，输入 `account-master`：

```text
lessons/17_fixed-length-files/account-master-200.dat
extensions/…/labs/03-one-to-many/starter/BATCHL2.COB
extensions/…/labs/04-many-to-many/starter/BATCHL3.COB
…
```

输入框右侧显示 `2624/2624`（匹配数/总数）。按 `<CR>` 打开后，**position-ruler 的列标尺立刻出现在窗口顶部**：

```text
1...+...10....+...20....+...30....+...40....+...50....+...60....+...70....+...80
0001234567C0001042TANAKA ICHIRO                 BR-TOKYO2020011520261014ORDINARY
```

这是两个插件协同的地方：picker 负责找到文件，position-ruler 负责让你看清定长记录的字段位置。

### 搜内容

按 `<leader>fg`，输入 `WS-RECORD-COUNT`：

```text
WS-RECORD-COUNT                        30/30

lessons/17_fixed-length-files/lesson.cob:42:10
lessons/17_fixed-length-files/lesson.cob:85:24
lessons/17_fixed-length-files/lesson.cob:106:48
lessons/17_fixed-length-files/README.md:119:27  计数字段宽度
lessons/…/lesson.cob:21:10        01 WS-RECORD-COUNT P
lessons/…/INPUTCSV.COB:50:15            05  WS-RECO
```

**30 处命中，跨 3 个以上文件**，每行都有 `文件:行:列`。右侧预览直接显示命中行的上下文，不用打开文件。

### 切缓冲区

按 `<leader>fb`：

```text
2/2
10  #a  account-master-200.dat:1:33
1    h  lesson.cob:1:6
```

显示缓冲区编号、修改标记（`#` = 有改动）、行:列位置。数字前缀就是 `<C-^` 能跳转的缓冲区号。

## 5. COBOL 开发中的五个高频用法

### 用法一：找所有用到某字段的地方

光标停在 `WS-ACCOUNT-STATUS` 上，按 `<leader>fw`。

结果立刻列出所有引用位置。这是改字段前**必须做的一步**——先知道有多少处要改，再决定用不用多光标（见[多光标那篇](08-multicursor-batch-editing.md)）。

### 用法二：跨课对照同一实现

想对比第 17 课和第 32 课的定长记录处理：

```text
<leader>ff → 输入 fixed-length → 选中目标
```

或者搜内容：`<leader>fg` → `RECORD CONTAINS 27`，一次看到所有相关课。

### 用法三：找 Copybook 定义

搜 `01  ACCOUNT-REC` 或 `PIC X(10)`，定位到 `.CPY` 文件里的声明。

配合 `<leader>fF`（Git 根目录搜索），即使在深层实验目录里也能搜到 `extensions/enterprise-batch/` 下的 Copybook。

### 用法四：快速确认某个键是否被占

按 `<leader>fh` 搜帮助，或 `<leader>?`。

想知道某个按键绑了什么，用 `:verbose nmap <leader>fw`，它会显示最终映射和定义在哪个文件。

### 用法五：结果送进 quickfix 逐条处理

grep 出 30 处 `WS-RECORD-COUNT` 后按 `<C-q>`：

```vim
:cnext    " 跳到下一处
:cprev    " 上一处
:copen    " 打开 quickfix 窗口查看全部
```

比在 picker 里来回切换更专注。

## 6. 练习

### 练习 1：找到并打开练习夹具

```sh
cd ~/development/cobol
nvim
```

1. `<leader>ff`
2. 输入 `account-master`
3. 按 `<CR>` 打开

**验收**：打开的是 `lessons/17_fixed-length-files/account-master-200.dat`，窗口顶部出现 `1...+...10` 这样的列标尺。

### 练习 2：用光标下的词搜索

在同一文件里，光标移到任意 `WS-` 开头的词（如果打开的是 `.dat` 就换到 `lesson.cob`）：

1. `<leader>fw`
2. 观察结果数量

**验收**：输入框已自动填入该词，结果列表显示所有引用位置。

**对比实验**：再用 `<leader>fg` 手动输入同一个词，结果应该一致——`<leader>fw` 只是帮你省了打字。

### 练习 3：quickfix 流转

1. `<leader>fg` → 输入 `FILE STATUS`
2. 按 `<C-q>` 把结果送进 quickfix
3. `:copen` 打开列表
4. `:cnext` 连续跳 3 次

**验收**：quickfix 窗口存在，`:cnext` 每次跳到一个新的 `FILE STATUS` 位置。

### 练习 4：恢复上次搜索

1. `<leader>fg` → 搜一个词
2. `<Esc>` 关闭
3. 编辑几下
4. `<leader>fR`

**验收**：picker 重新打开，搜索词和结果都还在。

### 练习 5：多选送 quickfix

1. `<leader>fg` → 搜 `PIC X(`
2. 用 `<Tab>` 选中前 3 条（每条选中后自动下移）
3. `<C-q>` 只把选中的送进 quickfix

**验收**：quickfix 里只有你选的那几条，不是全部。

## 7. 踩坑

### `<leader>ff` 找不到你想要的文件

三种可能：

1. **文件被 gitignore**：按 `<a-i>` 切换忽略状态。
2. **是隐藏文件**（`.` 开头）：按 `<a-h>`。
3. **不在当前 cwd 下**：换 `<leader>fF`（Git 根目录）。

### grep 搜不到

`<leader>fg` 走 ripgrep，默认尊重 `.gitignore`。搜 `build/site/` 里的生成文件时同样要按 `<a-i>`。

### `<Esc>` 之后光标还在 picker 里

配置里 `<Esc>` 是关闭 picker。如果你按了 `<C-c>`（插入模式下取消），会退回输入框而不是关闭——再按一次 `<Esc>`。

### 大仓库第一次搜索慢

ripgrep 首次扫描要建索引缓存，重复搜索会快很多。当前仓库 500+ 文件，正常范围是几百毫秒。

## 8. 与其它插件的关系

| 场景 | 用哪个 |
|---|---|
| 想找**文件** | `<leader>ff`（snacks） |
| 想找**内容** | `<leader>fg`（snacks） |
| 想跳**屏幕上的某个字符** | `s`（flash，见 [flash 那篇](10-flash-jump.md)） |
| 想**跨文件批量替换** | `<leader>sr`（grug-far，见 [grug-far 那篇](11-grug-far.md)） |
| 想读**目录结构** | `<leader>fe`（Neo-tree） |

**关键区分**：snacks 是「用文字找位置」，flash 是「用眼睛找位置」。前者适合你知道要找什么，后者适合你看见了但懒得数行。

## 9. 官方文档

```vim
:h snacks-picker
:h snacks-picker-config
```

仓库：<https://github.com/folke/snacks.nvim>

查看你当前的全部按键：

```vim
:map <leader>f
```

## 10. 边界

- 本篇按键来自你的本地配置（`lua/config/keymaps-defaults.lua`），不是插件默认值。升级配置后请用 `:map <leader>f` 复核。
- `<leader>fg` 和 `<leader>fG` 在配置里指向同一实现，没有实际区别。
- 实测记录来自 Neovim 真实会话；不同终端宽度下布局比例（`width = 0.85`）会让预览窗宽窄不同。
