# 07.2 MERGE: combine sorted transaction streams

## Interface and ordering

Each source is TRANSACTION v1: 55 ASCII bytes + LF. Each stream is strictly ascending independently by `(account_id 1–10, sequence_no 35–40, transaction_id 11–26)`. Empty sources are allowed. Global output uses the same full-key ordering and canonical LF; preserve all 55 bytes of every row without reinterpreting or rewriting `transaction_id` or `sequence`. Date, ID, direction, amount, and status validation matches 07.1; zero amount is preserved for downstream business classification; status must be N. A repeated full key is equivalent to a duplicate global transaction ID and returns RC8. Different IDs with the same account and sequence are valid and ordered by ID; duplicate IDs across sources or arbitrarily far apart return RC8.

MERGE first streams through each source to validate physical width, LF, fields, and per-source ordering. Then COBOL actually runs `MERGE ... USING source-1 source-2 ... OUTPUT PROCEDURE`; do not concatenate then SORT, and do not rely on accidental input-stream tie order. An identical full key has no stable source priority because the duplicate-ID contract requires rejecting it.

Hand expectation: Feed-A has (1,1,Z…001), (1,2,M…003), (2,1,B…005); Feed-B has (1,2,A…002), (1,3,A…004), (2,1,A…006). Both inputs are already sorted; correct output puts Feed-B A…002 before Feed-A M…003, with ID breaking the same-sequence tie. The L2 bridge uses ACCOUNT 1 with opening 1000, ACCOUNT 2 with opening 100, T01 credit 500, same-sequence A…002 credit 100 / M…003 debit 50, T04 reversing T01 for debit 500, and account 2 credit 10/debit 10; ending balances are 1050 and 100.

## RC and publication

Publish RC0 only after all inputs are validated, MERGE completes, global IDs are unique, SORT-RETURN=0, and output passes byte-level checks. RC8 means format/date/field/per-stream-order/duplicate-ID error; RC12 means system/temp-space/permission/lock/build/unexpected SORT-RETURN/verification/publication failure. No non-success RC produces official output. Streaming verification checks per-source and merged counts, full-key ordering, field-byte preservation, and global ID uniqueness across streams.
