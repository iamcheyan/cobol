       IDENTIFICATION DIVISION.
       PROGRAM-ID. M05-CONTROL-FLOW-PROBE.
      *> 05.1 制御フロー実験。check.sh で実行。
      *> PERFORM VARYING：数値カウンターによる反復
      *> インライン PERFORM：PERFORM n TIMES と END-PERFORM
      *> 段落スコープ：PERFORM は段落末尾で戻る
      *> 落下：PERFORM ... THRU は次段落へ移る。
      *> Area B で起きやすい典型的な注意点。
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
