---
_translated_from: lessons/18_csv-processing/README.md
_translated_by: site-src/translation agent
---
# Lesson 18: Parse Customer CSV Character by Character — Commas Inside Quotes, Empty Fields, and Overlong Fields

A business team drops a `customers.csv` file into the batch directory with a note: “It’s just a CSV. Split it yourself.” This lesson takes that “just a CSV” seriously: it reads the file one line at a time with `READ` from [Lesson 15](../15_sequential-file-read/README.md), stores five fields in an `OCCURS` field table from [Lesson 11](../11_occurs-tables/README.md), adds a quote-aware state machine that scans one character at a time, and finally prints a line-by-line “valid / rejected” list that can be checked. [Lesson 19](../19_multiple-files/README.md) will use these decisions to organize multiple input streams, and [Lesson 22](../22_file-processing-practice/README.md) will connect them into end-to-end reconciliation.

## The Business Situation

At 5:20 on Friday afternoon, the upstream business system’s contact exports that day’s customer data to `customers.csv`, drops it in the batch shared directory, and leaves a note: “The format hasn’t changed. Same as last time. Just get it done by 8 tomorrow morning.”

You open the file and scan it: eight lines, quick to read, looks like ten minutes of work. Once you start, you learn that “It’s just a CSV” is the interface contact’s most common phrase—and one of the easiest ways to derail batch processing.

That is because the file contains details the business team will not volunteer: a customer name contains a comma (`"Grace, Hopper"`), a note is an empty `""`, one row is missing a column, and one name is absurdly long. Nobody upstream is trying to make your life difficult; the system simply exports the fields as they are. If you split blindly on commas, the name containing a comma produces an extra field and the whole row is misread. If you treat “empty field” and “missing field” as the same thing, a person can disappear without anyone noticing. If you do not stop overlong fields, they push the fields that follow out of place.

There is one more half-sentence to put up front: **structurally correct does not mean valid business data.** Five columns, valid widths, and closed quotes do not mean the name should be empty, the amount is numeric, or the status code is allowed. This lesson handles only the first half: determine structure cleanly and give a specific rejection reason. Business validation comes in later lessons.

The scenario above and the customer IDs and names in `customers.csv` are fictional teaching examples. They do not correspond to any real organization, customer, or account.

## Why Learn This Now

You can already open a file, `READ` it line by line, and recognize EOF from [Lesson 15](../15_sequential-file-read/README.md). In [Lesson 17](../17_fixed-length-files/README.md), you extracted fields from fixed-length records using fixed byte offsets; as long as the offsets were calculated correctly, that was enough.

What about CSV? You might think: it is just comma-delimited, so one `split(",")` and you are done. What is there to learn?

The problem is those words “you are done.” Fixed-length records assume every record has the same width, so the byte position of each field is fixed. CSV is different: field lengths vary with their contents, and a comma can itself be part of the data. In fixture row 02, the comma in `"Grace, Hopper"` is inside quotes and is part of the name. If you treat it as a delimiter, a five-field record becomes six pieces and is rejected, even though that customer is clearly in the books.

So this lesson adds a scanning rule: “a comma inside quotes is not a delimiter.” Once that rule is in place, you can no longer judge a whole line at a glance. You have to move forward one byte at a time while remembering “am I inside quotes right now?” That is where “character-by-character scanning” comes from.

There is another equally practical requirement: explain why a row was rejected. In a real batch, someone needs to take the reason the next day and ask upstream, “What happened with this row?” So this lesson does not report a vague `FAILED`; it reports a specific reason code.

## What Is This Concept, and What Problem Does It Solve?

**What is the concept?** A **quote-aware state machine**: it reads one byte at a time from left to right and uses three switches to remember its current situation—`WS-IN-QUOTES` (am I inside quotes?), `WS-AFTER-QUOTE` (did a quote just close?), and `WS-FIELD-START` (is this field still empty?). A comma is a delimiter only when the scanner is not inside quotes. Two consecutive quotes `""` inside a field become one quote character. After each field is complete, it is stored in an `OCCURS 5 TIMES` field table.

