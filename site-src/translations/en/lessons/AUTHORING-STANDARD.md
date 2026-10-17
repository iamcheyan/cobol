# Analysis and Authoring Standard for the 32-Lesson Main Curriculum

> Scope: READMEs, COBOL/Copybooks, scripts, input fixtures, `exercise.md`, and `answer.md` for `lessons/01_*` through `lessons/32_*`. This document guides the next round of lesson-by-lesson revision and review. It does not claim that all existing lessons already meet every item, nor does it authorize a bulk revision in this round.

## 1. Goals and Current State

The curriculum is for readers who already have some programming, Linux, and data-file experience but are new to COBOL. The eventual goal is to help them understand and run a bank’s overnight reconciliation batch. Every lesson must help readers answer: What business problem does this lesson solve? Why are their current skills not enough? What input does the code actually process, and what result does it produce? Which guarantees are implemented, and which are still production requirements? The complete dependency chain is in [`DIRECTORY.md`](DIRECTORY.md).

The existing material does not lack all business context; its entry points and depth vary. Lessons 01–28 often open with the same GnuCOBOL version sentence, while lessons 29–32 begin with toolchain details or a project summary. Lesson 02 already explains PIC and interface contracts, and lesson 20 explains the relationship between sort keys and sequential matching, but readers must reach the body to learn the business motivation. Lesson 15 uses four transactions to demonstrate file reading and EOF; lesson 28 explicitly uses five in-program transactions to focus on module interfaces; lesson 32 already has real files, SQL, rerun, and partial-failure checks. Preserve these useful materials, then reorganize the entry points and add explanations and evidence that are actually missing.

Main review points:

- `Makefile`’s `course-check` verifies that four kinds of files exist for each lesson and compiles and runs only lesson 01. It must not be described as behavioral acceptance for all 32 lessons.
- `01/exercise.md` still says “draft, pending course acceptance,” and its modification task asks for an English greeting while the README and `answer.md` ask for a Japanese greeting. Check each lesson’s README, exercise, answer, and actual state; do not carry forward stale acceptance claims.
- Explanations are in Chinese, some source comments and terminal output are in Japanese, and interface markers are also in English. Each lesson should let Chinese-speaking readers explain key output. Do not blindly change existing runtime language just for consistency.
- Some comments repeat statement behavior, such as the EOF flag and count explanation at the end of lesson 15 source; lesson 03 also explains truncation without `ROUNDED` several times. Keep business rules, exception reasons, and interface assumptions instead of line-by-line narration.
- Lessons 15–21 have clear small fixtures and some boundary exercises; lessons 22 and 32 have more complete input, output, failure, and recovery checks. Increase complexity gradually with the teaching stage, rather than judging by line count.

### Results from the First Revision Round (2026-10-16)

All 32 lessons were revised and committed according to this standard. The current state of the five review points above is recorded here as facts; the review findings above remain valid:

- `Makefile`: `course-check` now checks deliverables for all 32 lessons, syntax-checks lessons 01–28, and retains the lesson 01 behavioral smoke test. A new `course-check-sql` covers preprocessor checks for lessons 29–32 and the lesson 32 `check.sh` end-to-end scenarios. Behavioral acceptance remains as documented in each lesson’s README and in lesson 32’s `check.sh`.
- Lesson 01: the draft status and English/Japanese greeting conflict were resolved; the README, exercise, and answer now agree.
- Language convention: retain “Chinese README + existing Japanese runtime output,” and require each README to explain output labels in Chinese.
- Comments: redundant or invalid comments in lessons such as 03 and 15 were removed or rewritten; comments are now written around contracts, business rules, and recovery boundaries.
- Fixtures and boundaries: lessons 15–22, 26, and 30–32 now cover empty input, EOF, overlong records, missing files, write failures, partial SQL failures, and reruns. Scenarios that cannot be injected are explicitly marked unverified.
- Unreferenced duplicate `*_ja.cob` copies (most byte-for-byte identical to their main files, a few differing only in DISPLAY labels) were removed with their lessons; useful contract comments were carried into the main files.

## 2. General Principles and Acceptance Levels

