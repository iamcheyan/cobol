# L1 fixtures

The fixtures use the frozen ACCOUNT v1 (47-byte) and TRANSACTION v1 (55-byte) layouts. Records are ASCII, LF-terminated, and sorted by their matching keys unless a case explicitly tests invalid ordering. `normal/` is the hand-trace case; `boundary/` covers empty/single inputs and boundary keys; `invalid/` covers malformed records and contract violations.

Do not edit fixture originals during an exercise. Copy a fixture into a temporary work directory when constructing a fault case; verify its hash and the runner's no-publication behavior.