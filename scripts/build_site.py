#!/usr/bin/env python3
"""Render the public COBOL course Markdown as a trilingual static website.

Each locale gets a complete copy of the site tree at ``build/site/<locale>/``.
Translations live in ``site-src/translations/<locale>/`` using the same relative
paths as the repository.  Any file without a translation falls back to the
Chinese original and is clearly marked as pending.
"""
from __future__ import annotations

import functools
import hashlib
import html
import json
import os
import re
import shutil
from pathlib import Path
from urllib.parse import quote

import markdown

from site_about import ABOUT
from site_reference import REFERENCE
from site_history import HISTORY
from site_glossary import GLOSSARY
from lesson_context import LESSON_CONTEXT
from site_glossary_japan import JAPAN_TERMS
from site_hardware import HARDWARE

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "build" / "site"
LESSONS = ROOT / "lessons"
EXTENSIONS = ROOT / "extensions"
TRANSLATIONS = ROOT / "site-src" / "translations"
EXCLUDED_PARTS = {"instructor", "tasks", "validation", "evidence", "grading"}
EXCLUDED_NAMES = {"AGENTS.md", "INSTRUCTOR.md", "manual-review-signoff.md", "SESSION-REPORT.md"}
EXCLUDED_SUFFIXES = {".pyc", ".db", ".sqlite", ".o", ".so", ".swp", ".tmp"}
TEXT_SUFFIXES = {".md", ".cob", ".cpy", ".cbsql", ".sql", ".txt", ".csv", ".dat", ".json", ".yml", ".yaml", ".sh", ".py"}

def asset_version() -> str:
    """Content hash so a CSS/JS change is never masked by an edge cache."""
    digest = hashlib.sha1()
    for name in ("site.css", "theme.css", "site.js"):
        digest.update((ROOT / "site-src" / name).read_bytes())
    return digest.hexdigest()[:10]


ASSET_VERSION = asset_version()

