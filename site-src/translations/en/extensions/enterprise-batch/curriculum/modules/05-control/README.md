# 05 Program Control and Data Cleansing (4 hours)

Recommended: 4 hours, after Module 04. Corresponds to outline 05.1 IF/EVALUATE/PERFORM, 05.2 SEARCH/SEARCH ALL and STRING/UNSTRING/INSPECT/INITIALIZE, and 05.3 customer status normalization and rejection-reason classification.

Business requirement: before nightly batch processing can load customer master data, it must cleanse the upstream CUSTOMER v1 raw file. The upstream source does not guarantee case, required fields, or value ranges, so JOB002 must classify each 27-byte record as “accepted” or “rejected,” state a reason for every rejection, and prove **read = accepted + rejected**. The cleansed 27-byte file becomes the customer master data available to later modules. Your deliverable is the cleansing program `CLEANSE.COB`.

## 1. Input, format, and assumptions

- Input is an ASCII CUSTOMER v1 file terminated by LF. Each logical record is **27 bytes** (**excluding LF**): positions 1–8 `customer_id`, 9–18 `customer_name`, 19–26 `balance_demo`, 27 `status`.
- Assumption: the file is sorted by `customer_id` ascending (sorting is outside this module; descending input violates the contract).
- `status` may mix letter case (the cleansing stage normalizes it to uppercase `A`/`D`); `balance_demo` is a synthetic experimental amount from 0 through 50,000,000, not a final ledger.
- The business date comes from a command-line argument, not the machine's current date. It must match the business date used by the `ACCOUNT/TRANSACTION` contracts; format `YYYYMMDD` and a valid calendar date are required.
- Boundary/error assumptions: an empty file is allowed (0 records); a missing/unreadable file is a system failure; short/long lines, CRLF, missing final LF, and descending keys are file-contract errors. The whole batch fails and is not published.

## 2. Build, run, and reset from a clean checkout

Requires Linux x86-64, GnuCOBOL 3.2, Bash, GNU coreutils, and Python 3 (acceptance only). macOS/WSL are unverified.

```bash
lab=curriculum/modules/05-control
bash "$lab/scripts/build.sh" /tmp/cleanse      # compile exercise/reference implementation
bash "$lab/scripts/run.sh" "$lab/fixtures/normal/clean.dat" \
  /tmp/bank-cleanse-normal 20261009            # official JOB entry point
bash "$lab/scripts/check.sh"                    # full acceptance
bash "$lab/scripts/reset.sh" /tmp/bank-cleanse-normal   # reset
```

`run.sh` accepts only a new output directory that does **not** exist. It first writes to a private stage directory and publishes the complete result only after validation. Derived files are inside that output directory: `accepted.dat`, `rejected.dat`, `report.txt`, `run.txt`, `source.sha256`, `compiler.txt`, `inputs.sha256`, `outputs.sha256`, and `customer.input.dat` (immutable input snapshot). It does **not** overwrite originals under `fixtures/` or artifacts from other modules. `reset.sh` only deletes a directory outside the repository that has course markers (`run.txt`/`inputs.sha256`/`outputs.sha256`/`report.txt`).

## 3. Expected output, RC, counts, and amount

`report.txt` has one line per input record and a final control line:

```text
CUST|<id>|ACCEPT|<A|D>|<8-digit amount>
CUST|<id>|REJECT|<reason>
CONTROL|BUSINESS-DATE=<YYYYMMDD>|READ=n|ACCEPT=n|REJECT=n|AMOUNT=18 digits
```

`accepted.dat` contains normalized 27-byte records (uppercase status); `rejected.dat` contains the original 27 bytes + `|` + reason. RC policy:

| RC | Meaning | Output policy |
|---:|---|---|
| 0 | No business rejections; read = accepted + rejected | Publish |
| 4 | Business rejections (see below), file contract is intact | Publish checked results with rejection details |
| 8 | File-contract error: length, CRLF, missing final LF, descending order, invalid business date | Fail whole batch; do not publish |
| 12 | File/permission/system failure | Fail whole batch; do not publish |

