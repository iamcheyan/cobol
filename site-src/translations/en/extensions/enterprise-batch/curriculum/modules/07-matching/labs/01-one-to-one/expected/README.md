# Expected results

The files in this directory are complete expected reports for the fixtures. They were calculated from the matching rules, not copied from program output. `check.py` compares the report byte for byte.

- `normal.txt`: accounts 1, 3, 5, 8 and transactions 1, 2, 5, 7; MATCH keys 1 and 5, MASTER-ONLY keys 3 and 8, TX-ONLY keys 2 and 7.

The final control row must satisfy both conservation equations: account reads = MATCH + MASTER-ONLY, and transaction reads = MATCH + TX-ONLY.