**Design for incremental capability, not length.** Each lesson identifies one core capability, its prerequisites, a business action that makes the capability observable, and the result it hands to later lessons. Early lessons may hard-code small data sets to isolate a concept. Once the curriculum reaches files, engineering, and databases, examples must process real fixtures/files/SQLite; do not describe a `DISPLAY` simulation as reading, writing, or executing SQL.

**Distinguish three levels of commitment:**

| Level | Minimum requirements | Must not be described as |
|---|---|---|
| Teaching demonstration (01–14 and some single-concept lessons) | Compiles and runs; the target concept and key boundary are observable; hard-coded data, limitations, and untaught topics are stated | A business batch ready for production |
| Repeatable business exercise (15–31) | Actually processes the attached input or a real module/database; documents contracts, status, output, exit codes, and reset steps; verifies the lesson’s core boundary | Complete operational, transaction, or audit guarantees |
| Capstone project (08, 14, 22, 28, 32; requirements increase by stage) | Connects learned capabilities; fully explains input → rules → output, count invariants, typical failures, and reruns; results can be independently reconciled | Automatic atomicity across files/databases or production idempotency |

Choose necessary complexity for the lesson’s subject. Prefer meaningful business branches, boundary inputs, state changes, and independently checkable results. Add code only when it teaches the lesson’s goal or supports a capability already taught. Do not add file I/O to lesson 02 before it is taught, or implement a complete transaction posting system in lesson 15. Put production-level designs in later capstone lessons, and identify the risks and follow-on lesson in earlier ones. Use business terms consistently and define their rules; do not claim that examples meet banking, financial, regulatory, or security standards without evidence.

## 3. Make a Design Card Before Revising Each Lesson

Before revising a lesson, record the following for that lesson. Fill in the actual details; do not use vague claims such as “learn enterprise development.”

1. **Learning position:** Lesson number, prerequisites, one or two new core concepts, and how the next lesson/project uses the output.
2. **Business task:** Who supplies what data, which specific rule the program applies, what decision it makes, and who receives the result. For early lessons, label simulated data as demonstration data.
3. **Contract:** Input source, field width/unit/encoding where relevant, ordering and uniqueness assumptions, output file/stdout/database changes, and normal/error return codes.
4. **Decision points:** Which field/state changes which path; distinguish conditions checked in code from conditions guaranteed only by the fixture.
5. **Observable evidence:** Normal values, boundaries or failure values directly related to the core concept, expected output, and an independent calculation.
6. **Teaching boundary:** What this lesson does not implement yet, which later lesson adds it, and whether the limitation affects the reader’s understanding of the example.
7. **Change list:** Effects on README, source, comments, exercises, answers, fixtures, scripts, course index, and cross-lesson interfaces; list unchanged items and why.

Keep the design card in the lesson revision task or delivery report; it does not need a permanent file of its own. Check neighboring lessons and `DIRECTORY.md` before deciding whether to expand code. Preserve material that already meets a requirement instead of repeating a template.

## 4. README Writing Standard

### 4.1 Opening Order

1. Title: lesson number and specific task/concept.
2. **One-sentence introduction:** Describe “business situation + action in this lesson + output/follow-on use.” One or two sentences are fine; a version number alone is not an introduction.
3. **Why learn this now:** State what prerequisite skills can already do, the concrete problem they cannot handle, and how this lesson’s concept addresses it. A short business example is enough for a foundation lesson.
4. **Capabilities and boundaries after the lesson:** List 3–5 observable actions, identify the core result, and state what later capability is not covered. Avoid goals that only say “understand,” “be familiar with,” or “master.”
5. **Runtime environment:** State the GnuCOBOL version, default dialect/fixed format, platform, and extra tools used. Database lessons must specify GixSQL/SQLite dependencies, supported platforms, and build entry point. Link to the course index for shared conventions; describe lesson-specific limits here.

For example, lesson 15 could say: “Daily bank transactions arrive in text files. This lesson reads each source record and distinguishes end-of-file from an open failure, establishing the input path for later field parsing and reconciliation.” Then explain why EOF is not a business error and why this lesson does not parse fields yet. This is only a writing example; when revising, confirm that the code supports every verb.

### 4.2 Questions the Body Must Answer

