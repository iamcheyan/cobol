# Incident INC-2026-005: Sort Node Aborted, Nothing Published

> Student package. **Root cause not disclosed.** Follow this order: symptoms and impact → timeline → hypotheses and evidence → minimal reproduction → root cause → fix/rollback → recovery and rerun → prevention.
> Tiered hints are in [hints.md](hints.md).

## 1. Symptoms and impact

- The overnight batch for business date `20261009` aborted in **JOB003 (sort and ordering validation)** with exit code **RC12 (system failure)**.
- JOB001/JOB002 completed; after JOB003 failed, JOB004+ did not run, and nothing was published.
- Operations noted that the host's temporary space had an abnormal condition during this window.
- Impact: the sorted file was not generated, so downstream steps received no data; **nothing was formally published**, and the lock was released.

## 2. Timeline

| Time (UTC) | Event |
|---|---|
| 01:02:xx | JOB001/JOB002 COMPLETE rc=0 |
| 01:02:xx | JOB003 sort start |
| 01:02:xx | JOB003 ERROR (system failure) rc=12 |
| 01:02:xx | Nightly flow stopped, JOB004+ NOT_RUN, lock released |

Original scene: `scene/console.txt`, `scene/logs/nightly.log`, and `scene/scheduler-status.txt`.

## 3. Package contents

| Material | Location |
|---|---|
| Scheduler status | `scene/scheduler-status.txt` |
| Run parameters | `scene/run.env` |
| Original receive manifests | `scene/MANIFEST`, `input/MANIFEST` |
| Original input (unchanged) | `input/transaction.dat`, `input/account_seed.dat`, `input/customer_seed.dat` |
| JOB logs | `scene/logs/nightly.log`, `scene/logs/JOB0*.log` |
| Relevant source | `scene/source/job003-sort.sh` (sort node), `scene/logs/JOB003.log`, `scene/source/nightly.sh` |
| Copybooks (frozen interfaces) | `scene/copybooks/{CUSTOMER,ACCOUNT,TRANSACTION}-V1.CPY` |
| Reproduction script | `run.sh` (injects a failing `mktemp` into PATH for this run only) |

## 4. Reproduce

```bash
bash INC-2026-005/student/run.sh /tmp/INC-2026-005-scene /tmp/INC-2026-005-db
echo "rc=$?"
cat /tmp/INC-2026-005-scene/logs/nightly.log
```

## 5. Investigation tasks

1. Reproduce and record the original RC and the failing node.
2. What does this node do? Which **system resources** does it depend on (temporary directory, write permissions, disk space, child processes)? Read `system/jobs/job003-sort.sh` to find where it creates its temporary workspace.
3. Why is this failure **RC12 rather than RC8**? Distinguish a “data error” from an “environment/resource failure.”
4. Key evidence: after failure, **is there** a temporary directory left in the run directory? Does `publish/` exist? Was the business-date lock released? Give the command and result for each.
5. Describe recovery (fix temporary space/permissions, then rerun with a new run_id) and prevention (preflight resource checks, disk-usage alerts, no publication on failure, and lock cleanup).

## 6. Hint ladder

See [hints.md](hints.md).

## 7. Plugin and terminal alternatives

```bash
ls -la /tmp/INC-2026-005-scene/work/ 2>/dev/null
ls -la /tmp/INC-2026-005-scene/publish 2>/dev/null
ls -la /tmp/INC-2026-005-db/locks 2>/dev/null
df -h /tmp
rg -n 'mktemp|temp space|system failure' \
   INC-2026-005/student/scene/source/job005-match.sh \
   INC-2026-005/student/scene/logs/nightly.log
```