Business rejection catalog (**fixed priority**, top to bottom):

| Reason | Trigger |
|---|---|
| `MISSING-ID` | `customer_id` is not numeric |
| `DUPLICATE-ID` | Numeric ID equals the preceding record (input must be sorted; descending order is RC8) |
| `MISSING-NAME` | `customer_name` is all spaces after removing null characters |
| `BAD-AMOUNT` | `balance_demo` is not numeric |
| `AMOUNT-RANGE` | Amount is numeric but > 50,000,000 |
| `UNKNOWN-STATUS` | Uppercase status is not in `{A,D}` |

**Amount conservation**: `AMOUNT` is the sum of amounts in all accepted records (exact 18-digit decimal). Rejected-record amounts are excluded from every total. Text files under `expected/` are independently determined from **hand calculations and business rules**, not inferred from program output. `check.py` independently rebuilds accepted/rejected byte for byte from fixtures and compares the complete `report.txt` (no whole-file trimming).

## 4. What to modify and interfaces to preserve

Task: implement cleansing in `starter/CLEANSE.COB` (read file, check lengths, classify rejections, write both outputs, calculate control totals). **Do not break** the 27-byte CUSTOMER v1 layout, business-date argument semantics, RC conventions, reason-code spelling, or the `ACCOUNT v1`/`TRANSACTION v1` contracts. The reference is [`instructor/modules/05-control/CLEANSE.COB`](../../../instructor/modules/05-control/CLEANSE.COB).

## 5. Deliberately induce and recover from faults (reproducible)

1. Copy `fixtures/normal/clean.dat` to a temporary directory and remove the final LF: expect RC8, `MISSING-FINAL-LF` on stderr, and no publication.
2. Change a record's `status` to `X`: expect RC4 and a published `UNKNOWN-STATUS`; other records remain normal.
3. Change two record IDs to the same value: the second should be RC4 `DUPLICATE-ID`, while read = accepted + rejected remains conserved.
4. Swap two records: expect RC8 `UNSORTED-INPUT`, no publication, and the original fixture unchanged.

Investigation order: inspect the reason code and RC on stderr, check that `report.txt` aligns with each input record, then run `sha256sum -c inputs.sha256` to confirm the input snapshot is unchanged.

## 6. Plugin workflow and terminal alternative

- Plugin: use `:CobolGotoCopybook` to open `COPY "CUSTOMER-V1.CPY"` and verify the 27-byte layout; `:CobolCalcRecord` to inspect field byte sizes; `gd` to jump to a paragraph; use the local ruler to check Area A/B.
- Terminal alternative: `rg -n 'REASON|SEARCH|INSPECT|STRING'`, `awk '{print length($0)}'`, and `od -An -tc` to inspect line endings and raw bytes. Both workflows must achieve the same business goal.

## 7. Acceptance evidence and failure criteria

Submit the source, normal plus at least one RC4 case and one RC8 (no publication) case, input SHA256, read = accepted + rejected conservation, and amount conservation. Template: [evidence/README.md](evidence/README.md). **Failure criteria**: logs do not match assertions; RC and reason code disagree; a failed case still publishes an output directory; or an original fixture is modified.

## 8. 05.1 control-flow micro-experiment (PERFORM VARYING / inline / scope / fall-through)

[`scripts/control-flow-probe.COB`](scripts/control-flow-probe.COB) is a self-contained program that tests four control points from outline 05.1. `check.sh` compiles and runs it and asserts each output line:

```text
VARYING=15    PERFORM VARYING I FROM 1 BY 1 UNTIL I > 5 (1+2+3+4+5)
INLINE=20     PERFORM 2 TIMES … END-PERFORM (inline PERFORM, separate scope)
FIRST         PERFORM 2000-FIRST: runs only that paragraph and returns at its end (scope ends at paragraph boundary)
SCOPE-DONE
FIRST         PERFORM 2000-FIRST THRU 3000-SECOND: executes through the
SECOND        EXIT in 3000-SECOND, so control **falls through into the next paragraph** — a classic Area B trap
THRU-DONE
```

