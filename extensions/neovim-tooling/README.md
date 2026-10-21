# Neovim 编辑器辅助教程

这套教程讲的是**你本机 Neovim 配置里真正在用的工具**，分七类（含 COBOL 专用与通用能力）：

- **COBOL 专用**（01–07）：`cobol.nvim` 提供的固定格式标尺、结构导航、PIC 计算、GnuCOBOL 诊断。
- **通用编辑器能力**（08–17、19–35）：搜索、跳转、批量编辑、代码理解、Git、会话管理。

两类工具各有分工：COBOL 专用工具处理列位置和 Copybook；通用工具处理搜索、代码导航与批量编辑。

**不是主课的前置要求。** 这是可选工具资料，随时可按需查阅。教程使用 `extensions/standalone-examples/` 和 `lessons/` 中的真实文件。

## 环境前提

| 依赖 | 用于 |
|---|---|
| Neovim 0.10+ | 全部 |
| `cobol.nvim` | 01–07，以及 COBOL 相关的结构/诊断 |
| Tree-sitter parser | 语法高亮、折叠（**COBOL 无 parser**，见 16） |
| GnuCOBOL（`cobc`） | 语法诊断、编译 |
| Aerial、blink.cmp | 可选，缺了不影响其它功能 |

## 教程目录

现有 34 篇教程按编号顺序排列，覆盖 01–37（第 18、36、37 篇已撤下）。分类只是把相邻的教程归成一组，方便查找。

### 一、COBOL 专用：`cobol.nvim`

| 篇 | 主题 | 你会学会 |
|---|---|---|
| [01](tutorials/01-punchcard-and-ruler.md) | 固定格式列规则与列标尺 | 7/8/12/73 列的意义，越界告警 |
| [02](tutorials/02-structure-and-navigation.md) | 结构概览、大纲与定义跳转 | `gd` / `gf` / `K`，Aerial 大纲 |
| [03](tutorials/03-pic-and-memory-calculator.md) | PIC 与内存计算 | `:CobolCalcRecord` 估算字节数 |
| [04](tutorials/04-syntax-check-and-diagnostics.md) | 语法检查与诊断 | `cobc` 诊断接入编辑器 |
| [05](tutorials/05-compilation-and-workflow.md) | 编译和工作流 | 构建、运行、错误定位 |
| [06](tutorials/06-practical-examples-guide.md) | 实战示例 | 四个独立示例配合插件 |
| [07](tutorials/07-cobol-nvim-plugin-lab.md) | 插件练习 | 综合演练 |

### 二、找到并改动：多光标、搜索与替换

| 篇 | 主题 | 你会学会 |
|---|---|---|
| [08](tutorials/08-multicursor-batch-editing.md) | 多光标批量编辑 | `Ctrl-n`、`Ctrl+Shift+n`、`gaip`、`C`、`ci"` |
| [09](tutorials/09-snacks-picker.md) | 文件与内容搜索（snacks picker） | `ff`/`fg`/`fw`，picker 内部按键，quickfix 流转 |
| [10](tutorials/10-flash-jump.md) | 屏幕内快速跳转（flash） | `s`/`S`，配合操作符 |
| [11](tutorials/11-grug-far.md) | 跨文件查找替换（grug-far） | `<leader>sr`，匹配数安全检查，分级替换 |

### 三、编辑辅助

| 篇 | 主题 | 你会学会 |
|---|---|---|
| [12](tutorials/12-mini-ai-textobjects.md) | 文本对象（mini.ai） | 按语义边界选中，`cia`/`ciq`/`g` |
| [13](tutorials/13-mini-surround.md) | 包围符号（mini.surround） | `gsa`/`gsd`/`gsr` |
| [14](tutorials/14-smart-paste.md) | 智能粘贴 | 保持相对缩进，重排到当前行 |

### 四、代码理解

| 篇 | 主题 | 你会学会 |
|---|---|---|
| [15](tutorials/15-lsp-code-intelligence.md) | LSP 代码智能 | 跳转/引用/重命名，**COBOL 没有 LSP** |
| [16](tutorials/16-treesitter-and-folding.md) | 语法解析与折叠 | Treesitter 能力边界，COBOL 折叠来源 |
| [17](tutorials/17-aerial-outline.md) | 代码大纲（aerial） | `<leader>cs`，COBOL 专用 backend |

### 五、Git 操作