LOCALES = {
    "zh-cn": {
        "pager_prev": "上一课", "pager_next": "下一课",
        "pager_all": "全部课程", "pager_end": "完成全部 32 课",
        "html": "zh-CN", "name": "简体中文", "brand_sub": "实战课程",
        "nav_home": "课程首页", "nav_directory": "32 课目录", "nav_extensions": "拓展课程",
        "nav_source": "GitHub 源码", "nav_lang": "语言", "course_nav": "课程导航",
        "lesson_context_label": "现场工作",
        "course_expand": "展开课程目录",
        "course_collapse": "收起课程目录",
        "search": "筛选课程", "directory_link": "查看完整课程目录 →",
        "tab_guide": "课程讲义", "tab_exercise": "动手练习", "tab_answer": "参考答案", "tab_resources": "源码与资料",
        "download": "下载文件 ↓", "pending_page": "此内容的翻译正在准备中。以下先显示中文原文。",
        "pending_resource": "此文件暂无该语言版本，下面显示中文原文。",
        "source_format": "固定格式 COBOL · 80 列刻度",
        "source_scroll_hint": "左右滑动查看完整列 · 第 72 列为程序正文边界",
        "view_source": "查看中文原文 →", "unsupported": "此资源不适合直接预览，可下载后在本地打开。",
        "footer": "课程源码与练习材料",
        "footer_compiler": "配套编译器",
        "hero_eyebrow": "GNU COBOL · PRACTICAL COURSE",
        "hero_h1": "从第一条 COBOL 语句，", "hero_h1_em": "走到银行夜间对账系统。",
        "hero_intro": "一套循序渐进的 GnuCOBOL 实战课程。读讲解、运行程序、完成练习，逐步构建完整的批处理项目。",
        "hero_cta": "从第 01 课开始", "hero_cta2": "浏览全部课程",
        "path_eyebrow": "THE LEARNING PATH", "path_title": "六个阶段，完成一套课程", "path_link": "查看课程大纲 →",
        "stages": [
            ("01 — 08", "语言基础", "语句、数据与控制流"),
            ("09 — 14", "数据结构", "记录、表格与查找"),
            ("15 — 22", "文件处理", "CSV、排序与文件对账"),
            ("23 — 28", "工程化", "模块、接口与日志"),
            ("29 — 31", "数据库", "Embedded SQL 与同步"),
            ("32", "毕业项目", "银行对账批处理系统"),
        ],
        "start_eyebrow": "START HERE", "start_title": "每一课，都能动手运行",
        "start_text": "准备 GnuCOBOL 与 Make，从第一课开始编译、修改、练习。GnuCOBOL 源自日本开发者西田圭介发布的 OpenCOBOL，会先把 COBOL 翻译成 C，再调用系统的 C 编译器。Debian/Ubuntu 可用 apt 安装，在家用 Linux 就能练习本课程采用的固定格式；这不要求大型机，也不代表与主机生产环境完全相同。源码、输入数据和参考答案都与讲义一起浏览。",

        "start_term": "终端 · Debian / Ubuntu", "start_open": "打开第 01 课",
        "more_eyebrow": "BEYOND THE MAIN COURSE", "more_title": "继续探索",
        "more_kn": "知识库", "more_kn_desc": "语言背景、史话、速查手册与术语表",
        "more_ext": "拓展课程", "more_ext_desc": "旧版专题、企业批处理与编辑器教程",
        "more_src": "课程源码", "more_src_desc": "查看代码、夹具与构建脚本",
        "nav_plugins": "cobol.nvim",
        "nav_resources": "更多资料",
        "nav_gnucobol": "GnuCOBOL 官方",
        "more_gnu_desc": "配套编译器与官方文档",
        "nav_about": "COBOL 是什么", "nav_reference": "速查手册",
        "nav_knowledge": "知识库",
        "kn_eyebrow": "KNOWLEDGE BASE",
        "kn_title": "COBOL 知识库",
        "kn_lead": "除了 32 课主课程，这里还有四份资料：语言背景、发展史话、可随时查的速查手册，以及术语表。都不需要按顺序读。",
        "kn_note": "内容以 COBOL 的公开历史资料、ISO 标准编号与 GnuCOBOL 官方文档为依据；能实测的行为都在 GnuCOBOL 3.2 上验证过。",
        "kn_about": "COBOL 是什么",
        "kn_about_desc": "语言定位、四个分部、为什么长成现在这样，以及它今天还在哪些行业运行。",
        "kn_history": "COBOL 史话",
        "kn_hardware": "硬件演进",
        "kn_hardware_desc": "从打孔卡、磁带与大型机，到个人电脑和开放系统；沿时间线看 COBOL 的变化与遗留契约。",
        "kn_history_desc": "从 1959 年的会议、FACT 之争与那块墓碑，到 ISO/IEC 1989:2023 的标准化历程。",
        "kn_reference": "速查手册",
        "kn_reference_desc": "固定格式列规则、PIC 符号、USAGE 实测字节数、常用语句与文件状态码，一页查完。",
        "kn_glossary": "术语表",
        "kn_glossary_desc": "程序结构、数据层级、文件、表、模块与编译等 8 类术语，支持页内筛选。",
        "about_title": "COBOL 是什么", "reference_title": "COBOL 速查手册",
        "gnucobol_title": "GnuCOBOL 官方编译器",
        "gnucobol_eyebrow": "OFFICIAL COMPILER",
        "gnucobol_lead": "本课程与 `cobol.nvim` 插件都以 GnuCOBOL（`cobc`）为编译器。课程里的每个示例都由它编译运行，插件也把它的诊断结果接进编辑器。两者都不自带编译器，而是配套使用 GnuCOBOL。",
        "gnucobol_flow_title": "课程、插件与编译器的关系",
        "gnucobol_flow": [
            ("课程与示例", "固定格式 COBOL 源码，含 Copybook、夹具与练习"),
            ("`cobc` 编译", "GnuCOBOL 做语法检查并生成原生可执行程序"),
            ("编辑器插件", "`cobol.nvim` 在 Neovim 内调用 `cobc`，显示结构、布局与诊断"),
        ],
        "gnucobol_resources_title": "GnuCOBOL 官方资料",
        "gnucobol_resources": [
            ("GnuCOBOL 3.2 Programmer's Guide", "官方程序员指南（HTML）", "https://gnucobol.sourceforge.io/HTML/gnucobpg.html"),
            ("GnuCOBOL 3.2 Quick Reference", "语句与语法速查", "https://gnucobol.sourceforge.io/HTML/gnucobqr.html"),
            ("GnuCOBOL 3.2 Sample Programs", "官方示例程序", "https://gnucobol.sourceforge.io/HTML/gnucobsp.html"),
            ("GnuCOBOL 语言参考", "`cobc` 与运行时手册", "https://gnucobol.sourceforge.io/doc/gnucobol.html"),
            ("FAQ and HOWTO", "常见问题与具体做法", "https://gnucobol.sourceforge.io/faq/index.html"),
            ("Guides 总目录", "PDF / Info / 语法文档等全部官方资料", "https://gnucobol.sourceforge.io/guides.html"),
            ("下载与镜像", "GNU FTP 镜像（源码包）", "https://ftpmirror.gnu.org/gnucobol/"),
            ("项目与社区", "SourceForge 工单、讨论与邮件列表", "https://sourceforge.net/p/gnucobol/"),
        ],
        "gnucobol_features_title": "GnuCOBOL 提供的能力",
        "gnucobol_features": [
            "19 种 COBOL 方言，含 COBOL 85/2002/2014、IBM、Micro Focus、RM/COBOL 等",
            "REPORT SECTION、SCREEN SECTION、FUNCTION-ID",
            "与 C 无缝集成，可直接调用 C 库",
            "`EXEC SQL` 预处理器：PostgreSQL、Firebird、ODBC、DB2",
            "通过 9740 余项 NIST COBOL 85 测试套件",
            "把 COBOL 源码转译为 C，再链接成原生可执行程序",
        ],
        "gnucobol_versions_title": "版本与方言",
        "gnucobol_versions": "官方最新发布为 3.2（2023-07-28），本课程与示例以 3.2 验证。除非确有必要，不要给现代 GnuCOBOL 传 `-std=cobol85`：严格的 COBOL 85 不含 `COMP-3`（该标准中名为 `PACKED-DECIMAL`）与 `FUNCTION TRIM` 等现代函数。",
        "gnucobol_note": "GnuCOBOL 是 GNU 工程的一部分，由 Free Software Foundation 以 GPL 发布；官方文档另有其授权条款。本页只提供指向官方站点的链接，不对其内容作任何再分发。",
        "nav_menu": "菜单",
        "nav_close": "关闭",
        "theme_dark": "切换到深色主题", "theme_light": "切换到浅色主题",
        "course_toggle": "课程目录",
        "lessons_label": "课",
        "plugin_eyebrow": "EDITOR PLUGIN",
        "plugin_lead": "`cobol.nvim` 是配合本课程的 Neovim 插件，把固定格式 COBOL 的列规则、结构导航、记录布局和编译器反馈直接放进编辑器：写代码时就能看到列标尺、结构面包屑和错误。",
        "plugin_features_title": "它能做什么",
        "plugin_features": [
            ("固定格式标尺与 Winbar", "在第 7、8、12、73 列绘制标尺，越界到识别区会告警", "ruler-winbar.png", "光标所在行实时显示记录字节数；Winbar 显示当前 Division / Section / Paragraph 位置"),
            ("结构大纲", "Aerial 侧边栏展示 Division / Section / Paragraph / 数据层级，可双向跳转", "aerial-outline.png", "左侧大纲与右侧代码同步高亮，可直接跳转任意段落或数据项"),
            ("定义直达与 Copybook 预览", "`gd` 跳段落或字段定义，`gf` 打开 `COPY` 引用的 Copybook，`K` 就地预览", "copybook-preview.png", "`K` 在不离开当前文件的情况下弹出 Copybook 内容"),
            ("PIC 与记录字节计算", "把 `PIC X(20)`、`PIC S9(7) COMP-3` 等换算成字节数，并对 `01` 记录递归求和", "record-layout.png", "`:CobolCalcRecord` 输出字段偏移、PIC、字节数与记录总长"),
            ("保存即语法飞检", "异步调用 `cobc -fsyntax-only`，把编译器诊断映射到对应行", "diagnostics.png", "保存后行内标出编译器错误，无需离开编辑器"),
            ("折叠与格式化", "按 Division / Section / Paragraph 折叠，批量把保留字规整为大写", "folding.png", "按结构折叠长程序，只展开当前在看的段落"),
        ],
        "plugin_install": "用 lazy.nvim 安装",
        "plugin_repo": "GitHub 仓库",
        "plugin_tutorials": "配套教程",
        "plugin_requirements": "需要 Neovim 0.10+。结构标记与面包屑需要 COBOL Tree-sitter 解析器（启动时自动编译，或手动运行 `scripts/build_parser.sh`）；GnuCOBOL（`cobc`）只在编译器诊断与构建时需要；Aerial 与 blink.cmp 均为可选依赖。",
        "plugin_license": "MIT 许可，源码公开。",
        "plugin_open": "了解并安装 cobol.nvim",
        "plugin_preview_label": "cobol.nvim 实际运行画面 · 查看功能",
        "plugin_figure": "Neovim 实际画面：Syms 大纲、固定格式列标尺、Winbar 和 IF / ELSE / END-IF 的彩色配对及连接虚线。Syms 是另装的界面；插件另提供 Aerial 后端。",
    },
    "en": {
        "pager_prev": "Previous lesson", "pager_next": "Next lesson",
        "pager_all": "All lessons", "pager_end": "You have reached the last lesson",
        "html": "en", "name": "English", "brand_sub": "Practical Course",
        "nav_home": "Home", "nav_directory": "32 lessons", "nav_extensions": "Extensions",
        "nav_source": "GitHub source", "nav_lang": "Language", "course_nav": "Course contents",
        "lesson_context_label": "IN PRACTICE",
        "course_expand": "Expand course sidebar",
        "course_collapse": "Collapse course sidebar",
        "search": "Filter lessons", "directory_link": "View the full curriculum →",
        "tab_guide": "Lesson", "tab_exercise": "Exercise", "tab_answer": "Answer key", "tab_resources": "Code & files",
        "download": "Download ↓", "pending_page": "This translation is being prepared. The Chinese original is shown below.",
        "pending_resource": "This file has no English version yet; the Chinese original is shown below.",
        "source_format": "FIXED FORMAT · 80-COLUMN RULER",
        "source_scroll_hint": "Scroll sideways to inspect all columns · source text ends at column 72",
        "view_source": "Read the Chinese original →", "unsupported": "Preview is unavailable for this file; download it to open locally.",
        "footer": "Course source and practice material",
        "footer_compiler": "compiler",
        "hero_eyebrow": "GNU COBOL · PRACTICAL COURSE",
        "hero_h1": "From your first COBOL statement", "hero_h1_em": "to a bank nightly reconciliation system.",
        "hero_intro": "A step-by-step GnuCOBOL course. Read the lesson, run the program, finish the exercise, and build a real batch project.",
        "hero_cta": "Start with lesson 01", "hero_cta2": "Browse all lessons",
        "path_eyebrow": "THE LEARNING PATH", "path_title": "Six stages, one complete course", "path_link": "View the curriculum →",
        "stages": [
            ("01 — 08", "Language basics", "Statements, data and control flow"),
            ("09 — 14", "Data structures", "Records, tables and lookups"),
            ("15 — 22", "File processing", "CSV, sorting and file matching"),
            ("23 — 28", "Engineering", "Modules, interfaces and logging"),
            ("29 — 31", "Database", "Embedded SQL and synchronization"),
            ("32", "Capstone", "Bank reconciliation batch system"),
        ],
        "start_eyebrow": "START HERE", "start_title": "Every lesson runs on your machine",
        "start_text": "Install GnuCOBOL and Make, then compile, modify and practise from lesson one. GnuCOBOL grew from OpenCOBOL, released by Japanese developer Keisuke Nishida, and translates COBOL to C for the system C compiler. On Debian/Ubuntu, apt makes it easy to practise this course’s fixed-format source on home Linux—no mainframe needed. This is a learning setup, not a guarantee of identical mainframe production behavior. Source code, fixtures and answer keys sit next to each lesson.",

        "start_term": "Terminal · Debian / Ubuntu", "start_open": "Open lesson 01",
        "more_eyebrow": "BEYOND THE MAIN COURSE", "more_title": "Keep exploring",
        "more_kn": "Knowledge base", "more_kn_desc": "Language background, history, reference and glossary",
        "more_ext": "Extensions", "more_ext_desc": "Legacy topics, enterprise batch and editor tutorials",
        "more_src": "Course source", "more_src_desc": "Code, fixtures and build scripts",
        "nav_plugins": "cobol.nvim",
        "nav_resources": "Resources",
        "nav_gnucobol": "GnuCOBOL",
        "more_gnu_desc": "Companion compiler and official documentation",
        "nav_about": "What is COBOL", "nav_reference": "Reference",
        "nav_knowledge": "Knowledge",
        "kn_eyebrow": "KNOWLEDGE BASE",
        "kn_title": "COBOL knowledge base",
        "kn_lead": "Beyond the 32-lesson course there are four references: what the language is, how it came to be, a lookup sheet, and a glossary. None of them needs to be read in order.",
        "kn_note": "Content follows COBOL's published history, ISO standard numbers and official GnuCOBOL documentation; anything observable was verified on GnuCOBOL 3.2.",
        "kn_about": "What is COBOL",
        "kn_about_desc": "What the language is for, its four divisions, why it looks the way it does, and where it still runs.",
        "kn_history": "A short history",
        "kn_hardware": "Hardware evolution",
        "kn_hardware_desc": "From punched cards, tape, and mainframes to PCs and open systems; trace COBOL and the contracts left behind.",
        "kn_history_desc": "From the 1959 meetings, the FACT fight and the tombstone, to ISO/IEC 1989:2023.",
        "kn_reference": "Reference sheet",
        "kn_reference_desc": "Fixed-format columns, PICTURE symbols, measured USAGE sizes, statements and file status codes.",
        "kn_glossary": "Glossary",
        "kn_glossary_desc": "Eight groups of terms covering structure, data levels, files, tables, modules and compilation, filterable in place.",
        "about_title": "What is COBOL", "reference_title": "COBOL reference sheet",
        "gnucobol_title": "The GnuCOBOL compiler",
        "gnucobol_eyebrow": "OFFICIAL COMPILER",
        "gnucobol_lead": "This course and the `cobol.nvim` plugin both use the GnuCOBOL compiler (`cobc`). Every example is compiled and run by it, and the plugin feeds its diagnostics back into the editor. Neither ships a compiler: they are built to work with GnuCOBOL.",
        "gnucobol_flow_title": "How the course, plugin and compiler fit together",
        "gnucobol_flow": [
            ("Course and examples", "Fixed-format COBOL source with copybooks, fixtures and exercises"),
            ("`cobc` compiles", "GnuCOBOL syntax-checks the source and produces a native executable"),
            ("Editor plugin", "`cobol.nvim` calls `cobc` inside Neovim and shows structure, layout and diagnostics"),
        ],
        "gnucobol_resources_title": "Official GnuCOBOL documentation",
        "gnucobol_resources": [
            ("GnuCOBOL 3.2 Programmer's Guide", "The official guide (HTML)", "https://gnucobol.sourceforge.io/HTML/gnucobpg.html"),
            ("GnuCOBOL 3.2 Quick Reference", "Statement and syntax reference", "https://gnucobol.sourceforge.io/HTML/gnucobqr.html"),
            ("GnuCOBOL 3.2 Sample Programs", "Official sample programs", "https://gnucobol.sourceforge.io/HTML/gnucobsp.html"),
            ("GnuCOBOL language reference", "`cobc` and runtime manual", "https://gnucobol.sourceforge.io/doc/gnucobol.html"),
            ("FAQ and HOWTO", "Common questions and recipes", "https://gnucobol.sourceforge.io/faq/index.html"),
            ("Guides index", "Every official document: PDF, Info, grammar", "https://gnucobol.sourceforge.io/guides.html"),
            ("Download and mirrors", "GNU FTP mirror (source packages)", "https://ftpmirror.gnu.org/gnucobol/"),
            ("Project and community", "SourceForge tickets, discussion and mailing lists", "https://sourceforge.net/p/gnucobol/"),
        ],
        "gnucobol_features_title": "What GnuCOBOL gives you",
        "gnucobol_features": [
            "19 COBOL dialects, including COBOL 85/2002/2014, IBM, Micro Focus and RM/COBOL",
            "REPORT SECTION, SCREEN SECTION and FUNCTION-ID",
            "Seamless C integration: call C libraries directly",
            "`EXEC SQL` preprocessors for PostgreSQL, Firebird, ODBC and DB2",
            "Passes over 9740 NIST COBOL 85 test suite tests",
            "Translates COBOL to C, then links a native executable",
        ],
        "gnucobol_versions_title": "Versions and dialects",
        "gnucobol_versions": "The latest official release is 3.2 (28 July 2023), which this course and its examples are verified against. Do not pass `-std=cobol85` to a modern GnuCOBOL unless you must: strict COBOL 85 lacks `COMP-3` (named `PACKED-DECIMAL` in that standard) and modern functions such as `FUNCTION TRIM`.",
        "gnucobol_note": "GnuCOBOL is part of the GNU Project, released under the GPL by the Free Software Foundation; its documentation carries its own terms. This page only links to the official site and does not redistribute its content.",
        "nav_menu": "Menu",
        "nav_close": "Close",
        "theme_dark": "Switch to dark theme", "theme_light": "Switch to light theme",
        "course_toggle": "Lessons",
        "lessons_label": "lessons",
        "plugin_eyebrow": "EDITOR PLUGIN",
        "plugin_lead": "`cobol.nvim` is the Neovim plugin built alongside this course. It brings fixed-format column rules, structure navigation, record layout and compiler feedback into the editor, so the column ruler, structure breadcrumb and errors are visible while you type.",
        "plugin_features_title": "What it does",
        "plugin_features": [
            ("Fixed-format ruler and Winbar", "Draws the column ruler at 7, 8, 12 and 73, and warns when text crosses into the identification area", "ruler-winbar.png", "The record size is shown on the current line; the Winbar shows the Division / Section / Paragraph you are in"),
            ("Structure outline", "An Aerial sidebar for Division / Section / Paragraph and the data hierarchy, with jump-to and follow-cursor", "aerial-outline.png", "The outline highlights in step with the code and jumps to any paragraph or data item"),
            ("Definition jump and Copybook preview", "`gd` jumps to a paragraph or field definition, `gf` opens the `COPY` copybook, `K` previews it in place", "copybook-preview.png", "`K` shows the copybook contents without leaving the file"),
            ("PIC and record size calculation", "Converts `PIC X(20)`, `PIC S9(7) COMP-3` and friends into byte counts, and sums an `01` record recursively", "record-layout.png", "`:CobolCalcRecord` lists each field offset, PIC, size and the record total"),
            ("Syntax check on save", "Runs `cobc -fsyntax-only` asynchronously and maps compiler diagnostics onto the lines that caused them", "diagnostics.png", "Compiler errors appear inline after saving, without leaving the editor"),
            ("Folding and formatting", "Folds by Division / Section / Paragraph and normalises reserved words to upper case", "folding.png", "Fold a long program by structure and keep only the paragraph you are reading open"),
        ],
        "plugin_install": "Install with lazy.nvim",
        "plugin_repo": "GitHub repository",
        "plugin_tutorials": "Tutorials",
        "plugin_requirements": "Neovim 0.10+ is required. Structure badges and breadcrumbs need the COBOL Tree-sitter parser (built automatically on startup, or via `scripts/build_parser.sh`); GnuCOBOL (`cobc`) is only needed for compiler diagnostics and builds; Aerial and blink.cmp are optional.",
        "plugin_license": "MIT licensed, open source.",
        "plugin_open": "Get cobol.nvim",
        "plugin_preview_label": "cobol.nvim in action · Explore features",
        "plugin_figure": "A real Neovim session: the optional Syms outline, column guides, Winbar, and paired IF / ELSE / END-IF badges with a connecting line. The plugin also includes a separate Aerial backend.",
    },
    "ja": {
        "pager_prev": "前のレッスン", "pager_next": "次のレッスン",
        "pager_all": "全レッスン", "pager_end": "最後のレッスンです",
        "html": "ja", "name": "日本語", "brand_sub": "実践コース",
        "nav_home": "ホーム", "nav_directory": "全32レッスン", "nav_extensions": "発展教材",
        "nav_source": "GitHub ソース", "nav_lang": "言語", "course_nav": "コース目次",
        "lesson_context_label": "現場との接点",
        "course_expand": "コース一覧を展開",
        "course_collapse": "コース一覧を折りたたむ",
        "search": "レッスンを絞り込む", "directory_link": "全カリキュラムを見る →",
        "tab_guide": "レッスン", "tab_exercise": "演習", "tab_answer": "解答例", "tab_resources": "コード・資料",
        "download": "ダウンロード ↓", "pending_page": "このページは翻訳準備中です。以下は中国語の原文です。",
        "pending_resource": "このファイルの日本語版は未作成です。以下は中国語の原文です。",
        "source_format": "固定形式 COBOL · 80 桁ルーラー",
        "source_scroll_hint": "左右にスクロールして全桁を表示 · ソース本文は 72 桁まで",
        "view_source": "中国語の原文を見る →", "unsupported": "このファイルはプレビューできません。ダウンロードして開いてください。",
        "footer": "コースのソースと演習資料",
        "footer_compiler": "対応コンパイラ",
        "hero_eyebrow": "GNU COBOL · 日本の基幹系のための実践コース",
        "hero_h1": "最初の COBOL ステートメントから、", "hero_h1_em": "銀行の夜間照合システムまで。",
        "hero_intro": "国内の金融・保険・公共システムでは、いまも COBOL が現役です。このコースは、実際に動く固定形式のバッチプログラムを 32 本読み・直しながら、勘定系の処理を安全に変更できる力を身につけます。",
        "hero_cta": "レッスン01から始める", "hero_cta2": "全レッスンを見る",
        "path_eyebrow": "THE LEARNING PATH", "path_title": "6つのステージで完結するコース", "path_link": "カリキュラムを見る →",
        "stages": [
            ("01 — 08", "言語の基礎", "文・データ・制御フロー"),
            ("09 — 14", "データ構造", "レコード・表・探索"),
            ("15 — 22", "ファイル処理", "CSV・ソート・突合"),
            ("23 — 28", "エンジニアリング", "モジュール・インターフェース・ログ"),
            ("29 — 31", "データベース", "埋め込みSQLと同期"),
            ("32", "卒業プロジェクト", "銀行照合バッチシステム"),
        ],
        "start_eyebrow": "START HERE", "start_title": "Linux と GnuCOBOL があれば、今日から動かせます",
        "start_text": "メインフレームがなくても大丈夫です。GnuCOBOL は日本の開発者・西田圭介氏が公開した OpenCOBOL から始まり、COBOL を C に変換してシステムの C コンパイラーでビルドする自由なコンパイラーです。Debian/Ubuntu なら apt で導入でき、自宅の Linux で本番の現場でも使われる固定形式の書き方を練習できます。ただし、メインフレームの方言や本番動作まで同じになるわけではありません。",

        "start_term": "ターミナル · Debian / Ubuntu", "start_open": "レッスン01を開く",
        "more_eyebrow": "BEYOND THE MAIN COURSE", "more_title": "さらに学ぶ",
        "more_kn": "ナレッジベース", "more_kn_desc": "言語の概要・史話・リファレンス・用語集",
        "more_ext": "発展教材", "more_ext_desc": "旧版のトピック、企業バッチ、エディタのチュートリアル",
        "more_src": "コースのソース", "more_src_desc": "コード、フィクスチャ、ビルドスクリプト",
        "nav_plugins": "cobol.nvim",
        "nav_resources": "資料",
        "nav_gnucobol": "GnuCOBOL 公式",
        "more_gnu_desc": "対応コンパイラと公式ドキュメント",
        "nav_about": "COBOL とは", "nav_reference": "リファレンス",
        "nav_knowledge": "ナレッジ",
        "kn_eyebrow": "KNOWLEDGE BASE",
        "kn_title": "COBOL ナレッジベース",
        "kn_lead": "32 課のコースとは別に 4 つの資料を用意しています。言語の概要、成り立ちの史話、引けるリファレンス、用語集です。順番に読む必要はありません。",
        "kn_note": "内容は COBOL の公開された歴史資料、ISO 標準番号、GnuCOBOL 公式ドキュメントに基づきます。観測できる挙動は GnuCOBOL 3.2 で実測しています。",
        "kn_about": "COBOL とは",
        "kn_about_desc": "言語の目的、4 つの DIVISION、なぜこの形なのか、現在も動く分野。",
        "kn_history": "COBOL 史話",
        "kn_hardware": "ハードウェアの変遷",
        "kn_hardware_desc": "パンチカード、テープ、メインフレームから PC・オープンシステムへ。COBOL の変化と残った契約をたどります。",
        "kn_history_desc": "1959 年の会合、FACT 論争と墓石、ISO/IEC 1989:2023 までの標準化。",
        "kn_reference": "リファレンス",
        "kn_reference_desc": "固定形式の桁、PIC 記号、USAGE の実測バイト数、主要な文、ファイル状態コード。",
        "kn_glossary": "用語集",
        "kn_glossary_desc": "構造・データ階層・ファイル・表・モジュール・コンパイルなど 8 分類の用語。ページ内で絞り込めます。",
        "about_title": "COBOL とは", "reference_title": "COBOL クイックリファレンス",
        "gnucobol_title": "GnuCOBOL コンパイラ",
        "gnucobol_eyebrow": "OFFICIAL COMPILER",
        "gnucobol_lead": "本コースと `cobol.nvim` プラグインは、どちらも GnuCOBOL（`cobc`）をコンパイラとして使います。すべてのサンプルはこれでコンパイル・実行され、プラグインはその診断結果をエディタに表示します。どちらもコンパイラを同梱せず、GnuCOBOL と組み合わせて使う前提です。",
        "gnucobol_flow_title": "コース・プラグイン・コンパイラの関係",
        "gnucobol_flow": [
            ("コースとサンプル", "固定形式 COBOL のソース、Copybook、フィクスチャ、演習"),
            ("`cobc` でコンパイル", "GnuCOBOL が構文を検査し、ネイティブ実行ファイルを生成"),
            ("エディタプラグイン", "`cobol.nvim` が Neovim 内で `cobc` を呼び、構造・レイアウト・診断を表示"),
        ],
        "gnucobol_resources_title": "GnuCOBOL 公式ドキュメント",
        "gnucobol_resources": [
            ("GnuCOBOL 3.2 Programmer's Guide", "公式プログラマーズガイド（HTML）", "https://gnucobol.sourceforge.io/HTML/gnucobpg.html"),
            ("GnuCOBOL 3.2 Quick Reference", "文法・文のクイックリファレンス", "https://gnucobol.sourceforge.io/HTML/gnucobqr.html"),
            ("GnuCOBOL 3.2 Sample Programs", "公式サンプルプログラム", "https://gnucobol.sourceforge.io/HTML/gnucobsp.html"),
            ("GnuCOBOL 言語リファレンス", "`cobc` とランタイムのマニュアル", "https://gnucobol.sourceforge.io/doc/gnucobol.html"),
            ("FAQ and HOWTO", "よくある質問と実践的な手順", "https://gnucobol.sourceforge.io/faq/index.html"),
            ("Guides 一覧", "PDF・Info・文法資料など公式資料の全体", "https://gnucobol.sourceforge.io/guides.html"),
            ("ダウンロードとミラー", "GNU FTP ミラー（ソースパッケージ）", "https://ftpmirror.gnu.org/gnucobol/"),
            ("プロジェクトとコミュニティ", "SourceForge のチケット・議論・メーリングリスト", "https://sourceforge.net/p/gnucobol/"),
        ],
        "gnucobol_features_title": "GnuCOBOL が提供するもの",
        "gnucobol_features": [
            "19 種の COBOL 方言（COBOL 85/2002/2014、IBM、Micro Focus、RM/COBOL など）",
            "REPORT SECTION、SCREEN SECTION、FUNCTION-ID",
            "C とのシームレスな連携。C ライブラリを直接呼び出せます",
            "`EXEC SQL` プリプロセッサ（PostgreSQL、Firebird、ODBC、DB2）",
            "NIST COBOL 85 テストスイートを 9740 件以上通過",
            "COBOL を C に変換し、ネイティブ実行ファイルとしてリンク",
        ],
        "gnucobol_versions_title": "バージョンと方言",
        "gnucobol_versions": "公式の最新リリースは 3.2（2023-07-28）で、本コースとサンプルはこれで検証しています。必要がない限り、現代の GnuCOBOL に `-std=cobol85` を渡さないでください。厳格な COBOL 85 には `COMP-3`（同標準での名称は `PACKED-DECIMAL`）や `FUNCTION TRIM` などの現代的な機能が含まれません。",
        "gnucobol_note": "GnuCOBOL は GNU プロジェクトの一部で、Free Software Foundation により GPL で公開されています。公式ドキュメントには独自のライセンス条件があります。本ページは公式サイトへのリンクのみを提供し、その内容を再配布しません。",
        "nav_menu": "メニュー",
        "nav_close": "閉じる",
        "theme_dark": "ダークテーマに切り替える", "theme_light": "ライトテーマに切り替える",
        "course_toggle": "レッスン一覧",
        "lessons_label": "レッスン",
        "plugin_eyebrow": "EDITOR PLUGIN",
        "plugin_lead": "`cobol.nvim` は本コースとともに育てている Neovim プラグインです。固定形式 COBOL の桁ルール、構造ナビゲーション、レコードレイアウト、コンパイラのフィードバックをエディタに持ち込み、書いているそばから桁定規・パンくず・エラーが見えます。",
        "plugin_features_title": "できること",
        "plugin_features": [
            ("固定形式の桁定規と Winbar", "7・8・12・73 列に定規を描き、識別領域へのはみ出しを警告します", "ruler-winbar.png", "カーソル行にレコード長を表示し、Winbar に現在の Division / Section / Paragraph を出します"),
            ("構造アウトライン", "Division / Section / Paragraph とデータ階層を Aerial サイドバーに表示し、双方向にジャンプできます", "aerial-outline.png", "アウトラインとコードが連動してハイライトされ、任意の段落や項目へ移動できます"),
            ("定義ジャンプと Copybook プレビュー", "`gd` で段落や項目定義へ、`gf` で `COPY` の Copybook を開き、`K` でその場にプレビューします", "copybook-preview.png", "`K` でファイルを離れずに Copybook の中身を確認できます"),
            ("PIC とレコード長の計算", "`PIC X(20)` や `PIC S9(7) COMP-3` をバイト数に換算し、`01` レコードを再帰的に合計します", "record-layout.png", "`:CobolCalcRecord` が各項目のオフセット・PIC・サイズとレコード合計を一覧表示します"),
            ("保存時の構文チェック", "`cobc -fsyntax-only` を非同期に実行し、コンパイラ診断を該当行に表示します", "diagnostics.png", "保存するとコンパイラエラーが行内に表示され、エディタを離れる必要がありません"),
            ("折りたたみと整形", "Division / Section / Paragraph 単位で折りたたみ、予約語を大文字に揃えます", "folding.png", "長いプログラムを構造単位で折りたたみ、読んでいる段落だけを開けます"),
        ],
        "plugin_install": "lazy.nvim でインストール",
        "plugin_repo": "GitHub リポジトリ",
        "plugin_tutorials": "チュートリアル",
        "plugin_requirements": "Neovim 0.10 以降が必要です。構造マーカーとパンくずには COBOL Tree-sitter パーサーが必要です（起動時に自動ビルド、または `scripts/build_parser.sh` を実行）。GnuCOBOL（`cobc`）はコンパイラ診断とビルドにのみ必要で、Aerial と blink.cmp は任意です。",
        "plugin_license": "MIT ライセンスで公開しています。",
        "plugin_open": "cobol.nvim を導入する",
        "plugin_preview_label": "cobol.nvim の実画面 · 機能を見る",
        "plugin_figure": "Neovim の実画面：別途導入した Syms アウトライン、桁ガイド、Winbar、IF / ELSE / END-IF の対応表示と接続線。プラグインには Aerial 用バックエンドも含まれます。",
    },
}

