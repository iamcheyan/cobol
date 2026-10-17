# INC-2026-006 Hint Ladder (Read One Level at a Time)

## Level 1: A business error despite success?

- The full flow returned RC0 and published results. RC0 only means “the flow completed under its current rules.” First recalculate the input amounts independently and compare them with the published report.

## Level 2: What should it reconcile against?

- Besides “the program's own output,” is there an **external** expected value? Check whether `input/MANIFEST` contains upstream control totals named `control_*`.

## Level 3: What does JOB007 compare?

- Read `scene/source/control.py`: it compares validation controls, match results, and the ledger. Do these numbers **all** come from the same already-accepted transaction set?
- Did it read the `control_*` declarations in `MANIFEST`?

## Level 4: Locate the difference

- List each amount and compare it with the upstream declaration; find the record that was keyed incorrectly (the amount itself is wrong but still valid), and give its offset.

## Level 5: Fix and recovery

- Minimal fix: add reconciliation against upstream declared control totals in JOB007; a mismatch means RC8 and no publication (this upgrades “internally consistent” to “consistent with upstream”).
- Recovery: a corrected-data run needs a new business version and an audit relationship; explain why you must not delete the completion marker to rerun. Prevention: include upstream declarations in the contract checked at receive time.
