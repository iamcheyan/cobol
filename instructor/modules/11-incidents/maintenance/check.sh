#!/usr/bin/env bash
# Maintenance 11.5 acceptance: enterprise customer layout v1 -> v2
# migration, rollback, parallel validation and the v2 classification
# extract -- plus a regression proving the canonical 27-byte CUSTOMER v1
# STATUS interface is untouched.
#
#   check.sh [WORKDIR]
set -Eeuo pipefail
export LC_ALL=C
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo=$(cd -- "$here/../../../../" && pwd)
module="$repo/curriculum/modules/11-incidents"
system="$module/system"
expected="$module/expected"
work=${1:-"$PWD/m11-maintenance"}
rm -rf -- "$work"
mkdir -p -- "$work"
fail=0
note() { printf '%-46s %s\n' "$1" "$2"; }

# 0. independent layout verification: copybook PIC/offsets, GnuCOBOL
#    ADDRESS OF offsets + LENGTH OF, and semantic golden bytes; also the
#    CUSTOMER v1 27-byte status regression.  Uses a DISTINCT lab name
#    (ENTERPRISE-CLASS) from canonical module 07 L4 ENTERPRISE-CUSTOMER-V1.
if python3 "$here/verify-layout.py"; then
  note "layout offset/PIC/golden (verify-layout.py)" "OK"
else
  note "layout offset/PIC/golden (verify-layout.py)" "FAIL"; fail=1
fi

v1="$module/fixtures/enterprise-customer/customer.v1"
custv1="$module/fixtures/normal/customer_seed.dat"
cp -- "$v1" "$work/customer.v1"

# 1. enterprise v1 -> v2 migration (new file, original untouched).
if python3 "$here/migrate-customer.py" to-v2 "$v1" "$work/customer.v2"; then
  rc=0; else rc=$?; fi
width=$(tr -d '\n' <"$work/customer.v2" | wc -c)
rows=$(wc -l <"$work/customer.v2")
note "migrate v1->v2 rc" "$rc (rows=$rows width=$((width/rows))B)"
[[ $rc == 0 && $((width / rows)) == 24 ]] || fail=1
cmp -s -- "$v1" "$work/customer.v1" && note "v1 file untouched" yes \
  || { note "v1 file untouched" no; fail=1; }

# 2. build the reference v2 extractor and the CUSTOMER v1 status extractor.
bash "$system/scripts/build.sh" "$work/m11cust2" \
  "$here/M11CUST2.COB" >/dev/null || { note "build M11CUST2" fail; fail=1; }
bash "$system/scripts/build.sh" "$work/m11cust" \
  "$system/cobol/M11CUST.COB" >/dev/null || { note "build M11CUST" fail; fail=1; }

# 3. v2 enterprise extract matches the independently written expected.
M11CUST_INPUT="$work/customer.v2" M11CUST_EXTRACT="$work/class.v2" \
  M11CUST_REPORT="$work/report.v2" "$work/m11cust2" >/dev/null 2>&1
rr=$?
if [[ $rr == 0 ]] && diff -q -- "$work/class.v2" \
     "$expected/enterprise-class-v2.txt" >/dev/null; then
  note "v2 enterprise extract vs expected" "MATCH"
else
  note "v2 enterprise extract vs expected" "MISMATCH (rc=$rr)"; fail=1
fi

# 3b. v1 enterprise baseline extract (independent awk derivation).
awk '{print "CLASS|" substr($0,4,8) "|" substr($0,23,1)}' "$v1" \
  >"$work/class.v1"
if diff -q -- "$work/class.v1" \
     "$expected/enterprise-class-v1.txt" >/dev/null; then
  note "v1 enterprise baseline vs expected" "MATCH"
else
  note "v1 enterprise baseline vs expected" "MISMATCH"; fail=1
fi

# 4. canonical CUSTOMER v1 (27B) STATUS extract unchanged (regression).
M11CUST_INPUT="$custv1" M11CUST_EXTRACT="$work/status.v1" \
  M11CUST_REPORT="$work/status.rep" "$work/m11cust" >/dev/null 2>&1
rr=$?
if [[ $rr == 0 ]] && diff -q -- "$work/status.v1" \
     "$expected/customer-v1.txt" >/dev/null; then
  note "CUSTOMER v1 status extract vs expected" "MATCH"
else
  note "CUSTOMER v1 status extract vs expected" "MISMATCH (rc=$rr)"; fail=1
