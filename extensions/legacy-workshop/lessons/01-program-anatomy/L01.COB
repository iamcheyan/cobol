       IDENTIFICATION DIVISION.
       PROGRAM-ID. L01.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       PROCEDURE DIVISION.
       0000-MAIN.
           DISPLAY "IDENTIFICATION -> ENVIRONMENT -> DATA -> PROCEDURE"
           PERFORM 1000-GREET
           STOP RUN.
           1000-GREET.
               DISPLAY "A paragraph is a named procedure."
           STOP RUN.
