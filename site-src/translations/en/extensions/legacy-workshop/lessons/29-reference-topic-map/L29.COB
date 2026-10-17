       IDENTIFICATION DIVISION.
       PROGRAM-ID. L29.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-TOPIC-COUNT PIC 99 VALUE 30.
       PROCEDURE DIVISION.
       0000-MAIN.
           DISPLAY "Use the topic map to plan your next exercise."
           DISPLAY "Topics indexed: " WS-TOPIC-COUNT
           STOP RUN.
