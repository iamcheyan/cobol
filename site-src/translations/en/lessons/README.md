---
_translated_from: lessons/README.md
_translated_by: site-src/translation agent
---

# Course Navigation

Each lesson has a fixed set of deliverables: `lesson.cob`, `README.md`, `exercise.md`, `answer.md`, plus any scripts, copybooks, data fixtures, and expected results it needs. Exercises with answers and transfer exercises without answers are listed separately in `exercise.md`; the answer file covers only the exercises with answers.

- [32-lesson course directory](DIRECTORY.md): goals, prerequisites, estimated time, and source deliverables for all six stages.
- [Lesson 01: Hello COBOL](01_hello-cobol/README.md): compile and run your first `DISPLAY` statement in a fixed-format program.

To continue with legacy topics, enterprise batch processing, or the Neovim workflow, browse the [extension index](../extensions/README.md) by lesson number. Extensions do not change the prerequisite order of this course.

## Conventions Shared by All Lessons

- **Language**: READMEs and source comments use Chinese. Business text printed by programs follows the Japanese already used in the repository (some interface markers, such as `POSTED` and `SQLSTATE`, remain in English). Each lesson README provides a Chinese legend for output labels; use actual output and the README to determine program behavior.
- **Compiler and dialect**: GnuCOBOL 3.2.x with its default dialect. Do **not** add `-std=cobol85`; strict COBOL 85 does not support extensions used in this course, including `COMP-3` and `FUNCTION TRIM`.
- **Source format**: Fixed format. Column 7 is the indicator area (`*` marks a comment); Area A starts at column 8 (Divisions, `FD`/`SD`, level 01, and paragraph names). Repository convention places level 05 at column 11 and statements at column 12. Valid program text must not extend past column 72. The toolchain checks this boundary by **byte**, so lines containing Chinese or Japanese reach it earlier.
- **Build and clean**: Create `build/` with `mkdir -p build`, then use `cobc` to place executables there (`copybooks/` is also used as an `-I` path in multi-program lessons). `.gitignore` excludes `build/`; remove it with `rm -rf build`. Lessons that read or write business data (16, 22, 26, 27) use input copies in `build/` to avoid changing repository fixtures.
- **Database lessons (29–32)**: Use GixSQL 1.0.20b + SQLite. Lesson 29's `install-toolchain.sh` extracts the toolchain to `build/toolchain/` without modifying system packages or committing binaries. Lessons 30–32 reuse it by default. If it is missing, these lessons' `build.sh check` commands report an error; **do not substitute simulated SQL**.
- **Completeness checks**: From the repository root, `make course-check` checks deliverables for all 32 lessons, syntax-checks lessons 01–28, and runs a behavior smoke test for lesson 01. `make course-check-sql` covers precompiler checks for lessons 29–32 and the end-to-end scenario for lesson 32.

For exact commands, expected output, and unverified areas, follow each lesson README. Do not treat executables, logs, or runtime output as source files.
