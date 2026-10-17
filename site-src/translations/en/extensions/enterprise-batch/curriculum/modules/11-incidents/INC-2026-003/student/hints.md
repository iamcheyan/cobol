# INC-2026-003 Hint Ladder (Read One Level at a Time; Do Not Skip Ahead)

## Level 1: Who reported the error first?

- Failure occurred in JOB001 (before COBOL validation). Read `scene/logs/JOB001.log`: does the program report “open failed,” “checksum mismatch,” or something else?

## Level 2: What is the checksum compared against?

- Read `scene/MANIFEST`: what does it declare for `transaction.dat` (size, hash)?
- Calculate the actual file hash with `sha256sum`. Does it match the declaration? Why?

## Level 3: Why don't they match?

- Check the actual byte count of `input/transaction.dat` with `wc -c`. Does it conflict with the Manifest's declaration of “non-empty content”?
- Does this look more like “incorrect data content” or a “file damaged/truncated during transfer or write to disk”?

## Level 4: RC classification

- RC8 vs. RC12: is this a “business/contract exception” or a “system failure”? Give your evidence.
- Why does stopping at JOB001 protect downstream systems (instead of entering JOB002 and continuing as if the file were empty)? If the contract permits a “valid empty file,” how does this scene differ?

## Level 5: Recovery and prevention

- Recovery: receive the file again from the source system and verify it; rerun with a new run_id/output directory.
- Prevention: post-receive length/record-count sentinels, transfer-layer checks, alerts, and manual confirmation thresholds.