- **Business and concept:** Why does the scenario need this capability? How does the new syntax perform the action? How is it different from the previous lesson? Why not use a method already learned?
- **Input and rules:** Where does data come from? What are the key fields and valid values, amount units and precision, and policies for empty, duplicate, out-of-range, or unknown values? If there is no input, explicitly say that values are in-program constants. Distinguish assumptions, checked rules, and behavior after failure.
- **Running and observing:** What conditions are needed to run from the lesson directory or another directory? Explain the separate purposes of syntax checking, building, running, and cleanup. List expected stdout, file contents, database changes, and exit codes separately. Do not present stderr environment warnings as business output.
- **Source reading path:** Explain important paragraphs/fields in the order data and state change. Clarify non-obvious COBOL scope, memory layout, call interfaces, or status codes; do not narrate obvious code line by line.
- **Practical use:** Explain how this lesson’s output supports later bank reconciliation and what guarantees a real system would still need. Name specific later lessons instead of saying only “commonly used in enterprise.”
- **Exercises and answers:** Summarize tasks in the README and link to `exercise.md` / `answer.md`. Keep the task, initial values, and expected results consistent across all three. For migration exercises without answers, state what the learner must complete independently.
- **Evidence:** Commands and validation scope must match the current code. Mark unrun scenarios as pending/unverified or known limitations; never present expected output as an observed result.

Adjust section names and length to the lesson. Lessons 01–14 focus on concepts, state changes, and business motivation; 15–22 add file formats, physical records/EOF, and result files; 23–28 add module responsibilities and parameter contracts; 29–32 add preprocessing, SQL states, before/after database state, and recovery boundaries. Include only the details needed in each lesson. Do not paste the same “enterprise practice supplement” into every lesson.

## 5. COBOL Examples and Engineering Standard

### 5.1 Data, State, and Boundaries

- Keep all source in fixed format: indicator in column 7, Area A beginning at column 8, Area B at column 12, and effective program text within column 72. Do not use strict `-std=cobol85`; retain GnuCOBOL’s default dialect and existing uses of `COMP-3` / `FUNCTION TRIM`.
- Keep field `PIC`, `USAGE`, initial value, width, and business unit consistent. Distinguish identifiers from numbers, text length from physical bytes, and implied decimals from external formatting. If a record layout changes, trace every producer, consumer, Copybook, fixture, expected file, and SQL table.
- Make code branches match the documentation: EOF, not found, business rejection, and system failure are distinct. `FAILED` output, setting flags, nonzero return codes, and closing opened resources must match the stated contract. Do not claim checks that are not implemented.
- File lessons must state the difference between line-sequential and fixed-length records, working directory and filenames, overwrite/append behavior, record width, key order/uniqueness, and policy for overlong input. Database lessons must document the real `EXEC SQL` preprocessing chain, SQLCODE 0/100/error, connection/cursor lifetime, and driver-specific behavior. Do not generalize SQLite behavior to Oracle/PostgreSQL.
- Count and amount checks in capstones need a hand-checkable basis. Describe output and committed database state after failure and the recovery method accurately. Lesson 32 already documents that earlier updates may remain after an SQL failure; do not call it atomic.

### 5.2 Increase Complexity Gradually

| Stage | Real tasks that may be added | Scope that still needs control |
|---|---|---|
| 01–08 Language and control flow | Consistent miniature rules for account numbers, balances, transaction types, amounts; boundary values with explicit accept/reject reasons | Do not require external files, full financial authorization, or tables/SQL before they are taught |
| 09–14 Data structures | Record layouts, capacity limits, view changes, lookup assumptions, and match results | Do not describe a small in-memory table as a large-file index or production master |
| 15–22 File processing | Real fixtures, empty files/short or long records/asynchronous EOF/orphan keys, output files | A single-concept lesson covers only failures directly related to its topic; reserve the full chain for capstones |
| 23–28 Engineering | Parameter order/direction, shared Copybooks, separation of logs and business errors, repeatable builds | Do not require every interface lesson to handle all external I/O failures |
| 29–32 Database and project | Real SQL, not-found and error cases, snapshot differences, rerun and partial-failure checks | Do not invent transaction, concurrency, or portability guarantees |

Any added branch or field must be accompanied by updates to fixtures, explanations, exercises, and expected results. Reject expansions that add lines without adding observable behavior.

## 6. Source Comment Standard: Write Like Someone Maintaining a Business Program