| 篇 | 主题 | 你会学会 |
|---|---|---|
| [19](tutorials/19-gitsigns.md) | 行级 Git 操作 | hunk 暂存/重置，blame |
| [20](tutorials/20-diffview.md) | 完整差异与历史 | 并排 diff，文件历史 |

### 六、会话与发现

| 篇 | 主题 | 你会学会 |
|---|---|---|
| [21](tutorials/21-auto-session.md) | 会话保存与恢复 | 按目录保存布局 |
| [22](tutorials/22-which-key.md) | 按键发现 | `<leader>` + 停顿，逐层展开 |
| [23](tutorials/23-quicker.md) | quickfix 上下文展开 | `>`/`<` 展开结果上下文 |

### 七、界面与外观

| 篇 | 主题 | 你会学会 |
|---|---|---|
| [24](tutorials/24-bufferline.md) | 缓冲区标签栏 | 顶部标签、改动标记 |
| [25](tutorials/25-noice.md) | 消息与命令行 | 命令行、复制提示、确认框 |
| [26](tutorials/26-dashboard.md) | 启动页 | 最近文件、快捷入口 |
| [27](tutorials/27-ccc-color.md) | 颜色编辑 | 拾色器、格式转换 |
| [28](tutorials/28-satellite.md) | 边缘滚动标记 | 改动/诊断/搜索的分布 |
| [29](tutorials/29-rainbow-delimiters.md) | 彩虹括号 | 嵌套层级着色 |
| [30](tutorials/30-markview.md) | Markdown 渲染 | 标题/表格/代码块 |

### 八、辅助与其它

| 篇 | 主题 | 你会学会 |
|---|---|---|
| [31](tutorials/31-mini-pairs.md) | 自动配对 | `(` `"` 自动补全与跳过 |
| [32](tutorials/32-contextline.md) | 面包屑下拉 | 结构菜单（COBOL 里通常为空） |
| [33](tutorials/33-bookmark.md) | 书签 | 标记位置，`]b` / `[b` 跳转 |
| [34](tutorials/34-batch-and-shellcheck.md) | 批处理与 Shell 检查 | `.bat` 支持、`shellcheck` 诊断 |
| [35](tutorials/35-vimquest.md) | 英语词汇练习 | 在代码里练英语（不影响开发） |

## 建议学习顺序

**如果时间有限**，按这个顺序学四篇，覆盖 80% 日常操作：

1. **[22 which-key](tutorials/22-which-key.md)** —— 先学会怎么发现其它键
2. **[09 snacks picker](tutorials/09-snacks-picker.md)** —— 找文件、搜内容
3. **[19 gitsigns](tutorials/19-gitsigns.md)** —— 看清楚自己改了什么
4. **[08 多光标](tutorials/08-multicursor-batch-editing.md)** —— 一次改很多处

**如果要处理 COBOL 代码**，再加：

5. [01 列规则](tutorials/01-punchcard-and-ruler.md) —— 固定格式的基础
6. [17 aerial](tutorials/17-aerial-outline.md) —— COBOL 段落结构

**如果要改课程文档**，再加：

7. [11 grug-far](tutorials/11-grug-far.md) —— 跨文件批量替换
8. [20 diffview](tutorials/20-diffview.md) —— 审查改动

## 阅读约定

每篇的结构是统一的：

| 小节 | 内容 |
|---|---|
| 它解决什么问题 | 用对比表说明不用它的代价 |
| 你的实际配置 | 从 `lua/plugins/*.lua` 摘出的真实配置 |
| 按键表 | 你的配置里实际可用的键 |
| 实测记录 | 真实会话中的观察（标注为"实测"） |
| 练习 | 带**验收标准**的具体操作 |
| 踩坑 | 常见失败原因 |
| 官方文档 | `:help` 主题和仓库链接 |
| 边界 | 哪些限制来自你的配置而非插件默认 |

**"实测记录"只出现在真正跑过的操作上。** 没验证的步骤会明确标注为"建议先练习"或"未验证"。

## 与主课的关系

32 课主课教 COBOL 语言本身。这些教程教**怎么用编辑器高效地写和改 COBOL**。

- 主课不依赖这些教程。
- 但这些教程反复用到主课里的文件（第 17 课的定长记录、第 20 课的匹配、第 32 课的毕业项目）。
- 建议：**先读主课对应章节，再用教程练手**，效果最好。

## 参考

- Neovim 官方文档：`:help`
- 你的配置仓库：`~/nvim`
- 插件的逐项速查：`~/nvim/docs/plugins/PLUGINS.md`（47 个插件，每个 5 个小节，比本教程浅但覆盖广）
