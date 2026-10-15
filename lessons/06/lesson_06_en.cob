      * A last index of zero therefore processes no sample records.
      * The processed count records how many loop bodies actually ran.
       IDENTIFICATION DIVISION.
       PROGRAM-ID. PERFORM06.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-LAST-SAMPLE PIC 9 VALUE 3.
       01 WS-SAMPLE-INDEX PIC 9 VALUE ZERO.
       01 WS-PROCESSED-COUNT PIC 9(3) VALUE ZERO.
      * LAST-SAMPLE controls the loop's inclusive upper boundary.
      * The processed count is separate from the loop index.
       PROCEDURE DIVISION.
           DISPLAY "Last sample=" WS-LAST-SAMPLE
           PERFORM VARYING WS-SAMPLE-INDEX FROM 1 BY 1
               UNTIL WS-SAMPLE-INDEX > WS-LAST-SAMPLE
               EVALUATE WS-SAMPLE-INDEX
                   WHEN 1
                       DISPLAY "Sample=001 CODE=D AMOUNT=125.50"
                   WHEN 2
                       DISPLAY "Sample=002 CODE=W AMOUNT=040.10"
                   WHEN 3
                       DISPLAY "Sample=003 CODE=T AMOUNT=075.00"
                   WHEN OTHER
                       DISPLAY "Sample=UNMAPPED"
               END-EVALUATE
               COMPUTE WS-PROCESSED-COUNT =
                   WS-PROCESSED-COUNT + 1
           END-PERFORM
           DISPLAY "Samples processed=" WS-PROCESSED-COUNT
      * A limit above three also exercises the unmapped sample branch.
      * With last index zero, the initial test is already true.
      * The sample count is separate from the configured last index.
           STOP RUN.
