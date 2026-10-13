      * Lesson 13: locate account keys in an OCCURS table.
      * SEARCH checks table entries sequentially from a set index.
      * SEARCH ALL uses binary search and requires a sorted unique key.
      * The account keys below are stored in ascending text order.
      * Both statements use an INDEXED BY table index for references.
      * A search target may be present or absent from the table.
      * AT END handles a search that reaches no matching account.
      * The table order and its ASCENDING KEY clause must agree.
      * SEARCH ALL does not sort data or check the actual key order.
      * This sample uses four fixed account entries and no file input.
       IDENTIFICATION DIVISION.
       PROGRAM-ID. SEARCH13.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
      * The key clause describes the required order for SEARCH ALL.
       01 WS-ACCOUNT-TABLE.
          05 WS-ACCOUNT-ENTRY OCCURS 4 TIMES
             ASCENDING KEY IS WS-ACCOUNT-NUMBER
             INDEXED BY WS-ACCOUNT-IDX.
             10 WS-ACCOUNT-NUMBER PIC X(10).
             10 WS-ACCOUNT-BALANCE PIC 9(7)V99.
       01 WS-SEARCH-KEY PIC X(10) VALUE SPACES.
       PROCEDURE DIVISION.
      * Search for one present key and one missing key by both methods.
       0000-MAIN.
           PERFORM 1000-LOAD-ACCOUNTS
           MOVE "0002468101" TO WS-SEARCH-KEY
           PERFORM 2000-SEQUENTIAL-SEARCH
           PERFORM 3000-BINARY-SEARCH
           MOVE "0005550000" TO WS-SEARCH-KEY
           PERFORM 2000-SEQUENTIAL-SEARCH
           PERFORM 3000-BINARY-SEARCH
           STOP RUN.
      * Load four unique account keys in ascending order.
       1000-LOAD-ACCOUNTS.
           MOVE "0000000042" TO WS-ACCOUNT-NUMBER(1)
           MOVE 0.00 TO WS-ACCOUNT-BALANCE(1)
           MOVE "0001234567" TO WS-ACCOUNT-NUMBER(2)
           MOVE 1000.00 TO WS-ACCOUNT-BALANCE(2)
           MOVE "0002468101" TO WS-ACCOUNT-NUMBER(3)
           MOVE 520.00 TO WS-ACCOUNT-BALANCE(3)
           MOVE "0007654321" TO WS-ACCOUNT-NUMBER(4)
           MOVE 250.75 TO WS-ACCOUNT-BALANCE(4).
      * SEARCH checks each entry in sequence from index 1.
       2000-SEQUENTIAL-SEARCH.
           DISPLAY "SEARCH=SEQUENTIAL KEY=" WS-SEARCH-KEY
           SET WS-ACCOUNT-IDX TO 1
           SEARCH WS-ACCOUNT-ENTRY
               AT END
                   DISPLAY "SEQUENTIAL=NOT_FOUND"
               WHEN WS-ACCOUNT-NUMBER(WS-ACCOUNT-IDX)
                   = WS-SEARCH-KEY
                   DISPLAY "SEQUENTIAL=FOUND ACCOUNT="
                       WS-ACCOUNT-NUMBER(WS-ACCOUNT-IDX)
                       " BALANCE="
                       WS-ACCOUNT-BALANCE(WS-ACCOUNT-IDX)
           END-SEARCH.
      * SEARCH ALL performs binary search over the declared key order.
       3000-BINARY-SEARCH.
           DISPLAY "SEARCH=BINARY KEY=" WS-SEARCH-KEY
           SEARCH ALL WS-ACCOUNT-ENTRY
               AT END
                   DISPLAY "BINARY=NOT_FOUND"
               WHEN WS-ACCOUNT-NUMBER(WS-ACCOUNT-IDX)
                   = WS-SEARCH-KEY
                   DISPLAY "BINARY=FOUND ACCOUNT="
                       WS-ACCOUNT-NUMBER(WS-ACCOUNT-IDX)
                       " BALANCE="
                       WS-ACCOUNT-BALANCE(WS-ACCOUNT-IDX)
           END-SEARCH.
      * SEARCH starts at the current search index, so set it to 1 first.
      * On a miss, SEARCH advances the index through every table entry.
      * SEARCH ALL selects positions while performing binary search.
      * The WHEN condition uses the same table key and search target.
      * FOUND output reads balance from the matching occurrence.
      * AT END runs after all sequential entries fail to match.
      * SEARCH ALL uses AT END when the key is not present in the table.
      * SEARCH ALL requires INDEXED BY in the OCCURS definition.
      * ASCENDING KEY states the expected order but does not create it.
      * The values loaded in 1000-LOAD-ACCOUNTS are actually ascending.
      * Account keys are unique, as required for this SEARCH ALL table.
      * Fixed-width text keys preserve leading zeroes during comparison.
      * The target 0002468101 matches the third account entry.
      * The target 0005550000 is between stored keys but is not present.
      * Both search forms report the same match or miss for valid data.
      * The sequential form can inspect entries one by one.
      * The binary form repeatedly narrows the remaining ordered range.
      * Never use SEARCH ALL on a table whose actual key order is wrong.
      * Compiler checks the key clause, not runtime value order.
      * SEARCH ALL may be wrong if the table order is wrong.
      * Duplicate keys also violate this lookup contract.
      * Review every entry when changing the key or order.
      * This program does not sort the table before searching it.
      * Lesson 14 will combine table search with account transactions.
      * The table holds four accounts in WORKING-STORAGE.
      * The index is supplied by the table's INDEXED BY clause.
      * Both searches use the same table index name.
      * No arithmetic is performed on the index.
      * The table is already loaded before either search begins.
      * Search keys and account keys have the same X(10) width.
      * The search miss is an ordinary result, not a runtime error.
      * The output identifies the search method and key for each lookup.
      * STOP RUN ends this fixed-table search demonstration.
