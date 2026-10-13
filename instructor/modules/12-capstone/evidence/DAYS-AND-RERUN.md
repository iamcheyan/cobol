# module 12 -- real four-day run + rerun (raw RC)
date=2026-10-10T01:35:00Z  cobc=cobc (GnuCOBOL) 3.2.0
normal layout=v1 rc=0 published=d-normal
abnormal layout=v1 rc=4 published=d-abnormal
extension layout=v2 rc=0 published=d-extension
broken layout=v1 rc=8 published=none

# rerun idempotency (same DB as normal)
rerun rc=0 new_transactions=0 ledger_lines=6

# customer feed is the independent enterprise layout:
#   v1 = 31 B (classification byte 28 = A/B/C/D, status byte 27)
#   v2 = 32 B (classification bytes 28-29 = A1..D1)
# customer-day classification: normal A1, extension A1 + D1