fi

# 5. parallel validation v1 <-> v2.
if python3 "$here/migrate-customer.py" verify "$v1" "$work/customer.v2"; then
  note "parallel validation v1<->v2" PASS
  else note "parallel validation" FAIL; fail=1; fi

# 6. rollback v2 -> v1 must reproduce the original bytes (cross-version).
if python3 "$here/migrate-customer.py" to-v1 "$work/customer.v2" \
     "$work/customer.rolledback" \
   && cmp -s -- "$v1" "$work/customer.rolledback"; then
  note "rollback v2->v1 byte-identical" yes
  else note "rollback v2->v1" FAIL; fail=1; fi

# 7. exception: an enterprise v1 file fed to the v2 extractor -> RC8.
set +e
M11CUST_INPUT="$v1" M11CUST_EXTRACT="$work/bad.extract" \
  M11CUST_REPORT="$work/bad.report" "$work/m11cust2" >"$work/bad.log" 2>&1
bad_rc=$?
set -e
[[ $bad_rc == 8 ]] && note "v1 enterprise input to v2 rc" "8 (RC8 as designed)" \
  || { note "v1 enterprise input to v2" "unexpected rc=$bad_rc"; fail=1; }

# 7b. the 27-byte canonical CUSTOMER v1 file is also rejected (separate).
set +e
M11CUST_INPUT="$custv1" M11CUST_EXTRACT="$work/bad2.extract" \
  M11CUST_REPORT="$work/bad2.report" "$work/m11cust2" >"$work/bad2.log" 2>&1
bad2_rc=$?
set -e
[[ $bad2_rc == 8 ]] && note "CUSTOMER v1 (27B) to v2 extractor rc" "8 (RC8)" \
  || { note "CUSTOMER v1 (27B) to v2" "unexpected rc=$bad2_rc"; fail=1; }

# 8. boundary: empty v2 file -> RC0, zero rows.
: >"$work/empty.v2"
M11CUST_INPUT="$work/empty.v2" M11CUST_EXTRACT="$work/empty.extract" \
  M11CUST_REPORT="$work/empty.report" "$work/m11cust2" >/dev/null 2>&1
er=$?
if [[ $er == 0 && ! -s $work/empty.extract ]]; then
  note "empty v2 file" "RC0, 0 rows"
else
  note "empty v2 file" "unexpected rc=$er"; fail=1
fi

# 9. boundary: single v2 row -> RC0, one extract row.
head -1 -- "$work/customer.v2" >"$work/single.v2"
M11CUST_INPUT="$work/single.v2" M11CUST_EXTRACT="$work/single.extract" \
  M11CUST_REPORT="$work/single.report" "$work/m11cust2" >/dev/null 2>&1
sr=$?
if [[ $sr == 0 && $(wc -l <"$work/single.extract") == 1 ]]; then
  note "single v2 row" "RC0, 1 row"
else
  note "single v2 row" "unexpected rc=$sr"; fail=1
fi

# 10. exception: an unknown v1 classification code must not be guessed.
sed 's/.$/Z/' -- "$v1" >"$work/customer-badclass.v1"
set +e
python3 "$here/migrate-customer.py" to-v2 "$work/customer-badclass.v1" \
  "$work/customer-badclass.v2" >"$work/badclass.log" 2>&1
bc_rc=$?
set -e
[[ $bc_rc == 8 ]] && note "unknown v1 class (Z) migration rc" "8 (no guess)" \
  || { note "unknown v1 class migration" "unexpected rc=$bc_rc"; fail=1; }

# 11. exception: a wrong v1 layout version must not be migrated.
sed '1s/^001/003/' -- "$v1" >"$work/customer-badver.v1"
set +e
python3 "$here/migrate-customer.py" to-v2 "$work/customer-badver.v1" \
  "$work/customer-badver.v2" >"$work/badver.log" 2>&1
bv_rc=$?
set -e
[[ $bv_rc == 8 ]] && note "wrong v1 version (003) migration rc" "8 (no guess)" \
  || { note "wrong v1 version migration" "unexpected rc=$bv_rc"; fail=1; }

[[ $fail == 0 ]] || { echo "MAINTENANCE CHECK FAILED" >&2; exit 1; }
echo "PASS: maintenance 11.5 enterprise v1/v2 migration, rollback, parallel"
echo "      validation and CUSTOMER v1 status regression"
