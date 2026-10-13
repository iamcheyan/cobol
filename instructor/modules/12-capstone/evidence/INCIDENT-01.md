# module 12 incident-01 reproduce (raw)
date=2026-10-10T01:36:30Z
cmd: bash curriculum/modules/12-capstone/incidents/incident-01/reproduce/reproduce.sh /tmp/m12-incident-01
==== inner params (from materials/params.txt) ====
business_date=20261010
layout=v1
input=curriculum/modules/12-capstone/incidents/incident-01/materials/feed
output=/var/bank/runs/20261010-incident
db=/var/bank/db
run_id=night-20261010-01
db_layer=offline-file-checkpoint

reproduce_rc=8
published=none

==== scheduler state after the night ====
{"accounts": 3, "customers": 2, "tables": 12}
001a-receive-manifest INFO: start
001b-verify-checksums INFO: start
001c-freeze-snapshot INFO: start
002a-length-check INFO: start
002b-numeric-check INFO: start
002c-business-rules INFO: start
002d-customer-validate INFO: start
002e-reject-report INFO: start
003a-build-sort INFO: start
003b-sort INFO: start
003b-sort ERROR: validate: duplicate transaction_id A000000000000001x2
JOB003 ERROR: business failure rc=8
nightly failed rc=8; removing unpublished run dir

# duplicate transaction_id observable in the released feed
A000000000000001

# note: the incident feed's customer.dat was migrated to the enterprise
# layout (31 B, byte 27 = status); the duplicate-txid transaction.dat is
# unchanged (sha=1f220d91540d2732d49121ec6275964745fe1983e6cb86a50b197b066ce975e3).
script_rc=0
