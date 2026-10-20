# quickfix 增强：quicker.nvim

`:copen` 打开的 quickfix 列表，默认只显示一行摘要——**看不到上下文，判断不了这是不是你要找的那处**。

quicker.nvim 给 quickfix 加上「展开上下文」：按 `>` 显示命中行前后各 2 行，按 `<` 收起。

---

## 1. 它解决什么问题

| 需求 | 原生 quickfix | quicker |
|---|---|---|
| 看命中行的上下文 | 跳过去看，再跳回来 | `>` 就地展开 |
| 判断这处是不是要找的 | 需要来回跳 | 一眼看到周围几行 |
| 编辑结果 | 只能跳转 | 可以就地编辑 |

## 2. 你的配置

`lua/plugins/quicker.lua`：

```lua
{
  "stevearc/quicker.nvim",
  ft = "qf",
  opts = {
    keys = {
      {
        ">",
        function()
          require("quicker").expand({ before = 2, after = 2, add_to_existing = true })
        end,
        desc = "Expand quickfix context",
      },
      {
        "<",
        function() require("quicker").collapse() end,
        desc = "Collapse quickfix context",
      },
    },
  },
}
```

| 参数 | 值 | 含义 |
|---|---|---|
| `before` | 2 | 展开时显示命中行**前面** 2 行 |
| `after` | 2 | 显示**后面** 2 行 |
| `add_to_existing` | `true` | 再按 `>` 时叠加（连续展开更多行） |

`ft = "qf"` 表示只在 quickfix buffer 里加载。

## 3. 按键

| 按键 | 作用 |
|---|---|
| `>` | 展开上下文（前 2 行 + 后 2 行） |
| `<` | 收起 |
| `<Tab>` | 展开并跳到下一处 |
| `<S-Tab>` | 展开并跳到上一处 |
| `q` | 关闭 quickfix |

`>` 可以连按，每次再展开更多（`add_to_existing = true`）。

## 4. 完整工作流

### 从搜索到 quickfix

```text
1. <leader>fg            搜内容
2. 输入搜索词
3. <C-q                 结果全部送进 quickfix
4. :copen               打开列表
5. >                    展开当前项上下文
6. j / k                在结果间移动
7. Enter                跳到源码位置
```

### 从诊断到 quickfix

```text
1. <leader>xq           诊断送进 quickfix
2. :copen
3. >                    展开看错误上下文
```

## 5. COBOL 场景

### 场景一：确认某处引用是不是你要改的

用 `<leader>fw` 搜 `WS-RECORD-COUNT`，命中 30 处。问题是：**哪些是声明，哪些是使用？**

1. `<C-q>` 送进 quickfix
2. `:copen`
3. `>` 展开第一处 → 看到 `01 WS-RECORD-COUNT PIC 9(2).` 上下几行

**展开后一眼看出这是 WORKING-STORAGE 声明区，不是使用点。** 比 `Enter` 跳过去再跳回来快得多。

### 场景二：审查批量替换的影响范围

grug-far 改了 8 个文件后，想确认每处改动是否合理：

1. `<leader>fg` 搜改后的新模式
2. `<C-q`
3. `:copen`
4. 逐个 `>` 展开审查

### 场景三：看编译诊断的上下文

COBOL 报错说某行少了句点：

1. `<leader>xq`
2. `:copen`
3. `>` 展开 → 看到前一条语句和后面几条

**COBOL 的句点错误往往要看上下文才能定位**——单独一行看不出问题。

### 场景四：跨课的同类问题

搜 `PIC 9(2)` 找出所有两位计数器的位置，展开后能看出哪些可能溢出（第 17 课讨论过 `WS-RECORD-COUNT` 只能是 `00`–`99`）。

## 6. 练习

### 练习 1：基本展开

```sh
cd ~/development/cobol
nvim
```

1. `<leader>fg` → 搜 `WS-RECORD-COUNT`
2. `<C-q>` 送进 quickfix
3. `:copen`
4. 按 `>`

**验收**：当前命中行上方出现 2 行、下方出现 2 行上下文，带行号。

### 练习 2：叠加展开

1. 接着上一步，再按 `>`

**验收**：上下文扩展到 4 行（`add_to_existing = true`）。

### 练习 3：收起

1. 按 `<`

**验收**：回到单行显示。

### 练习 4：在结果间移动并展开

1. `j` 移到下一处
2. `>`
3. 再 `j`，再 `>`

**验收**：每处都能独立展开，已展开的保持展开。

### 练习 5：跳转

1. 在某处按 `Enter`

**验收**：跳到源码中的对应位置。`:copen` 能回来。

### 练习 6：诊断场景

1. 打开 COBOL 文件，删掉一个句点
2. `:w` 保存触发诊断
3. `<leader>xq`
4. `:copen` + `>`

**验收**：能看到错误行的上下文。改回去（`u`）。

## 7. 踩坑

### `>` 没反应

只在 **quickfix buffer** 里生效（`ft = "qf"`）。确认当前窗口是 quickfix：

```vim
:echo &filetype
```

应该输出 `qf`。

### 展开后看不到完整函数

`before = 2, after = 2` 是固定行数。上下文不够就多按几次 `>`（叠加展开）。

### `>` 和 `<` 与其它插件冲突

在普通 buffer 里这两个键是**缩进/反缩进**。quicker 的绑定只作用于 quickfix buffer，不冲突。

### quickfix 列表为空

`:copen` 打开但没有内容，说明没往里送东西。先用 `<C-q>`（snacks）或 `<leader>xq`（诊断）。

### 编辑后列表没更新

quickfix 的条目是快照。改了文件后，`:copen` 仍显示旧行号。重新搜索一次。

### 大列表展开很慢

展开会给每一条插入虚拟行。几百条时可能卡顿。先收起（`<`）再逐个展开。

## 8. 与其它插件的关系

| 想知道 | 用什么 |
|---|---|
| 搜内容并看结果 | `<leader>fg`（snacks） |
| 结果带上下文看 | `<C-q>` + `quicker` |
| 在结果间跳 | `:cnext` / `:cprev` 或 `j` / `k` |
| 看诊断 | `<leader>xq` + `quicker` |
| 改完看差异 | `<leader>gd`（diffview） |

**quicker 是 quickfix 的显示增强**，它不产生结果——结果来自搜索或诊断。

## 9. 官方文档

```vim
:h quicker
```

仓库：<https://github.com/stevearc/quicker.nvim>

## 10. 边界

- 本篇按键来自 `lua/plugins/quicker.lua`：`>`、`<`，参数 `before = 2`、`after = 2`、`add_to_existing = true`。
- `>` 和 `<` 只在 `qf` filetype 的 buffer 里是这个含义；普通 buffer 里仍是缩进。
- quicker 不负责产生 quickfix 内容，需要先 `<C-q>`（snacks）或 `<leader>xq`（诊断）。
- quickfix 是快照：文件改动后行号会失效，需要重新搜索。
