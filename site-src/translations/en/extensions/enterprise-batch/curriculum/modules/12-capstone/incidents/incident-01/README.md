# Incident 01: Nightly Flow Not Published on 20261010 (Issued Materials)

> This file contains **issued materials** and describes only observed symptoms and available evidence. It **does not include the root cause or a fix**.
> The root cause, minimal fix, and grading points are in `instructor/modules/12-capstone/INCIDENT-01.md`.

## Symptoms (report received by the on-call operator)

The nightly flow for business date 20261010 **failed before publish**: downstream did not receive that day's `closing-master.dat` / `customer-day.dat`, and `publish/CURRENT` was not updated. The earlier nodes (receive, validation, sorting) appeared to complete normally in the logs, but the flow stopped later.

## Scope of impact

- No official publish for the day; downstream reconciliation is waiting.
- The database store's ledger was **not** contaminated (verify this yourself; do not conclude from the last log line).
- No duplicate debit occurred (also requires evidence).

## Materials provided

| File | Contents |
|---|---|
| `materials/params.txt` | Business date, layout, input directory, and run_id for that night |
| `materials/feed/` | Received input snapshot (TRANSACTION/CUSTOMER/ACCOUNT + MANIFEST) |
| `materials/scheduler-state.txt` | Scheduler record of JOB status and RC |
| `materials/logs/` | JOB logs and excerpt from `nightly.log` |
| `materials/operator-notes.md` | On-call handoff notes |
| `reproduce/reproduce.sh` | Replays the night with the same parameters and exports raw evidence |

## Your task

Deliver, in the order specified by section 5 of `AUTHORING-STANDARD`: symptoms and impact scope → timeline → hypotheses and evidence → minimal reproduction → root cause → fix/rollback → recovery and rerun → prevention.

Hard requirements:

- **Do not modify original input** to "fix" the incident; recovery must be an auditable business correction.
- The root cause must be reproducible from the materials and identify the specific data/step involved.
- Explain with evidence why the ledger was or was not contaminated; do not rely on the last log line.
- Provide recovery commands and original RC that avoid duplicate debits.

## Suggested inspection (terminal; plugin optional)

```bash
incident=curriculum/modules/12-capstone/incidents/incident-01
cat "$incident/materials/scheduler-state.txt"
sed -n '1,80p' "$incident/materials/logs/nightly.log"
bash "$incident/reproduce/reproduce.sh" /tmp/m12-incident-01
```

Submit evidence as described in `curriculum/modules/12-capstone/evidence/README.md`.
