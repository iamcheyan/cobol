       IDENTIFICATION DIVISION.
       PROGRAM-ID. M05-SEARCH-ALL-PROBE.
      *> Lesson 05.2: SEARCH ALL does a binary search, so the table
      *> must really be in the declared key order. This searches the
      *> same three keys laid out sorted and unsorted.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 SORTED-TABLE.
          05 S-ENTRY OCCURS 3 TIMES
             ASCENDING KEY IS S-KEY INDEXED BY S-IX.
             10 S-KEY PIC X.
       01 UNSORTED-TABLE.
          05 U-ENTRY OCCURS 3 TIMES
             ASCENDING KEY IS U-KEY INDEXED BY U-IX.
             10 U-KEY PIC X.
       PROCEDURE DIVISION.
       1000-MAIN.
           MOVE 'A' TO S-KEY(1)
           MOVE 'M' TO S-KEY(2)
           MOVE 'Z' TO S-KEY(3)
           MOVE 'Z' TO U-KEY(1)
           MOVE 'A' TO U-KEY(2)
           MOVE 'M' TO U-KEY(3)
           SEARCH ALL S-ENTRY
             AT END DISPLAY 'SORTED=MISS'
             WHEN S-KEY(S-IX) = 'Z'
               DISPLAY 'SORTED=FOUND'
           END-SEARCH
           SEARCH ALL U-ENTRY
             AT END DISPLAY 'UNSORTED=MISS'
             WHEN U-KEY(U-IX) = 'Z'
               DISPLAY 'UNSORTED=FOUND'
           END-SEARCH
           MOVE 0 TO RETURN-CODE
           GOBACK.
