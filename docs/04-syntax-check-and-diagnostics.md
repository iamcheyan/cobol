# 第 4 课：GnuCOBOL 异步实时语法飞检与排错 (Async Compiler Diagnostics)

COBOL 的语法以“极端严肃”著称：漏写一个句号 `.`、段落名拼错一个字母、或者把语句写进了 Area A（第 8-11 列），都会引发编译器报错。

在传统开发模式下，程序员写完一大段代码后，必须切出终端去手动执行 `cobc` 编译，然后对着长串的编译错误日志一行行回头找代码，效率低下。

本课教你如何使用插件内置的 **GnuCOBOL 实时异步飞检引擎**，在 Neovim 内享受现代语言级别的红黄色波浪线诊断、精准错误高亮与 Quickfix 列表排错体验。

---

## 1. 核心理论：COBOL 新手最容易踩的三大深坑

### 1.1 深坑之一：句号（`.`）的致命陷阱
在 COBOL 中，句号 `.` 是语句块（Scope）的终结者。
* 如果在 `IF ... ELSE ...` 内部不小心提早打了一个句号 `.`，整个 `IF` 判定立刻强制提前结束！后面的代码无条件执行；
* 如果在一个段落或节末尾漏打了句号 `.`，编译器无法知道段落从何处结束，会报后续所有的标识符非法；
* 在 `DATA DIVISION` 中，每个变量定义行末尾**必须以句号 `.` 结尾**。

### 1.2 深坑之二：Area A 与 Area B 列错位
* 如果把具体的执行语句（如 `MOVE A TO B.`）顶格写在第 8 列（Area A），属于非法语法；
* 如果把段落名（如 `2000-PROCESS.`）缩进写在第 12 列（Area B），编译器会认为它是一条未知语句，而非段落标签。

### 1.3 深坑之三：未定义的段落与变量拼写
COBOL 标识符通常很长且由连字符连接（如 `WS-TOTAL-EMPLOYEE-SALARY`），手写极易拼错。调用了一个未定义的段落（如 `PERFORM 9999-NOT-FOUND.`），在编译时会被严正拦截。

---

## 2. 插件配备的语法飞检利器

1. **零阻塞异步飞检**：基于 Neovim 原生 `vim.system`，将编辑缓冲区通过管道实时推给 `cobc -fsyntax-only`，非阻塞后台运行，绝不卡死输入。
2. **全自动多重触发**：
   - 保存文件时（`BufWritePost`）自动飞检；
   - 键盘输入修改时（`TextChanged`）自动防抖 600 毫秒飞检；
   - 离开插入模式时（`InsertLeave`）立即校验。
3. **精准 Diagnostics 映射**：错误不是整行盲目下划线，而是精准高亮出错的标识符（如未定义的变量名或段落名）；
4. **Copybook 穿透标记**：引用的外部 `.CPY` 报错时，在主程序的 `COPY` 语句处醒目提示 `[In EMP-REC.CPY:5]`，且如果该 `.CPY` 在编辑区打开，也会在对应行同步标记；
5. **Quickfix 列表（`<leader>cq`）**：一键弹出 Neovim 原生错误列表，回车直达；
6. **手动即时飞检（`<leader>cl` / `:CobolLint`）**：主动检查当前代码，状态栏提示校验通过或错误数量。

---

## 3. 实操任务清单 (Step-by-Step)

打开测试文件开始演练排错：

```bash
cd /home/tetsuya/development/cobol
nvim INPUTCSV.COB
```

### 任务 4.1：体验无错误的正常代码校验
1. 文件打开后，在 Normal 模式下按下 **`<leader>cl`**（或输入命令 `:CobolLint`）；
2. **观察底部状态栏**：
   - 如果代码没有语法错误，弹出绿色提示：
     `COBOL: ✓ No syntax errors or warnings found by cobc.`
   - 如果存在告警，会提示：`COBOL: 0 error(s), 2 warning(s) detected.`。

### 任务 4.2：模拟未定义段落排错实操
1. 移动光标至第 85 行：
   ```cobol
              OPEN INPUT INPUT-FILE
                   OUTPUT OUTPUT-FILE.
   ```
2. 按 `V` 选中这两行，按 `c` 替换输入：
   ```cobol
              PERFORM 9999-NOT-FOUND.
   ```
3. 按 `<Esc>` 退出插入模式，并按 `:w` 保存文件；
4. **观察视觉反馈**：
   - 第 85 行下方**立即出现醒目的红色波浪下划线**！
   - 并且红色波浪线**精准紧贴在 `'9999-NOT-FOUND'` 这个标识符下方**！
5. 将光标移动到波浪线处，Neovim 浮窗立即弹出编译器真实报错：
   `'9999-NOT-FOUND' is not defined`。

### 任务 4.3：使用 Quickfix 集中浏览诊断（`<leader>cq`）
在大型工程中可能有多个报错，一个个滚动去找太慢。
1. 保持刚才的错误代码不变，按下 **`<leader>cq`**（或输入 `:CobolQuickfix`）；
2. **观察效果**：屏幕底部弹出了 Neovim 原生 Quickfix 列表：
   ```text
   || INPUTCSV.COB:85:23: '9999-NOT-FOUND' is not defined
   ```
3. 可以在 Quickfix 列表中按 `j`/`k` 移动，按下 **`<CR>`（回车）** 直达错误行！
4. 输入 `:cclose` 可以关闭 Quickfix 列表。

### 任务 4.4：体验修改防抖飞检与自动修复
1. 将光标移回第 85 行，按 `u` 撤销刚才的改动，恢复原来的 `OPEN INPUT INPUT-FILE` 代码；
2. 按 `:w` 保存文件；
3. **观察效果**：第 85 行的红色波浪线立即**自动彻底消失**！
4. 再次按下 **`<leader>cl`**，状态栏重新变绿：`COBOL: ✓ No syntax errors or warnings found by cobc.`。

### 任务 4.5：体验未保存状态下的实时防抖校验
甚至不需要按 `:w` 保存文件：
1. 找到第 100 行，在插入模式中故意少写一个参数或拼错保留字：
   ```cobol
              MOVE 1 TO
   ```
2. 停顿约 600 毫秒或按 `<Esc>` 退出插入模式；
3. **观察效果**：即使你**完全没有保存文件**，后台引擎也已经将当前内存内容发送给 `cobc` 并立刻在这一行标出了错误红色波浪线！
4. 补全语句 `MOVE 1 TO WS-FIELD-COUNT.`，波浪线下划线瞬间自动消解。

---

## 4. 本课速查总结

| 快捷键 / 命令 | 作用说明 |
|---|---|
| `<leader>cl` | **立即飞检**：后台运行 `cobc -fsyntax-only`，状态栏弹出诊断汇总反馈 |
| `<leader>cq` | **呼出 Quickfix 列表**：展示当前所有语法错误与告警，回车直达 |
| `:CobolLint` | 用户命令，等价于 `<leader>cl` |
| `:CobolQuickfix` | 用户命令，等价于 `<leader>cq` |
| `:CobolDiagnosticsToggle` | 用户命令，一键启用/禁用语法飞检 |
| `BufWritePost` | 保存文件时自动触发语法飞检 |
| `TextChanged` | 修改代码时以 600ms 防抖自动后台飞检 |
| `InsertLeave` | 退出插入模式时立即执行飞检 |
