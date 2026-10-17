---
_translated_from: lessons/DIRECTORY.md
_translated_by: site-src/translation agent
---

# GnuCOBOL Practical Course Directory

## Course Overview

This course is for learners with programming, Linux, Oracle/PostgreSQL, and CSV/TXT experience but no COBOL background. The goal is to independently deliver GnuCOBOL batch programs on Linux for CSV and fixed-length file processing, data validation, file reconciliation, migration, reporting, and database batch processing. A running project grows step by step from small console programs into a banking reconciliation system.

Every lesson delivers `lesson.cob`, `README.md`, `exercise.md`, and `answer.md`. The README covers objectives, concepts, build and run instructions, line-by-line explanations, input/output, and enterprise scenarios. Exercises include modifications with reference answers and transfer exercises without answers; the answer file covers only the modification exercises.

Course source uses the fixed format required by the repository: column 7 is the indicator area; Area A/B begin at columns 8/12; and program text does not extend past column 72. Compiler and target-platform behavior are based on actual GnuCOBOL/Linux verification.

## Course Directory

### Stage 1: Language Fundamentals

| Lesson | Title | Learning Objectives | Prerequisites | Est. Time | Project Connection | Final Source Deliverable |
|---|---|---|---|---:|---|---|
| 01 | Hello COBOL | Compile and run a minimal fixed-format program; identify the program name, output statement, and ending statement | Linux terminal, text editor | 1 hour | Establish an executable entry point for the banking batch developed later | `lessons/01_hello-cobol/lesson.cob` |
| 02 | Data Types | Describe characters, integers, and decimal amounts with `PIC`; distinguish display width from business meaning | 01 | 2 hours | Define account number, customer name, and balance fields | `lessons/02_data-types/lesson.cob` |
| 03 | MOVE and COMPUTE | Assign values and perform arithmetic and decimal calculations; observe decimal places and truncation | 02 | 2 hours | Calculate post-transaction balances and fees | `lessons/03_move-compute/lesson.cob` |
| 04 | IF | Select accept/reject paths using business conditions; identify boundary cases | 02–03 | 2 hours | Reject non-positive amounts or noncompliant transactions | `lessons/04_if-conditions/lesson.cob` |
| 05 | EVALUATE | Map multiple business values to explicit processing branches | 04 | 2 hours | Classify deposits, withdrawals, transfers, and unknown transaction codes | `lessons/05_evaluate/lesson.cob` |
| 06 | PERFORM | Repeat a processing step and understand loop boundaries | 03–05 | 2 hours | Process a sequence of sample transactions | `lessons/06_perform-loops/lesson.cob` |
| 07 | Paragraph | Split procedures into named paragraphs and call them from the main flow | 01, 06 | 2 hours | Divide batch initialization, processing, and final summary | `lessons/07_paragraphs/lesson.cob` |
| 08 | Integrated Practice | Combine fields, arithmetic, conditions, classification, and procedure control | 01–07 | 4 hours | Complete a mini account transaction batch without file input | `lessons/08_control-flow-practice/lesson.cob` |

### Stage 2: Data Structures

| Lesson | Title | Learning Objectives | Prerequisites | Est. Time | Project Connection | Final Source Deliverable |
|---|---|---|---|---:|---|---|
| 09 | Group Item | Organize customer, account, and transaction records with hierarchical data items | 02, 08 | 2 hours | Define a unified transaction record structure | `lessons/09_group-items/lesson.cob` |
| 10 | REDEFINES | Explain multiple views of the same storage area and their proper limits | 09 | 2 hours | Inspect a shared record layout for different transaction types | `lessons/10_redefines/lesson.cob` |
| 11 | OCCURS | Declare a bounded table and access its entries with subscripts | 06, 09 | 2 hours | Hold a small batch of accounts or transaction codes | `lessons/11_occurs-tables/lesson.cob` |
| 12 | INDEXED BY | Declare a table index and distinguish it from an ordinary numeric subscript | 11 | 2 hours | Traverse a loaded account table | `lessons/12_indexed-by/lesson.cob` |
| 13 | SEARCH | Look up keys in a table and understand the requirements for sequential and binary searches | 11–12 | 2 hours | Match transaction account numbers to account master records | `lessons/13_search-tables/lesson.cob` |
| 14 | Integrated Practice | Combine hierarchical records, redefinitions, tables, and lookups | 09–13 | 4 hours | Complete a small in-memory account and transaction matching task | `lessons/14_data-structures-practice/lesson.cob` |

### Stage 3: File Processing