Student modifications: change `PERFORM 2 TIMES` to `3 TIMES` (`INLINE` becomes 30); remove `THRU 3000-SECOND` (`SECOND` disappears, proving scope ends at the paragraph); change `UNTIL I > 5` to `> 3` (`VARYING` becomes 6). `check.py::check_control_flow` locks down the line-by-line output when unmodified.

## 9. 05.2 language micro-experiments (quantity and sorting premise)

- [`scripts/language-probe.COB`](scripts/language-probe.COB): load an unsorted `raw=canonical` status map with `UNSTRING`, normalize names with `INSPECT`, look up a status using `SEARCH` (linear search works on unsorted data), clear output with `INITIALIZE`, and assemble a report line with `STRING`.
- [`scripts/search-all-probe.COB`](scripts/search-all-probe.COB): place the same keys in sorted and unsorted order to prove that binary-search `SEARCH ALL` **requires the table to actually be sorted by its declared key**; otherwise an existing key may be missed.

`check.sh` compiles and runs both and asserts their output.

## 10. Outline requirements ↔ runnable practice map

Every row points to real, runnable source/fixtures asserted by `check.sh`, not empty files or keyword-only examples.

| Outline requirement | Source | Input | Student change/fault | expected / check | Evidence |
|---|---|---|---|---|---|
| 05.1 IF/EVALUATE | `instructor/.../CLEANSE.COB` `4000-PROCESS` (nested IF), `3000-READ-RECORD` (EVALUATE) | `fixtures/*` | Change a record `status` to `X` | `expected/invalid-unknown-status.txt`; `run_case` compares byte for byte | `evidence/README.md` |
| 05.1 PERFORM paragraphs | `CLEANSE.COB` PERFORM 3000/4000/5000/6000 | `fixtures/normal/clean.dat` | Comment out `PERFORM 5000-EMIT-ACCEPT` | `check_protection`/`run_case` fail if contract changes | Same |
| 05.1 PERFORM UNTIL | `CLEANSE.COB` `1000-MAIN`, `3000-READ-RECORD` read loop | Same | Remove terminating `UNTIL EOF-FLAG = 1` | Infinite read/count mismatch fails | Same |
| 05.1 PERFORM VARYING | [`scripts/control-flow-probe.COB`](scripts/control-flow-probe.COB) | None (self-contained) | Change `UNTIL I > 5` to `> 3` | `check_control_flow`: `VARYING=15` | `evidence/README.md` |
| 05.1 inline PERFORM | Same | Same | Change `2 TIMES` to `3 TIMES` | `INLINE=20` | Same |
| 05.1 scope and fall-through | Same (`PERFORM 2000-FIRST` vs `THRU 3000-SECOND`) | Same | Remove `THRU` | `FIRST/SCOPE-DONE/FIRST/SECOND/THRU-DONE` | Same |
| 05.2 SEARCH (linear, unsorted is allowed) | [`scripts/language-probe.COB`](scripts/language-probe.COB) | Temporary `map.txt`/`names.txt` | Use an unmapped status | `NORM...UNMAPPED` | `check_probes` |
| 05.2 SEARCH ALL (sorting precondition) | [`scripts/search-all-probe.COB`](scripts/search-all-probe.COB) | Self-contained | Shuffle `S-KEY` order | `SORTED=FOUND` / `UNSORTED=MISS` | Same |
| 05.2 STRING/UNSTRING/INSPECT/INITIALIZE | `language-probe.COB` | Same | Remove `INSPECT … REPLACING` | `NORM|00000001|Alice|ACTIVE` | Same |
| 05.3 status normalization/required fields/amount range/rejection classification | `instructor/.../CLEANSE.COB` | `fixtures/normal`, `invalid`, `boundary` | Change status/name/over-limit amount | `expected/*.txt`; `run_case` and `verify-publish.py` independently recompute | `evidence/README.md` |
