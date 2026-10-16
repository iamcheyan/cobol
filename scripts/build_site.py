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
        "html": "zh-CN", "name": "简体中文", "brand_sub": "实战课程",
        "nav_home": "课程首页", "nav_directory": "32 课目录", "nav_extensions": "拓展课程",
        "nav_source": "GitHub 源码", "nav_lang": "语言", "course_nav": "课程导航",
        "search": "筛选课程", "directory_link": "查看完整课程目录 →",
        "tab_guide": "课程讲义", "tab_exercise": "动手练习", "tab_answer": "参考答案", "tab_resources": "源码与资料",
        "download": "下载文件 ↓", "pending_page": "此内容的翻译正在准备中。以下先显示中文原文。",
        "pending_resource": "此文件暂无该语言版本，下面显示中文原文。",
        "view_source": "查看中文原文 →", "unsupported": "此资源不适合直接预览，可下载后在本地打开。",
        "footer": "课程源码与练习材料",
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
        "start_text": "准备 GnuCOBOL 与 Make，从第一课开始编译、修改、练习。源码、输入数据和参考答案都与讲义一起浏览。",
        "start_term": "终端 · Debian / Ubuntu", "start_open": "打开第 01 课",
        "more_eyebrow": "BEYOND THE MAIN COURSE", "more_title": "继续探索",
        "more_ext": "拓展课程", "more_ext_desc": "旧版专题、企业批处理与编辑器教程",
        "more_src": "课程源码", "more_src_desc": "查看代码、夹具与构建脚本",
        "nav_plugins": "编辑器插件",
        "nav_menu": "菜单",
        "nav_close": "关闭",
        "theme_dark": "切换到深色主题", "theme_light": "切换到浅色主题",
        "theme_dark_short": "深色", "theme_light_short": "浅色",
        "course_toggle": "课程目录",
        "lessons_label": "课",
        "plugin_eyebrow": "EDITOR PLUGIN",
        "plugin_lead": "`cobol.nvim` 是本课程配套的 Neovim 插件，把固定格式 COBOL 的列规则、记录布局和编译器反馈直接放进编辑器：写代码时就能看到穿孔卡标尺、结构和错误。",
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
        "plugin_requirements": "需要 Neovim 与 GnuCOBOL；实时语法诊断依赖 `cobc`，结构大纲侧边栏依赖可选的 `aerial.nvim`。",
        "plugin_license": "MIT 许可，源码公开。",
        "plugin_open": "了解并安装 cobol.nvim",
        "plugin_figure": "Neovim 实际画面：Syms 大纲、固定格式列标尺、Winbar 和 IF / ELSE / END-IF 的彩色配对及连接虚线。Syms 是另装的界面；插件另提供 Aerial 后端。",
    },
    "en": {
        "html": "en", "name": "English", "brand_sub": "Practical Course",
        "nav_home": "Home", "nav_directory": "32 lessons", "nav_extensions": "Extensions",
        "nav_source": "GitHub source", "nav_lang": "Language", "course_nav": "Course contents",
        "search": "Filter lessons", "directory_link": "View the full curriculum →",
        "tab_guide": "Lesson", "tab_exercise": "Exercise", "tab_answer": "Answer key", "tab_resources": "Code & files",
        "download": "Download ↓", "pending_page": "This translation is being prepared. The Chinese original is shown below.",
        "pending_resource": "This file has no English version yet; the Chinese original is shown below.",
        "view_source": "Read the Chinese original →", "unsupported": "Preview is unavailable for this file; download it to open locally.",
        "footer": "Course source and practice material",
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
        "start_text": "Install GnuCOBOL and Make, then compile, modify and practise from lesson one. Source code, fixtures and answer keys sit next to each lesson.",
        "start_term": "Terminal · Debian / Ubuntu", "start_open": "Open lesson 01",
        "more_eyebrow": "BEYOND THE MAIN COURSE", "more_title": "Keep exploring",
        "more_ext": "Extensions", "more_ext_desc": "Legacy topics, enterprise batch and editor tutorials",
        "more_src": "Course source", "more_src_desc": "Code, fixtures and build scripts",
        "nav_plugins": "Editor plugin",
        "nav_menu": "Menu",
        "nav_close": "Close",
        "theme_dark": "Switch to dark theme", "theme_light": "Switch to light theme",
        "theme_dark_short": "Dark", "theme_light_short": "Light",
        "course_toggle": "Lessons",
        "lessons_label": "lessons",
        "plugin_eyebrow": "EDITOR PLUGIN",
        "plugin_lead": "`cobol.nvim` is the Neovim plugin built alongside this course. It brings fixed-format COBOL rules, record layout and compiler feedback into the editor, so the punch-card ruler, structure and errors are visible while you type.",
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
        "plugin_requirements": "Neovim and GnuCOBOL are required; live diagnostics need `cobc`, and the outline sidebar needs the optional `aerial.nvim`.",
        "plugin_license": "MIT licensed, open source.",
        "plugin_open": "Get cobol.nvim",
        "plugin_figure": "A real Neovim session: the optional Syms outline, column guides, Winbar, and paired IF / ELSE / END-IF badges with a connecting line. The plugin also includes a separate Aerial backend.",
    },
    "ja": {
        "html": "ja", "name": "日本語", "brand_sub": "実践コース",
        "nav_home": "ホーム", "nav_directory": "全32レッスン", "nav_extensions": "発展教材",
        "nav_source": "GitHub ソース", "nav_lang": "言語", "course_nav": "コース目次",
        "search": "レッスンを絞り込む", "directory_link": "全カリキュラムを見る →",
        "tab_guide": "レッスン", "tab_exercise": "演習", "tab_answer": "解答例", "tab_resources": "コード・資料",
        "download": "ダウンロード ↓", "pending_page": "このページは翻訳準備中です。以下は中国語の原文です。",
        "pending_resource": "このファイルの日本語版は未作成です。以下は中国語の原文です。",
        "view_source": "中国語の原文を見る →", "unsupported": "このファイルはプレビューできません。ダウンロードして開いてください。",
        "footer": "コースのソースと演習資料",
        "hero_eyebrow": "GNU COBOL · PRACTICAL COURSE",
        "hero_h1": "最初の COBOL ステートメントから、", "hero_h1_em": "銀行の夜間照合システムまで。",
        "hero_intro": "段階的に学ぶ GnuCOBOL 実践コース。解説を読み、プログラムを動かし、演習をこなし、実際のバッチ処理を組み上げます。",
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
        "start_eyebrow": "START HERE", "start_title": "どのレッスンも手元で動かせます",
        "start_text": "GnuCOBOL と Make を用意し、第1課からコンパイル・修正・演習を進めます。ソースコード、入力データ、解答例も各レッスンと一緒に閲覧できます。",
        "start_term": "ターミナル · Debian / Ubuntu", "start_open": "レッスン01を開く",
        "more_eyebrow": "BEYOND THE MAIN COURSE", "more_title": "さらに学ぶ",
        "more_ext": "発展教材", "more_ext_desc": "旧版のトピック、企業バッチ、エディタのチュートリアル",
        "more_src": "コースのソース", "more_src_desc": "コード、フィクスチャ、ビルドスクリプト",
        "nav_plugins": "エディタプラグイン",
        "nav_menu": "メニュー",
        "nav_close": "閉じる",
        "theme_dark": "ダークテーマに切り替える", "theme_light": "ライトテーマに切り替える",
        "theme_dark_short": "ダーク", "theme_light_short": "ライト",
        "course_toggle": "レッスン一覧",
        "lessons_label": "レッスン",
        "plugin_eyebrow": "EDITOR PLUGIN",
        "plugin_lead": "`cobol.nvim` は本コースとともに育てている Neovim プラグインです。固定形式 COBOL の桁ルール、レコードレイアウト、コンパイラのフィードバックをエディタに持ち込み、書いているそばから桁定規・構造・エラーが見えます。",
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
        "plugin_requirements": "Neovim と GnuCOBOL が必要です。リアルタイム診断には `cobc`、アウトライン表示には任意の `aerial.nvim` を使います。",
        "plugin_license": "MIT ライセンスで公開しています。",
        "plugin_open": "cobol.nvim を導入する",
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


def fix_links(content: str, source: Path) -> str:
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
    return MD.convert(fix_links(text, source))


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


def lesson_panel(locale: str, key: str, source: Path, page: Path) -> str:
    labels = LOCALES[locale]
    has_translation = translated(source, locale) is not None
    notice = "" if has_translation or locale == "zh-cn" else pending(locale, source, page)
    active = " active" if key == "guide" else ""
    hidden = "" if key == "guide" else " hidden"
    return (
        f'<section class="lesson-panel{active}" id="panel-{key}" data-panel="{key}"{hidden}>'
        f'{notice}<article>{render_markdown(source, locale)}</article></section>'
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
        with_original = locale != "zh-cn" and localized is None and suffix in TEXT_SUFFIXES
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
                views.append(
                    f'<div class="resource-view" id="resource-{index}" data-resource="{index}" hidden>'
                    f'<div class="resource-heading"><span>{html.escape(label)}</span>'
                    f'<a href="{rel_from_page}" download>{labels["download"]}</a></div>'
                    f'{note}<pre><code class="language-{language}">{body}</code></pre></div>'
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
        lesson_panel(locale, "guide", source, page),
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


def shell(locale: str, title: str, body: str, page: Path, home: bool = False) -> str:
    labels = LOCALES[locale]
    home_href = site_href(Path(locale) / "index.html", locale, page)
    directory = site_href(Path(locale) / "lessons/DIRECTORY.html", locale, page)
    extensions = site_href(Path(locale) / "extensions/README.html", locale, page)
    plugins = site_href(Path(locale) / "plugins.html", locale, page)
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
            f'<button class="course-toggle" type="button" aria-expanded="false" aria-controls="course-body">'
            f'<span>{labels["course_toggle"]}</span><b>32 {labels["lessons_label"]}</b></button>'
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
<button class="theme-toggle" type="button" aria-label="{html.escape(labels["theme_dark"])}" aria-pressed="false" data-dark-label="{html.escape(labels["theme_dark"])}" data-light-label="{html.escape(labels["theme_light"])}" data-dark-short="{html.escape(labels["theme_dark_short"])}" data-light-short="{html.escape(labels["theme_light_short"])}"><span class="theme-icon" aria-hidden="true">◐</span><span class="theme-label">{html.escape(labels["theme_dark_short"])}</span></button>
<button class="nav-toggle" type="button" aria-expanded="false" aria-controls="site-nav" aria-label="{labels["nav_menu"]}"><span class="nav-bars" aria-hidden="true"></span><span class="nav-toggle-label">{labels["nav_menu"]}</span></button>
<nav id="site-nav"><a href="{home_href}">{labels["nav_home"]}</a><a href="{directory}">{labels["nav_directory"]}</a><a href="{extensions}">{labels["nav_extensions"]}</a><a href="{plugins}">{labels["nav_plugins"]}</a><a href="https://github.com/iamcheyan/cobol">{labels["nav_source"]}</a><div class="language-menu" aria-label="{labels["nav_lang"]}">{languages}</div></nav>
</header>
{main}
<footer><span>GnuCOBOL {html.escape(labels["brand_sub"])}</span><span>{html.escape(labels["footer"])} · <a href="https://github.com/iamcheyan/cobol">iamcheyan/cobol</a></span></footer>
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


def plugin_section(locale: str) -> str:
    labels = LOCALES[locale]
    return (
        f'<section class="plugin-band"><div class="plugin-copy">'
        f'<p class="eyebrow">{labels["plugin_eyebrow"]}</p><h2>cobol.nvim</h2>'
        f'<p>{inline_code(labels["plugin_lead"])}</p>'
        f'<div class="plugin-actions"><a class="primary" href="plugins.html">{labels["plugin_open"]} <span>→</span></a>'
        f'<a class="text-link" href="{PLUGIN_REPO}">{labels["plugin_repo"]} ↗</a></div></div>'
        f'<div class="plugin-snippet"><span>{labels["plugin_install"]}</span>'
        f'<pre><code>{html.escape(PLUGIN_SNIPPET)}</code></pre></div></section>'
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
<section class="more-reading"><div><p class="eyebrow">{labels["more_eyebrow"]}</p><h2>{labels["more_title"]}</h2></div><a href="extensions/README.html"><span>{labels["more_ext"]}</span><strong>{labels["more_ext_desc"]}</strong><b>→</b></a><a href="https://github.com/iamcheyan/cobol"><span>{labels["more_src"]}</span><strong>{labels["more_src_desc"]}</strong><b>→</b></a></section>'''
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
    return pages


def write_manifest() -> None:
    files = sorted(rel.as_posix() for rel in
                   [s.relative_to(ROOT) for s in page_sources()] +
                   [s.relative_to(ROOT) for s in resource_sources()])
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
    (OUT / "index.html").write_text(
        '<!doctype html><html lang="zh-CN"><head><meta charset="utf-8">'
        '<meta http-equiv="refresh" content="0;url=zh-cn/index.html">'
        '<meta name="viewport" content="width=device-width,initial-scale=1">'
        '<title>GnuCOBOL 实战课程</title></head><body>'
        '<a href="zh-cn/index.html">进入 GnuCOBOL 实战课程</a></body></html>', encoding="utf-8")
    write_manifest()
    print(f"Rendered {len(LOCALES)} locales, {total} pages ({total // len(LOCALES)} per locale) to {OUT}")


if __name__ == "__main__":
    main()
