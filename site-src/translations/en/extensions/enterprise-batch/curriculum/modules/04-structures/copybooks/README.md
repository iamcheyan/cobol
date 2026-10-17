# Versioned interfaces (reused read-only)

This module does **not copy** the enterprise customer Copybook, avoiding a second, potentially divergent implementation. The canonical version is shipped with the student bundle at:

    curriculum/modules/07-matching/labs/05-large-record/copybooks/ENTERPRISE-CUSTOMER-V1.CPY

(The in-repository instructor copy is at `instructor/modules/07/05-large-record/`; the contents are identical.)
Module 04 uses `cobc -I <canonical copybook dir>` (see `scripts/build.sh`; when the instructor tree exists it takes precedence, otherwise the published path above is used) to `COPY` the file at compile time. Lesson 04.2 also uses `COPY ... REPLACING` to derive V2 **in memory** (`CUSTOMER-CLASSIFICATION` widened from `X(1)` to `X(2)`); no new Copybook is written to disk.

The base banking interfaces (CUSTOMER v1=27B, ACCOUNT v1=47B, TRANSACTION v1=55B) are in `curriculum/bank/copybooks/`; this module does not modify them.