MD = markdown.Markdown(extensions=["fenced_code", "tables", "toc", "sane_lists", "smarty"])


def covered(path: Path) -> bool:
    """True when a repository file is part of the published learning material."""
    rel = path.relative_to(ROOT)
    if set(rel.parts) & EXCLUDED_PARTS or path.name in EXCLUDED_NAMES:
        return False
    if "build" in rel.parts or ".git" in rel.parts or "__pycache__" in rel.parts:
        return False
    if path.name.startswith("."):
        return False
    suffix = path.suffix.lower()
    if suffix in EXCLUDED_SUFFIXES:
        return False
    # Run logs are noise, but lesson reference logs are part of the material.
    if suffix == ".log" and not path.name.startswith("expected"):
        return False
    return True


def page_sources() -> list[Path]:
    """Markdown files rendered as pages (lesson exercise/answer live inside the lesson page)."""
    pages = [ROOT / "README.md"]
    for base in (LESSONS, EXTENSIONS):
        for path in sorted(base.rglob("*.md")):
            if not covered(path):
                continue
            if base is LESSONS and path.name in {"exercise.md", "answer.md"} and re.match(r"^\d{2}_", path.relative_to(LESSONS).parts[0]):
                continue
            pages.append(path)
    return pages


def resource_sources() -> list[Path]:
    """Non-Markdown learning assets copied next to the lesson pages."""
    assets = []
    for base in (LESSONS, EXTENSIONS):
        for path in sorted(base.rglob("*")):
            if path.is_file() and path.suffix.lower() != ".md" and covered(path):
                assets.append(path)
    return assets


