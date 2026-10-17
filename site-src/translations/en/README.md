---
_translated_from: README.md
_translated_by: site-src/translation agent
---

# GnuCOBOL Practical Course

**From your first COBOL statement to a working overnight bank reconciliation system.**

Course website: [cobol.iamcheyan.com](https://cobol.iamcheyan.com) (static pages generated automatically from this repository's Markdown by GitHub Actions).

The repository home page is the course entry point. Its 32 lessons progress through COBOL fundamentals, data layouts, file processing, sort-merge matching, databases, and modular batch development, culminating in a bank reconciliation capstone.

## Start the Course

1. Install GnuCOBOL and Make:
   ```sh
   sudo apt install gnucobol make
   cobc --version
   ```
2. Start with [Lesson 01](lessons/01_hello-cobol/README.md). Every lesson includes explanations, source code, exercises, and reference answers.
3. Open the [course directory](lessons/DIRECTORY.md) for the sequence, goals, and estimated time for all 32 lessons.

Check the deliverables for all 32 lessons, syntax-check lessons 01–28, and compile and run lesson 01:

```sh
make course-check
```

Lessons 29–32 use the GixSQL + SQLite toolchain (run `install-toolchain.sh` in lesson 29 first). Use this target for precompiler checks and the end-to-end scenario in lesson 32:

```sh
make course-check-sql
```

## Course Structure

- [`lessons/`](lessons/README.md): the 32-lesson core course. Lesson 32 is a working bank reconciliation capstone.
- [`extensions/`](extensions/README.md): optional content, including legacy courses, enterprise modules, standalone examples, and Neovim plugin tutorials.
- [`Makefile`](Makefile): core course checks and entry points for checking and running standalone extension examples.

Completing the 32 core lessons is enough to finish the course. Extensions do not change the core sequence or its prerequisites.
