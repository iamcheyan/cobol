       IDENTIFICATION DIVISION.
       PROGRAM-ID. BATCHL4-STARTER.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 TODO-MARKER PIC X VALUE "Y".
       PROCEDURE DIVISION.
       MAIN-PARA.
      * TODO: COPY the V1 layout, implement two ordered binary readers,
      * validate record framing/version/ABI/key/domains before compare,
      * compare all 175 fields using RAW/TEXT-NORM/NUMERIC/IGNORE rules,
      * redact sensitive output, verify controls, and publish safely.
           DISPLAY "TODO: B04 core is incomplete"
           MOVE 12 TO RETURN-CODE
           STOP RUN.
