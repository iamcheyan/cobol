# module 12 -- maintenance RED->GREEN (raw)
date=2026-10-10T01:36:00Z
cmd: bash curriculum/modules/12-capstone/maintenance/regression/red-green.sh /tmp/m12-rg
RED=12
GREEN=0
RED_PUBLISHED=no
PASS: RED (v1-only) then GREEN (v2-aware) on the extension feed
script_rc=0
note: RED/GREEN now run over the 32 byte CAP-CUSTOMER-FEED v2 feed;
      the 27 byte canonical CUSTOMER v1 (byte 27 = status) is unchanged.
