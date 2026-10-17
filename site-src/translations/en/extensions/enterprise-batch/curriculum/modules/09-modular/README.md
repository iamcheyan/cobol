# Module 09: Modular Programs (CALL / LINKAGE / Common Modules)

Estimated time: 4 hours. Prerequisites: Module 06 file processing and Module 07 amounts and conservation. Environment: Linux x86-64, GnuCOBOL 3.2.0, Bash, GNU coreutils, Python 3 (acceptance driver only). macOS/WSL have not been verified.

Covers outline 09.1–09.3: `CALL`/`LINKAGE`/`USING`, `BY REFERENCE`/`BY CONTENT`/`BY VALUE`, `RETURNING`, `GOBACK`; working-storage lifecycle, shared Copybooks, parameter length/version and interface mismatches; extracting three shared modules for amount calculation (AMTCALC), customer validation (CUSTVAL), and logging (LOGGER); and how caller and callee together affect an incident investigation. See [DESIGN.md](DESIGN.md) for interface layouts, field offsets, RC propagation, and worked calculations.

## 1. Why the business needs this processing

Nightly batch jobs repeatedly need to answer “can this amount be posted?”, “is this customer valid?”, and “how do we write a standardized log?”. If each job implements its own copy, rules drift whenever one changes, and incident investigation cannot determine which copy is correct. The requirement is to extract the logic into **versioned callable subprograms** that the main program reuses with `CALL`; when parameter length/version mismatches or a called module retains uninitialized state, reproduce and locate the fault and accurately return its status.

## 2. Input sources, formats, and guaranteed preconditions

Three fixed-width files under `fixtures/normal/`, `fixtures/boundary/<case>/`, and `fixtures/invalid/<case>/`: `customer.dat` (27B), `account.dat` (47B), and `transaction.dat` (55B), ASCII with LF endings. Fields and rules are in `../../../docs/curriculum/BANK-SYSTEM.md`; the business date is supplied as an argument (fixtures use `20261010`). Preconditions: the upstream job guarantees fixed record lengths and LF, accounts are ascending, transactions are ordered by account/sequence/transaction ID, and `transaction_id` is globally unique (duplicates produce RC8; see DESIGN §6). This module does not reimplement Module 07 matching/reversals; it focuses on CALL and shared modules.

## 3. Build, run, and reset from a clean checkout

```bash
lab=curriculum/modules/09-modular
set +e
bash "$lab/scripts/run.sh" "$lab/fixtures/normal/customer.dat" \
  "$lab/fixtures/normal/account.dat" "$lab/fixtures/normal/transaction.dat" \
  /tmp/bank09-run 20261010
rc=$?
set -e
test "$rc" -eq 0            # normal case has no business rejection
diff -u "$lab/expected/normal.txt" /tmp/bank09-run/report.txt
python3 "$lab/scripts/check.py"    # all normal/boundary/error and failure paths
```

`run.sh` supports any working directory, output paths containing spaces, immediate rejection of an existing output, and concurrent-run locking. Failure (RC8/12) publishes no directory. The published directory contains `report.txt`, `ledger.dat`, `customers-valid.dat`, `customers-rejected.dat`, `batch09.log`, `inputs.sha256`, `outputs.sha256`, `run.txt`, `compiler.txt`, and `source.sha256`. Reset:

```bash
bash "$lab/scripts/build.sh" /tmp/batch09         # compile the exercise only
bash "$lab/scripts/reset.sh" /tmp/bank09-run      # removes only a marked course output directory
```

`reset.sh` rejects symlinks, unmarked directories, and paths inside the repository. For manual exercises, copy fixtures first; do not edit the originals.

## 4. Expected output, RCs, transaction counts, amounts, and independent checks

`expected/normal.txt` is independently derived from business rules (see the worked example in DESIGN §8); it is not copied from program output. Normal case: customers 2/2 accepted; transactions 3=3 accepted+0 rejected; accounts 2=2 with transactions+0 without; opening 1500, credits 600, debits 200, closing 1900, with per-account `closing = opening + credit − debit`. RCs for each case are in `expected/cases.json` (RC0 clean, RC4 per-item business rejection and published, RC8 contract error and not published); `expected/README.md` explains the independent calculation basis for each fixture.

