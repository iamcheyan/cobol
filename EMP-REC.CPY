      *================================================================*
      * EMP-REC.CPY - 従業員レコード定義 COPYBOOK                       *
      *================================================================*
       01  EMP-RECORD.
           05  EMP-ID                   PIC X(05).
           05  EMP-NAME.
               10  EMP-FIRST-NAME       PIC X(10).
               10  EMP-LAST-NAME        PIC X(10).
           05  EMP-DEPT                 PIC X(02).
               88  DEPT-SALES           VALUE "01".
               88  DEPT-DEV             VALUE "02".
               88  DEPT-HR              VALUE "03".
           05  EMP-SALARY               PIC S9(7) COMP-3.
           05  EMP-STATUS               PIC X(01).
               88  EMP-ACTIVE           VALUE "A".
               88  EMP-INACTIVE         VALUE "I".
               88  EMP-SUSPENDED        VALUE "S".
