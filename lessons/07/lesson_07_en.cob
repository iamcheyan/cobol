      * Lesson 07: organize one batch into named COBOL paragraphs.
      * The main paragraph performs initialize, process, and finalize.
      * Each named paragraph owns one stage of the batch flow.
      * PERFORM returns to the statement after the called paragraph.
      * Paragraph names are written in Area A of fixed-format source.
      * STOP RUN prevents falling into later paragraph definitions.
      * This example uses earlier MOVE and COMPUTE statements.
      * It does not contain a loop, table, or file operation.
      * Values are fixed so the call order can be checked in output.
      * Paragraphs make this flow easier to locate and maintain.
      * PROGRAM-ID sets the program name used by the compiler.
      * Execution starts at the first paragraph in PROCEDURE DIVISION.
      * Main coordinates the stages but does not contain their work.
       IDENTIFICATION DIVISION.
       PROGRAM-ID. PARAGRAPH07.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
      * The opening amount and sample transactions are fixed inputs.
       01 WS-OPENING-BALANCE PIC 9(7)V99 VALUE 1000.00.
       01 WS-DEPOSIT PIC 9(7)V99 VALUE 125.50.
       01 WS-WITHDRAWAL PIC 9(7)V99 VALUE 40.10.
      * The result is initialized in the first performed paragraph.
       01 WS-CLOSING-BALANCE PIC 9(7)V99 VALUE ZERO.
      * All amount fields use the same two-decimal scale.
      * VALUE supplies fixed examples rather than external input.
      * The closing balance starts at zero before processing.
       PROCEDURE DIVISION.
      * Program execution begins at the first procedure paragraph.
       0000-MAIN.
      * Calls run in initialize, process, and finalize order.
      * Each call runs a named paragraph and returns to this point.
      * These are procedural calls, not inline PERFORM loop blocks.
      * Each target has a paragraph definition later in the source.
           PERFORM 1000-INITIALIZE
           PERFORM 2000-PROCESS
           PERFORM 9000-FINALIZE
      * This display proves control returned to the main paragraph.
      * STOP RUN prevents ordinary flow into paragraph definitions.
      * Main is the entry path used by this standalone program.
           DISPLAY "BATCH=COMPLETE"
      * STOP RUN ends main before execution can fall into definitions.
           STOP RUN.
      * Initialize stage prepares the output field for processing.
       1000-INITIALIZE.
           DISPLAY "STAGE=INITIALIZE"
           MOVE ZERO TO WS-CLOSING-BALANCE.
      * Process stage calculates the result from the fixed inputs.
       2000-PROCESS.
           DISPLAY "STAGE=PROCESS"
           COMPUTE WS-CLOSING-BALANCE =
               WS-OPENING-BALANCE + WS-DEPOSIT - WS-WITHDRAWAL
           DISPLAY "CLOSING-BALANCE=" WS-CLOSING-BALANCE.
      * Finalize stage reports the completed batch result.
       9000-FINALIZE.
           DISPLAY "STAGE=FINALIZE"
           DISPLAY "FINAL-BALANCE=" WS-CLOSING-BALANCE.
      * Each PERFORM targets one named paragraph in this program.
      * A paragraph ends at the next name or end of procedure division.
      * Reaching the paragraph end returns control to the caller.
      * A paragraph is not a separate program or process.
      * PERFORM does not create a new WORKING-STORAGE copy.
      * All four data items remain shared program storage here.
      * The main paragraph is the top-level sequence coordinator.
      * Initialization precedes the arithmetic processing stage.
      * Finalization runs only after the process paragraph returns.
      * The closing amount is displayed after it has been calculated.
      * Paragraph names in this sample use numeric prefixes.
      * Prefixes can group related work in a larger batch program.
      * The exact naming scheme is a team convention, not syntax.
      * These paragraph names are unique within this program.
      * A paragraph label starts in Area A in fixed-format source.
      * Procedure statements and their periods are placed in Area B.
      * A period ends the current COBOL sentence and its open scopes.
      * The MOVE period ends the initialize paragraph's sentence.
      * The DISPLAY period ends the process paragraph's sentence.
      * The final DISPLAY period ends the finalize paragraph's sentence.
      * Main ends with STOP RUN before the next paragraph label.
      * This prevents ordinary flow entering a stage by accident.
      * PERFORM calls a paragraph and returns within this program.
      * Use CALL for a separately compiled program in a later lesson.
      * A later lesson combines paragraphs with repeated processing.
      * This lesson deliberately keeps one execution of each stage.
      * The MOVE changes only the closing-balance receiving field.
      * COMPUTE stores opening plus credit less debit in that field.
      * Expected arithmetic is 1000.00 + 125.50 - 40.10.
      * Paragraph order is visible as three STAGE output lines.
      * Omitting a PERFORM call removes that stage's output.
      * Reordering calls changes the visible stage order.
      * No input values are read from a terminal or external file.
      * No branch changes whether these three paragraphs are called.
      * Main reports batch completion after finalization returns.
      * The final paragraph does not terminate the program itself.
      * Control returns to main, where STOP RUN terminates execution.
      * This separation helps test and review each stage independently.
      * It also gives later file lessons named places for their work.
      * Keep calculations in the processing stage, not final reporting.
      * Keep initialization before any stage that consumes the result.
      * The example's paragraphs each contain one terminated sentence.
      * The displayed closing value confirms shared data visibility.
      * STOP RUN ends this paragraph-organization demonstration.
