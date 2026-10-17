# Curriculum Production and Acceptance Standards


## 1. Deliverable Structure for an Individual Hands-on Unit

```text
curriculum/modules/07-matching/labs/03-one-to-many/
  README.md                 Learner task and acceptance criteria; avoid giving the answer directly
  DESIGN.md                 Inputs and outputs, state diagram, business rules, and constraints
  starter/                  Buildable starter code with clearly described TODOs
  copybooks/                Versioned interfaces
  fixtures/normal/          Normal inputs
  fixtures/boundary/        EOF, length, amount, empty-file, and other boundary cases
  fixtures/invalid/         Invalid inputs with a specific root cause
  expected/                 Independently calculated outputs, RCs, counts, and rule explanations
  scripts/                  build/run/check/reset; works from any starting directory
  evidence/README.md        Evidence learners must submit; do not prefill passing results
instructor/modules/07/...   Reference implementation, root causes, hint ladder, and grading notes
```

Maintain the shared banking model and common programs as a single canonical source. Labs should use them through versioned configuration, patches, or stage snapshots; do not create many divergent implementations by copying programs with the same names. Micro-labs may have standalone source, but must explain how they relate to the banking system.

## 2. Questions Every README Must Answer

1. Why does the business need this processing, and what request has the learner received?
2. Where do the input files/DB come from, what are their formats, and which assumptions are already guaranteed?
3. How can the learner build, run, and reset from a clean checkout? Which derived files will execution overwrite?
4. What are the expected outputs, RC, record counts, and amounts, and how can they be calculated independently?
5. What must be changed, and which interfaces must not be broken?
6. Which conditions should be deliberately broken, and how should the learner investigate and recover?
7. Which plugin operations help with diagnosis, and what is the terminal alternative?
8. What evidence must be submitted, and what result counts as failure?

A program that only displays explanatory text must not serve as the primary implementation for file processing, DB, sorting, matching, or an integrated project. Code must actually process the supplied data.

## 3. Fixture Matrix

| Category | Minimum coverage | Required outcome |
|---|---|---|
| Input boundaries | Missing, zero bytes, last record, no match, EOF on both sides, short/long records | Explicit policy for RC, rejection, and whether empty files are allowed |
| Fields | Empty required field, invalid number, unknown status, amount limits, sign/scale | Explicit field-level cause; no silent truncation |
| Keys | Duplicate Master, duplicate transaction, reverse order, different order within same key, orphan key | Explicit cardinality and classification strategy |
| DB | No result, NULL, unique constraint, connection failure, transaction rollback | Original DB state and mapped RC |
| Environment | No output permission, insufficient temporary space, concurrent lock, incorrect date | No formal output published; source data is not overwritten |
| Recovery | Crash before/after commit, before/after publication, same-day repeated start | No duplicate application; state and evidence remain consistent |
| Silent errors | RC0 with wrong amount, one row missing, one extra row, stale DB snapshot | Control totals or difference acceptance must detect the issue |

For file fixtures, record the character set, line endings, byte lengths, and checksums. Invalid bytes/bad Packed Decimal must be supplied as actual bytes or generated reproducibly; writing “this is bad data” in a README is insufficient. A random-data generator may create lab material but must not replace the learner’s core COBOL algorithm.

## 4. Expected Results and Verification Evidence

Determine expected results from business rules, a manually calculated small example, or an independent reference model before validating them against the learner/reference program. Do not treat the implementation’s own output as the correct answer. Every expected result must include an explanation of the rules and calculation.

Checks must include compilation, source format, script status, exit code, file bytes/logical contents, rejection classification, record-count conservation, amount conservation, and formal publication state. If comparisons allow normalization, explain each allowed difference, such as platform line-ending differences; do not trim entire outputs and thereby hide fixed-width record errors.

Evidence format: version/commit, compiler and DB tool versions, business date, run_id, command, raw RC, input checksums, output checksums, reconciliation table, investigation conclusion, and limitations. Any mismatch between logs/outputs and assertions is a failure.