**Why is it necessary?** The shortest approach is `UNSTRING ... DELIMITED BY ","`; the source code for this lesson also explains nearby why it was not chosen: it does not understand quotes. To `UNSTRING`, `"Grace, Hopper"` is two pieces split at the comma, and `""` is not converted back into a single quote. If you replace the state machine with `UNSTRING`, fixture rows 02 and 04 are immediately wrong, and the program gives you no warning.

**What problem does it solve in real business work?** Whenever customer master data, transaction records, or reconciliation results are exchanged as CSV, someone will put commas or quotes in a field or leave it empty. The person responsible has to decide which records can be used, which are rejected, and why. The more specific the reason, the easier it is to follow up with upstream the next day: you can say “the name on row 06 is 21 bytes, over the limit,” instead of “there’s a problem with your file.”

**When should you not use it, and what happens if you use it incorrectly?** Keep three things in mind:

- **Structurally correct ≠ valid business data.** This lesson checks structural conditions such as “five fields, no field over 20 bytes, and quotes are closed.” The program still calls fixture row 07 valid even though the name is empty, because its structure is valid. It does not check whether names may be empty, whether status codes are allowed, or whether amounts can be converted to numbers. **Do not treat this output as a conclusion that “the customer data is fine.”**
- **A record must fit on one physical line.** This lesson does not support line breaks inside quotes or backslash escaping `\`. Claiming to “support CSV” while supporting only half of it is more dangerous than honestly saying “not supported.”
- **Length is measured in bytes, not characters.** A 20-byte limit is fine for plain ASCII. The encoding and length semantics for multibyte characters are not implemented in this lesson.

## Skills and Boundaries After This Lesson

After this lesson, you can:

- Open `customers.csv`, `READ` it line by line through EOF, and report the run using three counts: `行数 / 有效 / 拒绝`.
- Scan a record character by character with a quote-aware state machine: commas inside quotes are data, and `""` parses as one quote character.
- Store fields in an `OCCURS 5 TIMES` field table and print all five fields, while reproducing four structural rejection types: `FIELD_COUNT`, `TOO_MANY_FIELDS`, `FIELD_TOO_LONG`, and `TRAILING_COMMA`; plus three text errors: `UNCLOSED_QUOTE`, `QUOTE_IN_UNQUOTED`, and `TEXT_AFTER_QUOTE`.
- Explain why this lesson does not use `UNSTRING` and what `UNSTRING` lacks for CSV.
- Distinguish “structurally valid” from “valid business content”: the program still accepts fixture row 07 even though its name is empty.

Boundaries: each CSV record must fit on one physical line (line breaks inside quotes are unsupported); character encodings are not converted and lengths are measured in bytes; required fields, status-code values, and account-number formats are not validated; the 200-byte record limit is not checked; rejected results are not written to a file and data is not imported into a database. Organizing multiple input streams is covered in [Lesson 19](../19_multiple-files/README.md), end-to-end integration in [Lesson 22](../22_file-processing-practice/README.md), and separating business rejections from system failures in Lesson 26. Encoding conversion, required/value validation, and whole-record length validation are outside this lesson.

## Runtime Environment

- GnuCOBOL 3.2.0, default dialect, fixed-format source; **do not use** `-std=cobol85` (this lesson uses `RETURN-CODE` and `FUNCTION TRIM(... TRAILING)`; strict COBOL 85 was tested and reports `'RETURN-CODE' is not defined` and `syntax error, unexpected TRAILING`).
- Follow fixed format by byte position: column 7 is the comment indicator `*`; `DIVISION`, `FD`, `01`, and similar declarations begin in Area A (column 8); statements such as `DISPLAY` and `PERFORM` begin in Area B (column 12); valid program text must not pass column 72. The longest code line in this lesson is 66 bytes. Tests confirm that GnuCOBOL’s right boundary is column 72 inclusive: column 73 is discarded (for example, if the final period is in column 73), while placing the closing quote after column 73 reports `missing terminating " character`.
- Linux terminal; no database, extra tools, or third-party libraries required.
- Input fixture [`customers.csv`](./customers.csv): 8 lines, 333 bytes, plain ASCII, each line ends with `LF`, and no header row.
- The program opens the fixture by relative path with `SELECT ... ASSIGN TO "customers.csv"`, so you **must run it from the directory containing `customers.csv`**; otherwise opening the file fails.
- Do not write build artifacts back into the repository: put them in a temporary directory or the lesson’s `build/` directory and clean them up.

