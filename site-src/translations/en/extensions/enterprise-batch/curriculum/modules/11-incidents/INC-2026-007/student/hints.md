# INC-2026-007 Hint Ladder

Proceed to the next level only after validation fails. Leave the commands you actually ran and their output at every level.

## Level 1: At which layer did it fail?

- Failure occurred in JOB002, exit code RC8; JOB001 completed. First confirm the boundary between receive-layer checksum/Manifest checks and validation-layer content-contract checks.

## Level 2: Is RC8 a “structural error” or a “business rejection”?

- Read `2000-PROCESS` in `scene/source/M11VAL.COB`:
  - Which conditions set `WS-STRUCT='Y'` and make the **entire batch** end with RC8?
  - Which conditions only write a rejection record and end with RC4?

## Level 3: Locate the specific record

- Print every record length with `awk '{print NR": "length($0)}'` and compare each field with the frozen 55-byte layout in `TRANSACTION-V1.CPY`.
- Which record's length/field alignment violates the contract? Give its original byte count and offset.

## Level 4: Root cause and fix direction

- Is this a **data delivery** problem or a **program** problem? Explain them separately.
- Why can't relaxing the length check fix it? Should the minimal fix happen at the source or in this program?

## Level 5: Recovery and prevention

- Recovery: correct/resend the source data, then rerun with a **new run_id/output directory**; explain why you must not overwrite the old failed directory in place.
- Prevention: post-receive length/record-count sentinels, upstream fixed-width validation, alerts, and a human-confirmation threshold.
