# GNUCOBOL Full-Stack Curriculum: From the First DISPLAY to Batch Projects

> This directory archives the older lessons 00–29 as optional supplemental material. The new main curriculum starts in [`lessons/`](../../lessons/README.md) at the repository root.

To find the corresponding exercises in these older topics by new main-course lesson number, see the [extension curriculum index](../README.md). The old lessons are useful for supplemental reading and repeated practice; the learning sequence, curriculum contract, and final project are defined by the 32-lesson main curriculum at the repository root.

This curriculum brings the COBOL language, GnuCOBOL toolchain, Bash automation, and `cobol.nvim` learning workflow together in runnable exercises. Its goal is to help learners read and independently complete a practical batch program: define records, read files, validate data, perform business calculations, write results, print summaries, and provide reliable shell builds and regression tests.

> The lessons follow this sequence: “concept -> run -> modify -> deliberately introduce an error -> use tools to locate it -> explain it yourself.” Examples target GnuCOBOL, and traditional source code follows fixed format. Specific storage layouts and extension behavior depend on the installed GnuCOBOL version and target platform.

## Environment Setup

GNU/Linux, macOS, or WSL; GnuCOBOL (`cobc`), GNU Make, and Bash are required. Neovim and `iamcheyan/cobol.nvim` are recommended. Installation examples:

```sh
# Debian / Ubuntu
sudo apt install gnucobol make
# Arch Linux
sudo pacman -S gnucobol make
# macOS
brew install gnu-cobol make

cobc --version
make check
```

Each lesson directory contains a `README.md` and standalone `.COB` examples. Lessons that need multiple files or test data also include `.CPY` files, data fixtures, or Bash scripts in that directory. After entering a lesson directory, compilation and execution usually look like this:

```sh
cobc -x -Wall -o build/lesson lesson.COB
./build/lesson
```

Create `build/` first: `mkdir -p build`. If a lesson includes scripts, its README provides more specific commands. To check syntax only, use `cobc -fsyntax-only lesson.COB`.

## Learning Path

### Stage A: Language and Data Fundamentals

| Lesson | Contents |
|---|---|
| [00](lessons/00-environment/) | Environment and first program |
| [01](lessons/01-program-anatomy/) | Four divisions, program skeleton, paragraphs |
| [02](lessons/02-source-format/) | Fixed format, Area A/B, column boundaries |
| [03](lessons/03-names-comments-literals/) | Names, comments, literals, periods |
| [04](lessons/04-data-hierarchy/) | Level numbers, group items, data division |
| [05](lessons/05-picture-storage/) | PIC, numbers, edited formats, storage |
| [06](lessons/06-values-move-arithmetic/) | VALUE, MOVE, arithmetic, and overflow |

### Stage B: Control Flow and Data Processing

| Lesson | Contents |
|---|---|
| [07](lessons/07-conditions-88/) | Conditions and level-88 condition names |
| [08](lessons/08-branching-evaluate/) | IF, EVALUATE, and branch ranges |
| [09](lessons/09-loops-perform/) | PERFORM and loops |
| [10](lessons/10-tables-occurs-search/) | OCCURS, tables, SEARCH |
| [11](lessons/11-strings-unstring-inspect/) | STRING, UNSTRING, INSPECT |
| [12](lessons/12-sequential-files/) | Sequential files and READ/WRITE |
| [13](lessons/13-file-status-errors/) | File status, validation, and error paths |

### Stage C: Modularization and Production Programs

| Lesson | Contents |
|---|---|
| [14](lessons/14-copybooks-redefines/) | COPY, Copybooks, REDEFINES |
| [15](lessons/15-subprograms-linkage/) | CALL, LINKAGE, parameter passing |
| [16](lessons/16-intrinsic-functions-dates/) | Intrinsic functions, dates, type conversion |
| [17](lessons/17-reports-control-break/) | Reports, accumulators, control breaks |
| [18](lessons/18-sort-merge/) | Sorting, merging, and job streams |
| [19](lessons/19-modules-environment/) | Multi-file projects and runtime environment |
| [20](lessons/20-debugging-diagnostics/) | Debugging, compiler diagnostics, and locating issues |
| [21](lessons/21-compiler-options/) | cobc options, formats, and dialects |

### Stage D: Bash, End-to-End Projects, and Plugin Workflow

| Lesson | Contents |
|---|---|
| [22](lessons/22-bash-build-run/) | Bash compile and run scripts |
| [23](lessons/23-bash-tests-batch/) | Batch builds and regression tests |
| [24](lessons/24-bash-pipelines-scheduling/) | Pipelines, logs, scheduling, and rerun capability |
| [25](lessons/25-project-csv-pipeline/) | Capstone project: delimited files to CSV |
| [26](lessons/26-project-fixed-records/) | Capstone project: fixed-width records |
| [27](lessons/27-plugin-learning-workflow/) | Practice and troubleshooting with cobol.nvim |
| [28](lessons/28-capstone-night-batch/) | Graduation project: complete batch system |
| [29](lessons/29-reference-topic-map/) | Topic overview and GnuCOBOL advanced learning path |

## Learning Loop for Each Lesson

1. Read the goals, concepts, and notes in `README.md`.
2. Run the original example first and save its expected output.
3. Make a small change from the “Modification Exercise,” then run syntax checks, compile, and execute.
4. Deliberately introduce a controlled error and use both `cobc` and the plugin to locate it.
5. After fixing it, check inputs, outputs, exit codes, and edge cases.
6. Write down the rule in your own words and anything that remains uncertain.

Lesson programs follow the repository’s fixed-format convention: column 7 is the indicator, Area A starts at column 8, Area B at column 12, and program text is valid through column 72. Free format can be practiced as a separate topic, but do not apply `-free` habits to the fixed-format examples in this repository.

## Plugin Practice Card

The Neovim plugin is an aid, not a replacement for the compiler. Each applicable lesson includes “Plugin Practice” steps:

- Fixed format: ruler, `g7` / `g8` / `g12` / `g73`, smart comments, and case formatting.
- Structural navigation: Aerial outline, Winbar breadcrumbs, `gd`, `<C-o>`, folding.
- Data: use `<leader>cr` / `:CobolCalcRecord` to check record length; verify arrays, redefinitions, and compiler ABI against the target platform.
- Modules: `gf` opens a Copybook, `K` previews it, and `<C-o>` returns.
- Diagnostics: `<leader>cl` / `:CobolLint`, `<leader>cq` / `:CobolQuickfix`.

For plugin installation and key details, see the plugin index in the [repository README](../../README.md) and [Lesson 27](lessons/27-plugin-learning-workflow/).

## Curriculum Scope and References

The curriculum covers practical development topics including COBOL program structure, data descriptions, operations, conditions and loops, tables, strings, sequential files, modularization, subprograms, reports, sorting, compilation, diagnostics, and job automation. COBOL standards and vendor dialects are extensive; the curriculum identifies GnuCOBOL behavior explicitly and does not claim to cover every historical dialect keyword in one tutorial. Continue with the local `info gnucobol`, `cobc --help`, the GnuCOBOL Programmer's Guide, and the ISO COBOL standard.

For Neovim editor support, see [`neovim-tooling/`](../neovim-tooling/README.md); for four standalone practical examples, see [`standalone-examples/`](../standalone-examples/README.md).