**Comments answer “why is this handled this way, what convention does it rely on, and what happens if it is violated?” Code answers “what does it do?”** Put comments next to the relevant rule or interface so a maintainer can avoid misuse by reading the source alone. The README teaches concepts; do not pack a whole textbook into source comments. Use concise Chinese or established project business terms in program comments. When external interfaces or runtime output must retain their existing language, explain them in the README instead of changing a real output contract for language consistency.

Comments should explain:

- Interface contracts and assumptions: for example, external-record offsets/units, upstream guarantees that keys are ascending and unique, the `CALL USING` layout, and who updates a field.
- Business decisions: for example, an overdraft is a business rejection rather than a batch failure; an amount must pass a numeric check before conversion from integer cents; an unknown transaction code must not be posted.
- Non-obvious technical constraints: for example, `REDEFINES` gives two views of the same storage, a `PERFORM` paragraph’s return boundary, a verified GixSQL exception, or a write failure after which success must not be reported.
- Recovery and audit boundaries: for example, accepted output exists before synchronization begins, earlier rows may remain updated after an SQL failure, or a reconciliation count invariant and its failure trigger.

Do not comment:

- A Chinese paraphrase of each `MOVE`, `ADD`, `IF`, or `DISPLAY`; field and paragraph names already describe the action.
- Repeated or obsolete execution results, unimplemented production guarantees, or long copies of README text.
- Fixture constants presented as formal business policy, or vague statements such as “check for errors here” that do not name the error.

Comment example (fixed format, `*` in column 7; use field and status names from the actual lesson):

```cobol
      * The upstream file is sorted by account number with unique keys; reverse order can cause sequential matching to miss rows.
      * This lesson treats that condition as an input contract and does not validate it in the program.
           PERFORM 2000-MATCH-RECORDS
```

If the target lesson validates ordering at runtime, rewrite the second sentence to describe the actual failure path. If no such assumption exists, do not copy this comment. For each comment, ask: would removing it lose a business constraint, surprising behavior, or maintenance risk? If not, remove it. Existing Japanese comments that describe valid rules may be accurately rewritten in Chinese; do not automatically translate them and leave duplicate information. Program comments, README, and actual error handling must agree.

## 7. Exercises, Answers, Fixtures, and Acceptance Evidence

Every lesson needs at least one **answered modification exercise**: specify the starting baseline, change location and constraints, rebuild/run command, complete expected difference, and reason. The answer must solve this task alone, without relying on another exercise. Add a **migration exercise without an answer**: change to a similar business scenario that requires the learner to choose fields/rules and explain validation independently. Do not require mechanisms that have not been taught unless clearly marked as a challenge. README, exercise, and answer must agree in scope.

Fixtures and expected results should make the core logic independently checkable. A small amount of data should show the normal path and a boundary close to the lesson’s topic. File handling should account for byte width, newlines, order, and record count; amount handling should account for units, rounding, and conservation; database handling should account for queries and state before/after changes. State whether inputs are modified in place, what a run overwrites, and how to rerun from clean fixtures. Do not use output generated by the program itself as the sole proof that it is correct; calculate expected results from the rules or check them independently first.

Choose acceptance scenarios based on the changes; do not require the same giant matrix for every lesson:

| Lesson type | Minimum execution and observation |
|---|---|
| Syntax/memory foundations | Syntax-check, compile, and observe actual output; rerun after changing a boundary value central to the concept |
| Files/sorting | Run with the lesson’s real fixtures; check file contents, line/byte counts, and return code; exercise EOF/bad input/sort boundaries relevant to the topic |
| Modules/scripts | Build and run the main program from a clean state; inspect interfaces, logs/output, and failure status |
| SQL/capstone | Use the real toolchain; check database queries, output files, counts, and return code; run declared failure and rerun scenarios |

`cobc -fsyntax-only` proves only the syntax path. Check each lesson’s `build.sh check` to see whether it also runs behavioral scenarios. If a toolchain is missing, a failure cannot be injected reliably, or the environment has a limitation, record the actual verification scope; do not fabricate a pass. When stdout, record formats, or interfaces change, check every affected consumer and answer. Fix stale exercises, links, draft status, and historical claims that no longer describe observed results.

## 8. Lesson-by-Lesson Review Questions

The table lists **questions to ask during design**, not claims that every lesson has a defect. Review each lesson against its current source, fixtures, and neighboring lessons. `DIRECTORY.md` documents the full prerequisite chain and project relationship.

