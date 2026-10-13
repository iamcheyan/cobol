# B04 instructor reference implementation

`BATCHL4.COB` is the executable implementation for the independent 1,778-byte `ENTERPRISE-CUSTOMER-V1.CPY` layout. It uses fixed sequential records and bounded OLD/NEW cursors; it owns the production-style field validation and field-by-field comparison algorithm. The course starter deliberately contains no copy of this implementation.

Build with:

```bash
cobc -Wall -I instructor/modules/07/05-large-record \
  -x -o /tmp/batchl4 instructor/modules/07/05-large-record/BATCHL4.COB
```

`curriculum/modules/07-matching/labs/05-large-record/scripts/check.py` compiles a probe that asks the GnuCOBOL runtime for `ADDRESS OF` every leaf field and checks each offset against `FIELD-CATALOG.csv`. It also confirms the course Copybook is byte-identical to this canonical file. `verify.py` is a separate Python oracle for the COBOL report and never executes the field comparison in place of COBOL.