def output_rel(source: Path) -> Path:
    return source.relative_to(ROOT).with_suffix(".html")


def translated(source: Path, locale: str) -> Path | None:
    if locale == "zh-cn":
        return source
    try:
        rel = source.relative_to(ROOT)
    except ValueError:
        return None
    candidate = TRANSLATIONS / locale / rel
    return candidate if candidate.is_file() else None


def title_of(source: Path, locale: str = "zh-cn") -> str:
    chosen = translated(source, locale) or source
    text = strip_frontmatter(chosen.read_text(encoding="utf-8"))
    match = re.search(r"^#\s+(.+?)\s*#*\s*$", text, re.M)
    return match.group(1) if match else source.stem.replace("-", " ").replace("_", " ")


def rel_href(target: Path, current: Path) -> str:
    """Relative URL from the page ``current`` to ``target`` (both inside the locale tree)."""
    return quote(os.path.relpath(target.as_posix(), current.parent.as_posix()), safe="/._-")


def site_href(target_page: Path, locale: str, page: Path, absolute: bool = False) -> str:
    """Relative URL between two paths expressed from the site root, locale included.

    ``page`` is the current page path inside its locale tree (for example
    ``lessons/01_hello-cobol/README.html``); ``target_page`` already includes the
    target locale prefix when a different language is requested.
    """
    if absolute:
        return "/" + quote(target_page.as_posix(), safe="/._-")
    current_root = Path(locale) / page
    return quote(os.path.relpath(target_page.as_posix(), current_root.parent.as_posix()), safe="/._-")


# Short navigation labels; the full lesson title stays in the page heading and tooltip.
LESSON_LABELS = {
    "01_hello-cobol": "Hello COBOL",
    "02_data-types": "Data Types",
    "03_move-compute": "MOVE & COMPUTE",
    "04_if-conditions": "IF",
    "05_evaluate": "EVALUATE",
    "06_perform-loops": "PERFORM",
    "07_paragraphs": "Paragraphs",
    "08_control-flow-practice": "Control Flow Practice",
    "09_group-items": "Group Item",
    "10_redefines": "REDEFINES",
    "11_occurs-tables": "OCCURS Tables",
    "12_indexed-by": "INDEXED BY",
    "13_search-tables": "SEARCH Tables",
    "14_data-structures-practice": "Data Structures Practice",
    "15_sequential-file-read": "Sequential File Read",
    "16_file-writing": "File Writing",
    "17_fixed-length-files": "Fixed-Length Files",
    "18_csv-processing": "CSV Processing",
    "19_multiple-files": "Multiple Files",
    "20_file-matching": "File Matching",
    "21_sort": "SORT",
    "22_file-processing-practice": "File Processing Practice",
    "23_copybooks": "COPYBOOK",
    "24_call-subprograms": "CALL Subprograms",
    "25_using-parameters": "USING Parameters",
    "26_error-handling": "Error Handling",
    "27_logging": "Logging",
    "28_modular-batch-project": "Modular Batch Project",
    "29_embedded-sql": "Embedded SQL",
    "30_sql-cursors": "SQL Cursors",
    "31_data-synchronization": "Data Synchronization",
    "32_bank-reconciliation-project": "Bank Reconciliation",
}


@functools.lru_cache(maxsize=None)
def directory_short_names(locale: str) -> dict[str, str]:
    """Short lesson names from the course index (translated index wins when present)."""
    index = translated(LESSONS / "DIRECTORY.md", locale)
    if index is None:
        return {}
    names: dict[str, str] = {}
    for line in index.read_text(encoding="utf-8").splitlines():
        match = re.match(r"^\|\s*(\d{2})\s*\|\s*([^|]+?)\s*\|", line)
        if match:
            names[match.group(1)] = match.group(2)
    return names


@functools.lru_cache(maxsize=None)
def lesson_items(locale: str) -> tuple[tuple[Path, str, str], ...]:
    """(page, short label, full title) for the course navigation."""
    names = directory_short_names(locale)
    items = []
    for source in sorted(LESSONS.glob("[0-9][0-9]*/README.md")):
        folder = source.parent.name
        short = names.get(folder[:2]) if locale == "zh-cn" else None
        items.append((output_rel(source), short or LESSON_LABELS.get(folder, folder), title_of(source, locale)))
    return tuple(items)


def is_lesson_workspace(source: Path) -> bool:
    try:
        rel = source.relative_to(LESSONS)
    except ValueError:
        return False
    return len(rel.parts) >= 2 and bool(re.match(r"^\d{2}_", rel.parts[0])) and source.name == "README.md"


def lesson_assets(source: Path) -> list[Path]:
    """Extra files shown in a lesson's resource browser."""
    folder = source.parent
    return [
        path for path in sorted(folder.rglob("*"))
        if path.is_file() and covered(path) and path.name not in {"README.md", "exercise.md", "answer.md"}
    ]


def localized_asset(resolved: Path, locale: str) -> Path:
    """Pick the locale variant of a lesson figure when one exists.

    Figures keep one canonical English SVG; ``scripts/diagram_i18n.py`` writes
    ``<name>.zh-cn.svg`` / ``<name>.ja.svg`` beside it. Everything else (source
    files, fixtures, screenshots) is shared as-is.
    """
    if resolved.suffix.lower() != ".svg":
        return resolved
    variant = resolved.with_name(f"{resolved.stem}.{locale}{resolved.suffix}")
    return variant if variant.is_file() else resolved


