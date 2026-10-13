       IDENTIFICATION DIVISION.
       PROGRAM-ID. M11CUST2.
      *> STARTER (module 11 maintenance task 11.5).
      *>
      *> The customer classification belongs to the independent,
      *> versioned ENTERPRISE-CLASS layout (a distinct name from the
      *> canonical module 07 L4 ENTERPRISE-CUSTOMER-V1) -- NOT to the
      *> 27-byte canonical CUSTOMER v1, whose byte 27 is the record
      *> STATUS (A/D).  Widen the classification from 1 to 2 chars
      *> (layout 001 -> 002, v1 23B -> v2 24B); this program must
      *> read the frozen v2 snapshot and write the downstream extract.
      *>
      *> TODO 1: read enterprise v2 records of 24 bytes, layout '002'.
      *> TODO 2: take the classification at bytes 23-24 (CLASS|<id>|xx).
      *> TODO 3: write the extract and counts and return RC0; keep a
      *>         structural width/version error at RC8.
      *>
      *> It compiles as shipped but is NOT implemented: it returns RC12
      *> so an unfinished starter can never be mistaken for a working
      *> job.  The reference implementation is in
      *> instructor/modules/11-incidents/maintenance/M11CUST2.COB.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT CUST-IN ASSIGN TO DYNAMIC CUST-PATH
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS CUST-STAT.
       DATA DIVISION.
       FILE SECTION.
       FD CUST-IN.
       01 CUST-LINE PIC X(400).
       WORKING-STORAGE SECTION.
       01 CUST-PATH PIC X(4096).
       01 CUST-STAT PIC XX.
       PROCEDURE DIVISION.
           ACCEPT CUST-PATH FROM ENVIRONMENT 'M11CUST_INPUT'
           DISPLAY 'M11CUST2: starter not implemented' UPON STDERR
           MOVE 12 TO RETURN-CODE
           GOBACK.
