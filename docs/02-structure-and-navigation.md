# 第 2 课：结构概览、大纲树与代码定义直达 (Structure, Outline & Jumps)

在大型机商业项目中，一个 COBOL 源码文件常常长达几千行甚至几万行。业务流程通过成百上千个 `PERFORM` 段落不断跳跃，数据字典通过大量的 Copybook（`.CPY`）互相引用。

如果没有现代 IDE 辅助，老程序员只能靠 `/` 手工搜索段落名，频繁在多个文件中切屏，极易打断思路。本课教你如何像现代开发一样，在 Neovim 中实现秒级大纲浏览、一键跳到定义、无缝原路跳回以及浮窗就地预览。

---

## 1. 核心理论：COBOL 的分层结构体系

COBOL 程序由四大部（Division）构成，自上而下严格排序：

```text
IDENTIFICATION DIVISION.       <-- 程序的身份证：程序名、作者、编写日期
ENVIRONMENT DIVISION.          <-- 运行环境与外部实体文件映射（SELECT ... ASSIGN TO）
DATA DIVISION.                 <-- 全局数据字典：文件记录结构（FILE SECTION）、工作变量（WORKING-STORAGE）
PROCEDURE DIVISION.            <-- 执行逻辑区：各种节（SECTION）与过程段落（PARAGRAPH）
```

在 `PROCEDURE DIVISION` 中：
- 一个 **SECTION（节）** 包含多个逻辑相关的段落；
- 一个 **PARAGRAPH（段落）** 是执行的最小命名单元（类似于函数，但没有入参和局部变量，所有数据全靠全局字段共享）；
- 调度控制使用 `PERFORM <段落名>`（类似子函数调用）或 `GO TO <段落名>`（无条件跳转）。

---

## 2. 插件配备的导航利器

1. **Winbar 动态面包屑**：标尺右侧常驻更新当前光标所在的 Division > Section > Paragraph 路径。
2. **Aerial 3 层符号侧边栏（`<leader>cs`）**：自动提取 Divisions -> Sections -> Paragraphs/Records，支持搜索与回车跳转。
3. **段落与数据定义一键直达（`gd`）**：光标停在 `PERFORM 1000-INITIALIZE` 或变量名上按 `gd` 瞬间跳至定义行。
4. **原生标签栈回跳（`<C-o>` / `<C-t>`）**：利用 Neovim 原生 Jumplist/Tagstack，看完定义后一键原路返回，绝不迷路。
5. **Copybook 悬停浮窗预览（`K`）**：光标在 `COPY "EMP-REC.CPY".` 上按 `K`，居中弹出语法高亮浮窗就地查阅，按 `q` 随手关闭。
6. **Copybook 实体文件直接打开（`gf`）**：按 `gf` 在当前窗口直接打开引用的 `.CPY` 实体文件。
7. **数据宿主行尾回溯**：深层嵌套字段行尾自动显示 `← 05 PARENT (01 ROOT)`。

---

## 3. 实操任务清单 (Step-by-Step)

打开测试源码继续演练：

```bash
cd /home/tetsuya/development/cobol
nvim INPUTCSV.COB
```

### 任务 2.1：体验 Winbar 实时动态面包屑
1. 观察窗口顶部 Winbar 最右侧的彩色面包屑标签；
2. 移动光标至第 1 行 `IDENTIFICATION DIVISION`，Winbar 显示 `[ IDENTIFICATION ]`；
3. 移动光标至第 40 行 `WORKING-STORAGE SECTION`，Winbar 变为绿色的 `[ DATA > WORKING-STORAGE ]`；
4. 移动光标至第 114 行 `2100-PROCESS-RECORD`，Winbar 变为亮蓝色的 `[ PROCEDURE > 2000-PROCESS-SECTION > 2100-PROCESS-RECORD ]`；
5. **体验收获**：无论你在代码中如何快速滚动，抬头一眼就能知道当前代码块位于整个系统架构的哪一个分支。

### 任务 2.2：使用 Aerial 3 层大纲侧边栏
1. 在 Normal 模式下按下 **`<leader>cs`**（或执行 `:AerialToggle!`）；
2. **观察左侧侧边栏**：
   - 顶层根节点：4 大 Division（带模块图标）；
   - 次层节点：`WORKING-STORAGE SECTION`、`1000-INIT-SECTION` 等；
   - 底层叶子：各个过程段落（如 `0000-MAIN`, `1000-INITIALIZE`, `2100-PROCESS-RECORD`）与 `01` 根级记录变量；
