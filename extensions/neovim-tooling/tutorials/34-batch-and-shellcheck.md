# 批处理脚本与 Shell 检查：batch.nvim / nvim-lint

COBOL 课程里有大量 `.sh` 脚本（`build.sh`、`check.sh`、`install-toolchain.sh`）。它们也是要读的代码。

这套配置给批处理脚本（`.bat`/`.cmd`）和 Shell 脚本提供了语言支持与 lint。

---

## 1. 它们解决什么问题

| 需求 | 没有支持 | 有支持 |
|---|---|---|
| `.bat` 文件语法高亮 | 纯文本 | `batch.nvim` 提供 |
| `.bat` 结构大纲 | 无 | `batch.nvim` 提供 |
| Shell 脚本查错 | 运行才发现 | `shellcheck` 实时提示 |

## 2. batch.nvim（Windows 批处理）

`lua/plugins/batch.lua`：

| 选项 | 值 | 含义 |
|---|---|---|
| `enable_diagnostics` | `true` | 启用诊断 |
| `enable_folding` | `true` | 启用折叠 |
| `enable_statusline` | `true` | 状态栏显示信息 |
| `map_keys` | `false` | **不映射按键** |

`ft = { "dosbatch" }` —— 只在 dosbatch 文件类型生效。

`map_keys = false` 是个重要选择：**不抢你的按键**。所有功能靠命令或 Aerial 访问。

### 与 Aerial 的配合

配置里 `batch.nvim` 是 `contextline.nvim` 的依赖，而 Aerial 的 backend 配置有：

```lua
dosbatch = { "batch" },
batch = { "batch" },
```

所以 `.bat` 文件可以在 Aerial 里看结构（`<leader>cs`）。

### COBOL 课程里的位置

课程主要是 Linux/Shell，但也有批处理相关内容。`extensions/enterprise-batch/` 是企业批处理课程（注意：那是 COBOL 批处理，不是 Windows `.bat`）。

## 3. nvim-lint + shellcheck（Shell 脚本）

`lua/plugins/shellcheck.lua`：

```lua
lint.linters_by_ft = {
  sh = { "shellcheck" },
  bash = { "shellcheck" },
}
```

触发时机：

```lua
vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
  callback = function(args)
    if vim.tbl_contains({ "sh", "bash" }, vim.bo[args.buf].filetype) then
      lint.try_lint("shellcheck")
    end
  end,
})
```

| 事件 | 作用 |
|---|---|
| `BufEnter` | 进入 buffer 时检查 |
| `BufWritePost` | 保存后检查 |
| `InsertLeave` | 退出插入模式后检查 |

### 前提：装了 `shellcheck`

```sh
which shellcheck
```

没装的话 lint 静默跳过（不报错，也不提示）。

安装：

```sh
sudo apt install shellcheck
```

### 诊断显示

`shellcheck` 的警告以诊断形式显示（行内 mark），和 `cobc` 的诊断一样：

- 引号未加导致的分词问题
- 未使用的变量
- 可移植性问题
- 常见的拼写错误

## 4. COBOL 课程里的实际价值

### 场景一：检查课程脚本

课程里有：

```sh
lessons/32_bank-reconciliation-project/build.sh
lessons/32_bank-reconciliation-project/check.sh
lessons/29_embedded-sql/install-toolchain.sh
extensions/standalone-examples/ 里的 Makefile 相关脚本
```

打开 `.sh` 文件，`shellcheck` 会标出潜在问题。

### 场景二：写构建脚本时

改 `build.sh` 时，保存就检查，不用跑一遍才发现语法问题。

### 场景三：学习 Shell 最佳实践

`shellcheck` 的提示本身就是 Shell 教材——它会告诉你为什么某种写法有风险。

## 5. 练习

### 练习 1：确认 shellcheck 装了没

```sh
which shellcheck || echo "not installed"
```

**验收**：装了会显示路径，没装会提示。

### 练习 2：打开一个脚本看诊断

```sh
cd ~/development/cobol
nvim lessons/32_bank-reconciliation-project/build.sh
```

1. 观察是否有诊断标记
2. 保存一次（`:w`）确保触发

**验收**：如果脚本有问题，会出现诊断标记。没问题则无标记（两者都正常）。

### 练习 3：故意引入一个问题

1. 在脚本里写 `echo $UNQUOTED_VAR`（不加引号）
2. `:w`
3. 观察

**验收**：`shellcheck` 提示变量应加引号。改回去后标记消失。

### 练习 4：确认只在 sh/bash 生效

1. 打开一个 `.cob` 文件
2. 故意写点什么
3. `:w`

**验收**：**没有** shellcheck 诊断（因为只对 sh/bash）。

### 练习 5：batch.nvim 不抢键

```vim
:verbose nmap <buffer>
```

在一个 `.bat` 文件里（如果有），确认没有 batch.nvim 的按键（`map_keys = false`）。

## 6. 踩坑

### shellcheck 没生效

检查：

1. 装了 `shellcheck` 吗：`which shellcheck`
2. 文件类型是 `sh` 或 `bash` 吗：`set ft?`

没装就静默跳过。

### 诊断太多看不过来

`shellcheck` 默认检查很严格。可以在脚本里加注释禁用某条：

```sh
# shellcheck disable=SC2086
```

或配置 `shellcheck` 的 `-e` 参数。

### `.bat` 文件没有高亮

`batch.nvim` 的 `ft = { "dosbatch" }` 限定。确认文件类型：

```vim
:set ft?
```

### batch.nvim 没按键

**这是配置有意的**（`map_keys = false`）。用 Aerial 或命令访问。

### 与 conform 的 shfmt 冲突

conform 用 `shfmt` 格式化 Shell，lint 用 `shellcheck` 检查。**一个管格式，一个管错误**，不冲突。

### 大脚本检查慢

`shellcheck` 是外部进程。很大的脚本可能卡一下。这是正常的。

## 7. 官方文档

- `nvim-lint`：<https://github.com/mfussenegger/nvim-lint>
- `batch.nvim`：<https://github.com/iamcheyan/batch.nvim>
- `shellcheck`：<https://www.shellcheck.net/>

## 8. 边界

- `shellcheck` 需要外部安装；没装时 lint **静默跳过**（不报错）。
- nvim-lint 只对 `sh` / `bash` 生效，与其它文件类型无关。
- `batch.nvim` 的 `map_keys = false` 是刻意的不抢键设计。
- 本课程主体是 COBOL，Shell 脚本只是辅助；这两项属于"顺带支持"。
