//BANKNITE JOB (ACCT),'NIGHT BATCH',CLASS=A,MSGCLASS=X,
//             NOTIFY=&SYSUID
//* ------------------------------------------------------------------
//* メインフレームJCLの例示。閲覧演習専用（10.5）
//* このファイルはコースでは実行しない。学習者がメインフレームのスケジューリング概念を
//* ローカルのGNUCOBOL/Bash JOBフローに対応付けて考えるための資料である。
//* このJCLを投入したことがあると主張してはならない。z/OS、
//* JES2、JCLランタイムは作成時に利用できなかった。
//* ------------------------------------------------------------------
//* 対応表（メインフレーム -> ローカルコース）
//*   JOB文                -> scripts/run.sh（最上位、ロックを保持）
//*   EXEC PGM/PROC         -> jobs/jobNNN-*.shノード
//*   DD入出力             -> --input / --output / --dbのパス + snapshot
//*   COND=(4,LT)           -> JOB依存：RC0のみ続行
//*   COND=(4,EQ)           -> RC4 Warningを通過（続行許可）
//*   RESTART=              -> nightly.shでmarkerベースの段階復旧
//*   return code 8/12      -> 業務／システム異常、公開なし
//* ------------------------------------------------------------------
//RECV     EXEC PGM=IKJEFT01            RECEIVE + MANIFEST verify (JOB001)
//INTRDR   DD   SYSOUT=*
//* ------------------------------------------------------------------
//VALDT    EXEC PGM=BANKVAL,COND=(4,LT,RECV)   length/business check (JOB002)
//TXIN     DD   DSN=BANK.DAY.TRANSACTION,DISP=SHR
//TXOK     DD   DSN=&&ACC,DISP=(NEW,PASS)
//TXBAD    DD   DSN=&&REJ,DISP=(NEW,PASS)
//* ------------------------------------------------------------------
//SORT     EXEC PGM=SORT,COND=(8,LT,VALDT)     SORT + order verify (JOB003)
//SORTIN   DD   DSN=&&ACC,DISP=(OLD,DELETE)
//SORTOUT  DD   DSN=&&SORTED,DISP=(NEW,PASS)
//* ------------------------------------------------------------------
//DBSNAP   EXEC PGM=BANKDB,COND=(8,LT,SORT)    DB customer snapshot (JOB004)
//SNAP     DD   DSN=BANK.DB.SNAPSHOT
//* ------------------------------------------------------------------
//MATCH    EXEC PGM=BATCHL2,COND=(8,LT,DBSNAP) sequential match (JOB005)
//ACCTIN   DD   DSN=&&SNAPACCT,DISP=SHR
//TXSORT   DD   DSN=&&SORTED,DISP=SHR
//MASTER   DD   DSN=&&CAND,DISP=(NEW,PASS)
//* ------------------------------------------------------------------
//APPLY    EXEC PGM=BANKAPLY,COND=(8,LT,MATCH) idempotent apply (JOB006)
//LEDGER   DD   DSN=BANK.DB.LEDGER,DISP=SHR
//COMMIT   DD   DSN=BANK.DB.COMMIT
//* ------------------------------------------------------------------
//CTLREP   EXEC PGM=BANKCTL,COND=(8,LT,APPLY)  control totals (JOB007)
//* ------------------------------------------------------------------
//PUBLISH  EXEC PGM=BANKPUB,COND=(8,LT,CTLREP) downstream publish (JOB008)
//* ------------------------------------------------------------------
//DONE     EXEC PGM=BANKDONE,COND=(8,LT,PUBLISH) completion (JOB009)
//*
