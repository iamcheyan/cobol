# 课程站翻译工作区

本目录存放课程网站的英文（`en/`）与日文（`ja/`）译稿。网站构建脚本
`scripts/build_site.py` 会把每个语言渲染成一套完整站点（`/zh-cn/`、`/en/`、`/ja/`）；
缺失译稿的文件会自动回退到中文原文，并在页面上标注“翻译准备中”，因此可以分批、
增量地补齐，不会阻塞发布。

## 目录约定

译稿路径必须与仓库中的源文件完全一致，只是根目录换成 `site-src/translations/<locale>/`：

| 源文件 | 英文译稿 | 日文译稿 |
|---|---|---|
| `lessons/01_hello-cobol/README.md` | `site-src/translations/en/lessons/01_hello-cobol/README.md` | `site-src/translations/ja/lessons/01_hello-cobol/README.md` |
| `lessons/01_hello-cobol/lesson.cob` | `site-src/translations/en/lessons/01_hello-cobol/lesson.cob` | `site-src/translations/ja/lessons/01_hello-cobol/lesson.cob` |
| `extensions/README.md` | `site-src/translations/en/extensions/README.md` | `site-src/translations/ja/extensions/README.md` |

`site-src/translation-manifest.json` 列出了全部待译文件（约 1300 项，含课程文档、
源码与文本夹具）。

## 翻译规则（必须严格遵守）

- **只翻译，不创作**：不扩写、不删节、不改写结论、不增加或删除示例、链接、表格行与章节。
- **结构保持不变**：标题层级、表格行列、列表层级、代码围栏、行内代码与链接目标必须与源文件一一对应。
- **代码保真**：Markdown 代码块内的程序代码原样保留；COBOL 源文件只翻译第 7 列 `*` 注释的文字，
  其余行必须逐字节一致，注释不得越过第 72 列（按 UTF-8 字节数计算）。
- **术语一致**：GnuCOBOL、COBOL、Copybook、PIC、Area A/Area B、Embedded SQL 等沿用技术惯用写法；
  命令、文件名、程序标识、输出字面量保持原样。
- **不做机翻半成品**：一个文件要么完整翻译并按检查脚本通过，要么不提交该文件。

## 校验

```sh
python3 scripts/check_translations.py
```

脚本会统计各语言完成度，并对已存在的译稿做结构校验：标题数、代码围栏、表格行、
链接目标集合、内联代码数量，以及 COBOL 非注释行的逐行一致性。硬性失败必须修正或移除；
内联代码数量差异只作为提示。

不合格的草稿统一放到 `_rejected/`，不要留在发布路径里。当前已撤下：
第 04 课英/日讲义（丢失表格行与链接）与第 02 课日文练习（新增原文没有的链接）。

## 构建

```sh
python3 scripts/build_site.py
```

输出到 `build/site/`（已忽略提交），由 GitHub Actions 发布到 GitHub Pages。
