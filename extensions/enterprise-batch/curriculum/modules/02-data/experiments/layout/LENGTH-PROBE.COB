       IDENTIFICATION DIVISION.
       PROGRAM-ID. LENGTH-PROBE.
      *M02形式実験。意図的な誤りで非契約。
      *正規copybooks/とexperiments/layout/を使ってそれぞれ
      *コンパイルし、誤ったPICひとつで後続の
      *
      *誤り版は故障デモ専用で、CUSTOMER v1契約でも
      *「27->28」移行でもない。CUSTOMER v1は27Bで、
      *27B目はCUSTOMER-STATUS（A/D）のみ。
       DATA DIVISION.
       WORKING-STORAGE SECTION.
           COPY "CUSTOMER-V1.CPY".
       PROCEDURE DIVISION.
           DISPLAY 'CUSTOMER-RECORD=' LENGTH OF CUSTOMER-RECORD
           DISPLAY 'NAME-LENGTH=' LENGTH OF CUSTOMER-NAME
           GOBACK.
