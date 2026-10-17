# INC-2026-001 Hint Ladder (Read One Level at a Time; Do Not Skip Ahead)

Proceed to the next level only after validation fails. At each level, record the commands you actually ran and their output.

## Level 1: At which stage did it fail?

- It failed in JOB002 with exit code RC8. Course convention: RC8 = business/contract exception; stop and do not publish. RC12 = system failure. First confirm which category applies.

## Level 2: Is RC8 a “structural error” or a “business rejection”?

- Read `2000-PROCESS` in `scene/source/M11VAL.COB`:
  - What condition sets `WS-STRUCT='Y'` and causes the **entire batch** to end with RC8?
  - What condition only writes a rejection record and ends with RC4?
- Read `scene/logs/JOB002.log`: which kind of message did the program print?

## Level 3: Locate the specific byte

- Compare every record against the frozen 55-byte layout in `TRANSACTION-V1.CPY`: account 1–10, transaction ID 11–26, business date 27–34, sequence 35–40, direction 41, amount 42–54, status 55.
- Which record and field fails the validator's “numeric key/amount” requirement? Provide the original byte (hex/od) and offset.

## Level 4: Root cause and fix direction

- Is this a **data** problem or a **code** problem? Explain them separately.
- Should the minimal fix happen at the source (provide a correct record) or in this program? Why can't “loosening the check so it does not report an error” fix it?
- Describe recovery and rerun: after correcting source data, rerun with a **new run_id/output directory**, and explain why the old failed directory must not be overwritten in place.
