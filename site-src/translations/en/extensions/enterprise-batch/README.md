# Enterprise Batch Curriculum Extension

This extension contains a 12-module enterprise batch curriculum built around a synthetic bank overnight workflow. It covers record layouts, file processing, sort/merge matching, Embedded SQL, modularization, JOB scheduling, incident investigation, and a capstone project. It is an advanced set of exercises for the CPR #31 main curriculum; we recommend first completing the related language, file, and modularization courses in `lessons/`.

## Connection to the 32-Lesson Main Curriculum

| Recommended main course to complete first | Enterprise extension module | Suggested follow-up practice |
|---|---|---|
| [15–22 File Processing](../../lessons/DIRECTORY.md) | [06 Files](curriculum/modules/06-files/README.md), [07 Sort/Merge Matching](curriculum/modules/07-matching/README.md) | Multi-stream files, sort/merge, and bank reconciliation |
| [23–28 Engineering](../../lessons/DIRECTORY.md) | [09 Modularization](curriculum/modules/09-modular/README.md), [10 JOBs](curriculum/modules/10-jobs/README.md), [11 Incident Investigation](curriculum/modules/11-incidents/README.md) | Job orchestration, rerun recovery, and maintenance of existing systems |
| [29–31 Databases](../../lessons/DIRECTORY.md) | [08 Embedded SQL](curriculum/modules/08-database/README.md) | Hands-on GixSQL/PostgreSQL cursors, transactions, and idempotent processing |
| [32 Capstone Project](../../lessons/32_bank-reconciliation-project/README.md) | [12 Enterprise Capstone Project](curriculum/modules/12-capstone/README.md) | Multi-job bank overnight batch processing and failure recovery |

## Resources

- [`curriculum/README.md`](curriculum/README.md): module map, status, and acceptance test entry points.
- [`docs/curriculum/README.md`](docs/curriculum/README.md): design, bank data contract, and authoring standards.
- [`instructor/`](instructor/): instructor reference implementations, grading materials, and review records.
- [`tasks/`](tasks/): curriculum development, review, and handoff records.

## Checks

Run from the repository root:

```sh
bash extensions/enterprise-batch/curriculum/check.sh
```

Or, after changing to this extension's directory:

```sh
cd extensions/enterprise-batch
bash curriculum/check.sh
```

The quick checks cover every module, curriculum packaging, and the fixed-format gate. The PostgreSQL/GixSQL route, which requires Docker, is verified by a separate script; if Docker is unavailable, its status must remain `UNVERIFIED`. Module documents distinguish actual database results from offline file checkpoints.
