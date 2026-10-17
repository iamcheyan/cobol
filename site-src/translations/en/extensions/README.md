# Optional Courses and Companion Materials

The 32-lesson main course starts at [`lessons/`](../lessons/README.md) in the repository root. This page indexes optional extensions without mixing their goals or prerequisites into the main course sequence.

## Choose Extensions by Main-Course Lesson

The materials below are mapped to the 32-lesson course. Use them for extra practice, to compare another implementation, or for further study; they do not change the course order and are not required to complete it.

| Main-course lessons | Optional companion material | Topics |
|---|---|---|
| 01–08 | [`legacy-workshop/lessons/00-environment/`](legacy-workshop/lessons/00-environment/), [`01-program-anatomy/`](legacy-workshop/lessons/01-program-anatomy/), [`07-conditions-88/`](legacy-workshop/lessons/07-conditions-88/)–[`09-loops-perform/`](legacy-workshop/lessons/09-loops-perform/) | Environment, fixed format, level-88 condition names, control flow |
| 09–14 | [`legacy-workshop/lessons/10-tables-occurs-search/`](legacy-workshop/lessons/10-tables-occurs-search/), [`11-strings-unstring-inspect/`](legacy-workshop/lessons/11-strings-unstring-inspect/), [`14-copybooks-redefines/`](legacy-workshop/lessons/14-copybooks-redefines/); [`TBLSRCH.COB`](standalone-examples/TBLSRCH.COB) | Tables, string processing, Copybooks, and redefinitions |
| 15–22 | [`legacy-workshop/lessons/12-sequential-files/`](legacy-workshop/lessons/12-sequential-files/), [`13-file-status-errors/`](legacy-workshop/lessons/13-file-status-errors/), [`17-reports-control-break/`](legacy-workshop/lessons/17-reports-control-break/), [`18-sort-merge/`](legacy-workshop/lessons/18-sort-merge/), [`25-project-csv-pipeline/`](legacy-workshop/lessons/25-project-csv-pipeline/), [`26-project-fixed-records/`](legacy-workshop/lessons/26-project-fixed-records/) | File status, reports, sorting, and end-to-end CSV/fixed-record projects |
| 23–28 | [`legacy-workshop/lessons/15-subprograms-linkage/`](legacy-workshop/lessons/15-subprograms-linkage/), [`19-modules-environment/`](legacy-workshop/lessons/19-modules-environment/), [`20-debugging-diagnostics/`](legacy-workshop/lessons/20-debugging-diagnostics/), [`21-compiler-options/`](legacy-workshop/lessons/21-compiler-options/), [`22-bash-build-run/`](legacy-workshop/lessons/22-bash-build-run/)–[`24-bash-pipelines-scheduling/`](legacy-workshop/lessons/24-bash-pipelines-scheduling/) | Subprograms, project debugging, builds, automation, and scheduling |
| 29–31 | [`legacy-workshop/lessons/16-intrinsic-functions-dates/`](legacy-workshop/lessons/16-intrinsic-functions-dates/), [`enterprise-batch/curriculum/modules/08-database/`](enterprise-batch/curriculum/modules/08-database/) | Date functions and advanced, real Embedded SQL |
| 32 | [`legacy-workshop/lessons/28-capstone-night-batch/`](legacy-workshop/lessons/28-capstone-night-batch/), [`29-reference-topic-map/`](legacy-workshop/lessons/29-reference-topic-map/), [`enterprise-batch/curriculum/modules/11-incidents/`](enterprise-batch/curriculum/modules/11-incidents/), [`12-capstone/`](enterprise-batch/curriculum/modules/12-capstone/) | Nightly batch processing, review, incident investigation, and an enterprise capstone |

For Neovim practice, see [`neovim-tooling/tutorials/`](neovim-tooling/tutorials/01-punchcard-and-ruler.md); four standalone examples are in [`standalone-examples/`](standalone-examples/README.md).

## Legacy Introductory Course

[`legacy-workshop/`](legacy-workshop/README.md) preserves the original lessons 00–29, compiler scripts, practice data, and plugin workflow. Use it for additional topic-based practice; its sequence is independent of the CPR #31 main course.

## Enterprise Batch Extension

[`enterprise-batch/`](enterprise-batch/README.md) is a 12-module enterprise course built around a synthetic overnight bank-processing scenario. It covers file layouts, sort and merge, modularization, databases, job scheduling, incident investigation, and a capstone.

Course design, instructor reference implementations, grading, and review materials live in this extension, whose README describes how to verify them. The database module distinguishes real Embedded SQL validation from offline file-based checkpoints; report results according to each module's stated environment requirements.

## Neovim Plugin Tutorials

[`neovim-tooling/tutorials/`](neovim-tooling/tutorials/01-punchcard-and-ruler.md) contains seven `cobol.nvim` tutorials covering fixed-format rulers, structural navigation, PIC calculations, diagnostics, compilation workflows, practical examples, and plugin regression exercises. These are editor companion materials, not prerequisites for the main course.

## Standalone COBOL Examples

[`standalone-examples/`](standalone-examples/README.md) preserves four independent COBOL programs, their Copybooks, and input data. In that directory, run `make check`, `make run`, or `make clean`.
