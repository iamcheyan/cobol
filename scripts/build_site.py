#!/usr/bin/env python3
"""Render the public COBOL course Markdown as a self-contained static website."""
from __future__ import annotations

import html
import re
import shutil
from pathlib import Path
from urllib.parse import quote

import markdown

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "build" / "site"
LESSONS = ROOT / "lessons"
EXTENSIONS = ROOT / "extensions"
EXCLUDED_PARTS = {"instructor", "tasks", "validation", "evidence", "grading"}
EXCLUDED_NAMES = {"AGENTS.md", "INSTRUCTOR.md", "manual-review-signoff.md"}
MD = markdown.Markdown(extensions=["fenced_code", "tables", "toc", "sane_lists", "smarty"])


def page_files() -> list[Path]:
    return sorted(
        p for base in (LESSONS, EXTENSIONS) for p in base.rglob("*.md")
        if p.name not in EXCLUDED_NAMES
        and not (set(p.relative_to(ROOT).parts) & EXCLUDED_PARTS)
        and ".git" not in p.parts
    )


def output_rel(source: Path) -> Path:
    return source.relative_to(ROOT).with_suffix(".html")


def title_of(source: Path) -> str:
    text = source.read_text(encoding="utf-8")
    match = re.search(r"^#\s+(.+?)\s*#*\s*$", text, re.M)
    return match.group(1) if match else source.stem.replace("-", " ").replace("_", " ")


def lesson_items() -> list[tuple[Path, str]]:
    items = []
    for source in sorted(LESSONS.glob("[0-9][0-9]*/README.md")):
        items.append((output_rel(source), title_of(source)))
    return items


def fix_links(content: str, source: Path, dest: Path) -> str:
    """Rewrite Markdown page links to HTML while preserving downloadable assets."""
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
                resolved = resolved / "README.md"
            else:
                github_path = quote(rel.as_posix(), safe="/._-")
                return f"](https://github.com/iamcheyan/cobol/tree/main/{github_path}" + (f"#{fragment}" if sep else "") + ")"
        target_rel = rel.with_suffix(".html") if resolved.suffix.lower() == ".md" else rel
        output_parent = output_rel(source).parent.as_posix()
        relative = Path(__import__("os").path.relpath(target_rel.as_posix(), output_parent)).as_posix()
        return f"]({quote(relative, safe='/._-')}" + (f"#{fragment}" if sep else "") + ")"
    return re.sub(r"\]\(([^)\s]+)(?:\s+[^)]*)?\)", replace, content)


def render_markdown(source: Path, dest: Path) -> str:
    text = fix_links(source.read_text(encoding="utf-8"), source, dest)
    MD.reset()
    return MD.convert(text)


def shell(title: str, body: str, current: Path | None = None, home: bool = False) -> str:
    home_href = "index.html" if current is None else __import__("os").path.relpath("index.html", current.parent.as_posix())
    lesson_links = "\n".join(
        f'<a href="{quote(__import__("os").path.relpath(p.as_posix(), current.parent.as_posix()) if current else p.as_posix(), safe="/._-")}"><span>{html.escape(p.parts[1][:2])}</span>{html.escape(t)}</a>'
        for p, t in lesson_items()
    )
    return f'''<!doctype html>
<html lang="zh-CN">
<head>
<meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<meta name="theme-color" content="#f5f5ed"><meta name="description" content="GnuCOBOL 实战课程：32 课，从 COBOL 基础走到银行夜间对账系统。">
<title>{html.escape(title)} · GnuCOBOL 实战课程</title>
<link rel="icon" type="image/png" href="{quote(__import__("os").path.relpath("assets/shire_200.png", current.parent.as_posix()) if current else "assets/shire_200.png", safe="/._-")}">
<link rel="stylesheet" href="{quote(__import__("os").path.relpath("assets/site.css", current.parent.as_posix()) if current else "assets/site.css", safe="/._-")}">
</head>
<body>
<div class="notice">GnuCOBOL 实战课程 <span>·</span> 从第一条语句，到银行夜间对账系统</div>
<header class="masthead"><a class="brand" href="{html.escape(home_href)}"><img src="{quote(__import__("os").path.relpath("assets/shire_200.png", current.parent.as_posix()) if current else "assets/shire_200.png", safe="/._-")}" alt="GnuCOBOL 的夏尔马标志"><span><strong>GnuCOBOL</strong><small>实战课程</small></span></a>
<nav><a href="{html.escape(home_href)}">课程首页</a><a href="{quote(__import__("os").path.relpath("lessons/DIRECTORY.html", current.parent.as_posix()) if current else "lessons/DIRECTORY.html", safe="/._-")}">32 课目录</a><a href="{quote(__import__("os").path.relpath("extensions/README.html", current.parent.as_posix()) if current else "extensions/README.html", safe="/._-")}">拓展课程</a><a href="https://github.com/iamcheyan/cobol">GitHub 源码</a></nav>
</header>
{f'<main class="home">{body}</main>' if home else f'''<div class="reading-layout"><aside class="course-nav"><div class="nav-heading">课程导航 <span>32</span></div><label class="search"><span>⌕</span><input id="course-search" type="search" placeholder="筛选课程" autocomplete="off"></label><div class="lesson-list" id="lesson-list">{lesson_links}</div><a class="directory-link" href="{quote(__import__("os").path.relpath("lessons/DIRECTORY.html", current.parent.as_posix()) if current else "lessons/DIRECTORY.html", safe="/._-")}">查看完整课程目录 →</a></aside><main class="article"><div class="article-top"><a href="{html.escape(home_href)}">课程首页</a><span>/</span><span>{html.escape(title)}</span></div><article>{body}</article></main></div>'''}
<footer><span>GnuCOBOL 实战课程</span><span>课程源码与练习材料 · <a href="https://github.com/iamcheyan/cobol">iamcheyan/cobol</a></span></footer>
<script src="{quote(__import__("os").path.relpath("assets/site.js", current.parent.as_posix()) if current else "assets/site.js", safe="/._-")}" defer></script>
</body></html>'''