`scripts/oracle.py` is a **Python reference model independent of COBOL** and generates `expected/`. Before publishing, `run.sh` calls `scripts/verify-publish.py`, which reruns the same model against the **raw inputs** and compares the report, ledger, both customer outputs, and log byte for byte. Any drift returns RC12 and publishes nothing. Before posting, `run.sh` also uses external sorting to check **global uniqueness** of `transaction_id`: a duplicate returns RC8 and is not published, and replacing `COURSE_SOURCE` cannot bypass the check (fixtures `fixtures/invalid/dup-global-txid` and `dup-cross-account`).

## 5. What to change and which interfaces must remain intact

- Complete the TODOs for customer validation, account key-break posting, and logging in `starter/BATCH09.COB`.
- The three common modules (AMTCALC / CUSTVAL / LOGGER) are **existing dependencies supplied with the student bundle**, under `lib/{AMTCALC,CUSTVAL,LOGGER}.COB`; interface Copybooks are in `copybooks/*-V1.CPY`. `instructor/modules/09-modular/` is the reference in the repository; `build.sh`/`run.sh` select between the two automatically.
- **Frozen contracts**: CUSTOMER 27B / ACCOUNT 47B / TRANSACTION 55B and interface header `VERSION='001'` must not be changed casually. For evolution, add `-V2` and keep the old version interpretable.
- Must preserve: `RETURN-CODE` (0/4/8/12) semantics, conservation and independent checks before publication, and no publication on failure.

## 6. Deliberately break conditions and investigate/recover

Proceed in order; predict each result before running:

1. **Interface version mismatch**: change the main program’s `MOVE '001' TO AMT-IFACE-VERSION` for AMTCALC to `002`. Expect the callee to return 8, the main program to report `INTERFACE-MISMATCH`, process RC8, and no publication. Root cause is in the **caller**: the callee is correct; the caller sent the wrong version header. Recovery: restore `001`.
2. **Parameter length mismatch**: change `MOVE LENGTH OF AMT-CALC-INTERFACE TO AMT-IFACE-LENGTH` to `MOVE 1`. Expect AMTCALC to return 8 `IFACE-LENGTH`, with no publication.
3. **State leakage**: run `ifaceprobe` and observe `STATIC CALL1=0001 CALL2=0002` (leftover state on call two) and `INITIAL CALL1=0001 CALL2=0001`. Cause: static callee working storage persists between calls; minimal fix: `IS INITIAL` or explicit initialization on each call.
4. **Business/contract boundaries**: `fixtures/` includes zero amount, overdraft, 13-digit overflow, unknown direction, missing account, frozen account (RC4, published), short record, layout version `002`, wrong business date, reversed transaction order, and **globally duplicated transaction ID** (RC8, not published).
5. **Global transaction ID duplicate**: replace bytes 11–26 of normal’s third transaction with the first transaction’s `transaction_id`, keeping account and sequence. The file remains ordered by `account/sequence/id`; the old ordered comparison would incorrectly return RC0 and publish a duplicate posting. The fixed job’s global external-sort check returns RC8 and publishes nothing. Fixtures `dup-global-txid` (same account, different sequence) and `dup-cross-account` (across accounts) cover both cases.

`check.py`’s `check_starter_and_faults` injects the first two faults into the reference source and asserts RC8 with no publication; `check_probe` asserts the deterministic output for fault 3.

## 7. Plugin workflow and terminal alternatives

The terminal alternatives are equivalent; a missing plugin does not block the course:

