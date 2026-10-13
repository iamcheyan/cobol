       IDENTIFICATION DIVISION.
       PROGRAM-ID. LENGTH-PROBE.
      *> Module 02 layout experiment: intentionally-wrong, non-contract.
      *> Compiled against the canonical copybooks/ and once against
      *> experiments/layout/, it shows how a single wrong PIC shifts the
      *> record length and every following field offset. The wrong
      *> variant is a fault demo only: it is NOT a CUSTOMER v1 contract
      *> and NOT a "27->28" migration. CUSTOMER v1 stays 27 bytes with
      *> its 27th byte CUSTOMER-STATUS (A/D) only.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
           COPY "CUSTOMER-V1.CPY".
       PROCEDURE DIVISION.
           DISPLAY 'CUSTOMER-RECORD=' LENGTH OF CUSTOMER-RECORD
           DISPLAY 'NAME-LENGTH=' LENGTH OF CUSTOMER-NAME
           GOBACK.