def fix_links(content: str, source: Path, locale: str = "zh-cn") -> str:
    """Rewrite repository-relative Markdown links into site-relative HTML links."""
    def replace(match: re.Match[str]) -> str:
        target = match.group(1)
        if target.startswith(("http://", "https://", "mailto:", "#", "data:")):
            return match.group(0)
        path, sep, fragment = target.partition("#")
        if not path:
            return match.group(0)
        resolved = (source.parent / path).resolve()
        try:
            rel = resolved.relative_to(ROOT)
        except ValueError:
            return match.group(0)
        if set(rel.parts) & EXCLUDED_PARTS:
            return "](#)"
        if not resolved.exists():
            return match.group(0)
        if resolved.is_dir():
            if (resolved / "README.md").is_file():
                rel = rel / "README.md"
            else:
                return f"](https://github.com/iamcheyan/cobol/tree/main/{quote(rel.as_posix(), safe='/._-')}" + (f"#{fragment}" if sep else "") + ")"
        if rel.suffix.lower() == ".md" and rel.parts[0] == "lessons" and len(rel.parts) >= 3 and re.match(r"^\d{2}_", rel.parts[1]) and rel.name in {"exercise.md", "answer.md"}:
            tab = "#tab-exercise" if rel.name == "exercise.md" else "#tab-answer"
            target = rel.parent / "README.html"
            relative = os.path.relpath(target.as_posix(), output_rel(source).parent.as_posix())
            return f"]({quote(relative, safe='/._-')}{tab})"
        if resolved.suffix.lower() == ".svg":
            chosen = localized_asset(resolved, locale)
            rel = chosen.relative_to(ROOT)
        target_rel = rel.with_suffix(".html") if rel.suffix.lower() == ".md" else rel
        relative = os.path.relpath(target_rel.as_posix(), output_rel(source).parent.as_posix())
        return f"]({quote(relative, safe='/._-')}" + (f"#{fragment}" if sep else "") + ")"
    return re.sub(r"\]\(([^)\s]+)(?:\s+[^)]*)?\)", replace, content)


FRONTMATTER = re.compile(r"\A---\r?\n.*?\r?\n---\r?\n", re.S)


def strip_frontmatter(text: str) -> str:
    """Drop leading YAML metadata (translation provenance) so it never renders."""
    return FRONTMATTER.sub("", text, count=1)


def render_markdown(source: Path, locale: str) -> str:
    chosen = translated(source, locale) or source
    MD.reset()
    text = strip_frontmatter(chosen.read_text(encoding="utf-8"))
    return MD.convert(fix_links(text, source, locale))


def inline_page_target(source: Path) -> tuple[Path, str]:
    """Where a source file is published: lesson exercise/answer live inside the lesson page."""
    rel = output_rel(source)
    parts = rel.parts
    if len(parts) >= 3 and parts[0] == "lessons" and re.match(r"^\d{2}_", parts[1]) and source.name in {"exercise.md", "answer.md"}:
        tab = "exercise" if source.name == "exercise.md" else "answer"
        return Path(parts[0], parts[1], "README.html"), f"#tab-{tab}"
    return rel, ""


def pending(locale: str, source: Path, page: Path) -> str:
    labels = LOCALES[locale]
    target, fragment = inline_page_target(source)
    link = site_href(Path("zh-cn") / target, locale, page) + fragment
    return f'<aside class="translation-pending"><p>{labels["pending_page"]}</p><a href="{link}">{labels["view_source"]}</a></aside>'


def lesson_panel(locale: str, key: str, source: Path, page: Path, extra: str = "") -> str:
    labels = LOCALES[locale]
    has_translation = translated(source, locale) is not None
    notice = "" if has_translation or locale == "zh-cn" else pending(locale, source, page)
    active = " active" if key == "guide" else ""
    hidden = "" if key == "guide" else " hidden"
    article = render_markdown(source, locale)
    if key == "guide" and source.parent.parent == LESSONS:
        lesson_dirs = sorted(p for p in LESSONS.iterdir() if p.is_dir() and p.name[:2].isdigit())
        index = lesson_dirs.index(source.parent)
        context = LESSON_CONTEXT[locale][index]
        article = re.sub(r'(</h1>)', rf'\1<aside class="lesson-context"><span>{html.escape(labels["lesson_context_label"])}</span>{html.escape(context)}</aside>', article, count=1)
    return (
        f'<section class="lesson-panel{active}" id="panel-{key}" data-panel="{key}"{hidden}>'
        f'{notice}<article>{article}</article>{extra}</section>'
    )


def resource_browser(locale: str, source: Path, page: Path) -> str:
    labels = LOCALES[locale]
    items = lesson_assets(source)
    if not items:
        return ""
    choices, views = [], []
    for index, path in enumerate(items):
        rel = path.relative_to(ROOT)
        rel_from_page = site_href(Path(locale) / rel, locale, page)
        label = path.relative_to(source.parent).as_posix()
        localized = translated(path, locale)
        suffix = path.suffix.lower()
        with_original = (locale != "zh-cn" and localized is None
                         and suffix in TEXT_SUFFIXES and needs_translation(path))
        choices.append(
            f'<button type="button" class="resource-choice{" selected" if index == 0 else ""}" '
            f'data-resource-choice="{index}">{html.escape(label)}</button>'
        )
        if suffix in TEXT_SUFFIXES:
            readable = localized if localized is not None else path
            try:
                body = html.escape(readable.read_text(encoding="utf-8"))
            except (UnicodeDecodeError, OSError):
                body = None
            if body is not None and len(body) <= 400_000:
                language = html.escape(suffix.lstrip(".") or "text")
                note = f'<p class="translation-pending">{labels["pending_resource"]}</p>' if with_original else ""
                cobol_source = suffix in {".cob", ".cbl", ".cobol", ".cpy"}
                source_badge = (f'<span class="source-format">{html.escape(labels["source_format"])}</span>'
                                if cobol_source else "")
                scroll_hint = (f'<p class="source-scroll-hint">{html.escape(labels["source_scroll_hint"])}</p>'
                               if cobol_source else "")
                editor_class = " cobol-source-view" if cobol_source else ""
                editor_attr = ' data-cobol-source="true"' if cobol_source else ""
                views.append(
                    f'<div class="resource-view{editor_class}" id="resource-{index}" data-resource="{index}"{editor_attr} hidden>'
                    f'<div class="resource-heading"><span>{html.escape(label)}</span>'
                    f'<span class="resource-heading-tools">{source_badge}'
                    f'<a href="{rel_from_page}" download>{labels["download"]}</a></span></div>'
                    f'{note}{scroll_hint}<pre class="source-pre"><code class="language-{language}">{body}</code></pre></div>'
                )
                continue
        views.append(
            f'<div class="resource-view" id="resource-{index}" data-resource="{index}" hidden>'
            f'<div class="resource-heading"><span>{html.escape(label)}</span>'
            f'<a href="{rel_from_page}" download>{labels["download"]}</a></div>'
            f'<p class="resource-download">{labels["unsupported"]}</p></div>'
        )
    return (
        f'<section class="lesson-panel" id="panel-resources" data-panel="resources" hidden>'
        f'<div class="resource-browser"><nav class="resource-choices">{"".join(choices)}</nav>'
        f'<div class="resource-content">{"".join(views)}</div></div></section>'
    )


def lesson_workspace(locale: str, source: Path, page: Path) -> str:
    labels = LOCALES[locale]
    panels = [
        lesson_panel(locale, "guide", source, page, extra=lesson_pager(locale, source, page)),
        lesson_panel(locale, "exercise", source.parent / "exercise.md", page),
        lesson_panel(locale, "answer", source.parent / "answer.md", page),
    ]
    assets = lesson_assets(source)
    if assets:
        panels.append(resource_browser(locale, source, page))
    order = [("guide", labels["tab_guide"]), ("exercise", labels["tab_exercise"]),
             ("answer", labels["tab_answer"]), ("resources", f'{labels["tab_resources"]} · {len(assets)}')]
    present = {panel.split('data-panel="', 1)[1].split('"', 1)[0] for panel in panels}
    tabs = "".join(
        f'<button type="button" class="lesson-tab{" selected" if index == 0 else ""}" role="tab" '
        f'aria-selected="{"true" if index == 0 else "false"}" data-tab="{key}" id="tab-{key}">{label}</button>'
        for index, (key, label) in enumerate((key, label) for key, label in order if key in present)
    )
    return f'<div class="lesson-workspace"><nav class="lesson-tabs" role="tablist">{tabs}</nav>{"".join(panels)}</div>'


def lesson_pager(locale: str, source: Path, page: Path) -> str:
    """Previous / next links at the end of a lesson, plus a way back to the index."""
    labels = LOCALES[locale]
    items = lesson_items(locale)
    current = output_rel(source)
    index = next((i for i, (target, _short, _full) in enumerate(items) if target == current), None)
    if index is None:
        return ""
    parts = []
    if index > 0:
        target, short, full = items[index - 1]
        parts.append(
            f'<a class="pager-link pager-prev" href="{site_href(Path(locale) / target, locale, page)}">'
            f'<span class="pager-dir">← {labels["pager_prev"]}</span>'
            f'<span class="pager-title">{html.escape(short)}</span></a>')
    else:
        parts.append('<span class="pager-link pager-empty"></span>')
    if index + 1 < len(items):
        target, short, full = items[index + 1]
        parts.append(
            f'<a class="pager-link pager-next" href="{site_href(Path(locale) / target, locale, page)}">'
            f'<span class="pager-dir">{labels["pager_next"]} →</span>'
            f'<span class="pager-title">{html.escape(short)}</span></a>')
    else:
        parts.append(
            f'<a class="pager-link pager-next pager-finish" href="{site_href(Path(locale) / "lessons/DIRECTORY.html", locale, page)}">'
            f'<span class="pager-dir">{labels["pager_end"]}</span>'
            f'<span class="pager-title">{labels["pager_all"]} →</span></a>')
    return (f'<nav class="lesson-pager" aria-label="{labels["pager_all"]}">'
            f'{"".join(parts)}</nav>')