| Lesson | Title | Learning Objectives | Prerequisites | Est. Time | Project Connection | Final Source Deliverable |
|---|---|---|---|---:|---|---|
| 15 | Sequential File Reading | Open and read a sequential file record by record; identify the EOF flow | 09, 14 | 3 hours | Read daily transaction text | `lessons/15_sequential-file-read/lesson.cob`, with input fixture |
| 16 | File Writing | Create an output file and write results record by record | 15 | 3 hours | Generate accepted and rejected result files | `lessons/16_file-writing/lesson.cob` |
| 17 | Fixed-Length Files | Define record width, field offsets, and fixed-length input/output conventions | 09, 15–16 | 3 hours | Read the account master and write fixed-width balance records | `lessons/17_fixed-length-files/lesson.cob`, with fixed-length fixture |
| 18 | CSV Processing | Parse delimited fields and handle field counts, empty values, and text boundaries | 11, 15–16 | 4 hours | Import customer and transaction CSV files | `lessons/18_csv-processing/lesson.cob`, with CSV fixture |
| 19 | Multiple Files | Read two or more input streams in sync and handle each EOF independently | 15–18 | 4 hours | Read the account master and daily transaction files | `lessons/19_multiple-files/lesson.cob`, with multiple-file fixtures |
| 20 | File Matching | Match sorted keys sequentially and classify matched and unmatched records | 17, 19 | 4 hours | Reconcile master balances with daily transactions | `lessons/20_file-matching/lesson.cob`, with fixtures for three match outcomes |
| 21 | SORT | Use GnuCOBOL sorting and input/output procedures to order records | 17–20 | 3 hours | Prepare ordered input for large-scale file matching | `lessons/21_sort/lesson.cob`, with sorting fixture |
| 22 | Integrated Practice | Combine file reading, validation, sorting, matching, and result writing | 15–21 | 5 hours | Deliver the first end-to-end file reconciliation batch | `lessons/22_file-processing-practice/lesson.cob`, with a complete miniature dataset |

### Stage 4: Engineering Practices

| Lesson | Title | Learning Objectives | Prerequisites | Est. Time | Project Connection | Final Source Deliverable |
|---|---|---|---|---:|---|---|
| 23 | COPYBOOK | Extract shared data declarations and reuse them with `COPY` | 09, 17 | 3 hours | Standardize account and transaction record definitions | `lessons/23_copybooks/lesson.cob`, `copybooks/` |
| 24 | CALL | Split a program into a main program and subprograms, then call them | 07, 23 | 3 hours | Extract customer/transaction validation subprograms | `lessons/24_call-subprograms/lesson.cob`, subprogram source |
| 25 | USING | Define call arguments, data direction, and interface contracts | 24 | 2 hours | Pass records and status between the main batch and validation module | `lessons/25_using-parameters/lesson.cob`, interface Copybook |
| 26 | Error Handling | Use file status and return codes to distinguish business rejections from system failures | 15–25 | 3 hours | Handle missing input, bad records, and write failures | `lessons/26_error-handling/lesson.cob`, with error fixtures |
| 27 | Logging System | Write logs that identify the batch, record number, and error category | 26 | 3 hours | Record reconciliation batch start, completion, and rejection details | `lessons/27_logging/lesson.cob`, with expected logs |
| 28 | Integrated Practice | Organize a buildable batch project with multiple programs and Copybooks | 23–27 | 5 hours | Create a repeatable file-processing project skeleton | `lessons/28_modular-batch-project/lesson.cob`, Copybooks, and build scripts |

### Stage 5: Databases

| Lesson | Title | Learning Objectives | Prerequisites | Est. Time | Project Connection | Final Source Deliverable |
|---|---|---|---|---:|---|---|
| 29 | Embedded SQL | Understand precompilation, host variables, SQL status, and real connection configuration | 23–28; database toolchain verified | 6 hours | Read an account snapshot from a relational database | `lessons/29_embedded-sql/lesson.cob`, SQL/build configuration, and initialization script |
| 30 | Cursor | Declare, open, fetch rows from, and close a cursor; distinguish no data from errors | 29 | 4 hours | Stream an account or customer snapshot | `lessons/30_sql-cursors/lesson.cob`, cursor query and fixtures |
| 31 | Data Synchronization | Compare a file with a database snapshot by business key and perform controlled synchronization | 20, 26–30 | 6 hours | Write reconciliation status back and generate a differences file | `lessons/31_data-synchronization/lesson.cob`, SQL, data, and run scripts |

> Before starting the database stage, verify a working GnuCOBOL Embedded SQL precompiler, driver, database, and dependencies on Linux. Until they are verified, do not label simulated calls as a database implementation or promise a particular SQL dialect or output.

### Stage 6: Capstone Project

| Lesson | Title | Learning Objectives | Prerequisites | Est. Time | Project Connection | Final Source Deliverable |
|---|---|---|---|---:|---|---|
| 32 | Banking Reconciliation System | Deliver a verifiable batch from input contracts through validation, matching, database synchronization, reporting, logging, and recovery | 01–31 | 16 hours | Complete bank account and transaction reconciliation project | `lessons/32_bank-reconciliation-project/lesson.cob`, Copybooks, SQL, fixtures, scripts, and run documentation |

## Learning Dependencies and Project Progression

```text
01–08 Language and control flow
  → 09–14 Record layouts and in-memory tables
  → 15–22 File reading/writing, CSV/fixed-length files, sorting, and matching
  → 23–28 Copybooks, subprograms, interfaces, errors, logging, and project builds
  → 29–31 Real Embedded SQL, cursors, and file/database synchronization
  → 32 Banking reconciliation capstone
```

Project data begins with constant output and hand-built examples. It then introduces account and transaction records, reproducible input fixtures, CSV, fixed-length and multi-file processing, matching output, module interfaces, and database snapshots, before combining them into a complete batch. Each integrated practice uses only syntax and tools taught in its prerequisites.

## Optional Extensions

After the corresponding core lesson, use the [extension index](../extensions/README.md) by lesson number to choose legacy topics, standalone practical examples, real Embedded SQL cases, or enterprise overnight batch projects. These reuse existing source, data, and toolchains as extra practice; they do not replace the 01–32 core sequence.

## Course Schedule

Estimated total study time is about 111 hours, based on the time listed for each lesson and including reading, modification, execution, and exercises.
The specific Embedded SQL toolchain and database dependencies for lessons 29–31 depend on environment verification.