| Lesson | Design questions |
|---|---|
| 01 Hello | How does a minimal program become a batch entry point? What do compile and run each prove? Remove stale draft status. |
| 02 PIC | What guarantees leading zeroes in account IDs, amount precision, and date shape? Keep the three existing modification exercises consistent. |
| 03 MOVE/COMPUTE | How does truncation or rounding affect the closing balance? Which business rule is chosen, and when is overflow reported? |
| 04 IF | Where do transaction boundary values branch? Can readers trace accepted and rejected paths through nested conditions? |
| 05 EVALUATE | What do known and unknown transaction types produce? Where is classification distinct from actual posting? |
| 06 PERFORM | What happens for zero iterations, the last iteration, and an index beyond a fixed mapping? Do not introduce tables early. |
| 07 Paragraph | When does the main flow call and return? When is shared state modified? |
| 08 Control-flow capstone | How can balances and accepted/rejected counts for multiple transactions be reconciled one by one? |
| 09 Group Item | How do group/item layout and moving a group relate to an external record? |
| 10 REDEFINES | Which business type selects between two interpretations of the same bytes? A view does not validate data automatically. |
| 11 OCCURS | Are table capacity, loaded count, and traversal limit consistent? |
| 12 INDEXED BY | What roles do an index and numeric subscript play in lookup? How are access boundaries checked? |
| 13 SEARCH | Are successful/failed lookup and ordering assumptions observable? |
| 14 Data-structure capstone | How does an in-memory table relate accounts and transactions? Are capacity, duplicate keys, and balance rules clear? |
| 15 File reading | What happens for line-sequential records, empty input, EOF, and open failure? |
| 16 File writing | How are accepted/rejected files routed? Does a rerun overwrite them? How is write failure reported? |
| 17 Fixed-length records | Can width, offsets, newline, and total file bytes be reconciled? |
| 18 CSV | What are the policies for quoting, empty fields, field count/length, encoding, and physical line boundaries? |
| 19 Multiple files | After each side reaches EOF, how does the other continue, and what does each count measure? |
| 20 File matching | Who guarantees ascending order and unique keys? How do the three match categories prove no rows were missed? |
| 21 SORT | How is unordered input sorted? Is the order of duplicate keys guaranteed? |
| 22 File capstone | How do validation, sorting, matching, result writing, and counts fit together? What artifacts remain after failure? |
| 23 COPYBOOK | Which consumers share the declaration, and what is affected by changing its width? |
| 24 CALL | How do the responsibilities of caller/callee, LINKAGE layout, and return status fit together? |
| 25 USING | What are the data direction and ABI for REFERENCE/CONTENT/VALUE, and what is the GnuCOBOL 3.2 toolchain warning? |
| 26 Error handling | How can rejection, file failure, and EOF be distinguished by return code and resource cleanup? |
| 27 Logging | Which events help locate a batch and record? How is a failure in logging itself reported? |
| 28 Modular capstone | Five fixed in-program transactions focus on interfaces. How can logs, return status, and module calls be reconciled? |
| 29 Embedded SQL | How can the preprocessor, real SQLite connection, host variables, and SQLCODE be verified? |
| 30 Cursors | What happens for empty, one-row, and multi-row results and EOF? Is the driver’s special blank-row behavior confined to this toolchain? |
| 31 Data synchronization | What are the file/DB snapshot differences, DB-only boundary, rerun behavior, and non-atomicity? |
| 32 Graduation project | Can count conservation, business rejection/system failure, partial SQL success, and recovery be independently reconciled? |

## 9. Execution Method and Delivery Gate for the Next Goal