def shell(locale: str, title: str, body: str, page: Path, home: bool = False) -> str:
    labels = LOCALES[locale]
    home_href = site_href(Path(locale) / "index.html", locale, page)
    directory = site_href(Path(locale) / "lessons/DIRECTORY.html", locale, page)
    extensions = site_href(Path(locale) / "extensions/README.html", locale, page)
    plugins = site_href(Path(locale) / "plugins.html", locale, page)
    gnucobol = site_href(Path(locale) / "gnucobol.html", locale, page)
    knowledge = site_href(Path(locale) / "knowledge.html", locale, page)
    languages = "".join(
        f'<a lang="{LOCALES[key]["html"]}" hreflang="{LOCALES[key]["html"]}"'
        f' class="{"current" if key == locale else ""}" href="{site_href(Path(key) / page, locale, page)}">{LOCALES[key]["name"]}</a>'
        for key in LOCALES
    )
    lessons = "\n".join(
        f'<a href="{site_href(Path(locale) / item, locale, page)}" title="{html.escape(full)}">'
        f'<span>{html.escape(item.parts[1][:2])}</span><em>{html.escape(short)}</em></a>'
        for item, short, full in lesson_items(locale)
    )
    if home:
        main = f'<main class="home">{body}</main>'
    else:
        main = (
            f'<div class="reading-layout"><aside class="course-nav">'
            f'<button class="course-toggle" type="button" aria-expanded="true" aria-label="{labels["course_collapse"]}" '
            f'title="{labels["course_collapse"]}" aria-controls="course-body" '
            f'data-expand-label="{labels["course_expand"]}" data-collapse-label="{labels["course_collapse"]}" '
            f'data-open-label="{labels["course_toggle"]}" data-closed-label="{labels["course_expand"]}">'
            f'<span class="course-toggle-label">{labels["course_toggle"]}</span>'
            f'<b class="course-count">32 {labels["lessons_label"]}</b>'
            f'<span class="course-toggle-icon" aria-hidden="true">‹</span></button>'
            f'<div class="course-body" id="course-body">'
            f'<div class="nav-heading">{labels["course_nav"]} <span>32</span></div>'
            f'<label class="search"><span>⌕</span><input id="course-search" type="search" '
            f'placeholder="{labels["search"]}" autocomplete="off"></label>'
            f'<div class="lesson-list" id="lesson-list">{lessons}</div></div>'
            f'<a class="directory-link" href="{directory}">{labels["directory_link"]}</a></aside>'
            f'<main class="article"><div class="article-top"><a href="{home_href}">{labels["nav_home"]}</a>'
            f'<span>/</span><span>{html.escape(title)}</span></div><article>{body}</article></main></div>'
        )
    return f'''<!doctype html>
<html lang="{labels["html"]}">
<head>
<meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<meta name="theme-color" content="#f5f5ed">
<script>(function(){{var theme;try{{theme=localStorage.getItem('cobol-theme')}}catch(e){{}}if(theme!=='light'&&theme!=='dark')theme=window.matchMedia&&matchMedia('(prefers-color-scheme: dark)').matches?'dark':'light';document.documentElement.dataset.theme=theme;}})();</script>
<meta name="description" content="GnuCOBOL 实战课程 · 32 lessons from COBOL basics to a bank nightly reconciliation system.">
<title>{html.escape(title)} · GnuCOBOL</title>
<link rel="icon" type="image/png" href="{site_href(Path(locale) / "assets/shire_200.png", locale, page)}">
<link rel="stylesheet" href="{site_href(Path(locale) / "assets/site.css", locale, page)}?v={ASSET_VERSION}">
<link rel="stylesheet" href="{site_href(Path(locale) / "assets/theme.css", locale, page)}?v={ASSET_VERSION}">
</head>
<body>
<div class="notice"><span class="notice-text">GnuCOBOL {html.escape(labels["brand_sub"])} <span>·</span> {html.escape(title)}</span></div>
<header class="masthead">
<a class="brand" href="{home_href}"><img src="{site_href(Path(locale) / "assets/shire_200.png", locale, page)}" alt="GnuCOBOL Shire horse mascot"><span><strong>GnuCOBOL</strong><small>{html.escape(labels["brand_sub"])}</small></span></a>
<button class="nav-toggle" type="button" aria-expanded="false" aria-controls="site-nav" aria-label="{labels["nav_menu"]}"><span class="nav-bars" aria-hidden="true"></span><span class="nav-toggle-label">{labels["nav_menu"]}</span></button>
<nav id="site-nav"><a href="{directory}">{labels["nav_directory"]}</a><a class="nav-plugin" href="{plugins}">{labels["nav_plugins"]}</a><details class="nav-library"><summary>{labels["nav_resources"]}</summary><div class="nav-library-menu"><a href="{knowledge}">{labels["nav_knowledge"]}</a><a href="{extensions}">{labels["nav_extensions"]}</a><a href="{gnucobol}">{labels["nav_gnucobol"]}</a></div></details><a class="nav-source" href="https://github.com/iamcheyan/cobol" aria-label="{labels["nav_source"]}" title="{labels["nav_source"]}" rel="noopener"><svg viewBox="0 0 24 24" aria-hidden="true"><path d="M12 .9a11.1 11.1 0 0 0-3.51 21.63c.55.1.76-.24.76-.54v-2.08c-3.1.67-3.76-1.31-3.76-1.31-.5-1.29-1.24-1.63-1.24-1.63-1.02-.7.08-.69.08-.69 1.13.08 1.73 1.16 1.73 1.16 1 1.72 2.62 1.22 3.26.93.1-.73.39-1.22.71-1.5-2.48-.28-5.09-1.24-5.09-5.52 0-1.22.44-2.22 1.16-3-.12-.28-.5-1.42.11-2.96 0 0 .95-.3 3.05 1.15a10.6 10.6 0 0 1 5.56 0c2.12-1.45 3.06-1.15 3.06-1.15.61 1.54.23 2.68.11 2.96.72.78 1.15 1.78 1.15 3 0 4.29-2.61 5.23-5.1 5.51.4.35.76 1.03.76 2.08v3.08c0 .3.2.65.77.54A11.1 11.1 0 0 0 12 .9Z"/></svg></a><div class="language-menu" aria-label="{labels["nav_lang"]}">{languages}</div></nav>
<button class="theme-toggle" type="button" aria-label="{html.escape(labels["theme_dark"])}" aria-pressed="false" data-dark-label="{html.escape(labels["theme_dark"])}" data-light-label="{html.escape(labels["theme_light"])}" title="{html.escape(labels["theme_dark"])}"><svg class="icon-moon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M20.5 14.6A8.6 8.6 0 1 1 9.4 3.5a6.9 6.9 0 0 0 11.1 11.1Z"/></svg><svg class="icon-sun" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><circle cx="12" cy="12" r="4.2"/><path d="M12 2.6v2.2M12 19.2v2.2M4.2 12H2M22 12h-2.2M6.5 6.5 5 5M19 19l-1.5-1.5M17.5 6.5 19 5M5 19l1.5-1.5"/></svg></button>
</header>
{main}
<footer><span>GnuCOBOL {html.escape(labels["brand_sub"])} · {labels["footer_compiler"]} <a href="https://gnucobol.sourceforge.io/" rel="noopener">GnuCOBOL</a></span><span>{html.escape(labels["footer"])} · <a href="https://github.com/iamcheyan/cobol">iamcheyan/cobol</a></span></footer>
<script src="{site_href(Path(locale) / "assets/site.js", locale, page)}?v={ASSET_VERSION}" defer></script>
</body></html>'''


PLUGIN_REPO = "https://github.com/iamcheyan/cobol.nvim"
PLUGIN_SNIPPET = '{\n  "iamcheyan/cobol.nvim",\n  ft = { "cobol", "cbl", "cob" },\n  opts = {},\n}'


def inline_code(text: str) -> str:
    """Escape text but render `backticked` fragments as inline code."""
    parts = re.split(r"`([^`]+)`", text)
    out = []
    for index, part in enumerate(parts):
        out.append(f"<code>{html.escape(part)}</code>" if index % 2 else html.escape(part))
    return "".join(out)


# `[label](href)`, `**bold**` and `` `code` `` in one pass. Bold and link text
# recurse, so `**`COMP-3` 公式**` renders code inside bold.
_INLINE_RE = re.compile(r"\[([^\]]+)\]\(([^)\s]+)\)|\*\*(.+?)\*\*|`([^`]+)`", re.S)


def inline_rich(text: str) -> str:
    """Escape text, rendering links, bold and inline code."""
    out, pos = [], 0
    for m in _INLINE_RE.finditer(text):
        out.append(html.escape(text[pos:m.start()]))
        if m.group(1) is not None:
            out.append(
                f'<a href="{html.escape(m.group(2), quote=True)}">{inline_rich(m.group(1))}</a>'
            )
        elif m.group(3) is not None:
            out.append(f"<strong>{inline_rich(m.group(3))}</strong>")
        else:
            out.append(f"<code>{html.escape(m.group(4))}</code>")
        pos = m.end()
    out.append(html.escape(text[pos:]))
    return "".join(out)


def plugin_section(locale: str) -> str:
    labels = LOCALES[locale]
    return (
        f'<section class="plugin-band"><div class="plugin-copy">'
        f'<p class="eyebrow">{labels["plugin_eyebrow"]}</p><h2>cobol.nvim</h2>'
        f'<p>{inline_code(labels["plugin_lead"])}</p>'
        f'<div class="plugin-actions"><a class="primary" href="plugins.html">{labels["plugin_open"]} <span>→</span></a>'
        f'<a class="text-link" href="{PLUGIN_REPO}">{labels["plugin_repo"]} ↗</a></div></div>'
        f'<a class="plugin-preview" href="plugins.html" aria-label="{labels["plugin_open"]}">'
        f'<img src="assets/plugin/overview.png" alt="{html.escape(labels["plugin_figure"])}">'
        f'<span>{labels["plugin_preview_label"]} <b>↗</b></span></a></section>'
    )


def plugins_page(locale: str) -> str:
    labels = LOCALES[locale]
    features = "".join(
        f'<figure class="plugin-feature"><img src="assets/plugin/{shot}" alt="{html.escape(name)}" loading="lazy">'
        f'<figcaption><strong>{html.escape(name)}</strong><span>{inline_code(desc)}</span>'
        f'<small>{inline_code(note)}</small></figcaption></figure>'
        for name, desc, shot, note in labels["plugin_features"]
    )
    return (
        f'<p class="eyebrow">{labels["plugin_eyebrow"]}</p>'
        f'<h1>cobol.nvim</h1>'
        f'<p class="plugin-lead">{inline_code(labels["plugin_lead"])}</p>'
        f'<figure class="plugin-figure"><img src="assets/plugin/structure-scope.png" alt="Neovim: Syms outline, Winbar and paired IF ELSE END-IF scope badges with dashed line" width="2726" height="2104">'
        f'<figcaption>{labels["plugin_figure"]}</figcaption></figure>'
        f'<h2>{labels["plugin_install"]}</h2>'
        f'<pre><code>{html.escape(PLUGIN_SNIPPET)}</code></pre>'
        f'<h2>{labels["plugin_features_title"]}</h2>'
        f'<div class="plugin-features">{features}</div>'
        f'<p class="plugin-note">{inline_code(labels["plugin_requirements"])}</p>'
        f'<div class="plugin-actions"><a class="primary" href="{PLUGIN_REPO}">{labels["plugin_repo"]} ↗</a>'
        f'<a class="text-link" href="extensions/neovim-tooling/README.html">{labels["plugin_tutorials"]} →</a></div>'
        f'<p class="plugin-license">{labels["plugin_license"]}</p>'
    )




def _prose(paragraphs, css_class: str = "") -> str:
    cls = f' class="{css_class}"' if css_class else ""
    return f'<div{cls}>' + "".join(f'<p>{inline_rich(p)}</p>' for p in paragraphs) + "</div>"


def _bullets(items) -> str:
    return '<ul class="plain-list">' + "".join(f'<li>{inline_rich(i)}</li>' for i in items) + "</ul>"