## 5. Reference Answers and Incident Distribution

The learner package provides only tasks, available materials, and graduated hints; the instructor package holds reference implementations, root causes, trigger conditions, minimal fixes, misleading clues, and grading points. Since a public repository cannot keep answers secret, provide a reproducible learner packaging method that excludes instructor materials, and tell self-study learners where the answers are located.

An incident package must include at least the Scheduler Flow/state, JOB Log, Shell, source, Copybook, original input, parameters/Manifest, and DB seed or SQL Log. Include at least six incident classes: invalid number, DB unique constraint, empty input, reverse-ordered Master, system resource failure, and RC0 with a business error. Each class must have an actual reproducible entry point; explain host ABEND names separately from actual GNUCOBOL behavior.

Incident investigation deliverables, in order: symptoms and impact scope → timeline → hypotheses and evidence → minimal reproduction → root cause → fix/rollback → recovery and rerun → prevention. Do not “fix” an incident by altering original input or relaxing assertions.

## 6. Legacy Maintenance Change Package

Requirement: expand the customer category from 1 digit to 2 digits. Deliver before coding:

- Impact investigation: field definition, all usage locations, dependency graph, and unknowns.
- Change target list: Copybooks, programs, files, DB, Shell, JOB, design documents, downstream interfaces, and responsible roles.
- Change strategy: layouts v1/v2, compatibility policy, migration/rollback steps, data cutover, and parallel validation.
- Test cases: normal, boundary, invalid, cross-version, end-to-end, and recovery scenarios.
- Evidence plan: expected result and evidence location for each test.

Modify only after the investigation review. On completion, submit before/after layouts, generated files, DB results, upstream/downstream tests, and rollback evidence. The graduation project must demonstrate complexity through real business behavior, runtime chains, and dependencies. Responsibilities for Copybooks, Shell, JOB nodes, and logical tables must be traceable in the system inventory.

## 7. Module 07 Benchmark Acceptance

L1 covers EOF states on both sides and three output classes; L2 covers accumulation across consecutive same-key records, transaction order within a key, duplicate transactions, and overflow; L3 submits a multi-stream cardinality table, state transition table, and snapshot-date validation; L4 submits a catalog of at least 150 fields and an independent difference list.

Checks must not use whole-flow in-memory arrays, SQL Join, or Python matching. A system SORT may be used as an independent JOB, but learners must still implement and verify COBOL sequential matching and ordering checks. Memory evidence, counts, and amount conservation are all required for acceptance.

## 8. Graduation Scoring and Hard Gates

| Dimension | Points |
|---|---:|
| Data structures and byte interpretation | 15 |
| File/sort/matching correctness | 25 |
| DB, JOB, recovery, and idempotency | 20 |
| Impact investigation and safe changes | 20 |
| Incident investigation and evidence | 20 |

The total must be at least 80/100, and all hard gates must pass: no duplicate debit, correct amount/count reconciliation, no publication on failure, evidence of upstream/downstream version compatibility, reproducible incident root cause, and investigation before modification. Failure of a hard gate cannot be offset by points in other areas. The graduation exercise includes an unknown incident; it is not limited to repeating answers already demonstrated.

## 9. Stage Release Checklist

- [ ] Stage goals, prerequisites, hours, and business outcomes are clear.
- [ ] Starter code and reference implementation build from a clean environment.
- [ ] All files read and DB seed data are included with the course.
- [ ] Expected results have an independent calculation basis; RCs and control totals are covered.
- [ ] Learners can complete the task without looking at the answer.
- [ ] Source follows the chosen fixed format; free-format exceptions are labeled separately.
- [ ] Platform/tool versions, ABI, DB precompiler, and error-code limitations are documented.
- [ ] Both plugin tasks and terminal-only alternatives are executable.
- [ ] Run/reset does not damage original fixtures or artifacts from other labs.
- [ ] Course/instructor/evidence versions are clearly associated; no fabricated “passed” claims.
