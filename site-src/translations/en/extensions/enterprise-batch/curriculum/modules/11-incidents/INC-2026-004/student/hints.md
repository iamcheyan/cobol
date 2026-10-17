# INC-2026-004 Hint Ladder (Read One Level at a Time; Do Not Skip Ahead)

## Level 1: Failing node and RC

- Failure occurred in JOB005, RC8. It is the sequential match node: it reads two ordered streams, the Master and transactions.

## Level 2: Which stream fails the prerequisite?

- The transaction stream was sorted and verified in JOB003 (JOB003 COMPLETE).
- What about the Master stream? Read the original text in `scene/logs/JOB005.log`: which stream's ordering problem does the program report?

## Level 3: Confirm it

- Compare the Master actually read by JOB005 (`work/db/account_master.dat`) with `input/account_seed.dat`.
- Use `sort -c -k1.1,1.10` to verify whether it is in ascending account_id order; find the first inversion.

## Level 4: Which layer is the root cause in?

- Where does the order originate? Seed file → JOB004 snapshot → JOB005. Did JOB004 sort or verify the Master ordering? Did it merely “copy” the Seed order?
- Is this a “data delivery error” or “missing ordering guarantee at the boundary”? State both aspects.

## Level 5: Recovery and prevention

- Recovery: correct the upstream extract/Seed ordering, rebuild derived files from the snapshot boundary, and rerun (explain why you need not and should not manually edit JOB005 output).
- Prevention: add an ordering precheck at the snapshot boundary (fail fast), use stable sorting at extraction, and record the sort key and version in the Manifest.
