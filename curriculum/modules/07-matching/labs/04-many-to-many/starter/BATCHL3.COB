       IDENTIFICATION DIVISION.
       PROGRAM-ID. BANK-MATCH-L3-STARTER.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 TODO-FOUR-STREAM-STATE PIC X VALUE "N".
       PROCEDURE DIVISION.
       1000-MAIN.
      *> TODO 1: validate snapshot and previous-day physical bytes.
      *> TODO 2: preserve the accepted L2 hand-off and source keys.
      *> TODO 3: SORT customer-key streams; merge the four cursors.
      *> TODO 4: spool groups; never keep rows in memory.
      *> TODO 5: calculate controls and isolate ineligible sources.
           MOVE 12 TO RETURN-CODE
           GOBACK.
