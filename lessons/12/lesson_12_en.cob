      *Lesson 12: traverse an OCCURS table with an INDEXED BY item.
      *The table index is declared in the table's OCCURS clause.
      *SET assigns and increments the index used in table references.
      *Unlike a subscript, an index has USAGE INDEX, not a numeric PIC.
      *The program displays a loaded account table in occurrence order.
      *All four entries are loaded before the indexed traversal begins.
      *No SEARCH, arithmetic on the index, or external input is used.
      *The last-entry count controls when the traversal ends.
      *This example keeps the table and traversal range synchronized.
      *No index value is displayed as though it were a numeric field.
      *Literal subscripts initialize known positions in the table.
      *Each literal writes one occurrence by its number.
      *The table entries are groups of two elementary items.
      *The index is named at OCCURS, not in WORKING-STORAGE.
      *One index selects each child of its current occurrence.
      *SET assigns the starting table occurrence explicitly.
      *SET UP BY advances the index by one table entry.
      *A numeric count can be compared with an index.
      *The loop checks its condition before displaying an account.
      *The last increment does not display another table entry.
      *No extra subscript is required on an indexed reference.
      *Field names retain their meaning under either selector.
       IDENTIFICATION DIVISION.
       PROGRAM-ID. INDEX12.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
      *Each account entry contains its key and current sample balance.
       01 WS-ACCOUNT-TABLE.
          05 WS-ACCOUNT-ENTRY OCCURS 4 TIMES
             INDEXED BY WS-ACCOUNT-IDX.
             10 WS-ACCOUNT-NUMBER PIC X(10).
             10 WS-ACCOUNT-BALANCE PIC 9(7)V99.
      *The index is implicit in INDEXED BY; it has no PIC declaration.
       01 WS-LAST-ACCOUNT PIC 9 VALUE 4.
       01 WS-PROCESSED-COUNT PIC 9(3) VALUE ZERO.
       PROCEDURE DIVISION.
      *Load every table occurrence before the index traverses it.
       0000-MAIN.
           PERFORM 1000-LOAD-ACCOUNTS
           PERFORM 2000-DISPLAY-ACCOUNTS
           PERFORM 9000-REPORT
           STOP RUN.
      *Populate each account by its ordinary numeric subscript.
       1000-LOAD-ACCOUNTS.
           MOVE "0001234567" TO WS-ACCOUNT-NUMBER(1)
           MOVE 1000.00 TO WS-ACCOUNT-BALANCE(1)
           MOVE "0007654321" TO WS-ACCOUNT-NUMBER(2)
           MOVE 250.75 TO WS-ACCOUNT-BALANCE(2)
           MOVE "0000000042" TO WS-ACCOUNT-NUMBER(3)
           MOVE 0.00 TO WS-ACCOUNT-BALANCE(3)
           MOVE "0002468101" TO WS-ACCOUNT-NUMBER(4)
           MOVE 520.00 TO WS-ACCOUNT-BALANCE(4).
      *Set the table index, visit each occurrence, then increment it.
       2000-DISPLAY-ACCOUNTS.
           SET WS-ACCOUNT-IDX TO 1
           PERFORM UNTIL WS-ACCOUNT-IDX > WS-LAST-ACCOUNT
               PERFORM 2100-DISPLAY-ONE-ACCOUNT
               SET WS-ACCOUNT-IDX UP BY 1
           END-PERFORM.
      *Use the current index in both fields of the account entry.
       2100-DISPLAY-ONE-ACCOUNT.
           DISPLAY "ACCOUNT="
               WS-ACCOUNT-NUMBER(WS-ACCOUNT-IDX)
               " BALANCE="
               WS-ACCOUNT-BALANCE(WS-ACCOUNT-IDX)
           COMPUTE WS-PROCESSED-COUNT =
               WS-PROCESSED-COUNT + 1.
      *Report how many loaded entries the indexed loop visited.
       9000-REPORT.
           DISPLAY "PROCESSED=" WS-PROCESSED-COUNT.
      *INDEXED BY declares an index associated with this OCCURS table.
      *WS-ACCOUNT-IDX is not a PIC numeric working-storage field.
      *SET WS-ACCOUNT-IDX TO 1 selects the first occurrence.
      *SET UP BY 1 advances to the next occurrence in the table.
      *Both selectors use parentheses in table references.
      *The data item declaration tells which selector is being used.
      *Lesson 11 instead used WS-SAMPLE-INDEX PIC 9(2) as a subscript.
      *A numeric subscript stores a number naming the table occurrence.
      *An index is a separate selector whose value is set with SET.
      *An index is not a PIC field for numeric calculations.
      *Use SET UP or SET DOWN to move an index through table entries.
      *The table has a declared maximum of four occurrences.
      *WS-LAST-ACCOUNT is a numeric count, not the index itself.
      *The index is compared with the populated account count.
      *After index 4, the next index is beyond the last entry.
      *The loop then ends before attempting another table reference.
      *Account numbers retain leading zeroes in the text key.
      *A zero balance still belongs to a populated entry.
      *The processed count increases once per visited occurrence.
      *The index itself is not used as the processed count.
      *All indexed fields in one group occurrence use the same index.
      *Each occurrence repeats both number and balance fields.
      *No table value is searched for or sorted by this program.
      *Lesson 13 uses table search to associate keys and records.
      *The order here is the declared occurrence order, from 1 to 4.
      *Keep the loaded entry count within the declared OCCURS bound.
      *Unloaded entries must not be treated as valid account records.
      *This is an in-memory traversal, not a file read operation.
      *GnuCOBOL supports table indexes in this fixed-format source.
      *STOP RUN ends this indexed table demonstration.