def homepage() -> str:
    readme = (ROOT / "README.md").read_text(encoding="utf-8")
    # Preserve the repository's own course introduction and links as rendered Markdown.
    body = f'''<section class="hero"><div class="hero-copy"><p class="eyebrow">GNU COBOL · PRACTICAL COURSE</p><h1>从第一条 COBOL 语句，<br><em>走到银行夜间对账系统。</em></h1><p class="intro">一套循序渐进的 GnuCOBOL 实战课程。读讲解、运行程序、完成练习，逐步构建完整的批处理项目。</p><div class="hero-actions"><a class="primary" href="lessons/01_hello-cobol/README.html">从第 01 课开始 <span>→</span></a><a class="text-link" href="lessons/DIRECTORY.html">浏览全部课程</a></div></div><div class="horse"><img src="assets/shire_200.png" alt="GnuCOBOL 的 Shire 马标志"><span>GNU COBOL</span></div></section>
<section class="course-overview"><div class="section-title"><div><p class="eyebrow">THE LEARNING PATH</p><h2>六个阶段，完成一套课程</h2></div><a href="lessons/DIRECTORY.html">查看课程大纲 →</a></div><div class="stages"><a href="lessons/DIRECTORY.html#第一阶段语言基础"><span>01 — 08</span><strong>语言基础</strong><small>语句、数据与控制流</small></a><a href="lessons/DIRECTORY.html#第二阶段数据结构"><span>09 — 14</span><strong>数据结构</strong><small>记录、表格与查找</small></a><a href="lessons/DIRECTORY.html#第三阶段文件处理"><span>15 — 22</span><strong>文件处理</strong><small>CSV、排序与文件对账</small></a><a href="lessons/DIRECTORY.html#第四阶段工程化"><span>23 — 28</span><strong>工程化</strong><small>模块、接口与日志</small></a><a href="lessons/DIRECTORY.html#第五阶段数据库"><span>29 — 31</span><strong>数据库</strong><small>Embedded SQL 与同步</small></a><a class="capstone" href="lessons/32_bank-reconciliation-project/README.html"><span>32</span><strong>毕业项目</strong><small>银行对账批处理系统</small></a></div></section>
<section class="start-row"><div><p class="eyebrow">START HERE</p><h2>每一课，都能动手运行</h2><p>准备 GnuCOBOL 与 Make，从第一课开始编译、修改、练习。源码、输入数据和参考答案都与讲义一起浏览。</p></div><div class="start-command"><span>终端 · Debian / Ubuntu</span><code>sudo apt install gnucobol make</code><a href="lessons/01_hello-cobol/README.html">打开第 01 课 <b>↗</b></a></div></section>
<section class="more-reading"><div><p class="eyebrow">BEYOND THE MAIN COURSE</p><h2>继续探索</h2></div><a href="extensions/README.html"><span>拓展课程</span><strong>旧版专题、企业批处理与编辑器教程</strong><b>→</b></a><a href="https://github.com/iamcheyan/cobol"><span>课程源码</span><strong>查看代码、夹具与构建脚本</strong><b>→</b></a></section>'''
    return shell("课程首页", body, home=True)


def main() -> None:
    if OUT.exists():
        shutil.rmtree(OUT)
    OUT.mkdir(parents=True)
    (OUT / "assets").mkdir()
    shutil.copy2(ROOT / "site-src" / "site.css", OUT / "assets" / "site.css")
    shutil.copy2(ROOT / "site-src" / "site.js", OUT / "assets" / "site.js")
    shutil.copy2(ROOT / "site-src" / "shire_200.png", OUT / "assets" / "shire_200.png")
    for source in [ROOT / "README.md", *page_files()]:
        dest = OUT / output_rel(source)
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_text(shell(title_of(source), render_markdown(source, dest), output_rel(source)), encoding="utf-8")
    # Copy course code, fixtures, scripts, and other linked learning assets for download.
    for tree in (LESSONS, EXTENSIONS):
        for source in tree.rglob("*"):
            if not source.is_file() or source.suffix.lower() == ".md":
                continue
            rel = source.relative_to(ROOT)
            if set(rel.parts) & EXCLUDED_PARTS or source.name in EXCLUDED_NAMES:
                continue
            target = OUT / rel
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(source, target)
    (OUT / "index.html").write_text(homepage(), encoding="utf-8")
    (OUT / "README.html").write_text(shell("课程首页", render_markdown(ROOT / "README.md", OUT / "README.html"), Path("README.html")), encoding="utf-8")
    shutil.copy2(ROOT / "Makefile", OUT / "Makefile")
    (OUT / "CNAME").write_text("cobol.iamcheyan.com\n", encoding="ascii")
    print(f"Rendered {len(page_files())} Markdown pages to {OUT}")


if __name__ == "__main__":
    main()