def _table(head, rows) -> str:
    thead = "".join(f"<th>{inline_rich(h)}</th>" for h in head)
    tbody = "".join(
        "<tr>" + "".join(f"<td>{inline_rich(c)}</td>" for c in row) + "</tr>" for row in rows
    )
    return f'<div class="table-wrap"><table><thead><tr>{thead}</tr></thead><tbody>{tbody}</tbody></table></div>'


def about_page(locale: str) -> str:
    """What COBOL is: origin, standard history, industries, current relevance."""
    data = ABOUT[locale]
    blocks = []
    for sec in data["sections"]:
        part = [f'<h2 id="{sec["id"]}">{html.escape(sec["title"])}</h2>']
        if sec.get("intro"):
            part.append(f'<p>{inline_rich(sec["intro"])}</p>')
        kind = sec["kind"]
        if kind == "prose":
            part.append(_prose(sec.get("body", [])))
            if sec.get("bullets"):
                part.append(_bullets(sec["bullets"]))
            if sec.get("after"):
                part.append(_prose(sec["after"]))
        elif kind == "timeline":
            items = "".join(
                f'<li><span class="tl-date">{html.escape(date)}</span>'
                f'<div class="tl-body"><strong>{html.escape(name)}</strong>'
                f'<span>{inline_rich(desc)}</span></div></li>'
                for date, name, desc in sec["items"]
            )
            part.append(f'<ol class="timeline">{items}</ol>')
            if sec.get("after"):
                part.append(_prose(sec["after"]))
        elif kind == "table":
            part.append(_table(sec["head"], sec["rows"]))
            if sec.get("after"):
                part.append(_prose(sec["after"]))
        elif kind == "code":
            part.append(f'<pre><code>{html.escape(sec["code"])}</code></pre>')
            if sec.get("after"):
                part.append(_prose(sec["after"]))
        blocks.append("".join(part))
    return (
        f'<p class="eyebrow">{data["eyebrow"]}</p>'
        f'<h1>{html.escape(data["title"])}</h1>'
        f'<p class="plugin-lead">{inline_rich(data["lead"])}</p>'
        + "".join(blocks)
        + f'<p class="plugin-license">{inline_rich(data["source_note"])}</p>'
    )


def reference_page(locale: str) -> str:
    """Cheat sheet: format, skeleton, data, PIC, USAGE, statements, status codes."""
    data = REFERENCE[locale]
    blocks = []
    for sec in data["sections"]:
        part = [f'<h2 id="{sec["id"]}">{html.escape(sec["title"])}</h2>']
        if sec.get("intro"):
            part.append(f'<p>{inline_rich(sec["intro"])}</p>')
        if sec.get("kind") == "code":
            part.append(f'<pre><code>{html.escape(sec["code"])}</code></pre>')
        else:
            part.append(_table(sec["head"], sec["rows"]))
        if sec.get("table2_title"):
            part.append(f'<h3>{html.escape(sec["table2_title"])}</h3>')
            part.append(_table(sec["table2_head"], sec["table2_rows"]))
        if sec.get("after"):
            part.append(_prose(sec["after"]))
        blocks.append("".join(part))
    return (
        f'<p class="eyebrow">{data["eyebrow"]}</p>'
        f'<h1>{html.escape(data["title"])}</h1>'
        f'<p class="plugin-lead">{inline_rich(data["lead"])}</p>'
        f'<label class="ref-search"><span aria-hidden="true">⌕</span>'
        f'<input id="ref-search" type="search" placeholder="{html.escape(data["search_placeholder"])}" '
        f'aria-label="{html.escape(data["search_label"])}" autocomplete="off"></label>'
        f'<p class="ref-empty" id="ref-empty" hidden>{html.escape(data["no_match"])}</p>'
        '<div class="ref-body" id="ref-body">'
        + "".join(blocks)
        + '</div>'
        + f'<p class="plugin-license">{inline_rich(data["note"])}</p>'
    )



KNOWLEDGE_PAGES = ("about", "history", "hardware", "reference", "glossary")


def _knowledge_nav(locale: str, current: str, page: Path) -> str:
    """Small cross-link strip shown on every knowledge page."""
    labels = LOCALES[locale]
    items = []
    for key in KNOWLEDGE_PAGES:
        href = site_href(Path(locale) / f"{key}.html", locale, page)
        cls = ' class="current"' if key == current else ""
        items.append(f'<a href="{href}"{cls}>{html.escape(labels[f"kn_{key}"])}</a>')
    return f'<nav class="kn-nav">{"".join(items)}</nav>'


def _kn_sections(locale: str, data: dict) -> str:
    """Render the shared section shapes used by history and glossary."""
    blocks = []
    for sec in data["sections"]:
        part = [f'<h2 id="{sec["id"]}">{html.escape(sec["title"])}</h2>']
        if sec.get("intro"):
            part.append(f'<p>{inline_rich(sec["intro"])}</p>')
        kind = sec.get("kind")
        if kind == "code":
            part.append(f'<pre><code>{html.escape(sec["code"])}</code></pre>')
        elif kind == "prose":
            part.append(_prose(sec.get("body", [])))
            if sec.get("bullets"):
                part.append(_bullets(sec["bullets"]))
        else:
            part.append(_table(sec["head"], sec["rows"]))
        if sec.get("after"):
            part.append(_prose(sec["after"]))
        blocks.append("".join(part))
    return "".join(blocks)


def history_page(locale: str) -> str:
    """How COBOL came to be: people, disputes, standards."""
    data = HISTORY[locale]
    return (
        _knowledge_nav(locale, "history", Path("history.html"))
        + f'<p class="eyebrow">{data["eyebrow"]}</p>'
        + f'<h1>{html.escape(data["title"])}</h1>'
        + f'<p class="plugin-lead">{inline_rich(data["lead"])}</p>'
        + _kn_sections(locale, data)
        + f'<p class="plugin-license">{inline_rich(data["note"])}</p>'
    )


def hardware_illustration(locale: str) -> str:
    """Inline SVG overview: four hardware eras, with compact editorial symbols."""
    data = HARDWARE[locale]
    labels = [era["date"] for era in data["eras"]]
    icons = [
        '<rect x="24" y="30" width="72" height="88" rx="3"/><circle cx="38" cy="44" r="2"/><circle cx="52" cy="44" r="2"/><circle cx="66" cy="44" r="2"/><circle cx="80" cy="44" r="2"/><circle cx="38" cy="58" r="2"/><circle cx="66" cy="58" r="2"/><circle cx="80" cy="72" r="2"/><path d="M36 92h48"/>',
        '<rect x="25" y="42" width="44" height="62" rx="20"/><circle cx="83" cy="73" r="25"/><circle cx="83" cy="73" r="7"/><path d="M69 73h8M89 73h10M25 53h44M25 92h44"/>',
        '<rect x="22" y="28" width="78" height="90" rx="3"/><path d="M34 42h54M34 58h54M34 74h54M34 90h54"/><circle cx="88" cy="42" r="2"/><circle cx="88" cy="58" r="2"/>',
        '<rect x="20" y="32" width="82" height="55" rx="4"/><path d="M61 87v15M43 104h36"/><rect x="67" y="76" width="38" height="28" rx="3"/><path d="M72 82h28M72 88h28M72 94h20"/>',
    ]
    blocks = []
    for i, (label, icon) in enumerate(zip(labels, icons)):
        x = 22 + i * 172
        blocks.append(
            f'<g transform="translate({x} 0)" class="hardware-era-icon era-tone-{i+1}"><rect class="hardware-panel" x="0" y="0" width="146" height="178" rx="3"/>'
            f'<g class="hardware-icon" transform="translate(18 12)">{icon}</g>'
            f'<text class="hardware-number" x="12" y="145">0{i+1}</text>'
            f'<text class="hardware-label" x="38" y="145">{html.escape(label)}</text></g>'
        )
    return ('<figure class="hardware-figure"><svg viewBox="0 0 710 178" role="img" aria-label="'
            + html.escape(data["title"], quote=True) + '">' + ''.join(blocks)
            + '</svg><figcaption>' + html.escape(data["columns_intro"]) + '</figcaption></figure>')


def hardware_page(locale: str) -> str:
    """Illustrated hardware timeline and COBOL's evolving compatibility contracts."""
    data = HARDWARE[locale]
    timeline = []
    for i, era in enumerate(data["eras"]):
        timeline.append(
            f'<section class="hardware-era" id="era-{i+1}"><div class="hardware-era-index">0{i+1}</div>'
            f'<div class="hardware-era-content"><p class="hardware-date">{html.escape(era["date"])}</p>'
            f'<h2>{html.escape(era["title"])}</h2><p class="hardware-device">{html.escape(era["hardware"])}</p>'
            f'<p>{inline_rich(era["body"])}</p><h3>COBOL</h3><p>{inline_rich(era["cobol"])}</p>'
            f'<div class="hardware-legacy"><strong>{html.escape(data["eyebrow"])}</strong><p>{inline_rich(era["legacy"])}</p></div>'
            f'</div></section>'
        )
    columns = ''.join(
        f'<div class="hardware-column-row"><code>{html.escape(col)}</code><strong>{html.escape(name)}</strong>'
        f'<span>{inline_rich(desc)}</span></div>' for col, name, desc in data["columns"]
    )
    return (
        _knowledge_nav(locale, "hardware", Path("hardware.html"))
        + f'<p class="eyebrow">{data["eyebrow"]}</p><h1>{html.escape(data["title"])}</h1>'
        + f'<p class="plugin-lead">{inline_rich(data["lead"])}</p>'
        + hardware_illustration(locale)
        + '<div class="hardware-timeline">' + ''.join(timeline) + '</div>'
        + f'<section class="hardware-columns"><h2>{html.escape(data["columns_title"])}</h2>'
        + f'<p>{inline_rich(data["columns_intro"])}</p><div class="hardware-column-table">{columns}</div>'
        + f'<p class="hardware-line-note">{inline_rich(data["line_number_note"])}</p></section>'
        + f'<p class="plugin-license">{inline_rich(data["note"])}</p>'
    )


def glossary_page(locale: str) -> str:
    """Terminology lookup, filterable in place."""
    data = GLOSSARY[locale]
    blocks = []
    for group in [*data["groups"], JAPAN_TERMS[locale]]:
        rows = "".join(
            f'<tr><th scope="row">{inline_rich(term)}</th><td>{inline_rich(desc)}</td></tr>'
            for term, desc in group["terms"]
        )
        blocks.append(
            f'<h2 id="{group["id"]}">{html.escape(group["title"])}</h2>'
            f'<div class="table-wrap"><table class="term-table"><tbody>{rows}</tbody></table></div>'
        )
    return (
        _knowledge_nav(locale, "glossary", Path("glossary.html"))
        + f'<p class="eyebrow">{data["eyebrow"]}</p>'
        + f'<h1>{html.escape(data["title"])}</h1>'
        + f'<p class="plugin-lead">{inline_rich(data["lead"])}</p>'
        + f'<label class="ref-search"><span aria-hidden="true">⌕</span>'
        + f'<input id="ref-search" type="search" placeholder="{html.escape(data["search_placeholder"])}" '
        + f'aria-label="{html.escape(data["search_placeholder"])}" autocomplete="off"></label>'
        + f'<p class="ref-empty" id="ref-empty" hidden>{html.escape(data["no_match"])}</p>'
        + '<div class="ref-body" id="ref-body">' + "".join(blocks) + '</div>'
    )


