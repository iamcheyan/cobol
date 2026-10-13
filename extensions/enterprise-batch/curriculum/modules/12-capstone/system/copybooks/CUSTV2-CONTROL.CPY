      * CUSTV2 JOB002c control-total record grammar (key=value, '|').
      *   CONTROL|RECEIVED=<n>|ACCEPTED=<n>|REJECTED=<n>|UPGRADED=<n>
      *   REJ|BADID=<n>|BADNAME=<n>|BADSTATUS=<n>|BADCLASS=<n>|
      *   REJ|...|BADVERSION=<n>
      * A v1 enterprise feed's A/B/C/D classification is upgraded to
      * the v2 "<code>1" form (A -> A1 .. D -> D1); the record status
      * (A/D) is a separate field and is never re-labelled.
       01 CUSTV2-CONTROL-RECORD.
          05 CVCTL-TAG            PIC X(7).
          05 CVCTL-RECEIVED       PIC 9(9).
          05 CVCTL-ACCEPTED       PIC 9(9).
          05 CVCTL-REJECTED       PIC 9(9).
          05 CVCTL-UPGRADED       PIC 9(9).
          05 CVCTL-REJ-BADID      PIC 9(9).
          05 CVCTL-REJ-BADNAME    PIC 9(9).
          05 CVCTL-REJ-BADSTATUS  PIC 9(9).
          05 CVCTL-REJ-BADCLASS   PIC 9(9).
          05 CVCTL-REJ-BADVERSION PIC 9(9).
