# INC-2026-002 Hint Ladder (Read One Level at a Time; Do Not Skip Ahead)

## Level 1: The batch succeeded. Why is the balance wrong?

- RC0 only means “the flow completed under its current rules”; it does not mean “the business result is correct.” Independently calculate the six balance figures (opening/credits/debits/closing) from the input and compare them with the published result.

## Level 2: Which transaction is wrong?

- Only account 0000000001 is off by 500; the other two accounts are correct. List each input transaction for this account (account/transaction ID/sequence/direction/amount). Check whether one transaction was counted twice or should have been counted only once.

## Level 3: What does the contract say?

- Read `ux_ledger_key` in `scene/db-schema.sql`: what is the business unique key?
- Read `scene/ledger-victim.dat`: how many times does this key appear in the ledger?
- Read `cmd_apply`/`ledger_index` in `scene/source/db.py`: how does it decide whether an item was “already posted” before applying it? What happens if two rows with the same key occur in one batch?

## Level 4: Why didn't the internal check find it?

- Read `scene/source/control.py`: which figures does it compare? Do all these figures come from the **same already-incorrect** accepted transaction set? If so, what does “internally consistent” mean?

## Level 5: Fix and recovery

- The minimal fix belongs in the uniqueness check before posting. Show the RC change for the same input before and after the change.
- How should you recover after commit and publication? Explain the difference between “check the ledger first, then decide” and a “business correction run”; why can't you simply delete the completion marker and rerun?
