# 结构概览、大纲与定义跳转

在大型机商业项目中，COBOL 程序会由多个 `PERFORM` 段落和 Copybook（`.CPY`）共同组成，阅读时需要追踪业务流程与数据定义之间的关系。

如果没有现代 IDE 辅助，老程序员只能靠 `/` 手工搜索段落名，频繁在多个文件中切屏，极易打断思路。本页演示如何用 `cobol.nvim` 在 Neovim 中浏览大纲、跳到定义、原路跳回以及浮窗就地预览。

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

1. **Winbar 动态面包屑**：窗口顶部常驻更新当前光标所在的 Division / Section / Paragraph 路径。
2. **Aerial 结构大纲**：Aerial 是可选的 Neovim Outline 插件；本插件的 Aerial backend 提供 Division、Section、Paragraph、FD/SD 与 01 记录符号。使用 `:AerialToggle` 打开；本插件不默认绑定 `<leader>cs`。
3. **段落与数据定义一键直达（`gd`）**：光标停在 `PERFORM 1000-INITIALIZE` 或变量名上按 `gd` 瞬间跳至定义行。
4. **跳转返回（`<C-o>` / `<C-i>`）**：使用 Neovim 原生 jumplist 返回上一个位置或前进。
5. **Copybook 预览（`K`）**：光标在 `COPY "EMP-REC.CPY".` 上按 `K`，在浮窗中查看内容；按 `q` 或 `<Esc>` 关闭。
6. **Copybook 文件跳转（`gf`）**：按 `gf` 打开当前 `COPY` 引用的 `.CPY` 文件。
7. **数据宿主提示**：深层字段旁显示父级名称，便于追踪数据层级。
8. **Tree-sitter 结构范围**：解析器可用时，高亮光标所在最内层已配对结构的起止关键字，并绘制连接线；`ELSE` / `WHEN` 分支也可显示标记。
9. **结构配对移动与文本对象**：`%` 在开始/结束关键字间移动；`af`/`if`、`ae`/`ie`、`ap`/`ip` 分别选中 IF、EVALUATE、PERFORM 内外范围。

![IF、ELSE、END-IF 结构范围标记与结构大纲](images/structure-scope.png)

此真实 Neovim 截图显示 Syms 大纲、Winbar 面包屑，以及当前 IF 块的开始、分支、结束标记和连接虚线。Syms 是截图中的外部大纲界面；插件自带的 Aerial 后端另见下图。

![Aerial COBOL 结构大纲](images/aerial-outline.png)

Aerial 是可选依赖。图中展示大纲与 COBOL 源码的联动；本插件不默认绑定 `<leader>cs`，打开大纲可用 `:AerialToggle`，快捷键须由用户配置。

---

## 3. 实操任务清单 (Step-by-Step)

打开测试源码继续演练：

```bash
cd <仓库根目录>
nvim extensions/standalone-examples/INPUTCSV.COB
```

### 任务 2.1：体验 Winbar 实时动态面包屑
1. 观察窗口顶部的面包屑，它随光标所在位置实时更新；
2. 移动光标至 `IDENTIFICATION DIVISION`，Winbar 显示 `[ IDENTIFICATION DIVISION ]`；
3. 移动光标至 `WORKING-STORAGE SECTION` 下任一数据行，Winbar 显示 `[ DATA DIVISION ]`；
4. 移动光标至 `2100-PROCESS-RECORD`，Winbar 显示 `[ PROCEDURE DIVISION > 2000-PROCESS-SECTION > 2100-PROCESS-RECORD ]`；
5. **体验收获**：无论你在代码中如何快速滚动，抬头一眼就能知道当前代码块位于整个系统架构的哪一个分支。

### 任务 2.2：使用 Aerial 3 层大纲侧边栏

Aerial 是可选的 Neovim 代码结构大纲插件。安装并配置后，`:AerialToggle` 打开大纲；本插件提供 COBOL 符号后端，但不默认绑定 `<leader>cs`。
1. 执行 `:AerialToggle` 打开可选 Aerial 大纲；
2. **观察左侧侧边栏**：
   - 顶层根节点：4 大 Division（带模块图标）；
   - 次层节点：`WORKING-STORAGE SECTION`、`1000-INIT-SECTION` 等；
   - 底层叶子：各个过程段落（如 `0000-MAIN`, `1000-INITIALIZE`, `2100-PROCESS-RECORD`）与 `01` 根级记录变量；
