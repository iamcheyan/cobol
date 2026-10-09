       IDENTIFICATION DIVISION.
       PROGRAM-ID. L21.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       PROCEDURE DIVISION.
       0000-MAIN.
           DISPLAY "Build with: cobc -x -o hello HELLO.COB"
           DISPLAY "Syntax only: cobc -fsyntax-only HELLO.COB"
           STOP RUN.
