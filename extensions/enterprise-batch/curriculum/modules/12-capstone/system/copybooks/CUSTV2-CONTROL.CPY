      *CUSTV2 JOB002d制御合計（key=value、|区切り）。
      *CONTROL|RECEIVED=<n>|ACCEPTED=<n>|REJECTED=<n>|UPGRADED=<n>
      *REJ|BADID=<n>|BADNAME=<n>|BADSTATUS=<n>|BADCLASS=<n>|
      *REJ|...|BADVERSION=<n>
      *v1区分A/B/C/Dをv2の"<code>1"形式へ変換。
      *A -> A1、B -> B1、C -> C1、D -> D1。
      *record status A/Dは別項目。名称は変更しない。
       01 CUSTV2-CONTROL-RECORD.
          05 CVCTL-TAG            PIC X(7).
          05 CVCTL-RECEIVED       PIC 9(9).
          05 CVCTL-ACCEPTED       PIC 9(9).
          05 CVCTL-REJECTED       PIC 9(9).
          05 CVCTL-UPGRADED       PIC 9(9).
          05 CVCTL-REJ-BADID      PIC 9(9).
          05 CVCTL-REJ-BADNAME    PIC 9(9).
          05 CVCTL-REJ-BADSTATUS  PIC 9(9).
          05 CVCTL-REJ-BADCLASS   PIC 9(9).
          05 CVCTL-REJ-BADVERSION PIC 9(9).