3. 在左侧侧边栏中用 `j`/`k` 光标移动到 `3000-PARSE-RECORD`，按下 **`<CR>`（回车）**；
4. **观察**：主编辑窗口瞬间精准平滑地跳转到 `3000-PARSE-RECORD.` 段落；
5. 在主窗口中按 `j`/`k` 移动代码光标，观察左侧侧边栏对应节点会双向联动高亮；
6. 再次执行 `:AerialToggle` 收起大纲。

### 任务 2.3：段落与变量直达跳转（`gd` / `<C-o>`）
这是日常开发中最常用的高频组合技：
1. 移动光标到 `PERFORM 1000-INITIALIZE`；
2. 将光标放在单词 `1000-INITIALIZE` 上，按下 **`gd`**（Go to Definition）；
3. **观察**：光标跳到 `1000-INITIALIZE.` 段落定义；
4. 确认完逻辑后，按下 **`<C-o>`**；
5. **观察**：光标原路飞回 `PERFORM` 调用处！
6. 移动光标到 `INITIALIZE WS-FLAGS WS-COUNTERS.`；
7. 将光标停在变量名 `WS-FLAGS` 上，按下 **`gd`**；
8. **观察**：光标跳到 `01 WS-FLAGS` 变量声明行。
9. 再次按下 **`<C-o>`** 原路跳回调用处。

> 💡 **技巧**：`gd` 与 `<C-o>` 在 Neovim 中形成完美的“前进-后退”工作流，彻底消除在多个定义间反复搜索的疲惫。

### 任务 2.4：Copybook 浮窗就地预览（`K`）与文件打开（`gf`）
COBOL 大量依靠 Copybook（类似 C 语言的 `#include`）复用数据结构。
1. 移动光标到 `COPY "EMP-REC.CPY".`；
2. 按下 **`K`**（悬停预览快捷键）；
3. **观察效果**：屏幕中央弹出预览浮窗，显示 `EMP-REC.CPY` 的内容：
   ```cobol
          01  EMP-RECORD.
              05  EMP-ID                   PIC X(05).
              05  EMP-NAME.
                  10  EMP-FIRST-NAME       PIC X(10).
                  10  EMP-LAST-NAME        PIC X(10).
              05  EMP-DEPT                 PIC X(02).
                  88  DEPT-SALES           VALUE "01".
                  88  DEPT-DEV             VALUE "02".
                  88  DEPT-HR              VALUE "03".
              05  EMP-SALARY               PIC S9(7) COMP-3.
              05  EMP-STATUS               PIC X(01).
   ```
4. 看完后按 **`q`** 或 **`<Esc>`**，浮窗平滑关闭，原编辑现场完好如初；
5. 在同一行按下 **`gf`**（Go to File）：Neovim 自动搜寻路径并直接打开该 `.CPY` 实体文件供你编辑；输入 `:bd` 或 `:b INPUTCSV.COB` 可切回主文件。
6. 光标停在 `PERFORM 2000-PROCESS-FILE` 上按 **`K`**：浮窗直接弹出该过程段落的代码片段，按 `q` 随手退出。

### 任务 2.5：查看深层嵌套字段的宿主回溯
1. 移动光标到 `10  IN-FULL-NAME         PIC X(80).`；
2. **观察行尾**：若层级提示已启用，会显示类似 `← 05 IN-NAME-GROUP (01 WS-INPUT-FIELDS)` 的父级信息；
3. 移动光标到 `88  CONVERT-SUCCESS      VALUE "S".`；
4. **观察行尾**：同样可查看其父级字段信息。
5. **思考**：面对 5-10 层嵌套的超大 COBOL 报文时，再也不用往上数缩进找父对象了。

---

![Copybook 预览浮窗](images/copybook-preview.png)

在 `COPY` 语句上按 `K` 后，浮窗显示 Copybook 内容，无需离开当前编辑位置。

## 4. 速查总结

| 快捷键 | 模式 | 作用说明 |
|---|---|---|
| `:AerialToggle` | 命令行 | 打开或关闭可选 Aerial 大纲（需先安装并配置） |
| `gd` | Normal | 光标在段落名、变量名或 Copybook 上时，直达其定义所在行 |
| `<C-o>` | Normal | 原生跳回上一位置（与 `gd` 完美成对使用） |
| `K` | Normal | 悬停浮窗就地预览 Copybook 内容或目标段落代码片段，按 `q` 退出 |
| `gf` | Normal | 直接打开光标处的 Copybook 文件进行编辑 |
