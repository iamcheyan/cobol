       IDENTIFICATION DIVISION.
       PROGRAM-ID. M05-CONTROL-FLOW-PROBE.
      *> Lesson 05.1 micro-lab, run by check.sh:
      *>   - PERFORM VARYING   (counted loop over a numeric counter)
      *>   - inline PERFORM    (PERFORM n TIMES, own END-PERFORM)
      *>   - paragraph scope   (PERFORM a paragraph stops at its end)
      *>   - fall-through      (PERFORM ... THRU runs into the next
      *>                        paragraph, the classic Area B trap)
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 I PIC 9(2).
       01 TOTAL PIC 9(2) VALUE 0.
       01 INLINE-TOTAL PIC 9(2) VALUE 0.
       PROCEDURE DIVISION.
       1000-MAIN.
           PERFORM VARYING I FROM 1 BY 1 UNTIL I > 5
               ADD I TO TOTAL
           END-PERFORM
           DISPLAY 'VARYING=' TOTAL
           PERFORM 2 TIMES
               ADD 10 TO INLINE-TOTAL
           END-PERFORM
           DISPLAY 'INLINE=' INLINE-TOTAL
           PERFORM 2000-FIRST
           DISPLAY 'SCOPE-DONE'
           PERFORM 2000-FIRST THRU 3000-SECOND
           DISPLAY 'THRU-DONE'
           MOVE 0 TO RETURN-CODE
           GOBACK.
       2000-FIRST.
           DISPLAY 'FIRST'.
       3000-SECOND.
           DISPLAY 'SECOND'
           CONTINUE.
