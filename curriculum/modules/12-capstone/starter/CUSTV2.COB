       IDENTIFICATION DIVISION.
       PROGRAM-ID. CUSTV2-STARTER.
      *> STARTER for module 12 JOB002d (enterprise customer
      *> classification 1 -> 2).
      *>
      *> The v1 path is done: a 31 byte CAP-CUSTOMER-FEED v1 feed
      *> is normalized to the internal v2 form.  The v2 path is NOT
      *> implemented.
      *>
      *> TODO (student):
      *>   1. accept a 32 byte CAP-CUSTOMER-FEED v2 feed (positions
      *>      28-29 hold the 2 character classification code A1..D1,
      *>      position 27 stays the record status A/D);
      *>   2. validate the v2 code and reject BADCLASS/BADVERSION;
      *>   3. write the normalized v2 stream and the control line.
      *> Until then a v2 feed fails with RC12 and nothing is published.
      *>
      *> The customer feed is the independent enterprise layout; the
      *> 27 byte canonical CUSTOMER v1 (byte 27 = status) is unchanged.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT CUST-IN ASSIGN TO DYNAMIC I-PATH
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS I-STAT.
       DATA DIVISION.
       FILE SECTION.
       FD CUST-IN.
       01 I-LINE PIC X(400).
       WORKING-STORAGE SECTION.
       01 I-PATH PIC X(4096).
       01 O-PATH PIC X(4096).
       01 J-PATH PIC X(4096).
       01 K-PATH PIC X(4096).
       01 I-STAT PIC XX.
       01 WS-REC PIC X(400).
       01 WS-LEN PIC 9(4) COMP.
       PROCEDURE DIVISION.
           ACCEPT I-PATH FROM ENVIRONMENT 'CUSTV2_IN'
           ACCEPT O-PATH FROM ENVIRONMENT 'CUSTV2_OUT'
           ACCEPT J-PATH FROM ENVIRONMENT 'CUSTV2_REJECTED'
           ACCEPT K-PATH FROM ENVIRONMENT 'CUSTV2_CONTROL'
           IF I-PATH = SPACES
               DISPLAY 'CUSTV2 starter: missing environment' UPON STDERR
               MOVE 12 TO RETURN-CODE
               GOBACK
           END-IF
           OPEN INPUT CUST-IN
           IF I-STAT NOT = '00'
               DISPLAY 'CUSTV2 starter: cannot open input' UPON STDERR
               MOVE 12 TO RETURN-CODE
               GOBACK
           END-IF
           READ CUST-IN
               AT END CONTINUE
               NOT AT END
                   MOVE I-LINE TO WS-REC
                   COMPUTE WS-LEN =
                       FUNCTION LENGTH(FUNCTION TRIM(WS-REC))
                   IF WS-LEN = 32
                       DISPLAY 'CUSTV2 starter: v2 feed not implemented'
                         UPON STDERR
                       CLOSE CUST-IN
                       MOVE 12 TO RETURN-CODE
                       GOBACK
                   END-IF
           END-READ
           CLOSE CUST-IN
           DISPLAY 'CUSTV2 starter: TODO not implemented' UPON STDERR
           MOVE 12 TO RETURN-CODE
           GOBACK.