## Interface Contract: Five-Field Customer CSV

The interface contact saying “the format hasn’t changed” is not enough. We need a contract that can be documented and checked by the program: whether there is a header row, field count and order, quoting and escaping rules, the meaning of empty values, length limits, character encoding, and line-ending style. This lesson defines those terms.

The fixture has no header row, and each record has exactly five fields:

| No. | Field (output label) | Example of valid content | Length limit in this lesson |
|---:|---|---|---:|
| 1 | Customer ID | `C0001042` | 20 bytes |
| 2 | Name | `Ada Lovelace` | 20 bytes |
| 3 | Account number | `0001234567` | 20 bytes |
| 4 | Status | `A` | 20 bytes |
| 5 | Note | `REGULAR` | 20 bytes |

Delimiter and quoting rules:

- Fields are separated by ordinary commas `,`, and a record ends at the physical line boundary. The program uses `ORGANIZATION IS LINE SEQUENTIAL`; the GnuCOBOL runtime strips line terminators, so the program itself does not see newline bytes (`LF` and `CRLF` have both been tested).
- A field may be enclosed in double quotes; **fields containing commas or double quotes must be quoted**, and a double quote inside a field is written as two consecutive double quotes `""`.
- The quoting and comma conventions above follow common field rules from RFC 4180 (see [References](#参考资料)), but this lesson implements only the portion that fits on one physical line: it does not support line breaks inside quotes or backslash escaping `\`. **This lesson does not claim to implement the complete CSV specification**; it guarantees only the rules listed here.
- An empty field can be written as zero length between two consecutive commas (`A,,C,D,E`) or as `""`. This lesson requires **an empty final field to be written as `""`**; a trailing comma (`A,B,C,D,`) is rejected as `TRAILING_COMMA`.
- Length limits: 20 bytes per field and 200 bytes per record. The raw comma counts measured line by line in the fixture are `4 / 5 / 3 / 4 / 4 / 4 / 4 / 4`: of the five commas on row 02, one is inside quotes (so it is still five fields); row 03 has only three (four fields); and the final comma on row 08 is trailing. The longest line is 53 bytes including its ending `LF`.

Each fixture line is written this way deliberately (verified byte by byte with `od -c`):

| Row | What to notice | Expected result |
|---:|---|---|
| 01 | Unquoted fields + quoted name | Valid |
| 02 | Name contains a comma (inside quotes), note is `""` | Valid |
| 03 | Only 4 fields | Reject `FIELD_COUNT` |
| 04 | Double-quote escaping in `"A ""quote"""` | Valid |
| 05 | Name is exactly 20 bytes | Valid |
| 06 | Name is 21 bytes | Reject `FIELD_TOO_LONG` |
| 07 | Name is a bare empty field (`,,`) | Valid (structure is valid; content is not checked) |
| 08 | Trailing comma (the final note is missing) | Reject `TRAILING_COMMA` |

## Who Catches Bad Rows: What the Code Checks and What the Fixture Guarantees

**What the code actually catches (reproducible in this lesson):**

- Field count is not 5 → `FIELD_COUNT` (too few) or `TOO_MANY_FIELDS` (more than 5).
- Any field exceeds 20 bytes → `FIELD_TOO_LONG`; excess characters are not written to the field table, so they are **not silently truncated**.
- Unclosed quote → `UNCLOSED_QUOTE`; a quote in an unquoted field → `QUOTE_IN_UNQUOTED`; non-comma, non-line-ending text after a closing quote → `TEXT_AFTER_QUOTE`.
- The line ends with a comma → `TRAILING_COMMA`.
- Only **one** reason is reported per row, using “first error wins”: `WS-CSV-ERROR` is set only while it is still spaces. Errors discoverable during scanning (`TOO_MANY_FIELDS`, `FIELD_TOO_LONG`, `QUOTE_IN_UNQUOTED`, `TEXT_AFTER_QUOTE`) are recorded before end-of-line checks (`UNCLOSED_QUOTE`, `TRAILING_COMMA`, `FIELD_COUNT`). In tests, `A,B,C,D,` reports `TRAILING_COMMA`, while `A,B,C,D,E,` reports `TOO_MANY_FIELDS` because its trailing comma has already started a sixth field.

**What the fixture (upstream) alone guarantees; the code does not check:**

- The whole record does not exceed 200 bytes (FD is `PIC X(200)`; the program does not check the length).
- No line breaks occur inside quotes; there is no header row; the fixture is plain ASCII (the program does not convert encodings or distinguish multibyte characters, and length is measured in bytes).

Keep these categories separate because they determine who to contact when something goes wrong: the first is the program’s responsibility, and the second is the interface’s. **Also outside this lesson:** encoding conversion and UTF-8 multibyte length semantics, business checks such as required fields and allowed status values, the escape character `\`, trailing empty fields (`A,B,C,D,`), duplicate-record deduplication, a file recording rejected rows, and database import.

## Follow One Byte Through the Program: Source Reading Path

Read in the order the data changes:

1. `0000-MAIN`: `OPEN INPUT` opens the fixture; if `WS-FILE-STATUS` is not `"00"`, the program displays the status, sets `RETURN-CODE` to 1, and exits. It then loops on `READ`; `AT END` sets `WS-END-OF-FILE` and exits the loop. Each successfully read record first increments `WS-ROW-COUNT`, then goes to `1000-PARSE-ROW`. After the loop, the file is closed and a summary is printed.
2. `1000-PARSE-ROW`: first `INITIALIZE WS-FIELDS` clears the field table and resets the quote state, field number, and field length—**each row starts clean**, or residue from the previous row would contaminate this one. Next it calculates `WS-LINE-LENGTH = FUNCTION LENGTH(FUNCTION TRIM(FD-CSV-RECORD TRAILING))`: the FD is fixed at 200 bytes, and short records are padded with spaces on the right, so `TRIM ... TRAILING` gives the actual text length and avoids treating padding as field content. The tradeoff is that **real spaces at the end of a line cannot be distinguished from padding**.
3. The scan loop uses reference modification, `FD-CSV-RECORD(WS-CHAR-POSITION:1)`, to take one byte at a time and pass it to `2000-PARSE-CHARACTER`. The three state variables are the scanner’s core contract: `WS-IN-QUOTES` (currently inside quotes), `WS-AFTER-QUOTE` (a quote just closed), and `WS-FIELD-START` (the current field has no content yet).
4. `2100-HANDLE-QUOTE-IN-FIELD`: when a quoted field contains `""`, append one quote and **skip one position**; a single quote closes the quoted field and enters the “just closed a quote” state.
5. `2200-HANDLE-UNQUOTED-CHAR`: after a closing quote, only a comma is accepted (it starts the next field); any other character records `TEXT_AFTER_QUOTE`. In the ordinary state, a comma goes to `2300-START-NEXT-FIELD` (increment field number and clear field length); a quote at the start of a field opens quote mode; a quote elsewhere records `QUOTE_IN_UNQUOTED`; an ordinary character goes to `4000-APPEND-CHARACTER`.
6. `4000-APPEND-CHARACTER`: increment `WS-FIELD-LENGTH` for each character; write it to `WS-FIELD-VALUE` only if it is no longer than 20 bytes and the field number is no greater than 5. Otherwise, record only `FIELD_TOO_LONG` / `TOO_MANY_FIELDS`. This is where the program “rejects without truncating.”
7. End-of-line checks are ordered: unclosed quote → trailing comma → field count. Each `SET-*` paragraph writes only if `WS-CSV-ERROR` is still spaces, so **the first reason wins**—but remember that reasons found during scanning are already ahead of the end-of-line checks. For example, `A,B,C,D,E,` immediately locks in `TOO_MANY_FIELDS` when the sixth field is encountered.
8. `3000-REPORT-ROW`: a row succeeds only if `WS-CSV-ERROR` is blank. On success, it prints every field. Each `FUNCTION TRIM(... TRAILING)` in `DISPLAY` is only for display formatting; it does not change the field table.

**Why not use UNSTRING?** `UNSTRING 源 DELIMITED BY "," INTO 字段1 字段2 ...` can split a record into multiple receiving fields by delimiter, produce zero-length receiving fields, and use `POINTER`, `TALLYING IN`, and `ON OVERFLOW` to control the starting position, count, and overflow. But it does not understand quotes: `"Grace, Hopper"` is still split at the comma, and `""` is not converted back into a quote. This lesson requires “only a comma outside quotes ends a field,” so it uses an explicit state machine. If a future input contract guarantees that fields contain neither commas nor quotes, `UNSTRING` would be a shorter approach.

## Run and Observe

First run the following in a temporary directory and record the baseline; compare all later changes against it.

**Working directory**: you must first enter the directory containing `customers.csv`, or copy the fixture along with the program to a temporary directory as in the script below. The program only reads the fixture and does not modify it.

```sh
scratch_dir=$(mktemp -d)
trap 'rm -rf "$scratch_dir"' EXIT
cobc -fsyntax-only -Wall lesson.cob                  # check：只解析，不生成可执行文件
cobc -x -Wall -o "$scratch_dir/lesson_18" lesson.cob # build：生成可执行文件，诊断写到标准错误
cp customers.csv "$scratch_dir/"
(cd "$scratch_dir" && ./lesson_18)                   # run：读夹具，判定写到标准输出
echo $?                                              # 查看退出码
# clean：上面的 trap 在退出 shell 时删除临时目录；若改用课内 build/，用 rm -rf build 清理
```

What each command does: `-fsyntax-only` proves only that the syntax path can be parsed; `-x -o` creates an executable; only running it actually reads the fixture and produces business output; both the executable and fixture copy stay in the temporary directory, so the repository working tree gains no untracked files.

**Expected standard output (9 lines):**

```text
行=01 状态=成功 客户编号=C0001042 姓名=[Ada Lovelace] 账户号=0001234567 状态=A 备注=[REGULAR]
行=02 状态=成功 客户编号=C0002042 姓名=[Grace, Hopper] 账户号=0002468101 状态=A 备注=[]
行=03 状态=拒绝 原因=FIELD_COUNT
行=04 状态=成功 客户编号=C0004042 姓名=[A "quote"] 账户号=0009990001 状态=A 备注=[NEW]
行=05 状态=成功 客户编号=C0005042 姓名=[12345678901234567890] 账户号=0003210001 状态=A 备注=[EXACT20]
行=06 状态=拒绝 原因=FIELD_TOO_LONG
行=07 状态=成功 客户编号=C0007042 姓名=[] 账户号=0003210003 状态=A 备注=[NO_NAME]
行=08 状态=拒绝 原因=TRAILING_COMMA
汇总 行数=08 有效=05 拒绝=03
```

**Output field key (Chinese → meaning)**: `行=` is the record number; `状态=成功/拒绝` is the decision; `客户编号 / 姓名 / 账户号 / 备注` are the four business fields (`[]` brackets display an empty value); `状态=A` is the value of the fourth CSV field; `原因=` is the rejection reason code; `汇总 行数 / 有效 / 拒绝` are the three counts. The invariant is `行数 = 有效 + 拒绝`; for this example, `8 = 5 + 3`.

A few details that are easy to miss:

- On row 02, `备注=[]` comes from `""`, an explicitly empty field; on row 07, `姓名=[]` comes from a bare empty field. Both are **structurally valid**—this lesson does not check required fields.
- Row 03 has only four fields. At end of line, the program finds `WS-FIELD-NUMBER = 4` and reports `FIELD_COUNT`.
- The `OVER21` text on row 06 is not printed: an overlong field rejects the whole row, and rejected rows print only the reason code.
- Leading spaces in a field are retained (tested: `C1, Name ,...` prints `姓名=[ Name]`), but `TRIM ... TRAILING` used for display removes trailing spaces, so trailing spaces in fields are not visible in the output.

**Exit codes:**

| Scenario | Exit code | Standard output |
|---|---|---|
| Reaches EOF normally (including an empty file or all rows rejected) | `0` | Per-row decisions + summary |
| Fixture is missing or cannot be opened | `1` | `文件打开失败 STATUS=35` (when tested with a missing file, `FILE STATUS` was `35`) |

**About standard error**: when running the executable in this environment, standard error contains `Warning: program compiled against libxml 212 using older 209`. This is a warning about linked library versions in the runtime environment, **not business output from this program**; the component that triggers it has not yet been identified. Business decisions appear only on standard output.

**Environment test**: `cobc -fsyntax-only -Wall` and `cobc -x -Wall` both produce no diagnostics and exit with code `0`. Using `-std=cobol85` instead causes errors for `RETURN-CODE` and `FUNCTION TRIM(... TRAILING)`, so this lesson uses the default dialect.

## Boundary Tests

The following inputs were actually run for this lesson in a temporary directory (using a copy of the fixture and leaving repository files untouched) to draw the line between “code checks” and “fixture guarantees”:

| Input (one line) | Actual observation | Conclusion |
|---|---|---|
| `A,,C,D,E` | Valid; field 2 is empty | Bare empty fields are allowed |
| `A,B,C,D,""` | Valid; field 5 is empty | `""` is allowed |
| `A,B,C,D,E,F` | `TOO_MANY_FIELDS` | More than five fields are rejected |
| `"ABC,D,E` | `UNCLOSED_QUOTE` | Quote is not closed |
| `AB"C,D,E,F` | `QUOTE_IN_UNQUOTED` | Quote appears in an unquoted field |
| `"A"X,B,C,D,E` | `TEXT_AFTER_QUOTE` | Text follows a closing quote |
| `A,B,C,D,` | `TRAILING_COMMA` | The trailing comma leaves the scanner at “start of field” at end of line |
| `A,B,C,D,E,` | `TOO_MANY_FIELDS` | The trailing comma has already started field 6, so scanning records this reason first |
| 210-byte line (200 `A`s + `X,B,C,D,E`) | Split into two records: `行=01` `FIELD_TOO_LONG`, `行=02` valid | Exceeding 200 bytes **splits into multiple records**; it is neither rejected as one whole row nor silently truncated. The program cannot reconstruct the original line, so only the fixture can guarantee whole-record length |
| 20-byte field / 21-byte field | Valid / `FIELD_TOO_LONG` | Length is measured in bytes; the limit is 20 |
| CRLF line endings | Both lines valid | The `LINE SEQUENTIAL` runtime strips line terminators; the program does not see `CR` |
| Empty file | `汇总 行数=00 有效=00 拒绝=00`, exit code `0` | No records is not an error |
| Missing fixture | `文件打开失败 STATUS=35`, exit code `1` | Failure to open is a system failure, not a business rejection |

## Modification Exercises

Both exercises start separately from the original [`customers.csv`](./customers.csv) and modify a copy in a temporary directory; do not overwrite the lesson fixture or let the program write into the repository. The complete prompts, edit locations, commands, and expected differences are in [`exercise.md`](./exercise.md); see [`answer.md`](./answer.md) for reference answers.

## Apply the Idea to a New Case

Design a four-field transaction CSV: transaction ID, payee, amount, and note. Let the payee field support commas and double quotes (including `""` escaping), and allow the note to be empty; require rejection of an incorrect field count, an unclosed quote, and an overlong note. Design your own fixture to cover valid records, an empty note, quote escaping, and each error type. Explain whether length is measured in bytes or characters and what command proves it. See [`exercise.md`](./exercise.md) for the prompt; no answer is provided for this exercise.

## Walk Through a Real Workflow

Put this back into that Friday batch: this parser is the first link in the chain.

1. **Friday 17:20**: upstream places `customers.csv` in the shared directory—the same eight-row fixture this lesson reads.
2. The **overnight batch** starts this program and classifies each row as “valid / rejected.” Valid rows continue downstream; rejected rows stop here with a reason code.
3. **Who handles rejected rows?** A real system writes them to a traceable error file for manual review. Writing files is covered in [Lesson 16](../16_file-writing/README.md), and separating business rejections from file/write failures in [Lesson 26](../26_error-handling/README.md). This lesson prints reasons only to standard output; it does not persist them.
4. **Where do valid rows go?** The next link is [Lesson 19](../19_multiple-files/README.md), which reads this customer data along with that day’s transaction file. Then [Lesson 20](../20_file-matching/README.md) matches the two using account numbers, and [Lesson 22](../22_file-processing-practice/README.md) connects the steps into an end-to-end reconciliation batch.
5. **Someone checks these numbers**: the next day, the three counts `汇总 行数=08 有效=05 拒绝=03` must be reconciled with the number of rows reported by upstream. If they do not match, this parsing step has lost records.

## What Would Happen if This Code Went into Production?

- **Who schedules it?** The overnight batch scheduler, after the “upstream file ready” check. If the file has not arrived, the program never gets a chance to start.
- **Who reads its output?** Troubleshooting and business reconciliation staff. They first look at the three counts in `汇总`, then at which rows were rejected and why.
- **Who gets called when something goes wrong?** The person woken up by a call in the middle of the night is usually not dealing with the parser itself, but with mismatched counts: upstream says it sent 8 rows, while your summary says 7, which means a record was lost.
- **How does the next system receive the data?** Valid records enter the multiple-input flow in [Lesson 19](../19_multiple-files/README.md), then ultimately join the reconciliation batch in [Lesson 22](../22_file-processing-practice/README.md). In a real system, rejected rows should be written to a traceable error file ([Lesson 16](../16_file-writing/README.md), [Lesson 26](../26_error-handling/README.md)).
- **The most likely first-month incident**: treating “structurally valid” as “valid content.” An empty name, status code `X`, or letters in an account number all pass this lesson. The problem surfaces only later when a downstream step matches by account number or runs statistics, making it hard to trace back to the parsing step.

The boundaries need to be clear too: this lesson distinguishes “structurally valid / rejection reason” and makes each decision independently checkable against the fixture, assuming **one line, five fields, and plain ASCII**. It does not implement the complete CSV specification (line breaks inside quotes and `\` escaping are unsupported), validate required values, codes, or encoding, write rejected rows to a file, check the 200-byte whole-record limit, provide idempotent reruns, or import into a database. You need to ask the business team one rule at a time whether these numbers and rules are interface agreements or actual business constraints. That is what to do the next time an interface contact tells you “the format hasn’t changed.”

## Evidence Sources and Scope of Verification

- Fixture audit: `od -c customers.csv`, `awk` line-by-line counts, `file customers.csv`, and `wc -c` confirmed 8 lines, 333 bytes, ASCII, `LF` endings, no `CR`, and a longest line of 53 bytes.
- Runtime verification: ran `cobc -fsyntax-only -Wall`, `cobc -x -Wall`, the executable, and exit-code checks in a temporary copy of the lesson directory. The normal fixture results matched the table above line by line; each boundary case in “Boundary Tests” was run individually.
- Fixed format: `LC_ALL=C awk` measured lengths by byte; the longest valid code line is 66 bytes, and no line exceeds 72 bytes. A separate boundary experiment confirmed GnuCOBOL’s right boundary is **column 72 inclusive**: a final period in column 73 is discarded, while a closing quote in column 73 reports `missing terminating " character`.
- Not verified: length semantics for UTF-8 multibyte characters, reconstructing an original line over 200 bytes, and required/value checks not implemented in this lesson. Why not: the first two have no corresponding implementation here—length is always measured in bytes, and after the runtime splits an overlong line the program cannot reconstruct it. The third is business validation deliberately left for later lessons, and this lesson has no path for injecting such a decision. These three cases have no repeatable run to document, so only the limitations are stated, not “test results.”

## References

- [RFC 4180: CSV field, quote, and comma rules](https://www.rfc-editor.org/rfc/rfc4180.html)
- [GnuCOBOL Programmer’s Guide: UNSTRING](https://superbol.eu/gnucobpg/chapter7.html#unstring)
- [GnuCOBOL Programmer’s Guide: LINE SEQUENTIAL](https://superbol.eu/gnucobpg/chapter5.html#organization-line-sequential)
- Course home page in this repository: [README.md](../../README.md)
