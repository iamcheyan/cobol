      * 通过引用或内容传递修改链接项。
       IDENTIFICATION DIVISION.
       PROGRAM-ID. ADD-ONE.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-EDITED-AMOUNT PIC 9(9) VALUE ZERO.
       LINKAGE SECTION.
       COPY "AMOUNT-INTERFACE.CPY".
      * 按调用方与被调用方的接口约定接收参数。
      * 直接对链接字段加一，因此BY REFERENCE会改变共享
      * 存储区。
      * 通过编辑字段显示结果，然后返回调用方。
       PROCEDURE DIVISION USING AMOUNT-ARGUMENT.
       0000-ADD-ONE.
           ADD 1 TO AMOUNT-ARGUMENT
           MOVE AMOUNT-ARGUMENT TO WS-EDITED-AMOUNT
           DISPLAY "被调用方=加法后 数值=" WS-EDITED-AMOUNT
           GOBACK.
