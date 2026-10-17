# Incident INC-2026-001: Validation Node Aborted; No Publication for the Day

> Student package. **The root cause is not included.** Investigate in this order: symptoms and impact → timeline → hypotheses and evidence → minimal reproduction → root cause → fix/rollback → recovery and rerun → prevention. Submit evidence in `evidence/`. See [hints.md](hints.md) for progressive hints.

## 1. Symptoms and impact

- The nightly batch for business date `20261009` aborted in **JOB002 (validation)** with exit code **RC8**.
- The net immediately stopped: nodes after JOB003 **did not run**, no publication directory for this run exists under `publish/`, and the CURRENT pointer was not updated.
- Impact: all downstream files for the day are missing; downstream systems did not receive erroneous data (nothing was published).

## 2. Timeline

| Time (UTC) | Event |
|---|---|
| 01:02:08 | Scheduler started `run_id=as-found`; JOB001 receive COMPLETE |
| 01:02:08 | JOB002 validation start |
| 01:02:09 | JOB002 validation ERROR `validator failed rc=8` |
| 01:02:09 | Net stopped, JOB003+ NOT_RUN, lock released |

Original scene: `scene/console.txt`, `scene/logs/nightly.log`, `scene/logs/JOB002.log`, and `scene/scheduler-status.txt`.

## 3. Package inventory

| Material | Location |
|---|---|
| Scheduler status | `scene/scheduler-status.txt` |
| Run parameters (business date/run_id/paths) | `scene/run.env` |
| Original receive manifests | `scene/MANIFEST`, `input/MANIFEST` |
| Original inputs (unchanged) | `input/transaction.dat`, `input/account_seed.dat`, `input/customer_seed.dat` |
| JOB logs | `scene/logs/nightly.log`, `scene/logs/JOB0*.log` |
| Relevant source | `scene/source/M11VAL.COB`, `scene/source/job002-validate.sh` |
| Copybooks (frozen interfaces) | `scene/copybooks/{CUSTOMER,ACCOUNT,TRANSACTION}-V1.CPY` |
| Reproduction script | `run.sh` |

## 4. Reproduce

```bash
# Run from any directory; uses this package's input/ copy without modifying shared fixtures
bash INC-2026-001/student/run.sh /tmp/INC-2026-001-scene /tmp/INC-2026-001-db
echo "rc=$?"
cat /tmp/INC-2026-001-scene/logs/JOB002.log
```

Expected: reproduce the same original RC as the scene (see `scene/rc.txt`).

## 5. Investigation tasks (reproduce first, then locate)

1. Reproduce and record the original RC and failing node.
2. Inspect `input/transaction.dat` byte by byte with `od -An -tc` / `cut`, and compare each field with the frozen layout in `copybooks/TRANSACTION-V1.CPY`. Decide whether this is a **structural error** or a **business rejection**, and explain the course RC convention.
3. Explain why it is correct that the net published no downstream files.
4. Record the root cause, minimal fix (data side vs. code side), recovery and rerun steps, and prevention measures in `evidence/`. Do not “fix” this by weakening validation or rewriting the original input.

## 6. Hint ladder

See [hints.md](hints.md). Read only Level 1 first.

## 7. Plugin and terminal alternatives

- Plugin: use `gd` on `source/M11VAL.COB` to jump to the validation paragraph; preview the Copybook with `K`/`:CobolPreview`; use diagnostics on save to check the 72-column limit and Area A/B.
- Terminal only:
  ```bash
  awk '{print NR": "length($0)" cols"}' INC-2026-001/student/input/transaction.dat
  od -An -tc INC-2026-001/student/input/transaction.dat
  rg -n 'WS-STRUCT|2000-PROCESS' \
     INC-2026-001/student/scene/source/M11VAL.COB
  ```
