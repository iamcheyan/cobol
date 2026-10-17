# Incident INC-2026-007: Validation Node Aborted, Nothing Published for the Day

> Student package. **Root cause not disclosed.** Investigate in this order: “symptoms and impact → timeline → hypotheses and evidence → minimal reproduction → root cause → fix/rollback → recovery and rerun → prevention,” and submit evidence in `evidence/`. Tiered hints are in [hints.md](hints.md).

## 1. Symptoms and impact

- The overnight batch for business date `20261009` aborted in **JOB002 (validation)** with exit code **RC8**.
- JOB001 (receive/validate Manifest) completed: the delivered files **match the Manifest declarations**, so the issue is not “not received/truncated”; validation found content that does not satisfy the contract.
- The nightly flow stopped: JOB003 onward **did not run**, there is no publication directory for this run under `publish/`, and the CURRENT pointer was not updated.
- Impact: all downstream files for the day are missing; downstream did not receive incorrect data (nothing was published).

## 2. Timeline

| Time (UTC) | Event |
|---|---|
| 01:02:08 | Scheduler started `run_id=as-found`; JOB001 receive COMPLETE |
| 01:02:08 | JOB002 validation start |
| 01:02:09 | JOB002 validation ERROR `validator failed rc=8` |
| 01:02:09 | Nightly flow stopped, JOB003+ NOT_RUN, lock released |

Original scene: `scene/console.txt`, `scene/logs/nightly.log`, `scene/logs/JOB002.log`, and `scene/scheduler-status.txt`.

## 3. Package contents

| Material | Location |
|---|---|
| Scheduler status | `scene/scheduler-status.txt` |
| Run parameters (business date/run_id/paths) | `scene/run.env` |
| Original receive manifest | `scene/MANIFEST`, `input/MANIFEST` |
| Original input (unchanged) | `input/transaction.dat`, `input/account_seed.dat`, `input/customer_seed.dat` |
| JOB logs | `scene/logs/nightly.log`, `scene/logs/JOB0*.log` |
| Relevant source | `scene/source/M11VAL.COB`, `scene/source/job002-validate.sh` |
| Copybooks (frozen interfaces) | `scene/copybooks/{CUSTOMER,ACCOUNT,TRANSACTION}-V1.CPY` |
| Reproduction script | `run.sh` |

## 4. Reproduce

```bash
# Run from any directory; use this package's input copy without changing shared fixtures
bash INC-2026-007/student/run.sh /tmp/INC-2026-007-scene /tmp/INC-2026-007-db
echo "rc=$?"
cat /tmp/INC-2026-007-scene/logs/JOB002.log
```

The expected reproduction has the same original RC as the scene (see `scene/rc.txt`).

## 5. Investigation tasks (reproduce first, then locate)

1. Reproduce and record the original RC and failing node.
2. Use `awk '{print NR": "length($0)}'` / `od -An -tc` to inspect the **byte length of every record** in `input/transaction.dat`, and compare it with the frozen 55-byte layout in `copybooks/TRANSACTION-V1.CPY`.
3. Identify the record that fails the length precondition; explain why this kind of **length/misalignment** issue is a **structural error (RC8)** rather than a per-transaction business rejection (RC4).
4. Explain why JOB001 accepted the delivery (Manifest matches delivered bytes), while JOB002 failed. Where is the boundary between receive validation and content-contract checks?
5. In `evidence/`, document the root cause, minimal fix (data side vs code side), recovery and rerun steps, and prevention measures. Do not “fix” the issue by relaxing the length check or rewriting the original input.

## 6. Hint ladder

See [hints.md](hints.md). Read only Level 1 first.

## 7. Plugin and terminal alternatives

- Plugin: on `source/M11VAL.COB`, use `gd` to jump to the validation paragraph; use `K`/`:CobolPreview` to preview the Copybook; when saving, use diagnostics to check the 72-column limit and Area A/B.
- Terminal-only alternative:
  ```bash
  awk '{print NR": "length($0)" cols"}' INC-2026-007/student/input/transaction.dat
  od -An -tc INC-2026-007/student/input/transaction.dat
  rg -n 'WS-LEN|record length|2000-PROCESS' \
     INC-2026-007/student/scene/source/M11VAL.COB
  ```