1. **Establish the baseline:** The lead checks the current tree, toolchain availability, and cross-lesson record/output contracts, then makes a 32-lesson task list. One integrator owns the course index, global README, and shared build/check entry points to avoid conflicting parallel edits. The existing extension [`AUTHORING-STANDARD.md`](../extensions/enterprise-batch/docs/curriculum/AUTHORING-STANDARD.md) is for more demanding enterprise batch training; do not impose its entire failure matrix on basic main-curriculum lessons.
2. **Assign by lesson:** One contributor owns the design card, README, source, comments, exercises, answers, fixtures, and lesson scripts for a lesson, and works through review in prerequisite order. Neighboring lessons can be investigated in parallel. Freeze cross-lesson contracts with the integrator before changing an interface or data format.
3. **Deliver lesson by lesson:** Report “current state → design decision → file changes → actual normal/boundary/failure commands and results → unverified items → cross-lesson effects.” Do not present an explanatory-only change as a tested functional change, and do not commit placeholders or fabricated output.
4. **Cross-review:** A second reviewer starts from scratch and runs the README steps or independently recalculates key data. Check business motivation, prerequisites, comment accuracy, exercise independence, answer consistency, fixed format, and lesson scope. If a specific error is found, revise that lesson; do not defer it with “improve later.”
5. **Integrate by stage:** At the end of each stage, the integrator checks neighboring prerequisites, naming and field units, directory links, lesson scripts, and reset behavior, then runs a representative path for the stage. Lessons 29–32 require the supported toolchain for acceptance; if it is missing, record the environment blocker rather than substituting mock SQL.
6. **Definition of done:** Every lesson has its own design and verification evidence; all affected callers, fixtures, answers, course index, and shared entry points agree; there are no inaccurate “draft/pending acceptance” statuses or conflicts between lesson goals and program behavior. Claim the full curriculum is complete only after the global integrity check, representative paths for each stage, and the existing final-project `check.sh` all pass.

### Reusable Single-Lesson Task Card

The integrator fills in these fields when assigning work. Mark unknowns “to investigate”; do not assign behavior changes based on assumptions:

```text
Lesson/directory:
Prerequisites and follow-on:
One or two capabilities this lesson must teach:
Existing correct material and specific issues to resolve (with file locations):
Allowed files: the lesson directory; confirm cross-lesson contracts with the integrator first.
Business input → rule → output/return code:
Teaching boundary: concepts not introduced early; assumptions provided by upstream:
Acceptance scenarios: normal, topic-specific boundary, applicable failures; expected values and independent basis for each:
Delivery: design card, file changes, commands and actual observations, unverified items, cross-lesson effects.
```

One contributor should close the loop on the README, code, exercise, answer, and fixtures for each lesson; the integrator handles shared entry points and cross-lesson contracts. Follow the six stages in `DIRECTORY.md`: 01–08, 09–14, 15–22, 23–28, 29–31, and 32. Lessons in a stage can be worked on in parallel when their directories do not overlap. If a later lesson depends on a changed earlier data definition, first agree on shared field widths, units, interface, and expected output. Count a lesson as complete only after its independent review passes. If a stage interface or convention changes, revisit all accepted consumers and rerun affected scenarios.

Use the following evidence table in delivery reports; there is no need for a permanent report file for every lesson:

| Scenario | Clean starting input | Expected stdout/files/DB/return code | Actual command and observation | Match? If not, why? |
|---|---|---|---|---|
| Normal path | Fixture and reset method | Independently calculated key values | Actual execution record | Conclusion |
| Topic boundary | Minimal change and its purpose | Corresponding change and invariant | Actual execution record | Conclusion |
| Failure path (when applicable) | Repeatable failure injection | Failure state and remaining artifacts | Actual execution or reason not verified | Conclusion |

Task cards and reports must distinguish “documented expectation,” “personally observed during execution,” and “inferred from code.” If only text changed, check it against the existing program and fixtures. If program behavior changed, rerun affected paths. An agent must not substitute its own paraphrase of a README for an independent review.

Per-lesson delivery review:

- [ ] The opening explains the business task, current knowledge gap, and lesson output; environment versions are in runtime requirements.
- [ ] The goal has evidence in source and runtime results; new concepts respect the prerequisite chain.
- [ ] Input/output, field units/widths, assumptions, branches, errors, and exit codes match the code.
- [ ] Comments explain rules, interfaces, or non-obvious decisions; line-by-line narration and stale comments are removed.
- [ ] Fixed format and all affected Copybooks, scripts, fixtures, and consumers agree.
- [ ] Modification exercise, migration exercise, answer, and README agree; results can be independently reconciled.
- [ ] Actual compilation, execution, and topic-boundary validation are complete, with commands, observations, and uncovered limits recorded.
- [ ] Neighboring lessons and course-index references remain accurate; no production guarantee or fabricated run is claimed.
- [ ] The lesson meets §10: a concrete business scene, conversational language, distinct writing for each lesson, and no implication that the code is production-ready.