3. 在左侧侧边栏中用 `j`/`k` 光标移动到 `3000-PARSE-RECORD`，按下 **`<CR>`（回车）**；
4. **观察**：主编辑窗口瞬间精准平滑地跳转到第 134 行的 `3000-PARSE-RECORD.` 段落；
5. 在主窗口中按 `j`/`k` 移动代码光标，观察左侧侧边栏对应节点会双向联动高亮；
6. 再次按下 **`<leader>cs`** 随手收起大纲。

### 任务 2.3：段落与变量直达跳转（`gd` / `<C-o>`）
这是日常开发中最常用的高频组合技：
1. 移动光标到第 74 行：`PERFORM 1000-INITIALIZE`；
2. 将光标放在单词 `1000-INITIALIZE` 上，按下 **`gd`**（Go to Definition）；
3. **观察**：光标瞬间跨越数十行，直达第 83 行的 `1000-INITIALIZE.` 段落定义顶格处；
4. 确认完逻辑后，按下 **`<C-o>`**；
5. **观察**：光标原路飞回第 74 行的 `PERFORM` 调用处！
6. 移动光标到第 84 行：`INITIALIZE WS-FLAGS WS-COUNTERS.`；
7. 将光标停在变量名 `WS-FLAGS` 上，按下 **`gd`**；
8. **观察**：光标直飞到数据部第 41 行 `01  WS-FLAGS.` 变量声明行！
9. 再次按下 **`<C-o>`** 原路跳回第 84 行。

> 💡 **技巧**：`gd` 与 `<C-o>` 在 Neovim 中形成完美的“前进-后退”工作流，彻底消除在几千行文件里上下滚动的疲惫。

### 任务 2.4：Copybook 浮窗就地预览（`K`）与文件打开（`gf`）
COBOL 大量依靠 Copybook（类似 C 语言的 `#include`）复用数据结构。
1. 移动光标到第 66 行：`COPY "EMP-REC.CPY".`；
2. 按下 **`K`**（悬停预览快捷键）；
3. **观察效果**：屏幕中央弹出一个带圆角边框的高亮浮动窗口，清晰展示了 `EMP-REC.CPY` 的内部代码：
   ```cobol
          01  EMP-RECORD.
              05  EMP-ID             PIC X(20).
              05  EMP-NAME.
                  10  EMP-FIRST-NAME PIC X(40).
                  10  EMP-LAST-NAME  PIC X(40).
              05  EMP-AGE            PIC 9(03).
              05  EMP-SALARY         PIC S9(07)V99 COMP-3.
   ```
4. 看完后按 **`q`** 或 **`<Esc>`**，浮窗平滑关闭，原编辑现场完好如初；
5. 在同一行按下 **`gf`**（Go to File）：Neovim 自动搜寻路径并直接打开该 `.CPY` 实体文件供你编辑；输入 `:bd` 或 `:b INPUTCSV.COB` 可切回主文件。
6. 光标停在第 75 行 `PERFORM 2000-PROCESS-FILE` 上按 **`K`**：浮窗直接弹出该过程段落的代码片段，按 `q` 随手退出。

### 任务 2.5：查看深层嵌套字段的宿主回溯
1. 移动光标到第 59 行：`10  IN-FULL-NAME         PIC X(80).`；
2. **观察行尾**：自动出现淡灰色斜体虚拟文本：`  ← 05 IN-NAME-GROUP (01 WS-INPUT-FIELDS)`；
3. 移动光标到第 46 行：`88  CONVERT-SUCCESS      VALUE "S".`；
4. **观察行尾**：自动显示 `  ← 05 WS-CONVERT-FLAG (01 WS-FLAGS)`；
5. **思考**：面对 5-10 层嵌套的超大 COBOL 报文时，再也不用往上数缩进找父对象了。

---

## 4. 本课速查总结

| 快捷键 | 模式 | 作用说明 |
|---|---|---|
| `<leader>cs` | Normal | 呼出/隐藏 Aerial 3 层层级大纲树（按回车跳转） |
| `gd` | Normal | 光标在段落名、变量名或 Copybook 上时，直达其定义所在行 |
| `<C-o>` | Normal | 原生跳回上一位置（与 `gd` 完美成对使用） |
| `K` | Normal | 悬停浮窗就地预览 Copybook 内容或目标段落代码片段，按 `q` 退出 |
| `gf` | Normal | 直接打开光标处的 Copybook 文件进行编辑 |
