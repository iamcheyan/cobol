//BANKNITE JOB (ACCT),'NIGHT BATCH',CLASS=A,MSGCLASS=X,
//             NOTIFY=&SYSUID
//* ------------------------------------------------------------------
//* ILLUSTRATIVE MAINFRAME JCL - READING EXERCISE ONLY (10.5)
//* This file is NOT executed by the course.  It exists so learners can
//* map mainframe scheduling concepts onto the local GNUCOBOL/Bash JOB
//* flow.  Do NOT claim this JCL has ever been submitted: no z/OS,
//* JES2 or JCL runtime was available during authoring.
//* ------------------------------------------------------------------
//* Mapping key (mainframe -> local course)
//*   JOB statement        -> scripts/run.sh (top level, holds the lock)
//*   EXEC PGM/PROC         -> jobs/jobNNN-*.sh node
//*   DD input/output       -> --input / --output / --db paths + snapshot
//*   COND=(4,LT)           -> JOB dependency: only RC0 proceeds
//*   COND=(4,EQ)           -> RC4 Warning放行 (allowed to continue)
//*   RESTART=              -> marker-based stage recovery in nightly.sh
//*   return code 8/12      -> business / system failure, no publish
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