## 10. Make It Practical and Conversational (In Addition to §§4–6)

Previous revision rounds made the material accurate: commands, output, and boundaries can be checked. But the reading still feels like an acceptance specification—uniform sentence patterns and dense conclusions—without telling readers who uses this system at work and what happens if they do not. This section asks each lesson to explain the material like an experienced coworker getting you started, without changing hard facts.

### 10.1 Every Lesson Must Answer Four Questions

Answer in this order so readers can explain the point after the first two screens:

1. **What is this concept?** In plain language, first say what new capability it gives you, then introduce the term. Do not begin with “this lesson introduces syntax X.”
2. **Why do you need it?** Be specific about what you cannot write without it, or how the result can go wrong. Examples: “You would have to copy the same code 120,000 times” or “A letter in the third transaction amount makes the whole batch fail.”
3. **What problem does it solve in real work?** Name a role and time: who in banking, insurance, securities, payments, or manufacturing needs it, and when? Without it, what would that person do manually that day, and what risk would they face?
4. **When should you not use it, and what happens if you misuse it?** A business misuse can cost more than a syntax error.

### 10.2 Open Every Lesson with a “Business Scene”

- Use 2–4 paragraphs for a specific situation: who is working on what system, on what day and time, with what volume and pressure, and what happens if something fails. Include concrete detail, such as “120,000 transactions must finish before 8 a.m.” or “The branch opens at 9 and customers are waiting to see their balances.”
- Make the scene match the concept the lesson teaches. Do not go off topic or claim regulatory compliance.
- Treat the scene as a **teaching demonstration**. Institutions, amounts, and batch dates must not imply real data from an actual organization.

### 10.3 Language: Talk to a Coworker, Not Like a Specification

- You can say “You might think…,” “Hold on before writing a loop…,” “Here’s the easy trap…,” or “I’ve seen someone lose an afternoon to this.” Use second person (“you”).
- Avoid bureaucratic language such as “this lesson will,” “the field shall,” “intended to,” and “in summary.” Use fewer “must/should” statements; explain what goes wrong if the step is skipped.
- **Write each of the 32 lessons in its own voice.** The business story must grow from that lesson’s own concept. Do not paste the same opening template into every lesson (for example, “the bank’s overnight batch…”). Lessons in a stage can refer to each other, but the wording must differ.
- Sentences can be short; a paragraph can be a single sentence. Keep necessary technical detail, but make it dense with data and code rather than adjectives.

### 10.4 Hard Facts That Must Survive Conversational Rewriting

- Commands, expected stdout/file contents, byte counts, exit codes, and file status codes must match the code and observed runs. Change the wording, not the conclusion.
- Continue to state unverified items and why they were not verified.
- New business narrative must not imply a new technical guarantee, especially that the example is “ready for production.”

### 10.5 Structural Changes

- Keep the opening order in §4.1 and questions in §4.2. This section adds requirements to them.
- Put the business scene before or within “why learn this now.” Make “what the concept is” and “what problem it solves” visible at a glance.
- Upgrade “where this fits in industry” to “what happens if this code goes into production”: who schedules it, who reads the logs, who gets called when it fails, what system consumes the output, and what the first month’s most likely incident is.
- Add a “Walk through a real flow” section to each lesson. Place its output in an end-to-end chain, say who receives it, and identify the downstream code by lesson number.

### 10.6 Counterexample → Example

Counterexample (formal prose without a business scene):

> This lesson introduces `PERFORM VARYING`, wrapping “process one record” in a loop so the loop boundary and count can be checked independently. The gap is repetition: a real batch must apply the same logic to N transactions, where N is only known at runtime.

Example (start with the work scene, then introduce the syntax):

> You do not have three transactions to process; you have 120,000—and you will not know the exact count until 7 a.m.
> Would you copy the same code 120,000 times? Of course not. “Run the same logic N times” is one of the most ordinary batch jobs, and COBOL gives you `PERFORM VARYING`: start at transaction one, increment the sequence after each transaction, and stop after the limit.
> It sounds simple, but batch incidents often happen at the edges: does the final item count? If there are no items that day, does the loop run once anyway? This lesson makes both behaviors visible.
