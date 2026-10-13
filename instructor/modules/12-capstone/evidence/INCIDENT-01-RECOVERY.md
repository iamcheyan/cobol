# module 12 incident-01 RECOVERY (business correction, raw RC)
date=2026-10-10T01:37:00Z
corrected feed = deduplicated incident feed, new run_id, same (still empty) db
cmd: scripts/run.sh --input /tmp/m12-fix/feed --output /tmp/m12-fix/out --db /tmp/m12-fix/db --business-date 20261010 --layout v1 --run-id night-20261010-02
recovery_rc=0
published=night-20261010-02
ledger_lines=6
customer_total=1850
account_total=1850
original incident feed unchanged: sha=1f220d91540d2732d49121ec6275964745fe1983e6cb86a50b197b066ce975e3
