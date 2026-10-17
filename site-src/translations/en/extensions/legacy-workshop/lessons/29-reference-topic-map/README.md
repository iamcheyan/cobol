# COBOL Topic Map and Advanced Learning Path

This lesson is an index for filling gaps in the course directory, helping you place the first 29 topics within the broader picture of GNUCOBOL development. COBOL standards, historical dialects, and vendor extensions cover a wide range. The guide below clearly distinguishes the core batch-processing course from topics that require a separate environment, without presenting obscure keywords or IBM-specific environments as hands-on material already covered.

## Core Language Map

| Knowledge area | Topics | Related lessons |
|---|---|---|
| Program organization | IDENTIFICATION / ENVIRONMENT / DATA / PROCEDURE DIVISION; SECTION, Paragraph, periods, and scope terminators | [01](../01-program-anatomy/), [02](../02-source-format/) |
| Source rules | Fixed format, free format, Area A/B, indicator area, comments, continuation lines, compiler column limits | [02](../02-source-format/) |
| Identifiers | User-defined names, reserved words, naming rules, literals, string quotation marks, comments | [03](../03-names-comments-literals/) |
| Data hierarchy | 01–49, 66 RENAMES, 77, 78 constants, 88 condition names; group and elementary items; WORKING-STORAGE / LOCAL-STORAGE / LINKAGE | [04](../04-data-hierarchy/), [07](../07-conditions-88/) |
| Data descriptions | PIC symbols X/A/9/V/S/P, editing symbols, VALUE, JUSTIFIED, SIGN, USAGE DISPLAY/COMP/COMP-3; REDEFINES; OCCURS / OCCURS DEPENDING ON; SYNCHRONIZED | [05](../05-picture-storage/), [10](../10-tables-occurs-search/), [14](../14-copybooks-redefines/) |
| Data operations | MOVE, INITIALIZE, SET, CORRESPONDING, arithmetic verbs, COMPUTE, ROUNDED, ON SIZE ERROR | [06](../06-values-move-arithmetic/), [07](../07-conditions-88/) |
| Control flow | IF/ELSE, EVALUATE, PERFORM, loops, inline PERFORM, EXIT PERFORM, paragraph calls | [08](../08-branching-evaluate/), [09](../09-loops-perform/) |
| Tables | OCCURS, subscripts, INDEXED BY, SEARCH, SEARCH ALL, sorting prerequisites and boundaries | [10](../10-tables-occurs-search/), [18](../18-sort-merge/) |
| Strings | STRING, UNSTRING, INSPECT, DELIMITED BY, TALLYING, WITH POINTER, reference modification | [11](../11-strings-unstring-inspect/) |
| File processing | SELECT, ASSIGN, FD/SD, OPEN, READ, WRITE, REWRITE, DELETE, CLOSE, file status, sequential/line sequential/relative/indexed organizations | [12](../12-sequential-files/), [13](../13-file-status-errors/) |
| Modularization | COPY, Copybook, COPY REPLACING, REDEFINES, CALL, CANCEL, LINKAGE, BY REFERENCE/CONTENT/VALUE, RETURNING | [14](../14-copybooks-redefines/), [15](../15-subprograms-linkage/) |
| Intrinsic functions | TRIM, LENGTH, NUMVAL, CURRENT-DATE, date/integer/numeric functions, and input conversion validation | [16](../16-intrinsic-functions-dates/) |
| Batch business processing | Control breaks, subtotals/totals, reports, SORT/MERGE, error counts, job exit codes | [17](../17-reports-control-break/), [18](../18-sort-merge/), [25](../25-project-csv-pipeline/), [26](../26-project-fixed-records/) |
| Engineering quality | Compiler dialects, warnings, diagnostics, debugging, build dependencies, test fixtures, logging, and idempotent jobs | [19](../19-modules-environment/), [20](../20-debugging-diagnostics/), [21](../21-compiler-options/), [22](../22-bash-build-run/), [23](../23-bash-tests-batch/), [24](../24-bash-pipelines-scheduling/) |

## GnuCOBOL Topics for Separate Study

These capabilities depend on a specific terminal, external database/protocol, compilation and build method, or use case. Complete the core lessons first, then consult the GnuCOBOL Programmer's Guide and the local `cobc --help` to study the version used by your project:

- **ACCEPT / DISPLAY extensions**: Command-line arguments, environment variables, standard input, terminal attributes, and return values.
- **SORT/MERGE in practice**: SD work files, input/output procedures, temporary directories, and resource strategies for large data sets.
- **Relative and indexed files**: Key definitions, INVALID KEY, locking, and concurrent access. Verify file-system behavior on the actual system.
- **Screen section (SCREEN SECTION)**: Interactive terminal input and output; not suitable for pure background batch programs.
- **Report writer (REPORT SECTION)**: Report page control and compatibility with legacy runtime environments.
- **Calling conventions and linking**: Static/dynamic calls, shared libraries, C interfaces, ABI, and deployment dependencies.
- **SQL / embedded databases**: Require the relevant database client, precompiler, or GnuCOBOL integration module; these are not capabilities of the basic `cobc` environment by default.
- **XML / JSON / sockets / CGI / GUI**: Implemented through GnuCOBOL libraries, external programs, or platform extensions. First check the modules and licenses available in the target environment.
- **Object-oriented COBOL and differences in modern standards**: Depend on the compiler implementation and target runtime; do not treat a particular mainframe dialect as universal GnuCOBOL syntax.
- **Internationalization, character sets, and locales**: UTF-8, EBCDIC, collating sequences, decimal point, and locale need to be verified with actual input on the target system.
- **Security and production operations**: File permissions, path traversal, temporary files, logging of sensitive data, concurrency control, auditing, retries, and idempotency.

## Next Steps

Choose a real data workflow from capstone lesson [28](../28-capstone-night-batch/), write down its input/output contract and failure matrix, then add the advanced topics you use. When adding a topic, follow the course structure of “a separate directory + explanation + fixed-format source code + compile/run commands + modification exercise + plugin exercise.”
