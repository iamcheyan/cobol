# L2 synthetic inputs

All files are ASCII text terminated by LF; ACCOUNT is 47B, TRANSACTION 55B, and REVERSAL-LINK 48B (LF excluded from each width). Data uses the fixed business date 20261009. Rebuild deterministically with `python3 scripts/generate-fixtures.py`; this script generates data only and does not implement account matching or posting. `SHA256SUMS` covers all input files.

| Fixture group | Purpose |
|---|---|
| normal | Four transactions on one account, nonadjacent reversal, overdraft rejection, frozen account, account with no transactions |
| boundary-* | Empty/no-transaction files, maximum single amount, overflow, zero amount, total/account accumulation beyond 13 digits |
| business-* | Orphan account, closed account, cross-account reversal, future/unaccepted/duplicate original, reversal amount mismatch |
| duplicate-id-cross-account | Duplicate global ID far apart on different accounts |
| short-transaction / unsorted-transactions | Raw length and account/sequence ordering errors |
| invalid-link-* | Wrong account, wrong sequence, invalid ID characters, orphan association without a transaction |

Business-rejection fixtures return RC4 and publish rejection details by design. Interface/order/global uniqueness errors return RC8 and are not published. The runner must never rewrite these source fixtures.
