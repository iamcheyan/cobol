# Incident INC-2026-003: Receive Node Aborted; No Publication for the Day

> Student package. **The root cause is not included.** Investigate in this order: symptoms and impact → timeline → hypotheses and evidence → minimal reproduction → root cause → fix/rollback → recovery and rerun → prevention. See [hints.md](hints.md) for progressive hints.

## 1. Symptoms and impact

- The nightly batch for business date `20261009` aborted in **JOB001 (receive/Manifest validation)** with exit code **RC12 (system failure)**.
- The net stopped immediately; JOB002+ did not run, and there is no publication for this run under `publish/`.
- Upstream transfer reports “sent successfully,” but the day's transaction file in the receive directory is **0 bytes**.

## 2. Timeline

| Time (UTC) | Event |
|---|---|
| 01:02:09 | Scheduler started `run_id=as-found`; JOB001 start |
| 01:02:09 | JOB001 ERROR `checksum mismatch for 'transaction.dat'` |
| 01:02:09 | Net stopped, JOB002+ NOT_RUN, lock released |

Original scene: `scene/console.txt`, `scene/logs/nightly.log`, `scene/logs/JOB001.log`, and `scene/scheduler-status.txt`.

## 3. Package inventory

| Material | Location |
|---|---|
| Scheduler status | `scene/scheduler-status.txt` |
| Run parameters | `scene/run.env` |
| Original receive manifests | `scene/MANIFEST`, `input/MANIFEST` |
| Original inputs (unchanged, 0 bytes) | `input/transaction.dat` |
| DB seeds | `input/account_seed.dat`, `input/customer_seed.dat` |
| JOB logs | `scene/logs/nightly.log`, `scene/logs/JOB001.log` |
| Relevant source | `scene/source/M11VAL.COB`, `scene/source/job002-validate.sh` |
| Copybooks (frozen interfaces) | `scene/copybooks/{CUSTOMER,ACCOUNT,TRANSACTION}-V1.CPY` |
| Reproduction script | `run.sh` |

## 4. Reproduce

```bash
bash INC-2026-003/student/run.sh /tmp/INC-2026-003-scene /tmp/INC-2026-003-db
echo "rc=$?"
wc -c INC-2026-003/student/input/transaction.dat   # inspect actual byte count
cat /tmp/INC-2026-003-scene/logs/JOB001.log
```

## 5. Investigation tasks

1. Reproduce and record the original RC and failing node.
2. List all checks JOB001 performs before entering JOB002 (Manifest declarations, checksums, snapshot). **Which check** detects the anomaly first?
3. Is this RC8 (business) or RC12 (system)? Explain why.
4. Key distinction: is a 0-byte file itself a “valid empty file” or a “damaged transfer”? How does the course contract define its empty-file policy? Do not guess; cite the expected content declared by the Manifest.
5. Provide recovery steps (receive again/verify the source, rerun with a new run_id) and prevention (transfer checks, a post-receive length sentinel, alerts).

## 6. Hint ladder

See [hints.md](hints.md).

## 7. Plugin and terminal alternatives

```bash
od -An -tc INC-2026-003/student/input/transaction.dat
sha256sum INC-2026-003/student/input/transaction.dat
cat INC-2026-003/student/scene/MANIFEST
rg -n 'checksum|MANIFEST|snapshot' \
   INC-2026-003/student/scene/source/M11VAL.COB \
   INC-2026-003/student/scene/logs/JOB001.log
```
