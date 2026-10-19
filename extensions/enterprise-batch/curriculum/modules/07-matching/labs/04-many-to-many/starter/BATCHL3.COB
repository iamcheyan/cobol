       IDENTIFICATION DIVISION.
       PROGRAM-ID. BANK-MATCH-L3-STARTER.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 TODO-FOUR-STREAM-STATE PIC X VALUE "N".
       PROCEDURE DIVISION.
       1000-MAIN.
      *> 未実装1：snapshotと前日データを物理検証。
      *> 未実装2：受理済みL2と元データキーを保持。
      *> 未実装3：顧客キーをSORTし、4カーソルを突合。
      *> 未実装4：グループをスプール。
      *> 未実装5：制御合計を算出し、対象外を分離。
           MOVE 12 TO RETURN-CODE
           GOBACK.