- Use `:CobolGotoDef` to inspect a call interface: place the cursor on `CALL 'AMTCALC' USING AMT-CALC-INTERFACE` in the main program and jump to `lib/AMTCALC.COB` to check `USING`; use `:CobolGotoCopybook` on `COPY "AMTCALC-INTERFACE-V1.CPY"` to open the interface Copybook and confirm length/version headers. Terminal alternative: `rg -n 'CALL .|USING|LINKAGE|RETURNING|GOBACK' lib/`.
- Use Aerial/outline to view main-program paragraph hierarchy `1000-MAIN/2000-.../3000-.../6000-...` and understand call boundaries. Terminal alternative: `rg -n '^       1|^       2|^       3|^       6|^       8' starter/BATCH09.COB` (after completion) or `instructor/modules/09-modular/BATCH09.COB`.
- Use the P1 PIC calculator to verify interface field bytes (`AMT-BALANCE` is `S9(13) COMP-3`=7B). Terminal alternative: measure `AMT-CALC-INTERFACE` with `LENGTH OF` (=45); field offsets are in DESIGN §3.

Do not treat plugin estimates as final byte-layout evidence; use measured `LENGTH OF` from `cobc` and `check.py`.

## 8. Evidence required for completion and failure criteria

Submit according to [evidence/README.md](evidence/README.md): source changes, normal report and `ledger.dat`, raw RC and “no output directory” evidence for at least one RC4 published case and one RC8/RC12 unpublished case, `ifaceprobe` byte/RC output, input/output SHA256, independently checked counts and amount conservation, and interface before/after version notes. Any of these is a failure: publishing after failure; treating 8/12 as business rejection; hard-coding interface length/version as a substitute for the contract; callee modifying the caller’s private area; state leakage that cannot be reproduced or fixed; or **missing a global duplicate transaction ID and posting it twice**.

## Guided exercises and reproducible faults (09.1–09.3)

- **09.1 CALL/LINKAGE/USING, BY REFERENCE/CONTENT/VALUE, RETURNING, GOBACK**
  - Exercise: change the `BYREF-SUB` call in `ifaceprobe.COB` to `BY CONTENT` and observe that `AFTER=` no longer reflects a write-back (compare with `BY REFERENCE`); then remove `RETURNING` from a `CALL ... USING ... RETURNING` and observe that the main program cannot read the return code.
  - Reproducible fault: change `CALL 'BYCTR-SUB' USING BY CONTENT WS-A` in the main program to `USING WS-A` (default `BY REFERENCE`). The callee can then overwrite the caller’s `WS-A`, and `BY-CONTENT AFTER` changes from `BBBBB` to `CCCCC`, proving that parameter passing at the call site directly affects the result.
- **09.2 Working-storage lifecycle, shared Copybook, parameter length/version/interface mismatch**
  - Exercise: remove `IS INITIAL` from `INIT-ACC`; `INITIAL CALL2` changes from `0001` to `0002`. Add it back to restore the result.
  - Reproducible fault: `check_starter_and_faults` automatically changes the interface version to `002` or `LENGTH OF` to `1`; the callee returns RC8, the main program returns RC8, and nothing is published. Or manually edit and rerun `run.sh`.
- **09.3 Extract amount calculation/customer validation/logging; caller and callee jointly affect investigation**
  - Exercise: temporarily move the `OVERDRAFT` check in `AMTCALC` to the main program and observe the report/RC change for `fixtures/invalid/overdraft`, then restore it. See how changing responsibility boundaries changes RC and reason ownership.
  - Reproducible fault: when versions mismatch, the callee behaves correctly but the caller is at fault (it sent an old/new version header). Investigation requires checking both the interface validation in `AMTCALC.COB` and `MOVE ... TO AMT-IFACE-VERSION` in `BATCH09.COB`: caller and callee jointly shape the investigation.

```bash
lab=curriculum/modules/09-modular
bash "$lab/scripts/check.sh"                 # full acceptance (fault injection and probe included)
COURSE_SOURCE="$lab/starter/BATCH09.COB" bash "$lab/scripts/run.sh" \
  "$lab/fixtures/normal/customer.dat" "$lab/fixtures/normal/account.dat" \
  "$lab/fixtures/normal/transaction.dat" /tmp/bank09-starter 20261010   # expected RC12; no directory
cobc -Wall -I "$lab/copybooks" -x -o /tmp/ifaceprobe \
  "$lab/scripts/ifaceprobe.COB" "$lab/lib/AMTCALC.COB" && /tmp/ifaceprobe
```

The instructor reference implementation, root-cause table, and grading guide are in `instructor/modules/09-modular/`.
