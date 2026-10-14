      * Lesson 10: describe two transaction layouts over shared storage.
      * REDEFINES gives two same-level data items the same storage area.
      * The transaction code tells the program which view is meaningful.
      * Deposit payload: account, amount, and transaction reference.
      * Transfer payload: source account, target account, and amount.
      * Each payload has 27 display character positions in this example.
      * The alternate view is not an automatic data conversion.
      * Values are moved through the selected elementary fields.
      * The program then shows how the other view sees those same bytes.
      * No file, external input, or table is used in this demonstration.
       IDENTIFICATION DIVISION.
       PROGRAM-ID. REDEF10.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
      * The transaction code is outside the payload being redefined.
       01 WS-TRANSACTION-RECORD.
          05 WS-TRANSACTION-CODE PIC X.
      * This subject view describes a deposit-shaped payload.
          05 WS-DEPOSIT-PAYLOAD.
             10 WS-ACCOUNT-NUMBER PIC X(10).
             10 WS-DEPOSIT-AMOUNT PIC 9(5)V99.
             10 WS-REFERENCE PIC X(10).
      * The redefining view begins at the same storage position.
          05 WS-TRANSFER-PAYLOAD REDEFINES WS-DEPOSIT-PAYLOAD.
             10 WS-SOURCE-ACCOUNT PIC X(10).
             10 WS-TARGET-ACCOUNT PIC X(10).
             10 WS-TRANSFER-AMOUNT PIC 9(5)V99.
       PROCEDURE DIVISION.
      * Show the payload first as a deposit transaction.
       0000-MAIN.
           PERFORM 1000-LOAD-DEPOSIT
           PERFORM 2000-LOAD-TRANSFER
           STOP RUN.
      * Load and display fields through the subject layout.
       1000-LOAD-DEPOSIT.
           MOVE "D" TO WS-TRANSACTION-CODE
           MOVE "0001234567" TO WS-ACCOUNT-NUMBER
           MOVE 125.50 TO WS-DEPOSIT-AMOUNT
           MOVE "TXN-000001" TO WS-REFERENCE
           DISPLAY "TYPE=" WS-TRANSACTION-CODE
           DISPLAY "DEPOSIT ACCOUNT=" WS-ACCOUNT-NUMBER
           DISPLAY "DEPOSIT AMOUNT=" WS-DEPOSIT-AMOUNT
           DISPLAY "DEPOSIT REFERENCE=" WS-REFERENCE.
      * Write a transfer through the redefining layout.
       2000-LOAD-TRANSFER.
           MOVE "T" TO WS-TRANSACTION-CODE
           MOVE "0001234567" TO WS-SOURCE-ACCOUNT
           MOVE "0007654321" TO WS-TARGET-ACCOUNT
           MOVE 250.75 TO WS-TRANSFER-AMOUNT
           DISPLAY "TYPE=" WS-TRANSACTION-CODE
           DISPLAY "TRANSFER SOURCE=" WS-SOURCE-ACCOUNT
           DISPLAY "TRANSFER TARGET=" WS-TARGET-ACCOUNT
           DISPLAY "TRANSFER AMOUNT=" WS-TRANSFER-AMOUNT
      * The subject names now read the transfer payload bytes.
           DISPLAY "DEPOSIT VIEW OF SAME BYTES:"
           DISPLAY "ACCOUNT=" WS-ACCOUNT-NUMBER
           DISPLAY "AMOUNT=" WS-DEPOSIT-AMOUNT
           DISPLAY "REFERENCE=" WS-REFERENCE.
      * Both layouts start at the same position within the record.
      * The subject and redefining item are both level 05 groups.
      * The redefining sibling follows the subject's child entries.
      * No peer level item is placed between these two definitions.
      * The deposit payload contains 10 + 7 + 10 display positions.
      * The transfer payload contains 10 + 10 + 7 display positions.
      * Both layouts therefore describe 27 positions in this example.
      * The base group is the subject named by REDEFINES.
      * The second group is the redefining object.
      * Both descriptions remain in the source program.
      * The payload has one shared set of bytes in memory.
      * The code field marks which transaction type is active.
      * Payload groups are siblings under the 01 record.
      * Their PIC clauses describe different business fields.
      * Named numeric fields display using their numeric picture.
      * Check each transaction type against its declared view.
      * GnuCOBOL requires the allocated sizes to match.
      * The redefining group and its children have no VALUE clauses.
      * PROCEDURE DIVISION MOVEs initialize both views.
      * Writing through one view changes the other view's bytes.
      * It does not copy data to a second, independent record.
      * The transaction code remains outside the shared payload.
      * Select a view using the transaction-code contract.
      * The sample uses D for deposit and T for transfer.
      * The deposit amount initially displays as 00125.50.
      * The transfer amount later displays as 00250.75.
      * In the deposit view, transfer target digits resemble an amount.
      * The first seven target digits display as 00076.54 in that view.
      * Remaining target digits join the transfer amount as reference.
      * This overlay is not a valid deposit interpretation.
      * Do not treat both views as independent transactions.
      * REDEFINES does not inspect or validate the transaction code.
      * REDEFINES does not convert data representations.
      * Field names document interpretations; they do not tag the bytes.
      * The exact layout depends on the declared PIC and USAGE clauses.
      * These display fields are used for a simple visible example.
      * Packed or binary fields would need a separate layout analysis.
      * File interchange additionally needs encoding and record rules.
      * Keep alternate layouts together to compare their size.
      * A size mismatch is a layout error, not conversion.
      * Lesson 14 will combine REDEFINES with tables and lookup logic.
      * STOP RUN ends this fixed-data storage demonstration.
