# Incident INC-2026-004: Match Node Aborted; Candidate Not Generated

> Student package. **The root cause is not included.** Investigate in this order: symptoms and impact → timeline → hypotheses and evidence → minimal reproduction → root cause → fix/rollback → recovery and rerun → prevention. See [hints.md](hints.md) for progressive hints.

## 1. Symptoms and impact

- The nightly batch for business date `20261009` aborted in **JOB005 (sequential match and balance calculation)** with exit code **RC8**.
- JOB003/JOB004 completed; after JOB005 failed, JOB006+ did not run and there was no publication.
- Impact: no candidate closing Master was generated; downstream systems have no data (no incorrect result was published).

## 2. Timeline

| Time (UTC) | Event |
|---|---|
| 01:02:xx | JOB001–JOB004 COMPLETE rc=0 |
| 01:02:xx | JOB005 match start |
| 01:02:xx | JOB005 ERROR `match failed rc=8`; log contains an out-of-order hint |
| 01:02:xx | Net stopped, JOB006+ NOT_RUN, lock released |

Original scene: `scene/console.txt`, `scene/logs/nightly.log`, `scene/logs/JOB005.log`, and `scene/scheduler-status.txt`.

## 3. Package inventory

| Material | Location |
|---|---|
| Scheduler status | `scene/scheduler-status.txt` |
| Run parameters | `scene/run.env` |
| Original receive manifests | `scene/MANIFEST`, `input/MANIFEST` |
| Original inputs (unchanged) | `input/transaction.dat`, `input/account_seed.dat`, `input/customer_seed.dat` |
| JOB logs | `scene/logs/nightly.log`, `scene/logs/JOB0*.log` |
| Relevant source | `scene/source/M11MATCH.COB`, `scene/source/job005-match.sh`, `scene/source/db.py` |
| Copybooks (frozen interfaces) | `scene/copybooks/{CUSTOMER,ACCOUNT,TRANSACTION}-V1.CPY` |
| Reproduction script | `run.sh` |

## 4. Reproduce

```bash
bash INC-2026-004/student/run.sh /tmp/INC-2026-004-scene /tmp/INC-2026-004-db
echo "rc=$?"
cat /tmp/INC-2026-004-scene/logs/JOB005.log
cat -A /tmp/INC-2026-004-scene/work/db/account_master.dat   # Master actually read by the match
```

## 5. Investigation tasks

1. Reproduce and record the original RC and failing node.
2. Sequential matching requires both input streams to be sorted (Master by account_id; transactions by account_id, sequence, transaction_id). Read the input section of `M11MATCH.COB`: which stream's ordering does it check and abort on?
3. Starting from `input/account_seed.dat`, independently verify whether each input stream satisfies its sorting prerequisite. If one violates it, provide the first violation (account values and adjacent records).
4. Trace the root cause: from Seed → JOB004 snapshot → JOB005 read, at which boundary was order lost or corrupted? Why is “candidate not generated” the correct failure behavior instead of “generate an incorrect candidate”?
5. Provide recovery (at **which boundary** to sort/extract again) and prevention (upstream extract ordering, boundary ordering precheck, snapshot/source consistency check).

## 6. Hint ladder

See [hints.md](hints.md).

## 7. Plugin and terminal alternatives

```bash
cut -b1-10 INC-2026-004/student/input/account_seed.dat
sort -c -k1.1,1.10 INC-2026-004/student/input/account_seed.dat \
  && echo "sorted" || echo "NOT sorted"
rg -n 'out of order|PREV-ACCT|1000-READ-ACCOUNT' \
   INC-2026-004/student/scene/source/M11MATCH.COB
```
