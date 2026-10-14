      * Lesson 03: post transactions and accrue simple account interest.
      * This is a teaching example, not a production interest engine.
      * All monetary data uses explicit decimal scales in its PICTURE.
      * Values begin in WORKING-STORAGE from their VALUE clauses.
      * COMPUTE evaluates arithmetic and places a result in a field.
      * MOVE copies a value; it does not add or subtract the amount.
      * Without ROUNDED, excess fractional digits are truncated.
      * One account and one fixed transaction set keep results stable.
      * The output is a ledger snapshot with no files or operator input.
       IDENTIFICATION DIVISION.
       PROGRAM-ID. MOVE03.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
      * Opening account balance before today's sample transactions.
      * Two decimal places represent cents for this lesson's example.
       01 WS-OPENING-BALANCE PIC 9(7)V99 VALUE 1000.00.
      * A credit increases the balance but is not applied by its PIC.
      * COMPUTE in the procedure performs the actual addition.
       01 WS-DEPOSIT PIC 9(7)V99 VALUE 250.55.
      * A debit is represented as a positive amount to subtract.
      * The business direction comes from the COMPUTE expression.
       01 WS-WITHDRAWAL PIC 9(7)V99 VALUE 40.10.
      * The fixed service fee is another positive amount to subtract.
      * No currency conversion or tax rule is modeled in this example.
       01 WS-SERVICE-FEE PIC 9(5)V99 VALUE 5.25.
      * The rate has four decimals; it is not text such as 1.25 percent.
      * The sample applies 0.0125 once, without a day-count adjustment.
       01 WS-PERIOD-RATE PIC 9(1)V9(4) VALUE 0.0125.
      * It receives opening balance plus credits and minus debits.
      * Its cents scale feeds the later interest calculation.
       01 WS-PRE-INTEREST-BALANCE PIC 9(7)V99 VALUE ZERO.
      * Keep four fractional digits to inspect the arithmetic result.
      * The target scale controls how many digits remain in this field.
       01 WS-INTEREST-RAW PIC 9(5)V9999 VALUE ZERO.
      * MOVE to cents demonstrates reducing scale without ROUNDED.
      * The receiver has two fractional positions rather than four.
       01 WS-INTEREST-MOVE PIC 9(5)V99 VALUE ZERO.
      * COMPUTE without ROUNDED has the same truncation behavior here.
      * Keeping both results lets learners compare the two statements.
       01 WS-INTEREST-TRUNC PIC 9(5)V99 VALUE ZERO.
      * ROUNDED requests arithmetic rounding to the receiver's scale.
      * GnuCOBOL's default mode is nearest away from zero.
       01 WS-INTEREST-ROUNDED PIC 9(5)V99 VALUE ZERO.
      * Closing balance uses the rounded interest amount for posting.
      * This explicit choice is a sample business rule for the exercise.
       01 WS-CLOSING-BALANCE PIC 9(7)V99 VALUE ZERO.
       PROCEDURE DIVISION.
      * First compute the balance after the transaction amounts.
      * Apply deposits, withdrawals, and fee in the written order.
           COMPUTE WS-PRE-INTEREST-BALANCE =
               WS-OPENING-BALANCE + WS-DEPOSIT
                   - WS-WITHDRAWAL - WS-SERVICE-FEE.
      * Multiply the cents-scale balance by the four-place rate.
      * The result has four fractional positions in this data item.
           COMPUTE WS-INTEREST-RAW =
               WS-PRE-INTEREST-BALANCE * WS-PERIOD-RATE.
      * MOVE changes scale from four fractional places to two.
      * MOVE does not use the arithmetic ROUNDED phrase.
           MOVE WS-INTEREST-RAW TO WS-INTEREST-MOVE.
      * COMPUTE can assign a numeric expression to a receiving field.
      * Without ROUNDED, extra fractional digits are truncated.
           COMPUTE WS-INTEREST-TRUNC = WS-INTEREST-RAW.
      * ROUNDED changes only the result saved in this receiving field.
      * The source field WS-INTEREST-RAW remains unchanged.
           COMPUTE WS-INTEREST-ROUNDED ROUNDED =
               WS-INTEREST-RAW.
      * Post the selected rounded amount into the closing balance.
      * Posting the rounded amount is the sample's chosen rule.
           COMPUTE WS-CLOSING-BALANCE =
               WS-PRE-INTEREST-BALANCE + WS-INTEREST-ROUNDED.
      * Display original inputs before the calculated values.
           DISPLAY "OPENING-BALANCE=" WS-OPENING-BALANCE
           DISPLAY "DEPOSIT=" WS-DEPOSIT
           DISPLAY "WITHDRAWAL=" WS-WITHDRAWAL
           DISPLAY "SERVICE-FEE=" WS-SERVICE-FEE
           DISPLAY "PERIOD-RATE=" WS-PERIOD-RATE
      * Compare the pre-interest balance and full-scale interest result.
           DISPLAY "PRE-INTEREST-BALANCE="
               WS-PRE-INTEREST-BALANCE
           DISPLAY "INTEREST-RAW-4DP=" WS-INTEREST-RAW
      * These next lines show MOVE and COMPUTE with two-place receivers.
           DISPLAY "INTEREST-MOVE-2DP=" WS-INTEREST-MOVE
           DISPLAY "INTEREST-COMPUTE-TRUNC=" WS-INTEREST-TRUNC
           DISPLAY "INTEREST-COMPUTE-ROUNDED="
               WS-INTEREST-ROUNDED
           DISPLAY "CLOSING-BALANCE=" WS-CLOSING-BALANCE
      * Every displayed amount has a declared receiving-field scale.
      * DISPLAY shows the implied point; PIC V uses no storage position.
      * The source amounts are unchanged by COMPUTE expressions here.
      * The MOVE statement changes only its receiving data item.
      * COMPUTE stores the result in the item before the equal sign.
      * A too-small receiving item can raise a size-error condition.
      * ON SIZE ERROR handles a size error explicitly.
      * The sample values fit the declared fields.
      * Real batches require documented rounding and posting rules.
      * This sample uses one account and does not read an external file.
      * Transaction validation and rejection paths are later lessons.
      * Paragraphs, loops, and conditions are also taught later.
      * STOP RUN ends the sample after displaying calculated values.
           STOP RUN.
