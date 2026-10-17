---
_translated_from: lessons/09_group-items/README.md
_translated_by: site-src/translation agent
---

# Lesson 09 — Group Items: Assembling Customer, Account, and Transaction Fields into a 58-Byte Record

What upstream hands to a batch job is never "a pile of fields", but an entire record: which field belongs to what, at which byte offset it sits, and how long the whole record is are all fixed in the interface documentation. This lesson organizes customer, account, and transaction fields into a 58-byte `WS-TRANSACTION-RECORD`, disambiguates two identical `WS-STATUS` names using `OF`, and copies the whole record verbatim into an equally wide fixed-length receiving area `WS-EXPORT-LINE` using a group-level `MOVE`. The byte shape of this record is precisely what you will match when reading fixed-length files later in [Lesson 17](../17_fixed-length-files/README.md).

## The Business Setting

(Note at the outset: institutions, times, and transaction volumes in this section are educational demo materials, not data from any real institution on any actual day.)

At 1:40 a.m., the end-of-day batch runs at the city commercial bank (demo). The upstream core system has written roughly 120,000 transactions from the day into a fixed-length record file sitting in a shared directory. The first page of the interface document is a table: bytes 1–8 customer ID, bytes 9–20 customer name, bytes 21–30 account number... one record is 58 bytes (the length used in this lesson's demo). Notice the subject of that agreement: **upstream gives you "a record", not individual fields one by one.** What you receive is the entire record, and what you hand off must also be the entire record.

What happens if someone reads the offset off by just one byte? Take a concrete example. This record contains two statuses: account status occupies 1 byte (sample value `A` in this lesson), and transaction status occupies 7 bytes (sample value `PENDING`). If someone calculates account status as 2 bytes, every single field from byte 32 onward shifts by one byte — yet what prints out looks deceptively reasonable: the account number string is still digits, and the transaction reference still looks like a transaction reference. **The program reports no error; it simply and quietly spits out a string of misaligned yet "valid-looking" values.**

Going deeper is the cost of fetching the wrong field name. In real records, status fields with the same name appear twice: one indicates what status the account is currently in, while the other indicates what status the transaction itself is in. Fetch the wrong one, and the resulting rejection reason reported downstream is wrong — the next morning when counters open at 9:00 a.m. and a customer asks "why was my withdrawal denied?", the reason you provide is the value from the other field. This lesson does not yet handle posting or rejection decisions (that requires real inputs and error routing; see [Lesson 16](../16_file-writing/README.md) and [Lesson 26](../26_error-handling/README.md)), but being able to distinguish two identically named status fields is something you must master right now.

## Why Learn This Now

You might think: in the previous eight lessons I named and declared fields myself and they ran fine; why do I need to learn "grouping" specifically?

When you reach "processing a record", flat declarations break down. File processing immediately requires answering three questions: **who belongs to what, what order it follows, and how long the whole thing is.** With independent fields scattered around, you cannot answer a single one of these questions. There is also a more concrete problem — name collisions: two distinct fields in the interface document are labeled "status"; you naturally want to name both `WS-STATUS`, but in a flat declaration list those two names collide immediately.

What you learn here, therefore, consists of three things: level numbers providing parent-child relationships (`01` / `05` / `10`), group names providing business ownership, and contiguous bytes of a group item serving as the "candidate shape of an external record." This is not for clean-looking code. Later, [Lesson 10](../10_redefines/README.md) will declare another view over the exact same bytes, Lessons [15](../15_sequential-file-read/README.md)–[17](../17_fixed-length-files/README.md) will read real files matching this shape, and [Lesson 23](../23_copybooks/README.md) will share this layout with other programs — all three depend on the prerequisite that "this sequence of bytes is a record."

## What This Knowledge Point Is, and What Problem It Solves

**What this knowledge point is.** In a sentence: packing several fields into a named "box", where boxes can nest inside other boxes. Group items do not declare a `PIC`; they represent only a parent-child relationship. Elementary items must declare a `PIC`; they are the fields that actually occupy storage bytes. Two capabilities follow immediately: **group names can be referenced as a whole** (group-level `MOVE`, group-level `DISPLAY`), and **identically named subordinate items can be disambiguated using `OF` to qualify their parent group**.

**What business problem it solves.** It turns "a record" inside the program into something that can be moved as a whole and whose field offsets can be calculated. Upstream writes by fixed offsets, you read by the same offsets, and downstream writes by the same offsets — what is called an interface contract translates in code into this hierarchical declaration. At delivery time, a single group-level `MOVE` transfers the whole thing, without you having to manually manage "what order to move eight fields in, and how many bytes they total."

**When not to use it, and what happens when misused.** Keep two points firmly in mind. First, **group items provide no validation**: whatever is in the bytes is read out as bytes; stuffing alphabetic characters into bytes covered by `PIC 9(5)V99` will not be stopped by anyone ([Lesson 10](../10_redefines/README.md) will explore this in greater depth). Second, **do not confuse hierarchy with business rules**: placing a field under `WS-ACCOUNT-INFO` does not mean the program will validate whether account status is active; that relies on evaluations starting in [Lesson 04](../04_if-conditions/README.md) and subsequent validation pipelines. The most common consequence of misuse does not occur at compile time — it occurs when someone assumes "grouping guarantees valid structure" and ceases checking offsets byte by byte. Offsets can only be reconciled against interface documentation; there is no other way.

## Capabilities and Limits After Completing This Lesson

After completing this lesson, you will be able to:

- Use `01` / `05` / `10` to establish parent-child relationships, distinguishing group items (no `PIC`) from elementary items with `PIC`.
- Calculate that this record totals 58 bytes, and identify that the account number spans bytes 21–30.
- Use qualified names like `WS-STATUS OF WS-ACCOUNT-INFO` to specify which of two identically named `WS-STATUS` fields you intend.
- Explain why displaying a group item shows raw contiguous bytes, whereas displaying the amount field individually formats it with a decimal point.
- Use a group-level `MOVE` to copy the record into an equally wide `WS-EXPORT-LINE PIC X(58)`, explaining that this is a pure byte-for-byte copy.

Limits: Record content comes entirely from source code constants; this lesson does not read files, write files, or validate business rules; width and offsets of real file records start in Lessons [15](../15_sequential-file-read/README.md)–[17](../17_fixed-length-files/README.md), and extracting this layout into a Copybook is covered in [Lesson 23](../23_copybooks/README.md).

## Runtime Environment

- GnuCOBOL 3.2.0, default dialect (without `-std=cobol85`), source file in fixed format.
- Fixed format is judged byte by byte: column 7 is indicator area, Area A begins in column 8, Area B begins in column 12, and program text cannot exceed column 72; every line in this lesson stays within 72 bytes.
- Direct verification: in this workspace, a test source line containing Japanese text totaling 89 bytes was truncated by `cobc` at byte 72, triggering `invalid literal`. Visual alignment is not enough; you must count bytes.
- Linux terminal; no dependencies on databases or extra tools; generates executables only under `build/`.

## Knowledge Explanation

### Level Numbers Govern Parent-Child Relationships, Not Indentation

`01`, `05`, and `10` represent only parent-child hierarchy: subordinate level numbers must be greater than their parent, and sibling items share the same level number. Indentation is purely for human readability; the compiler ignores it. Writing the declaration completely unindented changes not a single byte of program behavior — though do not do this, or your successor will despise you.

The boundary between group and elementary items is also clear: items without `PIC` are group items (such as `WS-CUSTOMER-INFO`), while items with `PIC` are fields that actually occupy storage bytes (such as `WS-CUSTOMER-ID PIC X(8)`).

### Two WS-STATUS Fields: The Valid Solution for Name Collisions Is OF

This lesson contains two data names called `WS-STATUS`: account status `PIC X`, value `A`, and transaction status `PIC X(7)`, value `PENDING`.

You might want to save typing and reference `WS-STATUS` directly. You cannot — COBOL does not guess your intent, and the compiler flags this error immediately (verified on this machine):

```text
error: 'WS-STATUS' is ambiguous; needs qualification
```

You must write `WS-STATUS OF WS-ACCOUNT-INFO` or `WS-STATUS OF WS-TXN-INFO`. Here `OF` and `IN` are equivalent; they only answer "which one you mean" without altering width, initial values, or storage locations — both fields still occupy their own respective bytes.

### Non-Example → Good Example

**Non-example: flattening eight fields into a series of `01`s**, where none belongs to any other, and no group names exist.

```cobol
       01 WS-CUSTOMER-ID      PIC X(8)    VALUE "C0001042".
       01 WS-CUSTOMER-NAME    PIC X(12)   VALUE "ADA LOVELACE".
       01 WS-ACCOUNT-NUMBER   PIC X(10)   VALUE "0001234567".
       01 WS-ACCT-STATUS      PIC X       VALUE "A".
       01 WS-TXN-ID           PIC X(12)   VALUE "TXN-00000001".
       01 WS-TXN-CODE         PIC X       VALUE "D".
       01 WS-TXN-AMOUNT       PIC 9(5)V99 VALUE 125.50.
       01 WS-TXN-STATUS       PIC X(7)    VALUE "PENDING".
```

The compiler will not stop this approach (verified on this machine: this declaration passes `-fsyntax-only` with exit code `0`), which is precisely why it is dangerous — the problems are all deferred to later:

1. **Without a group name, the record is not a single unit.** Transferring it to a fixed-length receiving area requires writing a `MOVE` for every single field; ordering, widths, and total length must all be tracked in your head, and adding a field requires updating multiple locations.
2. **The relationship that "account status belongs to account info" vanishes from code.** Readers can only guess ownership from field name prefixes, with nobody correcting misinterpretations.
3. **The two statuses cannot both be named `WS-STATUS`**; one must be renamed to something like `WS-ACCT-STATUS`, creating a mismatch between names in code and names in the interface specification, adding another layer of friction when checking offsets.

**The good example is how `lesson.cob` is written in this lesson**: one `01` root group, three `05` subgroups, and eight elementary items at level `10` with `PIC`.

```cobol
       01 WS-TRANSACTION-RECORD.
          05 WS-CUSTOMER-INFO.
             10 WS-CUSTOMER-ID PIC X(8) VALUE "C0001042".
          05 WS-ACCOUNT-INFO.
             10 WS-ACCOUNT-NUMBER PIC X(10) VALUE "0001234567".
             10 WS-STATUS PIC X VALUE "A".
          05 WS-TXN-INFO.
             10 WS-STATUS PIC X(7) VALUE "PENDING".
```

Ownership, sequence, and total length are resolved at once: group names enable collective transfer, `OF` disambiguates identically named items, and "how long the record is" can be calculated by summing declaration widths in order.

### Group Items in Memory Are Contiguous Bytes

Group items have no delimiters in memory; they are contiguous storage whose length equals the sum of byte counts of subordinate items in declaration order. `X(n)` occupies n bytes; `9(5)V99` occupies 7 bytes because `V` is an assumed decimal point and occupies no storage bytes — this often surprises newcomers: `00125.50` prints as 8 characters, but occupies only 7 bytes in storage.

The three subgroups occupy 20, 11, and 27 bytes respectively, totaling 58:

| Field | PIC | Bytes | Position in Record |
|---|---|---:|---|
| `WS-CUSTOMER-ID` | `X(8)` | 8 | 1–8 |
| `WS-CUSTOMER-NAME` | `X(12)` | 12 | 9–20 |
| `WS-ACCOUNT-NUMBER` | `X(10)` | 10 | 21–30 |
| `WS-STATUS` (account status) | `X` | 1 | 31 |
| `WS-TXN-ID` | `X(12)` | 12 | 32–43 |
| `WS-TXN-CODE` | `X` | 1 | 44 |
| `WS-TXN-AMOUNT` | `9(5)V99` | 7 | 45–51 |
| `WS-STATUS` (transaction status) | `X(7)` | 7 | 52–58 |
| Entire `WS-TRANSACTION-RECORD` (group) | — | 58 | 1–58 |

Positions accumulate from preceding widths: the account number is preceded by `8+12=20` bytes, so it begins at byte 21. A companion verification program calling `FUNCTION LENGTH` confirmed customer group 20, account group 11, transaction group 27, entire record 58, and amount 7, matching manual calculations (re-run in this workspace with identical results).

### Display and Transfer: Group Items Have Only Bytes, No Decimal Points or Conversions

Group items have no `PIC`; when referenced as a group, they consist purely of bytes without numeric interpretation. Three behaviors stem from this:

- `DISPLAY WS-TRANSACTION-RECORD` outputs 58 storage bytes, where the amount appears as `0012550` — the decimal point is not stored, so it does not appear out of thin air;
- `DISPLAY WS-TXN-AMOUNT OF WS-TXN-INFO` displays `00125.50` formatted according to its numeric definition;
- `MOVE WS-TRANSACTION-RECORD TO WS-EXPORT-LINE` performs no numeric conversion, inserts no delimiters, and validates no content. This is precisely the semantics required for external fixed-length records: raw bytes in, raw bytes out.

Conversely, remember: **group-level transfers provide zero business safety**. Whatever is in the field is transferred as is; "spaces mixed into account numbers" will be transferred without objection.

**Unverified items:** This lesson demonstrates only equal-width copies (both items are 58 bytes). How truncation behaves or whether warnings occur when the receiving area is declared narrower than 58 bytes was not tested here — because the goal is verifying offsets and lengths, not enumerating `MOVE` truncation edge cases; real width constraints await real files in [Lesson 17](../17_fixed-length-files/README.md). That path is unverified, so do not extrapolate from it.

## Source Reading Path

For full source, see [`lesson.cob`](./lesson.cob), reading by how data is placed and moved:

1. **Declare record**: `01 WS-TRANSACTION-RECORD.` is the root group, with three `05` subgroups and eight `10` elementary items with `VALUE` clauses, initialized with constants at startup.
2. **Declare receiving area**: `01 WS-EXPORT-LINE PIC X(58).` matches the record width, initialized to 58 spaces.
3. **Reference field by field**: Eight `DISPLAY` statements reference elementary items in `field OF parent-group` format — this is where the two `WS-STATUS` fields are separated.
4. **Group reference and transfer**: First `DISPLAY` the whole group to output 58 bytes, then `MOVE` to the receiving area, whose displayed output matches it, demonstrating that the move is a pure byte copy; finally `STOP RUN.` concludes with exit code 0.

## Run and Observe

This lesson has no external input, so results are independent of external data; commands below are given for this lesson directory.

**Input:** No external input. Customer, account, and transaction fields are all in-program constants in `lesson.cob`.

```sh
mkdir -p build
cobc -fsyntax-only lesson.cob                   # 只做语法检查
cobc -x -Wall -o build/lesson_09 lesson.cob     # 编译并生成可执行文件
./build/lesson_09                               # 运行，输出写到标准输出
echo $?                                         # 查看退出码
rm -rf build                                    # 清理可执行文件
```

**Expected results:**

| Observed Item | Expected Value |
|---|---|
| Syntax check and compile | Both exit codes `0`, no compilation diagnostics |
| Standard output | 10 lines, see code block below |
| Process exit code | `0` |

```text
顧客ID=C0001042
顧客名=ADA LOVELACE
口座番号=0001234567
口座状態=A
取引ID=TXN-00000001
取引コード=D
取引金額=00125.50
取引状態=PENDING
グループデータ=[C0001042ADA LOVELACE0001234567ATXN-00000001D0012550PENDING]
外部記録=[C0001042ADA LOVELACE0001234567ATXN-00000001D0012550PENDING]
```

**Output mappings:** `顧客` = customer, `口座` = account, `取引` = transaction, `状態` = status, `金額` = amount, `グループデータ` = group item content, `外部記録` = group move result.

**Observed environment details:** Running the executable outputs `Warning: program compiled against libxml 212 using older 209` on standard error; this is a library version warning from the runtime environment, not business output, and the triggering component has not been identified. Business output appears on standard output, with an exit code of 0.

## Modification Exercise

Change `WS-ACCOUNT-NUMBER` initial value from `0001234567` to `0007654321`, repeat syntax checking, compilation, and execution, and confirm that the account number line and both group output lines change synchronously, while the other 7 lines remain unchanged. See [`exercise.md`](./exercise.md) for details; see [`answer.md`](./answer.md) for answers.

## "Apply It Elsewhere" Exercise

Design an `01` record for a payment instruction, containing three `05` subgroups: payer, payee, and payment info; design several `10` elementary items with `VALUE` in each group, having at least two subgroups share an identical elementary item name and referencing them separately with `OF`; then declare an equal-width `PIC X(n)` receiving item, transferring the group via `MOVE` and displaying it. Calculate record byte length and field positions yourself, and verify using output. Use only hierarchical data items and fixed `VALUE` clauses from this lesson, without introducing `REDEFINES`, `OCCURS`, file input, or databases. See [`exercise.md`](./exercise.md) for details; no reference answer is provided for this exercise.

## Walking Through a Real Workflow

Placing this lesson's deliverable into an overnight processing chain, here is how it is used (real data requires waiting for [Lesson 15](../15_sequential-file-read/README.md)):

1. **Upstream generates files.** The core system writes fixed-length records according to interface documentation: account numbers start at byte 21 and occupy 10 bytes. What you read is a record of the shape taught in this lesson.
2. **Read into an equal-width group item.** Receive the whole record using an `01` record — this lesson's declarations are ready; real file reading begins in [Lesson 15](../15_sequential-file-read/README.md), while fixed-length I/O and total byte verification are covered in [Lesson 17](../17_fixed-length-files/README.md).
3. **Extract fields by offset.** Offsets are not guessed; they accumulate from declaration order (this is how bytes 21–30 in this lesson's table were derived). The two identically named statuses are disambiguated at this step using `OF`.
4. **Evaluate status.** This lesson merely displays both statuses; actually branching based on status is covered in [Lessons 04](../04_if-conditions/README.md) / [05](../05_evaluate/README.md), and chaining into a full batch is covered in [Lesson 22](../22_file-processing-practice/README.md). Rejection reasons wait for writing rejection details in [Lesson 16](../16_file-writing/README.md) and separating business rejections from system failures in [Lesson 26](../26_error-handling/README.md).
5. **Hand over downstream.** The 58 bytes produced by group `MOVE` become the fixed-length output record for downstream systems; batch execution progress and tallies are recorded in logs in [Lesson 27](../27_logging/README.md).
6. **Share the layout.** If readers and writers each maintain duplicate offset declarations, copy errors will eventually occur; [Lesson 23](../23_copybooks/README.md) extracts this declaration into a Copybook so both sides use the exact same definition.

## What Happens if This Code Goes to Production

- **Who schedules it:** Currently it is a manually compiled and executed teaching program without a scheduler. Inside a batch, this record declaration becomes part of the main program's `WORKING-STORAGE` (extracted into a Copybook after [Lesson 23](../23_copybooks/README.md)), and the scheduler inspects only the main program's exit code.
- **Who reads its output:** These 10 lines are for developers and troubleshooting teams to verify. In a real batch, nobody reads the screen; they read logs and output files; this lesson's output serves as your personal "byte-level reconciliation."
- **Who gets called when something breaks:** This is the most critical detail — **offset mistakes do not cause the program to error out**. The symptom is "the status on every record is wrong", not a crash or non-zero exit code, so nobody is alerted in the middle of the night; the issue waits until morning reconciliation or teller operations to be discovered.
- **How the next system connects:** The 58-byte `WS-EXPORT-LINE` is the candidate shape of an "external fixed-length record": [Lesson 10](../10_redefines/README.md) gives the same bytes a second interpretation, [Lesson 17](../17_fixed-length-files/README.md) persists it into a real file, and [Lesson 23](../23_copybooks/README.md) shares this layout across programs.
- **Most common first-month incidents:** A field order or width mismatch of one byte against interface docs (e.g., treating a 1-byte account status as 2 bytes), throwing off everything after it while the program runs quietly. Preventing this requires an unglamorous but effective method: tabulating byte counts and positions as done in this lesson, and re-verifying independently using tools like `FUNCTION LENGTH`.

To be explicit: this lesson only organizes in-memory constants and moves the record once as a group. It does not read external records, validate business rules, or post transactions, nor does it guarantee encoding, padding, sign representation, or newline conventions — which must be agreed upon separately with upstream and downstream systems (Lessons [15](../15_sequential-file-read/README.md)–[17](../17_fixed-length-files/README.md), [23](../23_copybooks/README.md)). It is still far from production-ready.

## References

- [GnuCOBOL Manual: Structured Data](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#Structured-Data)
- [GnuCOBOL Manual: Qualification of Data Names](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#Qualification-of-Data-Names)
- Course Directory: [DIRECTORY.md](../DIRECTORY.md) | Course Home: [README.md](../../README.md)
