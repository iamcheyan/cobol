# Incident INC-2026-006: Overnight Batch Succeeded, but Control Totals Differ from the Upstream Declaration

> Student package. **Root cause not disclosed.** Follow this order: symptoms and impact → timeline → hypotheses and evidence → minimal reproduction → root cause → fix/rollback → recovery and rerun → prevention.
> Tiered hints are in [hints.md](hints.md).

## 1. Symptoms and impact

- **All nodes completed** in the overnight batch for business date `20261009`, with overall **RC0**, and `publish/as-found/` was formally published.
- The business team independently recalculated the day's **credit total** and **closing total**; they **did not match** the control totals declared upstream alongside the file (the `control_*` declarations in the Manifest).
- Impact: **incorrect control totals and closing balances have already been published**; downstream reconciliation using them would produce an end-of-day result that differs from the upstream data.
- Note: this error is **internally self-consistent**—all of JOB007's internal comparisons passed.

## 2. Timeline

| Time (UTC) | Event |
|---|---|
| 01:02:xx | JOB001–JOB009 all COMPLETE rc=0 |
| — | JOB006 committed; JOB007 internal checks PASS; JOB008 published |
| Afterward | Business compared the result with the upstream declaration and found control totals did not match |

Original scene: `scene/console.txt`, `scene/logs/nightly.log`, `scene/logs/JOB007.log`, `scene/logs/JOB002.log`, `scene/published-control-report.txt`, `scene/MANIFEST`, and `scene/scheduler-status.txt`.

## 3. Package contents

| Material | Location |
|---|---|
| Scheduler status | `scene/scheduler-status.txt` |
| Run parameters | `scene/run.env` |
| Original receive manifest (including upstream `control_*` declarations) | `scene/MANIFEST`, `input/MANIFEST` |
| Original input (unchanged) | `input/transaction.dat`, `input/account_seed.dat`, `input/customer_seed.dat` |
| JOB logs | `scene/logs/nightly.log`, `scene/logs/JOB0*.log` |
| DB ledger scene | `scene/ledger-victim.dat`, `scene/db-account.table` |
| Published results | `scene/published-control-report.txt`, `scene/published-closing-master.dat` |
| Relevant source | `scene/source/control.py`, `scene/source/M11MATCH.COB`, `scene/source/M11VAL.COB` |
| Copybooks (frozen interfaces) | `scene/copybooks/{CUSTOMER,ACCOUNT,TRANSACTION}-V1.CPY` |
| Reproduction script | `run.sh` |

## 4. Reproduce

```bash
bash INC-2026-006/student/run.sh /tmp/INC-2026-006-scene /tmp/INC-2026-006-db
echo "rc=$?"                          # original RC
cat /tmp/INC-2026-006-scene/work/control/control.txt
grep '^control_' INC-2026-006/student/input/MANIFEST
```

## 5. Investigation tasks

1. Reproduce and confirm the original RC and the fact that results were published.
2. Independently recalculate the credit/debit/closing totals from `input/transaction.dat`, then compare all three sources: `scene/published-control-report.txt`, the upstream declaration (`control_*` in the Manifest), and your calculation. Which values disagree?
3. Read `scene/source/control.py`: which numbers does JOB007 actually compare? Does it use the control totals declared in the input Manifest? If not, why can “internal consistency” not replace “reconciliation with upstream”?
4. Determine the source of the difference (was a record's amount itself keyed incorrectly, or did the program calculate incorrectly?). Give a method to locate the record and its offset.
5. Propose a minimal fix (JOB007 should reconcile against the declared upstream control totals and return RC8 without publishing on mismatch), recovery/rerun (corrected data run, new business version), and prevention.

## 6. Hint ladder

See [hints.md](hints.md).

## 7. Plugin and terminal alternatives

```bash
cut -b41-54 INC-2026-006/student/input/transaction.dat
awk '{s+=substr($0,42,13)} END{print "sum amount="s}' \
  INC-2026-006/student/input/transaction.dat
rg -n 'control_|declared|MANIFEST|closing_total' \
   INC-2026-006/student/scene/source/control.py \
   INC-2026-006/student/input/MANIFEST
```
