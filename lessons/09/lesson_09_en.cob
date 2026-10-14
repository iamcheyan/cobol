      *Lesson 09: organize one account transaction as a hierarchy.
      *A group item contains related subordinate data items.
      *An elementary item has its own PIC and stores a field value.
      *The 01 record groups customer, account, and transaction details.
      *Level numbers identify each parent-child relationship.
      *Same-level items are siblings; child levels must increase.
      *This sample uses fixed values and performs no external input.
      *Duplicate STATUS names need parent qualification.
      *Group display is shown for observation, not as a file contract.
      *No OCCURS or REDEFINES clause is used in this lesson.
      *A record group can contain groups and elementary fields.
      *Group names provide a path from the record to a field.
      *This sample uses levels 01, 05, and 10.
      *Sibling subgroups use the same 05 level number.
      *Customer and account identifiers are text keys.
      *Leading zeroes remain significant in the account number.
      *The amount is numeric, unlike its text identifiers.
      *Status fields show separate roles despite a shared name.
      *Declaration order determines each field's place in the group.
      *Parent names add business context to elementary field names.
       IDENTIFICATION DIVISION.
       PROGRAM-ID. GROUP09.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
      *The 01-level record contains three business subgroups.
       01 WS-TRANSACTION-RECORD.
      *Customer fields belong together under one 05-level group.
          05 WS-CUSTOMER-INFO.
      *Elementary items carry PIC clauses and initial sample values.
             10 WS-CUSTOMER-ID PIC X(8) VALUE "C0001042".
             10 WS-CUSTOMER-NAME PIC X(12)
                VALUE "ADA LOVELACE".
      *Account identity and account status share this parent.
          05 WS-ACCOUNT-INFO.
             10 WS-ACCOUNT-NUMBER PIC X(10)
                VALUE "0001234567".
      *STATUS is also used below, so references qualify its parent.
             10 WS-STATUS PIC X VALUE "A".
      *Transaction details form a separate group in the same record.
          05 WS-TXN-INFO.
             10 WS-TXN-ID PIC X(12) VALUE "TXN-00000001".
             10 WS-TXN-CODE PIC X VALUE "D".
      *V gives the amount two implied decimal positions.
             10 WS-TXN-AMOUNT PIC 9(5)V99 VALUE 125.50.
             10 WS-STATUS PIC X(7) VALUE "PENDING".
       PROCEDURE DIVISION.
      *Display each elementary field with its business label.
           DISPLAY "CUSTOMER ID="
               WS-CUSTOMER-ID OF WS-CUSTOMER-INFO
           DISPLAY "CUSTOMER NAME="
               WS-CUSTOMER-NAME OF WS-CUSTOMER-INFO
           DISPLAY "ACCOUNT NUMBER="
               WS-ACCOUNT-NUMBER OF WS-ACCOUNT-INFO
      *Qualifiers choose the intended STATUS elementary item.
           DISPLAY "ACCOUNT STATUS=" WS-STATUS OF WS-ACCOUNT-INFO
           DISPLAY "TRANSACTION ID=" WS-TXN-ID OF WS-TXN-INFO
           DISPLAY "TRANSACTION CODE=" WS-TXN-CODE OF WS-TXN-INFO
           DISPLAY "TRANSACTION AMOUNT="
               WS-TXN-AMOUNT OF WS-TXN-INFO
           DISPLAY "TRANSACTION STATUS=" WS-STATUS OF WS-TXN-INFO
      *A group display exposes its contiguous subordinate contents.
      *It adds no separators between fields and omits the implied V.
           DISPLAY "GROUP DATA=[" WS-TRANSACTION-RECORD "]"
           STOP RUN.
      *WS-TRANSACTION-RECORD is the top-level record group.
      *WS-CUSTOMER-INFO, WS-ACCOUNT-INFO, and WS-TXN-INFO are groups.
      *WS-CUSTOMER-ID and WS-TXN-AMOUNT are elementary data items.
      *A group has children; it does not have an elementary PIC clause.
      *Each elementary PIC defines class, width, and decimal scale.
      *Level 01 begins a record; the following 05 items belong to it.
      *Level 10 items belong to the most recent preceding 05 parent.
      *Indentation helps readers see the nested levels.
      *COBOL uses level numbers, not indentation, to define parentage.
      *The group's children occupy storage in declaration order.
      *Group data joins child contents without delimiters.
      *The amount field displays as 00125.50 when referenced by itself.
      *In the group display its digit characters appear as 0012550.
      *The implied decimal point is not stored as a group character.
      *This demonstration is not a portable interchange format.
      *The amount remains numeric when referenced directly.
      *Qualify repeated names with their parent group.
      *Account STATUS is one character under WS-ACCOUNT-INFO.
      *Transaction STATUS is seven characters under WS-TXN-INFO.
      *Qualification resolves a name; it does not rename the field.
      *A leaf can be displayed without displaying its parent group.
      *A unique field name can be referenced without a qualifier.
      *This sample uses qualifiers to disambiguate STATUS.
      *One record definition can contain multiple related components.
      *A group does not validate status or transaction-code values.
      *This 01 item is a working-storage record for the sample.
      *File records use related definitions in the FILE SECTION.
      *File layout details arrive in the file-processing phase.
      *Every field here is initialized by its elementary VALUE clause.
      *The group itself has no VALUE clause in this program.
      *No file, table, loop, input, or arithmetic is used here.
      *The next lesson will show alternate views using REDEFINES.
      *Later lessons will use OCCURS for repeated records.
      *Group items make a logical record easier to navigate and review.
      *They do not validate field contents or enforce business rules.
      *STOP RUN ends this data-structure demonstration.
