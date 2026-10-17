<div align="center">

<img src="site-src/shire_200.png" width="160" alt="GnuCOBOL Shire horse mascot">

# GnuCOBOL Practical Course

**From your first COBOL statement to a working bank nightly reconciliation system.**

[![Live site](https://img.shields.io/badge/live-cobol.iamcheyan.com-76319f?style=flat-square)](https://cobol.iamcheyan.com/en/)
[![Lessons](https://img.shields.io/badge/lessons-32-2563eb?style=flat-square)](lessons/DIRECTORY.md)
[![Languages](https://img.shields.io/badge/languages-EN%20%C2%B7%20JA%20%C2%B7%20ZH-0d9488?style=flat-square)](#read-this-in-your-language)
[![Compiler](https://img.shields.io/badge/GnuCOBOL-3.2-d97706?style=flat-square)](https://gnucobol.sourceforge.io/)

[简体中文](README.zh-CN.md) · [日本語](README.ja.md) · [English](README.md)

</div>

---

## What this is

This repository is **the source of the course website** — not just a folder of sample programs.

Every lesson you read at [cobol.iamcheyan.com](https://cobol.iamcheyan.com/en/) is written here as Markdown, translated
into three languages, and rendered into a static site by a build script that runs in GitHub Actions on every push.
The site you see and the files in this repository are the same thing.

The course itself is 32 lessons of fixed-format GnuCOBOL that end in a runnable bank reconciliation batch: file
handling, sorting, matching, embedded SQL, modular batch design, error handling, logging, and a capstone project.

<table>
<tr>
<td width="50%"><img src="docs/screenshots/en-home.png" alt="Course home page"></td>
<td width="50%"><img src="docs/screenshots/en-lesson01.png" alt="A lesson page with its tabs"></td>
</tr>
<tr>
<td align="center"><sub>Course home — six stages, 32 lessons</sub></td>
<td align="center"><sub>Every lesson in one workspace: lesson, exercise, answer key, source</sub></td>
</tr>
</table>

## Why this course exists

Japan's core banking, insurance and municipal systems still run COBOL batch jobs, and the engineers who can safely
change them are retiring faster than they are replaced. The gap is not "learn COBOL syntax" — it is "be able to read
a fixed-format batch program, understand what it does to the data, and change it without breaking the night run".

So every lesson here is built around a real batch-shaped problem, and every claim is backed by code you can compile
and run:

- **Nothing is hand-waved.** Each lesson's expected output was produced by actually compiling and running the program,
  and the byte counts in the explanations were measured, not estimated.
- **Boundaries are stated.** Where a lesson does not handle something, the README says so instead of implying more
  capability than the code has.
- **Failures are part of the material.** Exit codes, `FILE STATUS` values, and what happens when a copybook is missing
  are taught alongside the happy path.

## The course site

The site generates one complete tree per language — `zh-cn/`, `en/`, `ja/` — with a language switcher, light and dark
themes, and a mobile layout with a collapsible course list. Each lesson page puts the lesson text, the exercise, the
answer key and the source files in one place, with per-file preview and download.

<table>
<tr>
<td width="60%"><img src="docs/screenshots/en-plugins.png" alt="The companion editor plugin page"></td>
<td width="40%" valign="top">

**What the site adds on top of the Markdown**

- 32 lessons · three languages · 562 generated pages
- Per-lesson tabs: guide, exercise, answer, code
- Inline SVG diagrams for byte layouts, control flow and data movement
- A companion page for [`cobol.nvim`](https://github.com/iamcheyan/cobol.nvim) with real screenshots
- Background pages: what COBOL is, its history, a GnuCOBOL primer, a reference sheet and a glossary

</td>
</tr>
</table>

## Quick start

```sh
# 1. GnuCOBOL and make
sudo apt install gnucobol make
cobc --version          # expect GnuCOBOL 3.2.x

# 2. Read the first lesson
open lessons/01_hello-cobol/README.md

# 3. Check the whole course
make course-check       # deliverables for all 32 lessons + syntax check for 01–28 + a run of lesson 01
```

Lessons 29–32 use an embedded SQL toolchain (GixSQL + SQLite). Install it once from lesson 29
(`install-toolchain.sh`), then:

```sh
make course-check-sql   # precompile checks for 29–32 and the lesson 32 end-to-end scenario
```

## Build the site locally

```sh
python3 -m pip install 'Markdown==3.7'
python3 scripts/build_site.py        # renders build/site/{zh-cn,en,ja}
python3 -m http.server -d build/site 8000
```

The build is plain Python and Markdown; there is no Node toolchain and no framework. `build/site/` is ignored by Git —
GitHub Actions builds and deploys it on every push to `main`.

## Repository layout

```text
lessons/            32 lessons — the main course
  01_hello-cobol/     README.md · exercise.md · answer.md · lesson.cob · assets/
   ...
  32_bank-reconciliation-project/
  DIRECTORY.md      full syllabus: stages, prerequisites, time estimates
  DIAGRAM-SPEC.md   how lesson figures are drawn
extensions/         optional material — legacy workshop, enterprise batch, editor tutorials
scripts/
  build_site.py       renders the trilingual static site
  check_translations.py  coverage report + structural fidelity gate
  diagram_i18n.py     builds zh-cn/ja variants of every lesson figure
site-src/
  site.css, theme.css, site.js   site styling and behaviour
  translations/                  en and ja versions of lesson text
  diagram-i18n.json              translated labels for the SVG figures
docs/screenshots/   images used in this README
Makefile            course checks and extension entry points
```

## Languages

The course is written in Chinese, English and Japanese. Each lesson's text, comments and answers exist in all three;
source code identifiers and program output stay as they are, because that is what the compiler and the batch actually
see.

- `README.md` — English (this file)
- `README.zh-CN.md` — 简体中文
- `README.ja.md` — 日本語

Translation coverage is enforced, not assumed: `scripts/check_translations.py` compares each translation against its
source for heading counts, code fences, table rows, link targets and COBOL non-comment lines, and fails when a file is
written in the wrong language.

## Course checks

| Command | What it does |
| --- | --- |
| `make course-check` | Verifies every lesson's deliverables, syntax-checks 01–28, compiles and runs 01 |
| `make course-check-sql` | Precompile checks for 29–32 plus the lesson 32 end-to-end run |
| `make legacy-course-check` | Checks the optional legacy workshop |
| `make standalone-check` / `standalone-run` | The four independent examples under `extensions/` |

## Contributing

The lessons are documentation as much as code, so a useful change is often a correction to an explanation rather than
a new feature.

- **A lesson is only "done" when the program runs.** Compile it, run it, and check the output matches what the lesson
  claims.
- **Keep the fixed-format rules.** Columns 1–6 blank, `*` in column 7 for comments, Area A from 8, Area B from 12, and
  no program text past column 72.
- **Do not add `-std=cobol85`.** This course relies on `COMP-3` and `FUNCTION TRIM`, which strict COBOL 85 does not
  include; build with plain `cobc -x`.
- **Translations must stay faithful.** Run `python3 scripts/check_translations.py` before sending a translation change.

## Credits

Built with [GnuCOBOL](https://gnucobol.sourceforge.io/). GnuCOBOL began as OpenCOBOL, released in 2002 by
**Keisuke Nishida**; development now runs under the GNU Project, led by Simon Sobisch and others. The Shire horse
mascot comes from the GnuCOBOL project.

The companion Neovim plugin, [`cobol.nvim`](https://github.com/iamcheyan/cobol.nvim), provides fixed-format column
guides, structure navigation, copybook preview, record-size calculation and compiler diagnostics while you work
through the lessons.