def knowledge_page(locale: str) -> str:
    """Hub that indexes the four knowledge pages."""
    labels = LOCALES[locale]
    cards = [
        ("about", labels["kn_about_desc"]),
        ("history", labels["kn_history_desc"]),
        ("hardware", labels["kn_hardware_desc"]),
        ("reference", labels["kn_reference_desc"]),
        ("glossary", labels["kn_glossary_desc"]),
    ]
    items = "".join(
        f'<a class="kn-card" href="{key}.html"><strong>{html.escape(labels[f"kn_{key}"])}</strong>'
        f'<span>{inline_rich(desc)}</span><b>→</b></a>'
        for key, desc in cards
    )
    return (
        f'<p class="eyebrow">{labels["kn_eyebrow"]}</p>'
        f'<h1>{html.escape(labels["kn_title"])}</h1>'
        f'<p class="plugin-lead">{inline_rich(labels["kn_lead"])}</p>'
        f'<div class="kn-cards">{items}</div>'
        f'<p class="plugin-license">{inline_rich(labels["kn_note"])}</p>'
    )


def gnucobol_page(locale: str) -> str:
    """The page that documents how this site is paired with GnuCOBOL itself."""
    labels = LOCALES[locale]
    flow = "".join(
        f'<li><strong>{inline_code(name)}</strong><span>{inline_code(desc)}</span></li>'
        for name, desc in labels["gnucobol_flow"]
    )
    resources = "".join(
        f'<a class="resource-row" href="{url}" rel="noopener"><span>{html.escape(name)}</span>'
        f'<strong>{inline_code(desc)}</strong><b>↗</b></a>'
        for name, desc, url in labels["gnucobol_resources"]
    )
    features = "".join(f'<li>{inline_code(item)}</li>' for item in labels["gnucobol_features"])
    return (
        f'<p class="eyebrow">{labels["gnucobol_eyebrow"]}</p>'
        f'<h1>GnuCOBOL</h1>'
        f'<p class="plugin-lead">{inline_code(labels["gnucobol_lead"])}</p>'
        f'<h2>{labels["gnucobol_flow_title"]}</h2>'
        f'<ol class="flow-list">{flow}</ol>'
        f'<h2>{labels["gnucobol_features_title"]}</h2>'
        f'<ul class="plain-list">{features}</ul>'
        f'<h2>{labels["gnucobol_resources_title"]}</h2>'
        f'<div class="resource-rows">{resources}</div>'
        f'<h2>{labels["gnucobol_versions_title"]}</h2>'
        f'<p>{inline_code(labels["gnucobol_versions"])}</p>'
        f'<p class="plugin-license">{inline_code(labels["gnucobol_note"])}</p>'
    )


def homepage(locale: str) -> str:
    labels = LOCALES[locale]
    stages = "".join(
        f'<a href="lessons/DIRECTORY.html"{"" if index < 5 else " class=\"capstone\""}>'
        f'<span>{rng}</span><strong>{name}</strong><small>{desc}</small></a>'
        for index, (rng, name, desc) in enumerate(labels["stages"])
    )
    body = f'''<section class="hero"><div class="hero-copy"><p class="eyebrow">{labels["hero_eyebrow"]}</p><h1>{labels["hero_h1"]}<br><em>{labels["hero_h1_em"]}</em></h1><p class="intro">{labels["hero_intro"]}</p><div class="hero-actions"><a class="primary" href="lessons/01_hello-cobol/README.html">{labels["hero_cta"]} <span>→</span></a><a class="text-link" href="lessons/DIRECTORY.html">{labels["hero_cta2"]}</a></div></div><div class="horse"><img src="assets/shire_200.png" alt="GnuCOBOL Shire horse mascot"><span>GNU COBOL</span></div></section>
<section class="course-overview"><div class="section-title"><div><p class="eyebrow">{labels["path_eyebrow"]}</p><h2>{labels["path_title"]}</h2></div><a href="lessons/DIRECTORY.html">{labels["path_link"]}</a></div><div class="stages">{stages}</div></section>
<section class="start-row"><div><p class="eyebrow">{labels["start_eyebrow"]}</p><h2>{labels["start_title"]}</h2><p>{labels["start_text"]}</p></div><div class="start-command"><span>{labels["start_term"]}</span><code>sudo apt install gnucobol make</code><a href="lessons/01_hello-cobol/README.html">{labels["start_open"]} <b>↗</b></a></div></section>
{plugin_section(locale)}
<section class="more-reading"><div><p class="eyebrow">{labels["more_eyebrow"]}</p><h2>{labels["more_title"]}</h2></div><a href="knowledge.html"><span>{labels["more_kn"]}</span><strong>{labels["more_kn_desc"]}</strong><b>→</b></a><a href="extensions/README.html"><span>{labels["more_ext"]}</span><strong>{labels["more_ext_desc"]}</strong><b>→</b></a><a href="gnucobol.html"><span>{labels["nav_gnucobol"]}</span><strong>{labels["more_gnu_desc"]}</strong><b>→</b></a></section>'''
    return shell(locale, labels["nav_home"], body, Path("index.html"), home=True)


def build_locale(locale: str) -> int:
    root = OUT / locale
    root.mkdir(parents=True, exist_ok=True)
    shutil.copytree(OUT / "assets", root / "assets", dirs_exist_ok=True)
    shutil.copy2(ROOT / "Makefile", root / "Makefile")
    pages = 0
    for source in page_sources():
        rel = output_rel(source)
        dest = root / rel
        dest.parent.mkdir(parents=True, exist_ok=True)
        if is_lesson_workspace(source):
            body = lesson_workspace(locale, source, rel)
        else:
            body = render_markdown(source, locale)
            if locale != "zh-cn" and translated(source, locale) is None:
                body = pending(locale, source, rel) + body
        dest.write_text(shell(locale, title_of(source, locale), body, rel), encoding="utf-8")
        pages += 1
    for source in resource_sources():
        rel = source.relative_to(ROOT)
        chosen = translated(source, locale)
        target = root / rel
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(chosen or source, target)
    (root / "index.html").write_text(homepage(locale), encoding="utf-8")
    (root / "plugins.html").write_text(
        shell(locale, "cobol.nvim", plugins_page(locale), Path("plugins.html")), encoding="utf-8")
    (root / "gnucobol.html").write_text(
        shell(locale, LOCALES[locale]["gnucobol_title"], gnucobol_page(locale), Path("gnucobol.html")), encoding="utf-8")
    (root / "about.html").write_text(
        shell(locale, LOCALES[locale]["about_title"], about_page(locale), Path("about.html")), encoding="utf-8")
    (root / "reference.html").write_text(
        shell(locale, LOCALES[locale]["reference_title"], reference_page(locale), Path("reference.html")), encoding="utf-8")
    (root / "history.html").write_text(
        shell(locale, LOCALES[locale]["kn_history"], history_page(locale), Path("history.html")), encoding="utf-8")
    (root / "hardware.html").write_text(
        shell(locale, LOCALES[locale]["kn_hardware"], hardware_page(locale), Path("hardware.html")), encoding="utf-8")
    (root / "glossary.html").write_text(
        shell(locale, LOCALES[locale]["kn_glossary"], glossary_page(locale), Path("glossary.html")), encoding="utf-8")
    (root / "knowledge.html").write_text(
        shell(locale, LOCALES[locale]["kn_title"], knowledge_page(locale), Path("knowledge.html")), encoding="utf-8")
    return pages


CJK_RE = re.compile(r"[\u3400-\u4dbf\u4e00-\u9fff\u3040-\u30ff]")


def needs_translation(path: Path) -> bool:
    """True when a file has prose that should differ per language.

    Excluded on purpose:
    * binary content;
    * files without Chinese/Japanese characters (already language-neutral);
    * literal artifacts -- expected program output, fixtures and sample data --
      because translating them would stop matching what the programs actually
      print.
    """
    rel_parts = set(path.parts)
    if rel_parts & {"expected", "fixtures", "db"}:
        return False
    if path.name.startswith("expected"):
        return False
    if path.suffix.lower() in {".dat", ".csv", ".png", ".jpg", ".gif", ".pdf"}:
        return False
    try:
        raw = path.read_bytes()[:16384]
    except OSError:
        return False
    if b"\0" in raw:
        return False
    try:
        text = path.read_text(encoding="utf-8")
    except (UnicodeDecodeError, OSError):
        return False
    return bool(CJK_RE.search(text))


def write_manifest() -> None:
    candidates = sorted(rel.as_posix() for rel in
                        [s.relative_to(ROOT) for s in page_sources()] +
                        [s.relative_to(ROOT) for s in resource_sources()])
    files = [rel for rel in candidates if needs_translation(ROOT / rel)]
    manifest = {
        "source_language": "zh-cn",
        "target_languages": ["en", "ja"],
        "translation_directory": "site-src/translations/<locale>/<same-relative-path>",
        "health_check": "python3 scripts/check_translations.py",
        "files": files,
    }
    (ROOT / "site-src" / "translation-manifest.json").write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def main() -> None:
    if OUT.exists():
        shutil.rmtree(OUT)
    (OUT / "assets").mkdir(parents=True)
    for name in ("site.css", "theme.css", "site.js", "shire_200.png"):
        shutil.copy2(ROOT / "site-src" / name, OUT / "assets" / name)
    plugin_images = ROOT / "site-src" / "plugin"
    if plugin_images.is_dir():
        shutil.copytree(plugin_images, OUT / "assets" / "plugin", dirs_exist_ok=True)
    total = 0
    for locale in LOCALES:
        total += build_locale(locale)
    (OUT / "CNAME").write_text("cobol.iamcheyan.com\n", encoding="ascii")
    # The audience is Japanese business readers, so the bare domain lands on
    # the Japanese tree; the language switcher covers zh-cn and en.
    (OUT / "index.html").write_text(
        '<!doctype html><html lang="ja"><head><meta charset="utf-8">'
        '<meta http-equiv="refresh" content="0;url=ja/index.html">'
        '<meta name="viewport" content="width=device-width,initial-scale=1">'
        '<title>GnuCOBOL 実践コース</title></head><body>'
        '<p><a href="ja/index.html">日本語</a> · <a href="zh-cn/index.html">简体中文</a>'
        ' · <a href="en/index.html">English</a></p></body></html>', encoding="utf-8")
    write_manifest()
    print(f"Rendered {len(LOCALES)} locales, {total} pages ({total // len(LOCALES)} per locale) to {OUT}")


if __name__ == "__main__":
    main()
