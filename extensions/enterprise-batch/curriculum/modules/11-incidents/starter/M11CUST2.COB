       IDENTIFICATION DIVISION.
       PROGRAM-ID. M11CUST2.
      *module 11の保守課題11.5の雛形。
      *ENTERPRISE-CLASSレイアウトで管理。
      *module 07 L4の標準ENTERPRISE-CUSTOMER-V1とは別形式。
      *CUSTOMER v1のbyte 27はSTATUS（A/D）。
      *区分は別項目。1文字から2文字へ拡張。
      *（layout 001 -> 002、v1 23B -> v2 24B）。
      *固定v2スナップショットから抽出を作成。
      *
      *TODO 1: 24Bのenterprise v2（layout '002'）。
      *TODO 2: bytes 23-24の区分を取得。
      *出力形式: CLASS|<id>|xx。
      *TODO 3: 抽出ファイルと件数を書き、RC0を返す。
      *幅/版の構造エラーはRC8と。
      *
      *同梱時はコンパイル可、未実装。RC12で終了。
      *稼働中のジョブと誤認させない。参照実装:
      *instructor/modules/11-incidents/maintenance/M11CUST2.COB
      *
      *
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
