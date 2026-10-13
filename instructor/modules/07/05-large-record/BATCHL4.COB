       IDENTIFICATION DIVISION.
       PROGRAM-ID. B04L4.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT OLD-FILE ASSIGN TO DYNAMIC OLD-PATH
             ORGANIZATION IS SEQUENTIAL
             FILE STATUS IS OLD-STATUS.
           SELECT NEW-FILE ASSIGN TO DYNAMIC NEW-PATH
             ORGANIZATION IS SEQUENTIAL
             FILE STATUS IS NEW-STATUS.
       DATA DIVISION.
       FILE SECTION.
       FD OLD-FILE RECORD CONTAINS 1778 CHARACTERS.
       01 OLD-REC.
           COPY 'ENTERPRISE-CUSTOMER-V1.CPY'.
       01 OLD-RAW REDEFINES OLD-REC PIC X(1778).
       FD NEW-FILE RECORD CONTAINS 1778 CHARACTERS.
       01 NEW-REC.
           COPY 'ENTERPRISE-CUSTOMER-V1.CPY'.
       01 NEW-RAW REDEFINES NEW-REC PIC X(1778).
       WORKING-STORAGE SECTION.
       01 OLD-PATH PIC X(512).
       01 NEW-PATH PIC X(512).
       01 RUN-ID PIC X(16).
       01 OLD-STATUS PIC XX.
       01 NEW-STATUS PIC XX.
       01 OLD-LAST-KEY PIC X(10) VALUE SPACES.
       01 NEW-LAST-KEY PIC X(10) VALUE SPACES.
       01 OLD-SEEN PIC X VALUE "N".
       01 NEW-SEEN PIC X VALUE "N".
       01 BYTE-BUFFER PIC X(64).
       01 BYTE-INDEX PIC 9(3) COMP-5.
       01 BYTE-LENGTH PIC 9(3) COMP-5.
       01 SPACE-SEEN PIC X VALUE "N".
       01 OLD-EOF PIC X VALUE "N".
       01 NEW-EOF PIC X VALUE "N".
       01 RC PIC 9 VALUE 0.
       01 MATCH-COUNT PIC 9(9) VALUE 0.
       01 DIFF-COUNT PIC 9(9) VALUE 0.
       01 ONLY-OLD PIC 9(9) VALUE 0.
       01 ONLY-NEW PIC 9(9) VALUE 0.
       01 NORM-EQUAL PIC 9(9) VALUE 0.
       01 AUDIT-ONLY PIC 9(9) VALUE 0.
       01 OLD-COUNT PIC 9(9) VALUE 0.
       01 NEW-COUNT PIC 9(9) VALUE 0.
       01 REP-EQUAL PIC 9(9) VALUE 0.
       01 NORMAL-OLD PIC X(64).
       01 NORMAL-NEW PIC X(64).
       01 RAW-OLD PIC X(64).
       01 RAW-NEW PIC X(64).
       01 CTX PIC X(52).
       01 FN1 PIC X(14) VALUE "LAYOUT_VERSION".
       01 FN2 PIC X(15) VALUE "BINARY_ABI_CODE".
       01 FN3 PIC X(11) VALUE "CUSTOMER_ID".
       01 FN4 PIC X(13) VALUE "RECORD_STATUS".
       01 FN5 PIC X(13) VALUE "SOURCE_SYSTEM".
       01 FN6 PIC X(14) VALUE "EFFECTIVE_DATE".
       01 FN7 PIC X(11) VALUE "RECORD_DATE".
       01 FN8 PIC X(15) VALUE "SOURCE_BATCH_ID".
       01 FN9 PIC X(11) VALUE "REVISION_NO".
       01 FN10 PIC X(13) VALUE "LEGAL_SURNAME".
       01 FN11 PIC X(16) VALUE "LEGAL_GIVEN_NAME".
       01 FN12 PIC X(17) VALUE "LEGAL_MIDDLE_NAME".
       01 FN13 PIC X(12) VALUE "DISPLAY_NAME".
       01 FN14 PIC X(12) VALUE "KANA_SURNAME".
       01 FN15 PIC X(15) VALUE "KANA_GIVEN_NAME".
       01 FN16 PIC X(13) VALUE "LATIN_SURNAME".
       01 FN17 PIC X(16) VALUE "LATIN_GIVEN_NAME".
       01 FN18 PIC X(10) VALUE "BIRTH_DATE".
       01 FN19 PIC X(13) VALUE "BIRTH_COUNTRY".
       01 FN20 PIC X(12) VALUE "BIRTH_REGION".
       01 FN21 PIC X(16) VALUE "NATIONALITY_CODE".
       01 FN22 PIC X(16) VALUE "CITIZENSHIP_CODE".
       01 FN23 PIC X(14) VALUE "RESIDENCY_CODE".
       01 FN24 PIC X(18) VALUE "TAX_RESIDENCY_CODE".
       01 FN25 PIC X(16) VALUE "ID_DOCUMENT_TYPE".
       01 FN26 PIC X(18) VALUE "ID_DOCUMENT_MASKED".
       01 FN27 PIC X(18) VALUE "ID_DOCUMENT_EXPIRY".
       01 FN28 PIC X(10) VALUE "BIRTH_NAME".
       01 FN29 PIC X(14) VALUE "PREFERRED_NAME".
       01 FN30 PIC X(23) VALUE "CUSTOMER_CLASSIFICATION".
       01 FN31 PIC X(13) VALUE "CUSTOMER_TYPE".
       01 FN32 PIC X(16) VALUE "CUSTOMER_SEGMENT".
       01 FN33 PIC X(19) VALUE "CUSTOMER_SUBSEGMENT".
       01 FN34 PIC X(23) VALUE "RELATIONSHIP_MANAGER_ID".
       01 FN35 PIC X(14) VALUE "HOME_BRANCH_ID".
       01 FN36 PIC X(19) VALUE "CUSTOMER_SINCE_DATE".
       01 FN37 PIC X(17) VALUE "CUSTOMER_END_DATE".
       01 FN38 PIC X(18) VALUE "PREFERRED_LANGUAGE".
       01 FN39 PIC X(13) VALUE "AGE_BAND_CODE".
       01 FN40 PIC X(20) VALUE "MARKETING_PERMISSION".
       01 FN41 PIC X(19) VALUE "CUSTOMER_RISK_GRADE".
       01 FN42 PIC X(10) VALUE "KYC_STATUS".
       01 FN43 PIC X(13) VALUE "CUSTOMER_TIER".
       01 FN44 PIC X(15) VALUE "ADDRESS_COUNTRY".
       01 FN45 PIC X(11) VALUE "POSTAL_CODE".
       01 FN46 PIC X(11) VALUE "REGION_CODE".
       01 FN47 PIC X(11) VALUE "REGION_NAME".
       01 FN48 PIC X(15) VALUE "PREFECTURE_CODE".
       01 FN49 PIC X(15) VALUE "PREFECTURE_NAME".
       01 FN50 PIC X(9) VALUE "CITY_CODE".
       01 FN51 PIC X(9) VALUE "CITY_NAME".
       01 FN52 PIC X(13) VALUE "DISTRICT_NAME".
       01 FN53 PIC X(13) VALUE "STREET_LINE_1".
       01 FN54 PIC X(13) VALUE "STREET_LINE_2".
       01 FN55 PIC X(13) VALUE "STREET_LINE_3".
       01 FN56 PIC X(13) VALUE "STREET_LINE_4".
       01 FN57 PIC X(13) VALUE "BUILDING_NAME".
       01 FN58 PIC X(14) VALUE "BUILDING_FLOOR".
       01 FN59 PIC X(13) VALUE "BUILDING_ROOM".
       01 FN60 PIC X(12) VALUE "ADDRESS_KANA".
       01 FN61 PIC X(13) VALUE "ADDRESS_LATIN".
       01 FN62 PIC X(15) VALUE "POST_OFFICE_BOX".
       01 FN63 PIC X(18) VALUE "MAILING_PREFERENCE".
       01 FN64 PIC X(18) VALUE "DELIVERY_ATTENTION".
       01 FN65 PIC X(16) VALUE "TAX_JURISDICTION".
       01 FN66 PIC X(18) VALUE "ADDRESS_VALID_FROM".
       01 FN67 PIC X(16) VALUE "ADDRESS_VALID_TO".
       01 FN68 PIC X(14) VALUE "ADDRESS_SOURCE".
       01 FN69 PIC X(21) VALUE "ADDRESS_VERIFIED_DATE".
       01 FN70 PIC X(21) VALUE "PRIMARY_PHONE_COUNTRY".
       01 FN71 PIC X(18) VALUE "PRIMARY_PHONE_AREA".
       01 FN72 PIC X(20) VALUE "PRIMARY_PHONE_NUMBER".
       01 FN73 PIC X(23) VALUE "SECONDARY_PHONE_COUNTRY".
       01 FN74 PIC X(20) VALUE "SECONDARY_PHONE_AREA".
       01 FN75 PIC X(22) VALUE "SECONDARY_PHONE_NUMBER".
       01 FN76 PIC X(13) VALUE "EMAIL_ADDRESS".
       01 FN77 PIC X(15) VALUE "ALTERNATE_EMAIL".
       01 FN78 PIC X(11) VALUE "FAX_COUNTRY".
       01 FN79 PIC X(10) VALUE "FAX_NUMBER".
       01 FN80 PIC X(25) VALUE "PREFERRED_CONTACT_CHANNEL".
       01 FN81 PIC X(17) VALUE "CONTACT_TIME_FROM".
       01 FN82 PIC X(15) VALUE "CONTACT_TIME_TO".
       01 FN83 PIC X(16) VALUE "CONTACT_LANGUAGE".
       01 FN84 PIC X(11) VALUE "SMS_CONSENT".
       01 FN85 PIC X(13) VALUE "EMAIL_CONSENT".
       01 FN86 PIC X(13) VALUE "VOICE_CONSENT".
       01 FN87 PIC X(22) VALUE "NOTICE_DELIVERY_METHOD".
       01 FN88 PIC X(22) VALUE "EMERGENCY_CONTACT_NAME".
       01 FN89 PIC X(23) VALUE "EMERGENCY_RELATION_CODE".
       01 FN90 PIC X(15) VALUE "EMERGENCY_PHONE".
       01 FN91 PIC X(12) VALUE "CONTACT_NOTE".
       01 FN92 PIC X(18) VALUE "RELATIONSHIP_COUNT".
       01 FN93 PIC X(22) VALUE "PRIMARY_ACCOUNT_MASKED".
       01 FN94 PIC X(19) VALUE "PRODUCT_FAMILY_CODE".
       01 FN95 PIC X(23) VALUE "FIRST_ACCOUNT_OPEN_DATE".
       01 FN96 PIC X(23) VALUE "LAST_ACCOUNT_CLOSE_DATE".
       01 FN97 PIC X(16) VALUE "PRIMARY_CURRENCY".
       01 FN98 PIC X(20) VALUE "STATEMENT_CYCLE_CODE".
       01 FN99 PIC X(20) VALUE "OVERDRAFT_PERMISSION".
       01 FN100 PIC X(19) VALUE "DEBIT_CARD_ENROLLED".
       01 FN101 PIC X(20) VALUE "CREDIT_CARD_ENROLLED".
       01 FN102 PIC X(17) VALUE "LOAN_RELATIONSHIP".
       01 FN103 PIC X(20) VALUE "DEPOSIT_RELATIONSHIP".
       01 FN104 PIC X(20) VALUE "ACCOUNT_SERVICE_TIER".
       01 FN105 PIC X(19) VALUE "SERVICING_BRANCH_ID".
       01 FN106 PIC X(17) VALUE "ACTIVE_LOAN_COUNT".
       01 FN107 PIC X(19) VALUE "OWNERSHIP_ROLE_CODE".
       01 FN108 PIC X(22) VALUE "ACCOUNT_DIGITAL_ACCESS".
       01 FN109 PIC X(24) VALUE "ACCOUNT_RESTRICTION_CODE".
       01 FN110 PIC X(10) VALUE "RISK_SCORE".
       01 FN111 PIC X(13) VALUE "PEP_INDICATOR".
       01 FN112 PIC X(23) VALUE "SANCTIONS_SCREEN_STATUS".
       01 FN113 PIC X(17) VALUE "AML_REVIEW_STATUS".
       01 FN114 PIC X(20) VALUE "ADVERSE_MEDIA_STATUS".
       01 FN115 PIC X(16) VALUE "RISK_REVIEW_DATE".
       01 FN116 PIC X(21) VALUE "NEXT_RISK_REVIEW_DATE".
       01 FN117 PIC X(18) VALUE "RISK_SOURCE_SYSTEM".
       01 FN118 PIC X(18) VALUE "KYC_DOCUMENT_COUNT".
       01 FN119 PIC X(23) VALUE "BENEFICIAL_OWNER_STATUS".
       01 FN120 PIC X(12) VALUE "FATCA_STATUS".
       01 FN121 PIC X(10) VALUE "CRS_STATUS".
       01 FN122 PIC X(16) VALUE "TAX_COUNTRY_CODE".
       01 FN123 PIC X(28) VALUE "IDENTITY_VERIFICATION_STATUS".
       01 FN124 PIC X(19) VALUE "WATCHLIST_INDICATOR".
       01 FN125 PIC X(20) VALUE "FRAUD_RISK_INDICATOR".
       01 FN126 PIC X(20) VALUE "LAST_FRAUD_CASE_DATE".
       01 FN127 PIC X(15) VALUE "OPEN_CASE_COUNT".
       01 FN128 PIC X(21) VALUE "HIGH_RISK_REASON_CODE".
       01 FN129 PIC X(21) VALUE "RISK_SCORE_ADJUSTMENT".
       01 FN130 PIC X(20) VALUE "DAILY_TRANSFER_LIMIT".
       01 FN131 PIC X(16) VALUE "DAILY_CASH_LIMIT".
       01 FN132 PIC X(22) VALUE "MONTHLY_TRANSFER_LIMIT".
       01 FN133 PIC X(21) VALUE "PER_TRANSACTION_LIMIT".
       01 FN134 PIC X(21) VALUE "ONLINE_TRANSFER_LIMIT".
       01 FN135 PIC X(28) VALUE "INTERNATIONAL_TRANSFER_LIMIT".
       01 FN136 PIC X(20) VALUE "ATM_WITHDRAWAL_LIMIT".
       01 FN137 PIC X(18) VALUE "POS_PURCHASE_LIMIT".
       01 FN138 PIC X(19) VALUE "WIRE_TRANSFER_LIMIT".
       01 FN139 PIC X(17) VALUE "BRANCH_CASH_LIMIT".
       01 FN140 PIC X(21) VALUE "NEW_BENEFICIARY_LIMIT".
       01 FN141 PIC X(18) VALUE "ROLLING_7DAY_LIMIT".
       01 FN142 PIC X(19) VALUE "ROLLING_30DAY_LIMIT".
       01 FN143 PIC X(19) VALUE "CARD_PURCHASE_LIMIT".
       01 FN144 PIC X(18) VALUE "CASH_ADVANCE_LIMIT".
       01 FN145 PIC X(18) VALUE "LOAN_PAYMENT_LIMIT".
       01 FN146 PIC X(21) VALUE "MOBILE_TRANSFER_LIMIT".
       01 FN147 PIC X(18) VALUE "CASH_DEPOSIT_LIMIT".
       01 FN148 PIC X(22) VALUE "WEB_BANKING_PERMISSION".
       01 FN149 PIC X(25) VALUE "MOBILE_BANKING_PERMISSION".
       01 FN150 PIC X(21) VALUE "ATM_ACCESS_PERMISSION".
       01 FN151 PIC X(24) VALUE "PHONE_BANKING_PERMISSION".
       01 FN152 PIC X(25) VALUE "BRANCH_SERVICE_PERMISSION".
       01 FN153 PIC X(21) VALUE "API_ACCESS_PERMISSION".
       01 FN154 PIC X(23) VALUE "OPEN_BANKING_PERMISSION".
       01 FN155 PIC X(23) VALUE "EMAIL_NOTICE_PERMISSION".
       01 FN156 PIC X(21) VALUE "SMS_NOTICE_PERMISSION".
       01 FN157 PIC X(22) VALUE "PUSH_NOTICE_PERMISSION".
       01 FN158 PIC X(25) VALUE "BIOMETRIC_AUTH_PERMISSION".
       01 FN159 PIC X(12) VALUE "MFA_REQUIRED".
       01 FN160 PIC X(19) VALUE "VOICEPRINT_ENROLLED".
       01 FN161 PIC X(27) VALUE "CARD_NOT_PRESENT_PERMISSION".
       01 FN162 PIC X(32) VALUE "INTERNATIONAL_CHANNEL_PERMISSION".
       01 FN163 PIC X(25) VALUE "CHANNEL_PERMISSION_EXPIRY".
       01 FN164 PIC X(19) VALUE "CREATED_BY_OPERATOR".
       01 FN165 PIC X(17) VALUE "CREATED_TIMESTAMP".
       01 FN166 PIC X(19) VALUE "UPDATED_BY_OPERATOR".
       01 FN167 PIC X(17) VALUE "UPDATED_TIMESTAMP".
       01 FN168 PIC X(19) VALUE "UPDATE_SOURCE_BATCH".
       01 FN169 PIC X(20) VALUE "UPDATE_SOURCE_SYSTEM".
       01 FN170 PIC X(18) VALUE "UPDATE_SEQUENCE_NO".
       01 FN171 PIC X(17) VALUE "AUDIT_REASON_CODE".
       01 FN172 PIC X(20) VALUE "APPROVED_BY_OPERATOR".
       01 FN173 PIC X(18) VALUE "APPROVED_TIMESTAMP".
       01 FN174 PIC X(21) VALUE "LAST_REVIEW_TIMESTAMP".
       01 FN175 PIC X(10) VALUE "SYNC_STATE".
       PROCEDURE DIVISION.
       MAIN-PARA.
           ACCEPT OLD-PATH FROM ENVIRONMENT "B04_OLD"
           ACCEPT NEW-PATH FROM ENVIRONMENT "B04_NEW"
           ACCEPT RUN-ID FROM ENVIRONMENT "B04_RUN_ID"
           DISPLAY "RUN," FUNCTION TRIM(RUN-ID)
           OPEN INPUT OLD-FILE NEW-FILE
           IF OLD-STATUS NOT = "00" OR NEW-STATUS NOT = "00"
               MOVE 12 TO RETURN-CODE
               STOP RUN
           END-IF
           PERFORM READ-OLD
           PERFORM READ-NEW
           PERFORM UNTIL OLD-EOF = "Y" AND NEW-EOF = "Y"
             EVALUATE TRUE
               WHEN OLD-EOF = "Y"
                 ADD 1 TO ONLY-NEW
                 DISPLAY "NEW-ONLY,******", CUSTOMER-ID OF NEW-REC(7:4)
                 PERFORM READ-NEW
               WHEN NEW-EOF = "Y"
                 ADD 1 TO ONLY-OLD
                 DISPLAY "OLD-ONLY,******", CUSTOMER-ID OF OLD-REC(7:4)
                 PERFORM READ-OLD
               WHEN CUSTOMER-ID OF OLD-REC < CUSTOMER-ID OF NEW-REC
                 ADD 1 TO ONLY-OLD
                 DISPLAY "OLD-ONLY,******", CUSTOMER-ID OF OLD-REC(7:4)
                 PERFORM READ-OLD
               WHEN CUSTOMER-ID OF OLD-REC > CUSTOMER-ID OF NEW-REC
                 ADD 1 TO ONLY-NEW
                 DISPLAY "NEW-ONLY,******", CUSTOMER-ID OF NEW-REC(7:4)
                 PERFORM READ-NEW
               WHEN OTHER
                 ADD 1 TO MATCH-COUNT
           MOVE SPACES TO CTX
           STRING "," RUN-ID "," LAYOUT-VERSION OF OLD-REC ","
             OLD-COUNT "," NEW-COUNT ",******"
             CUSTOMER-ID OF OLD-REC(7:4)
             INTO CTX
           END-STRING
                 IF OLD-RAW(35:8) NOT =
                   NEW-RAW(35:8)
                   DISPLAY "AUDIT" CTX ",B04-HEA-006," FN7
                     ",35,8,IGNORE-AUDIT"
                   ADD 1 TO AUDIT-ONLY
                 END-IF
                 IF OLD-RAW(43:12) NOT =
                   NEW-RAW(43:12)
                   DISPLAY "AUDIT" CTX ",B04-HEA-007," FN8
                     ",43,12,IGNORE-AUDIT"
                   ADD 1 TO AUDIT-ONLY
                 END-IF
                 IF OLD-RAW(55:4) NOT =
                   NEW-RAW(55:4)
                   AND REVISION-NO OF OLD-REC =
                     REVISION-NO OF NEW-REC
                   ADD 1 TO REP-EQUAL
                 END-IF
                 IF OLD-RAW(1401:3) NOT =
                   NEW-RAW(1401:3)
                   AND RELATIONSHIP-COUNT OF OLD-REC =
                     RELATIONSHIP-COUNT OF NEW-REC
                   ADD 1 TO REP-EQUAL
                 END-IF
                 IF OLD-RAW(1458:3) NOT =
                   NEW-RAW(1458:3)
                   AND ACTIVE-LOAN-COUNT OF OLD-REC =
                     ACTIVE-LOAN-COUNT OF NEW-REC
                   ADD 1 TO REP-EQUAL
                 END-IF
                 IF OLD-RAW(1467:4) NOT =
                   NEW-RAW(1467:4)
                   AND RISK-SCORE OF OLD-REC =
                     RISK-SCORE OF NEW-REC
                   ADD 1 TO REP-EQUAL
                 END-IF
                 IF OLD-RAW(1498:3) NOT =
                   NEW-RAW(1498:3)
                   AND KYC-DOCUMENT-COUNT OF OLD-REC =
                     KYC-DOCUMENT-COUNT OF NEW-REC
                   ADD 1 TO REP-EQUAL
                 END-IF
                 IF OLD-RAW(1521:4) NOT =
                   NEW-RAW(1521:4)
                   AND OPEN-CASE-COUNT OF OLD-REC =
                     OPEN-CASE-COUNT OF NEW-REC
                   ADD 1 TO REP-EQUAL
                 END-IF
                 IF OLD-RAW(1529:6) NOT =
                   NEW-RAW(1529:6)
                   AND RISK-SCORE-ADJUSTMENT OF OLD-REC =
                     RISK-SCORE-ADJUSTMENT OF NEW-REC
                   ADD 1 TO REP-EQUAL
                 END-IF
                 IF OLD-RAW(1535:6) NOT =
                   NEW-RAW(1535:6)
                   AND DAILY-TRANSFER-LIMIT OF OLD-REC =
                     DAILY-TRANSFER-LIMIT OF NEW-REC
                   ADD 1 TO REP-EQUAL
                 END-IF
                 IF OLD-RAW(1541:6) NOT =
                   NEW-RAW(1541:6)
                   AND DAILY-CASH-LIMIT OF OLD-REC =
                     DAILY-CASH-LIMIT OF NEW-REC
                   ADD 1 TO REP-EQUAL
                 END-IF
                 IF OLD-RAW(1547:6) NOT =
                   NEW-RAW(1547:6)
                   AND MONTHLY-TRANSFER-LIMIT OF OLD-REC =
                     MONTHLY-TRANSFER-LIMIT OF NEW-REC
                   ADD 1 TO REP-EQUAL
                 END-IF
                 IF OLD-RAW(1553:6) NOT =
                   NEW-RAW(1553:6)
                   AND PER-TRANSACTION-LIMIT OF OLD-REC =
                     PER-TRANSACTION-LIMIT OF NEW-REC
                   ADD 1 TO REP-EQUAL
                 END-IF
                 IF OLD-RAW(1559:6) NOT =
                   NEW-RAW(1559:6)
                   AND ONLINE-TRANSFER-LIMIT OF OLD-REC =
                     ONLINE-TRANSFER-LIMIT OF NEW-REC
                   ADD 1 TO REP-EQUAL
                 END-IF
                 IF OLD-RAW(1565:6) NOT =
                   NEW-RAW(1565:6)
                   AND INTERNATIONAL-TRANSFER-LIMIT OF OLD-REC =
                     INTERNATIONAL-TRANSFER-LIMIT OF NEW-REC
                   ADD 1 TO REP-EQUAL
                 END-IF
                 IF OLD-RAW(1571:6) NOT =
                   NEW-RAW(1571:6)
                   AND ATM-WITHDRAWAL-LIMIT OF OLD-REC =
                     ATM-WITHDRAWAL-LIMIT OF NEW-REC
                   ADD 1 TO REP-EQUAL
                 END-IF
                 IF OLD-RAW(1577:6) NOT =
                   NEW-RAW(1577:6)
                   AND POS-PURCHASE-LIMIT OF OLD-REC =
                     POS-PURCHASE-LIMIT OF NEW-REC
                   ADD 1 TO REP-EQUAL
                 END-IF
                 IF OLD-RAW(1583:6) NOT =
                   NEW-RAW(1583:6)
                   AND WIRE-TRANSFER-LIMIT OF OLD-REC =
                     WIRE-TRANSFER-LIMIT OF NEW-REC
                   ADD 1 TO REP-EQUAL
                 END-IF
                 IF OLD-RAW(1589:6) NOT =
                   NEW-RAW(1589:6)
                   AND BRANCH-CASH-LIMIT OF OLD-REC =
                     BRANCH-CASH-LIMIT OF NEW-REC
                   ADD 1 TO REP-EQUAL
                 END-IF
                 IF OLD-RAW(1595:6) NOT =
                   NEW-RAW(1595:6)
                   AND NEW-BENEFICIARY-LIMIT OF OLD-REC =
                     NEW-BENEFICIARY-LIMIT OF NEW-REC
                   ADD 1 TO REP-EQUAL
                 END-IF
                 IF OLD-RAW(1601:6) NOT =
                   NEW-RAW(1601:6)
                   AND ROLLING-7DAY-LIMIT OF OLD-REC =
                     ROLLING-7DAY-LIMIT OF NEW-REC
                   ADD 1 TO REP-EQUAL
                 END-IF
                 IF OLD-RAW(1607:6) NOT =
                   NEW-RAW(1607:6)
                   AND ROLLING-30DAY-LIMIT OF OLD-REC =
                     ROLLING-30DAY-LIMIT OF NEW-REC
                   ADD 1 TO REP-EQUAL
                 END-IF
                 IF OLD-RAW(1613:6) NOT =
                   NEW-RAW(1613:6)
                   AND CARD-PURCHASE-LIMIT OF OLD-REC =
                     CARD-PURCHASE-LIMIT OF NEW-REC
                   ADD 1 TO REP-EQUAL
                 END-IF
                 IF OLD-RAW(1619:6) NOT =
                   NEW-RAW(1619:6)
                   AND CASH-ADVANCE-LIMIT OF OLD-REC =
                     CASH-ADVANCE-LIMIT OF NEW-REC
                   ADD 1 TO REP-EQUAL
                 END-IF
                 IF OLD-RAW(1625:6) NOT =
                   NEW-RAW(1625:6)
                   AND LOAN-PAYMENT-LIMIT OF OLD-REC =
                     LOAN-PAYMENT-LIMIT OF NEW-REC
                   ADD 1 TO REP-EQUAL
                 END-IF
                 IF OLD-RAW(1631:6) NOT =
                   NEW-RAW(1631:6)
                   AND MOBILE-TRANSFER-LIMIT OF OLD-REC =
                     MOBILE-TRANSFER-LIMIT OF NEW-REC
                   ADD 1 TO REP-EQUAL
                 END-IF
                 IF OLD-RAW(1637:6) NOT =
                   NEW-RAW(1637:6)
                   AND CASH-DEPOSIT-LIMIT OF OLD-REC =
                     CASH-DEPOSIT-LIMIT OF NEW-REC
                   ADD 1 TO REP-EQUAL
                 END-IF
                 IF OLD-RAW(1666:10) NOT =
                   NEW-RAW(1666:10)
                   DISPLAY "AUDIT" CTX ",B04-AUD-001," FN164
                     ",1666,10,IGNORE-AUDIT"
                   ADD 1 TO AUDIT-ONLY
                 END-IF
                 IF OLD-RAW(1676:14) NOT =
                   NEW-RAW(1676:14)
                   DISPLAY "AUDIT" CTX ",B04-AUD-002," FN165
                     ",1676,14,IGNORE-AUDIT"
                   ADD 1 TO AUDIT-ONLY
                 END-IF
                 IF OLD-RAW(1690:10) NOT =
                   NEW-RAW(1690:10)
                   DISPLAY "AUDIT" CTX ",B04-AUD-003," FN166
                     ",1690,10,IGNORE-AUDIT"
                   ADD 1 TO AUDIT-ONLY
                 END-IF
                 IF OLD-RAW(1700:14) NOT =
                   NEW-RAW(1700:14)
                   DISPLAY "AUDIT" CTX ",B04-AUD-004," FN167
                     ",1700,14,IGNORE-AUDIT"
                   ADD 1 TO AUDIT-ONLY
                 END-IF
                 IF OLD-RAW(1714:12) NOT =
                   NEW-RAW(1714:12)
                   DISPLAY "AUDIT" CTX ",B04-AUD-005," FN168
                     ",1714,12,IGNORE-AUDIT"
                   ADD 1 TO AUDIT-ONLY
                 END-IF
                 IF OLD-RAW(1726:4) NOT =
                   NEW-RAW(1726:4)
                   DISPLAY "AUDIT" CTX ",B04-AUD-006," FN169
                     ",1726,4,IGNORE-AUDIT"
                   ADD 1 TO AUDIT-ONLY
                 END-IF
                 IF OLD-RAW(1730:6) NOT =
                   NEW-RAW(1730:6)
                   DISPLAY "AUDIT" CTX ",B04-AUD-007," FN170
                     ",1730,6,IGNORE-AUDIT"
                   ADD 1 TO AUDIT-ONLY
                 END-IF
                 IF OLD-RAW(1736:4) NOT =
                   NEW-RAW(1736:4)
                   DISPLAY "AUDIT" CTX ",B04-AUD-008," FN171
                     ",1736,4,IGNORE-AUDIT"
                   ADD 1 TO AUDIT-ONLY
                 END-IF
                 IF OLD-RAW(1740:10) NOT =
                   NEW-RAW(1740:10)
                   DISPLAY "AUDIT" CTX ",B04-AUD-009," FN172
                     ",1740,10,IGNORE-AUDIT"
                   ADD 1 TO AUDIT-ONLY
                 END-IF
                 IF OLD-RAW(1750:14) NOT =
                   NEW-RAW(1750:14)
                   DISPLAY "AUDIT" CTX ",B04-AUD-010," FN173
                     ",1750,14,IGNORE-AUDIT"
                   ADD 1 TO AUDIT-ONLY
                 END-IF
                 IF OLD-RAW(1764:14) NOT =
                   NEW-RAW(1764:14)
                   DISPLAY "AUDIT" CTX ",B04-AUD-011," FN174
                     ",1764,14,IGNORE-AUDIT"
                   ADD 1 TO AUDIT-ONLY
                 END-IF
                 IF OLD-RAW(1778:1) NOT =
                   NEW-RAW(1778:1)
                   DISPLAY "AUDIT" CTX ",B04-AUD-012," FN175
                     ",1778,1,IGNORE-AUDIT"
                   ADD 1 TO AUDIT-ONLY
                 END-IF
                 IF LAYOUT-VERSION OF OLD-REC NOT = LAYOUT-VERSION OF
                 NEW-REC
                   DISPLAY "FIELD" CTX ",B04-HEA-001," FN1
                     ",1,3,RAW"
           DISPLAY "OLD|", LAYOUT-VERSION OF OLD-REC
           DISPLAY "NEW|", LAYOUT-VERSION OF NEW-REC
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF BINARY-ABI-CODE OF OLD-REC NOT = BINARY-ABI-CODE OF
                 NEW-REC
                   DISPLAY "FIELD" CTX ",B04-HEA-009," FN2
                     ",4,8,RAW"
           DISPLAY "OLD|", BINARY-ABI-CODE OF OLD-REC
           DISPLAY "NEW|", BINARY-ABI-CODE OF NEW-REC
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF CUSTOMER-ID OF OLD-REC NOT = CUSTOMER-ID OF NEW-REC
                   DISPLAY "FIELD" CTX ",B04-HEA-002," FN3
                     ",12,10,RAW,[REDACTED]"
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF RECORD-STATUS OF OLD-REC NOT = RECORD-STATUS OF
                 NEW-REC
                   DISPLAY "FIELD" CTX ",B04-HEA-003," FN4
                     ",22,1,RAW"
           DISPLAY "OLD|", RECORD-STATUS OF OLD-REC
           DISPLAY "NEW|", RECORD-STATUS OF NEW-REC
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF SOURCE-SYSTEM OF OLD-REC NOT = SOURCE-SYSTEM OF
                 NEW-REC
                   DISPLAY "FIELD" CTX ",B04-HEA-004," FN5
                     ",23,4,RAW"
           DISPLAY "OLD|", SOURCE-SYSTEM OF OLD-REC
           DISPLAY "NEW|", SOURCE-SYSTEM OF NEW-REC
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF EFFECTIVE-DATE OF OLD-REC NOT = EFFECTIVE-DATE OF
                 NEW-REC
                   DISPLAY "FIELD" CTX ",B04-HEA-005," FN6
                     ",27,8,RAW"
           DISPLAY "OLD|", EFFECTIVE-DATE OF OLD-REC
           DISPLAY "NEW|", EFFECTIVE-DATE OF NEW-REC
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF REVISION-NO OF OLD-REC NOT = REVISION-NO OF NEW-REC
           DISPLAY "FIELD" CTX ",B04-HEA-008," FN9
             ",55,4,NUMERIC"
           DISPLAY "OLD|", REVISION-NO OF OLD-REC
           DISPLAY "NEW|", REVISION-NO OF NEW-REC
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 MOVE LEGAL-SURNAME OF OLD-REC TO RAW-OLD
                 MOVE LEGAL-SURNAME OF NEW-REC TO RAW-NEW
                 MOVE FUNCTION UPPER-CASE(
                   FUNCTION TRIM(LEGAL-SURNAME OF OLD-REC TRAILING)
                   ) TO NORMAL-OLD
                 MOVE FUNCTION UPPER-CASE(
                   FUNCTION TRIM(LEGAL-SURNAME OF NEW-REC TRAILING)
                   ) TO NORMAL-NEW
                 IF RAW-OLD NOT = RAW-NEW
                   AND NORMAL-OLD = NORMAL-NEW
                   ADD 1 TO NORM-EQUAL
                 END-IF
                 IF NORMAL-OLD NOT = NORMAL-NEW
           DISPLAY "FIELD" CTX ",B04-IDE-001," FN10
             ",59,32,TEXT-NORM,[REDACTED]"
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 MOVE LEGAL-GIVEN-NAME OF OLD-REC TO RAW-OLD
                 MOVE LEGAL-GIVEN-NAME OF NEW-REC TO RAW-NEW
                 MOVE FUNCTION UPPER-CASE(
                   FUNCTION TRIM(LEGAL-GIVEN-NAME OF OLD-REC TRAILING)
                   ) TO NORMAL-OLD
                 MOVE FUNCTION UPPER-CASE(
                   FUNCTION TRIM(LEGAL-GIVEN-NAME OF NEW-REC TRAILING)
                   ) TO NORMAL-NEW
                 IF RAW-OLD NOT = RAW-NEW
                   AND NORMAL-OLD = NORMAL-NEW
                   ADD 1 TO NORM-EQUAL
                 END-IF
                 IF NORMAL-OLD NOT = NORMAL-NEW
           DISPLAY "FIELD" CTX ",B04-IDE-002," FN11
             ",91,32,TEXT-NORM,[REDACTED]"
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 MOVE LEGAL-MIDDLE-NAME OF OLD-REC TO RAW-OLD
                 MOVE LEGAL-MIDDLE-NAME OF NEW-REC TO RAW-NEW
                 MOVE FUNCTION UPPER-CASE(
                   FUNCTION TRIM(LEGAL-MIDDLE-NAME OF OLD-REC TRAILING)
                   ) TO NORMAL-OLD
                 MOVE FUNCTION UPPER-CASE(
                   FUNCTION TRIM(LEGAL-MIDDLE-NAME OF NEW-REC TRAILING)
                   ) TO NORMAL-NEW
                 IF RAW-OLD NOT = RAW-NEW
                   AND NORMAL-OLD = NORMAL-NEW
                   ADD 1 TO NORM-EQUAL
                 END-IF
                 IF NORMAL-OLD NOT = NORMAL-NEW
           DISPLAY "FIELD" CTX ",B04-IDE-003," FN12
             ",123,24,TEXT-NORM,[REDACTED]"
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 MOVE DISPLAY-NAME OF OLD-REC TO RAW-OLD
                 MOVE DISPLAY-NAME OF NEW-REC TO RAW-NEW
                 MOVE FUNCTION UPPER-CASE(
                   FUNCTION TRIM(DISPLAY-NAME OF OLD-REC TRAILING)
                   ) TO NORMAL-OLD
                 MOVE FUNCTION UPPER-CASE(
                   FUNCTION TRIM(DISPLAY-NAME OF NEW-REC TRAILING)
                   ) TO NORMAL-NEW
                 IF RAW-OLD NOT = RAW-NEW
                   AND NORMAL-OLD = NORMAL-NEW
                   ADD 1 TO NORM-EQUAL
                 END-IF
                 IF NORMAL-OLD NOT = NORMAL-NEW
           DISPLAY "FIELD" CTX ",B04-IDE-004," FN13
             ",147,64,TEXT-NORM,[REDACTED]"
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 MOVE KANA-SURNAME OF OLD-REC TO RAW-OLD
                 MOVE KANA-SURNAME OF NEW-REC TO RAW-NEW
                 MOVE FUNCTION UPPER-CASE(
                   FUNCTION TRIM(KANA-SURNAME OF OLD-REC TRAILING)
                   ) TO NORMAL-OLD
                 MOVE FUNCTION UPPER-CASE(
                   FUNCTION TRIM(KANA-SURNAME OF NEW-REC TRAILING)
                   ) TO NORMAL-NEW
                 IF RAW-OLD NOT = RAW-NEW
                   AND NORMAL-OLD = NORMAL-NEW
                   ADD 1 TO NORM-EQUAL
                 END-IF
                 IF NORMAL-OLD NOT = NORMAL-NEW
           DISPLAY "FIELD" CTX ",B04-IDE-005," FN14
             ",211,32,TEXT-NORM,[REDACTED]"
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 MOVE KANA-GIVEN-NAME OF OLD-REC TO RAW-OLD
                 MOVE KANA-GIVEN-NAME OF NEW-REC TO RAW-NEW
                 MOVE FUNCTION UPPER-CASE(
                   FUNCTION TRIM(KANA-GIVEN-NAME OF OLD-REC TRAILING)
                   ) TO NORMAL-OLD
                 MOVE FUNCTION UPPER-CASE(
                   FUNCTION TRIM(KANA-GIVEN-NAME OF NEW-REC TRAILING)
                   ) TO NORMAL-NEW
                 IF RAW-OLD NOT = RAW-NEW
                   AND NORMAL-OLD = NORMAL-NEW
                   ADD 1 TO NORM-EQUAL
                 END-IF
                 IF NORMAL-OLD NOT = NORMAL-NEW
           DISPLAY "FIELD" CTX ",B04-IDE-006," FN15
             ",243,32,TEXT-NORM,[REDACTED]"
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 MOVE LATIN-SURNAME OF OLD-REC TO RAW-OLD
                 MOVE LATIN-SURNAME OF NEW-REC TO RAW-NEW
                 MOVE FUNCTION UPPER-CASE(
                   FUNCTION TRIM(LATIN-SURNAME OF OLD-REC TRAILING)
                   ) TO NORMAL-OLD
                 MOVE FUNCTION UPPER-CASE(
                   FUNCTION TRIM(LATIN-SURNAME OF NEW-REC TRAILING)
                   ) TO NORMAL-NEW
                 IF RAW-OLD NOT = RAW-NEW
                   AND NORMAL-OLD = NORMAL-NEW
                   ADD 1 TO NORM-EQUAL
                 END-IF
                 IF NORMAL-OLD NOT = NORMAL-NEW
           DISPLAY "FIELD" CTX ",B04-IDE-007," FN16
             ",275,32,TEXT-NORM,[REDACTED]"
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 MOVE LATIN-GIVEN-NAME OF OLD-REC TO RAW-OLD
                 MOVE LATIN-GIVEN-NAME OF NEW-REC TO RAW-NEW
                 MOVE FUNCTION UPPER-CASE(
                   FUNCTION TRIM(LATIN-GIVEN-NAME OF OLD-REC TRAILING)
                   ) TO NORMAL-OLD
                 MOVE FUNCTION UPPER-CASE(
                   FUNCTION TRIM(LATIN-GIVEN-NAME OF NEW-REC TRAILING)
                   ) TO NORMAL-NEW
                 IF RAW-OLD NOT = RAW-NEW
                   AND NORMAL-OLD = NORMAL-NEW
                   ADD 1 TO NORM-EQUAL
                 END-IF
                 IF NORMAL-OLD NOT = NORMAL-NEW
           DISPLAY "FIELD" CTX ",B04-IDE-008," FN17
             ",307,32,TEXT-NORM,[REDACTED]"
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF BIRTH-DATE OF OLD-REC NOT = BIRTH-DATE OF NEW-REC
                   DISPLAY "FIELD" CTX ",B04-IDE-009," FN18
                     ",339,8,RAW,[REDACTED]"
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF BIRTH-COUNTRY OF OLD-REC NOT = BIRTH-COUNTRY OF
                 NEW-REC
                   DISPLAY "FIELD" CTX ",B04-IDE-010," FN19
                     ",347,2,RAW"
           DISPLAY "OLD|", BIRTH-COUNTRY OF OLD-REC
           DISPLAY "NEW|", BIRTH-COUNTRY OF NEW-REC
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF BIRTH-REGION OF OLD-REC NOT = BIRTH-REGION OF
                 NEW-REC
                   DISPLAY "FIELD" CTX ",B04-IDE-011," FN20
                     ",349,3,RAW"
           DISPLAY "OLD|", BIRTH-REGION OF OLD-REC
           DISPLAY "NEW|", BIRTH-REGION OF NEW-REC
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF NATIONALITY-CODE OF OLD-REC NOT = NATIONALITY-CODE
                 OF NEW-REC
                   DISPLAY "FIELD" CTX ",B04-IDE-012," FN21
                     ",352,2,RAW"
           DISPLAY "OLD|", NATIONALITY-CODE OF OLD-REC
           DISPLAY "NEW|", NATIONALITY-CODE OF NEW-REC
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF CITIZENSHIP-CODE OF OLD-REC NOT = CITIZENSHIP-CODE
                 OF NEW-REC
                   DISPLAY "FIELD" CTX ",B04-IDE-013," FN22
                     ",354,2,RAW"
           DISPLAY "OLD|", CITIZENSHIP-CODE OF OLD-REC
           DISPLAY "NEW|", CITIZENSHIP-CODE OF NEW-REC
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF RESIDENCY-CODE OF OLD-REC NOT = RESIDENCY-CODE OF
                 NEW-REC
                   DISPLAY "FIELD" CTX ",B04-IDE-014," FN23
                     ",356,2,RAW"
           DISPLAY "OLD|", RESIDENCY-CODE OF OLD-REC
           DISPLAY "NEW|", RESIDENCY-CODE OF NEW-REC
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF TAX-RESIDENCY-CODE OF OLD-REC NOT =
                 TAX-RESIDENCY-CODE OF NEW-REC
                   DISPLAY "FIELD" CTX ",B04-IDE-015," FN24
                     ",358,2,RAW"
           DISPLAY "OLD|", TAX-RESIDENCY-CODE OF OLD-REC
           DISPLAY "NEW|", TAX-RESIDENCY-CODE OF NEW-REC
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF ID-DOCUMENT-TYPE OF OLD-REC NOT = ID-DOCUMENT-TYPE
                 OF NEW-REC
                   DISPLAY "FIELD" CTX ",B04-IDE-016," FN25
                     ",360,4,RAW"
           DISPLAY "OLD|", ID-DOCUMENT-TYPE OF OLD-REC
           DISPLAY "NEW|", ID-DOCUMENT-TYPE OF NEW-REC
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF ID-DOCUMENT-MASKED OF OLD-REC NOT =
                 ID-DOCUMENT-MASKED OF NEW-REC
                   DISPLAY "FIELD" CTX ",B04-IDE-017," FN26
                     ",364,24,RAW,[REDACTED]"
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF ID-DOCUMENT-EXPIRY OF OLD-REC NOT =
                 ID-DOCUMENT-EXPIRY OF NEW-REC
                   DISPLAY "FIELD" CTX ",B04-IDE-018," FN27
                     ",388,8,RAW"
           DISPLAY "OLD|", ID-DOCUMENT-EXPIRY OF OLD-REC
           DISPLAY "NEW|", ID-DOCUMENT-EXPIRY OF NEW-REC
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 MOVE BIRTH-NAME OF OLD-REC TO RAW-OLD
                 MOVE BIRTH-NAME OF NEW-REC TO RAW-NEW
                 MOVE FUNCTION UPPER-CASE(
                   FUNCTION TRIM(BIRTH-NAME OF OLD-REC TRAILING)
                   ) TO NORMAL-OLD
                 MOVE FUNCTION UPPER-CASE(
                   FUNCTION TRIM(BIRTH-NAME OF NEW-REC TRAILING)
                   ) TO NORMAL-NEW
                 IF RAW-OLD NOT = RAW-NEW
                   AND NORMAL-OLD = NORMAL-NEW
                   ADD 1 TO NORM-EQUAL
                 END-IF
                 IF NORMAL-OLD NOT = NORMAL-NEW
           DISPLAY "FIELD" CTX ",B04-IDE-019," FN28
             ",396,32,TEXT-NORM,[REDACTED]"
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 MOVE PREFERRED-NAME OF OLD-REC TO RAW-OLD
                 MOVE PREFERRED-NAME OF NEW-REC TO RAW-NEW
                 MOVE FUNCTION UPPER-CASE(
                   FUNCTION TRIM(PREFERRED-NAME OF OLD-REC TRAILING)
                   ) TO NORMAL-OLD
                 MOVE FUNCTION UPPER-CASE(
                   FUNCTION TRIM(PREFERRED-NAME OF NEW-REC TRAILING)
                   ) TO NORMAL-NEW
                 IF RAW-OLD NOT = RAW-NEW
                   AND NORMAL-OLD = NORMAL-NEW
                   ADD 1 TO NORM-EQUAL
                 END-IF
                 IF NORMAL-OLD NOT = NORMAL-NEW
           DISPLAY "FIELD" CTX ",B04-IDE-020," FN29
             ",428,32,TEXT-NORM,[REDACTED]"
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF CUSTOMER-CLASSIFICATION OF OLD-REC NOT =
                 CUSTOMER-CLASSIFICATION OF NEW-REC
                   DISPLAY "FIELD" CTX ",B04-CLA-001," FN30
                     ",460,1,RAW"
           DISPLAY "OLD|", CUSTOMER-CLASSIFICATION OF OLD-REC
           DISPLAY "NEW|", CUSTOMER-CLASSIFICATION OF NEW-REC
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF CUSTOMER-TYPE OF OLD-REC NOT = CUSTOMER-TYPE OF
                 NEW-REC
                   DISPLAY "FIELD" CTX ",B04-CLA-003," FN31
                     ",461,3,RAW"
           DISPLAY "OLD|", CUSTOMER-TYPE OF OLD-REC
           DISPLAY "NEW|", CUSTOMER-TYPE OF NEW-REC
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF CUSTOMER-SEGMENT OF OLD-REC NOT = CUSTOMER-SEGMENT
                 OF NEW-REC
                   DISPLAY "FIELD" CTX ",B04-CLA-004," FN32
                     ",464,4,RAW"
           DISPLAY "OLD|", CUSTOMER-SEGMENT OF OLD-REC
           DISPLAY "NEW|", CUSTOMER-SEGMENT OF NEW-REC
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF CUSTOMER-SUBSEGMENT OF OLD-REC NOT =
                 CUSTOMER-SUBSEGMENT OF NEW-REC
                   DISPLAY "FIELD" CTX ",B04-CLA-005," FN33
                     ",468,6,RAW"
           DISPLAY "OLD|", CUSTOMER-SUBSEGMENT OF OLD-REC
           DISPLAY "NEW|", CUSTOMER-SUBSEGMENT OF NEW-REC
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF RELATIONSHIP-MANAGER-ID OF OLD-REC NOT =
                 RELATIONSHIP-MANAGER-ID OF NEW-REC
                   DISPLAY "FIELD" CTX ",B04-CLA-006," FN34
                     ",474,10,RAW"
           DISPLAY "OLD|", RELATIONSHIP-MANAGER-ID OF OLD-REC
           DISPLAY "NEW|", RELATIONSHIP-MANAGER-ID OF NEW-REC
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF HOME-BRANCH-ID OF OLD-REC NOT = HOME-BRANCH-ID OF
                 NEW-REC
                   DISPLAY "FIELD" CTX ",B04-CLA-007," FN35
                     ",484,6,RAW"
           DISPLAY "OLD|", HOME-BRANCH-ID OF OLD-REC
           DISPLAY "NEW|", HOME-BRANCH-ID OF NEW-REC
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF CUSTOMER-SINCE-DATE OF OLD-REC NOT =
                 CUSTOMER-SINCE-DATE OF NEW-REC
                   DISPLAY "FIELD" CTX ",B04-CLA-008," FN36
                     ",490,8,RAW"
           DISPLAY "OLD|", CUSTOMER-SINCE-DATE OF OLD-REC
           DISPLAY "NEW|", CUSTOMER-SINCE-DATE OF NEW-REC
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF CUSTOMER-END-DATE OF OLD-REC NOT = CUSTOMER-END-DATE
                 OF NEW-REC
                   DISPLAY "FIELD" CTX ",B04-CLA-009," FN37
                     ",498,8,RAW"
           DISPLAY "OLD|", CUSTOMER-END-DATE OF OLD-REC
           DISPLAY "NEW|", CUSTOMER-END-DATE OF NEW-REC
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF PREFERRED-LANGUAGE OF OLD-REC NOT =
                 PREFERRED-LANGUAGE OF NEW-REC
                   DISPLAY "FIELD" CTX ",B04-CLA-010," FN38
                     ",506,2,RAW"
           DISPLAY "OLD|", PREFERRED-LANGUAGE OF OLD-REC
           DISPLAY "NEW|", PREFERRED-LANGUAGE OF NEW-REC
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF AGE-BAND-CODE OF OLD-REC NOT = AGE-BAND-CODE OF
                 NEW-REC
                   DISPLAY "FIELD" CTX ",B04-CLA-011," FN39
                     ",508,2,RAW"
           DISPLAY "OLD|", AGE-BAND-CODE OF OLD-REC
           DISPLAY "NEW|", AGE-BAND-CODE OF NEW-REC
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF MARKETING-PERMISSION OF OLD-REC NOT =
                 MARKETING-PERMISSION OF NEW-REC
                   DISPLAY "FIELD" CTX ",B04-CLA-012," FN40
                     ",510,1,RAW"
           DISPLAY "OLD|", MARKETING-PERMISSION OF OLD-REC
           DISPLAY "NEW|", MARKETING-PERMISSION OF NEW-REC
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF CUSTOMER-RISK-GRADE OF OLD-REC NOT =
                 CUSTOMER-RISK-GRADE OF NEW-REC
                   DISPLAY "FIELD" CTX ",B04-CLA-013," FN41
                     ",511,2,RAW"
           DISPLAY "OLD|", CUSTOMER-RISK-GRADE OF OLD-REC
           DISPLAY "NEW|", CUSTOMER-RISK-GRADE OF NEW-REC
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF KYC-STATUS OF OLD-REC NOT = KYC-STATUS OF NEW-REC
                   DISPLAY "FIELD" CTX ",B04-CLA-014," FN42
                     ",513,2,RAW"
           DISPLAY "OLD|", KYC-STATUS OF OLD-REC
           DISPLAY "NEW|", KYC-STATUS OF NEW-REC
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF CUSTOMER-TIER OF OLD-REC NOT = CUSTOMER-TIER OF
                 NEW-REC
                   DISPLAY "FIELD" CTX ",B04-CLA-015," FN43
                     ",515,2,RAW"
           DISPLAY "OLD|", CUSTOMER-TIER OF OLD-REC
           DISPLAY "NEW|", CUSTOMER-TIER OF NEW-REC
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF ADDRESS-COUNTRY OF OLD-REC NOT = ADDRESS-COUNTRY OF
                 NEW-REC
                   DISPLAY "FIELD" CTX ",B04-ADD-001," FN44
                     ",517,2,RAW,[REDACTED]"
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF POSTAL-CODE OF OLD-REC NOT = POSTAL-CODE OF NEW-REC
                   DISPLAY "FIELD" CTX ",B04-ADD-002," FN45
                     ",519,10,RAW,[REDACTED]"
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF REGION-CODE OF OLD-REC NOT = REGION-CODE OF NEW-REC
                   DISPLAY "FIELD" CTX ",B04-ADD-003," FN46
                     ",529,4,RAW,[REDACTED]"
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 MOVE REGION-NAME OF OLD-REC TO RAW-OLD
                 MOVE REGION-NAME OF NEW-REC TO RAW-NEW
                 MOVE FUNCTION UPPER-CASE(
                   FUNCTION TRIM(REGION-NAME OF OLD-REC TRAILING)
                   ) TO NORMAL-OLD
                 MOVE FUNCTION UPPER-CASE(
                   FUNCTION TRIM(REGION-NAME OF NEW-REC TRAILING)
                   ) TO NORMAL-NEW
                 IF RAW-OLD NOT = RAW-NEW
                   AND NORMAL-OLD = NORMAL-NEW
                   ADD 1 TO NORM-EQUAL
                 END-IF
                 IF NORMAL-OLD NOT = NORMAL-NEW
           DISPLAY "FIELD" CTX ",B04-ADD-004," FN47
             ",533,32,TEXT-NORM,[REDACTED]"
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF PREFECTURE-CODE OF OLD-REC NOT = PREFECTURE-CODE OF
                 NEW-REC
                   DISPLAY "FIELD" CTX ",B04-ADD-005," FN48
                     ",565,4,RAW,[REDACTED]"
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 MOVE PREFECTURE-NAME OF OLD-REC TO RAW-OLD
                 MOVE PREFECTURE-NAME OF NEW-REC TO RAW-NEW
                 MOVE FUNCTION UPPER-CASE(
                   FUNCTION TRIM(PREFECTURE-NAME OF OLD-REC TRAILING)
                   ) TO NORMAL-OLD
                 MOVE FUNCTION UPPER-CASE(
                   FUNCTION TRIM(PREFECTURE-NAME OF NEW-REC TRAILING)
                   ) TO NORMAL-NEW
                 IF RAW-OLD NOT = RAW-NEW
                   AND NORMAL-OLD = NORMAL-NEW
                   ADD 1 TO NORM-EQUAL
                 END-IF
                 IF NORMAL-OLD NOT = NORMAL-NEW
           DISPLAY "FIELD" CTX ",B04-ADD-006," FN49
             ",569,32,TEXT-NORM,[REDACTED]"
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF CITY-CODE OF OLD-REC NOT = CITY-CODE OF NEW-REC
                   DISPLAY "FIELD" CTX ",B04-ADD-007," FN50
                     ",601,6,RAW,[REDACTED]"
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 MOVE CITY-NAME OF OLD-REC TO RAW-OLD
                 MOVE CITY-NAME OF NEW-REC TO RAW-NEW
                 MOVE FUNCTION UPPER-CASE(
                   FUNCTION TRIM(CITY-NAME OF OLD-REC TRAILING)
                   ) TO NORMAL-OLD
                 MOVE FUNCTION UPPER-CASE(
                   FUNCTION TRIM(CITY-NAME OF NEW-REC TRAILING)
                   ) TO NORMAL-NEW
                 IF RAW-OLD NOT = RAW-NEW
                   AND NORMAL-OLD = NORMAL-NEW
                   ADD 1 TO NORM-EQUAL
                 END-IF
                 IF NORMAL-OLD NOT = NORMAL-NEW
           DISPLAY "FIELD" CTX ",B04-ADD-008," FN51
             ",607,32,TEXT-NORM,[REDACTED]"
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 MOVE DISTRICT-NAME OF OLD-REC TO RAW-OLD
                 MOVE DISTRICT-NAME OF NEW-REC TO RAW-NEW
                 MOVE FUNCTION UPPER-CASE(
                   FUNCTION TRIM(DISTRICT-NAME OF OLD-REC TRAILING)
                   ) TO NORMAL-OLD
                 MOVE FUNCTION UPPER-CASE(
                   FUNCTION TRIM(DISTRICT-NAME OF NEW-REC TRAILING)
                   ) TO NORMAL-NEW
                 IF RAW-OLD NOT = RAW-NEW
                   AND NORMAL-OLD = NORMAL-NEW
                   ADD 1 TO NORM-EQUAL
                 END-IF
                 IF NORMAL-OLD NOT = NORMAL-NEW
           DISPLAY "FIELD" CTX ",B04-ADD-009," FN52
             ",639,32,TEXT-NORM,[REDACTED]"
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 MOVE STREET-LINE-1 OF OLD-REC TO RAW-OLD
                 MOVE STREET-LINE-1 OF NEW-REC TO RAW-NEW
                 MOVE FUNCTION UPPER-CASE(
                   FUNCTION TRIM(STREET-LINE-1 OF OLD-REC TRAILING)
                   ) TO NORMAL-OLD
                 MOVE FUNCTION UPPER-CASE(
                   FUNCTION TRIM(STREET-LINE-1 OF NEW-REC TRAILING)
                   ) TO NORMAL-NEW
                 IF RAW-OLD NOT = RAW-NEW
                   AND NORMAL-OLD = NORMAL-NEW
                   ADD 1 TO NORM-EQUAL
                 END-IF
                 IF NORMAL-OLD NOT = NORMAL-NEW
           DISPLAY "FIELD" CTX ",B04-ADD-010," FN53
             ",671,40,TEXT-NORM,[REDACTED]"
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 MOVE STREET-LINE-2 OF OLD-REC TO RAW-OLD
                 MOVE STREET-LINE-2 OF NEW-REC TO RAW-NEW
                 MOVE FUNCTION UPPER-CASE(
                   FUNCTION TRIM(STREET-LINE-2 OF OLD-REC TRAILING)
                   ) TO NORMAL-OLD
                 MOVE FUNCTION UPPER-CASE(
                   FUNCTION TRIM(STREET-LINE-2 OF NEW-REC TRAILING)
                   ) TO NORMAL-NEW
                 IF RAW-OLD NOT = RAW-NEW
                   AND NORMAL-OLD = NORMAL-NEW
                   ADD 1 TO NORM-EQUAL
                 END-IF
                 IF NORMAL-OLD NOT = NORMAL-NEW
           DISPLAY "FIELD" CTX ",B04-ADD-011," FN54
             ",711,40,TEXT-NORM,[REDACTED]"
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 MOVE STREET-LINE-3 OF OLD-REC TO RAW-OLD
                 MOVE STREET-LINE-3 OF NEW-REC TO RAW-NEW
                 MOVE FUNCTION UPPER-CASE(
                   FUNCTION TRIM(STREET-LINE-3 OF OLD-REC TRAILING)
                   ) TO NORMAL-OLD
                 MOVE FUNCTION UPPER-CASE(
                   FUNCTION TRIM(STREET-LINE-3 OF NEW-REC TRAILING)
                   ) TO NORMAL-NEW
                 IF RAW-OLD NOT = RAW-NEW
                   AND NORMAL-OLD = NORMAL-NEW
                   ADD 1 TO NORM-EQUAL
                 END-IF
                 IF NORMAL-OLD NOT = NORMAL-NEW
           DISPLAY "FIELD" CTX ",B04-ADD-012," FN55
             ",751,40,TEXT-NORM,[REDACTED]"
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 MOVE STREET-LINE-4 OF OLD-REC TO RAW-OLD
                 MOVE STREET-LINE-4 OF NEW-REC TO RAW-NEW
                 MOVE FUNCTION UPPER-CASE(
                   FUNCTION TRIM(STREET-LINE-4 OF OLD-REC TRAILING)
                   ) TO NORMAL-OLD
                 MOVE FUNCTION UPPER-CASE(
                   FUNCTION TRIM(STREET-LINE-4 OF NEW-REC TRAILING)
                   ) TO NORMAL-NEW
                 IF RAW-OLD NOT = RAW-NEW
                   AND NORMAL-OLD = NORMAL-NEW
                   ADD 1 TO NORM-EQUAL
                 END-IF
                 IF NORMAL-OLD NOT = NORMAL-NEW
           DISPLAY "FIELD" CTX ",B04-ADD-013," FN56
             ",791,40,TEXT-NORM,[REDACTED]"
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 MOVE BUILDING-NAME OF OLD-REC TO RAW-OLD
                 MOVE BUILDING-NAME OF NEW-REC TO RAW-NEW
                 MOVE FUNCTION UPPER-CASE(
                   FUNCTION TRIM(BUILDING-NAME OF OLD-REC TRAILING)
                   ) TO NORMAL-OLD
                 MOVE FUNCTION UPPER-CASE(
                   FUNCTION TRIM(BUILDING-NAME OF NEW-REC TRAILING)
                   ) TO NORMAL-NEW
                 IF RAW-OLD NOT = RAW-NEW
                   AND NORMAL-OLD = NORMAL-NEW
                   ADD 1 TO NORM-EQUAL
                 END-IF
                 IF NORMAL-OLD NOT = NORMAL-NEW
           DISPLAY "FIELD" CTX ",B04-ADD-014," FN57
             ",831,40,TEXT-NORM,[REDACTED]"
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF BUILDING-FLOOR OF OLD-REC NOT = BUILDING-FLOOR OF
                 NEW-REC
                   DISPLAY "FIELD" CTX ",B04-ADD-015," FN58
                     ",871,4,RAW,[REDACTED]"
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF BUILDING-ROOM OF OLD-REC NOT = BUILDING-ROOM OF
                 NEW-REC
                   DISPLAY "FIELD" CTX ",B04-ADD-016," FN59
                     ",875,8,RAW,[REDACTED]"
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 MOVE ADDRESS-KANA OF OLD-REC TO RAW-OLD
                 MOVE ADDRESS-KANA OF NEW-REC TO RAW-NEW
                 MOVE FUNCTION UPPER-CASE(
                   FUNCTION TRIM(ADDRESS-KANA OF OLD-REC TRAILING)
                   ) TO NORMAL-OLD
                 MOVE FUNCTION UPPER-CASE(
                   FUNCTION TRIM(ADDRESS-KANA OF NEW-REC TRAILING)
                   ) TO NORMAL-NEW
                 IF RAW-OLD NOT = RAW-NEW
                   AND NORMAL-OLD = NORMAL-NEW
                   ADD 1 TO NORM-EQUAL
                 END-IF
                 IF NORMAL-OLD NOT = NORMAL-NEW
           DISPLAY "FIELD" CTX ",B04-ADD-017," FN60
             ",883,40,TEXT-NORM,[REDACTED]"
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 MOVE ADDRESS-LATIN OF OLD-REC TO RAW-OLD
                 MOVE ADDRESS-LATIN OF NEW-REC TO RAW-NEW
                 MOVE FUNCTION UPPER-CASE(
                   FUNCTION TRIM(ADDRESS-LATIN OF OLD-REC TRAILING)
                   ) TO NORMAL-OLD
                 MOVE FUNCTION UPPER-CASE(
                   FUNCTION TRIM(ADDRESS-LATIN OF NEW-REC TRAILING)
                   ) TO NORMAL-NEW
                 IF RAW-OLD NOT = RAW-NEW
                   AND NORMAL-OLD = NORMAL-NEW
                   ADD 1 TO NORM-EQUAL
                 END-IF
                 IF NORMAL-OLD NOT = NORMAL-NEW
           DISPLAY "FIELD" CTX ",B04-ADD-018," FN61
             ",923,64,TEXT-NORM,[REDACTED]"
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF POST-OFFICE-BOX OF OLD-REC NOT = POST-OFFICE-BOX OF
                 NEW-REC
                   DISPLAY "FIELD" CTX ",B04-ADD-019," FN62
                     ",987,12,RAW,[REDACTED]"
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF MAILING-PREFERENCE OF OLD-REC NOT =
                 MAILING-PREFERENCE OF NEW-REC
                   DISPLAY "FIELD" CTX ",B04-ADD-020," FN63
                     ",999,1,RAW,[REDACTED]"
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 MOVE DELIVERY-ATTENTION OF OLD-REC TO RAW-OLD
                 MOVE DELIVERY-ATTENTION OF NEW-REC TO RAW-NEW
                 MOVE FUNCTION UPPER-CASE(
                   FUNCTION TRIM(DELIVERY-ATTENTION OF OLD-REC TRAILING)
                   ) TO NORMAL-OLD
                 MOVE FUNCTION UPPER-CASE(
                   FUNCTION TRIM(DELIVERY-ATTENTION OF NEW-REC TRAILING)
                   ) TO NORMAL-NEW
                 IF RAW-OLD NOT = RAW-NEW
                   AND NORMAL-OLD = NORMAL-NEW
                   ADD 1 TO NORM-EQUAL
                 END-IF
                 IF NORMAL-OLD NOT = NORMAL-NEW
           DISPLAY "FIELD" CTX ",B04-ADD-021," FN64
             ",1000,32,TEXT-NORM,[REDACTED]"
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF TAX-JURISDICTION OF OLD-REC NOT = TAX-JURISDICTION
                 OF NEW-REC
                   DISPLAY "FIELD" CTX ",B04-ADD-022," FN65
                     ",1032,4,RAW,[REDACTED]"
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF ADDRESS-VALID-FROM OF OLD-REC NOT =
                 ADDRESS-VALID-FROM OF NEW-REC
                   DISPLAY "FIELD" CTX ",B04-ADD-023," FN66
                     ",1036,8,RAW,[REDACTED]"
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF ADDRESS-VALID-TO OF OLD-REC NOT = ADDRESS-VALID-TO
                 OF NEW-REC
                   DISPLAY "FIELD" CTX ",B04-ADD-024," FN67
                     ",1044,8,RAW,[REDACTED]"
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF ADDRESS-SOURCE OF OLD-REC NOT = ADDRESS-SOURCE OF
                 NEW-REC
                   DISPLAY "FIELD" CTX ",B04-ADD-025," FN68
                     ",1052,4,RAW,[REDACTED]"
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF ADDRESS-VERIFIED-DATE OF OLD-REC NOT =
                 ADDRESS-VERIFIED-DATE OF NEW-REC
                   DISPLAY "FIELD" CTX ",B04-ADD-026," FN69
                     ",1056,8,RAW,[REDACTED]"
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF PRIMARY-PHONE-COUNTRY OF OLD-REC NOT =
                 PRIMARY-PHONE-COUNTRY OF NEW-REC
                   DISPLAY "FIELD" CTX ",B04-CON-001," FN70
                     ",1064,3,RAW,[REDACTED]"
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF PRIMARY-PHONE-AREA OF OLD-REC NOT =
                 PRIMARY-PHONE-AREA OF NEW-REC
                   DISPLAY "FIELD" CTX ",B04-CON-002," FN71
                     ",1067,6,RAW,[REDACTED]"
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF PRIMARY-PHONE-NUMBER OF OLD-REC NOT =
                 PRIMARY-PHONE-NUMBER OF NEW-REC
                   DISPLAY "FIELD" CTX ",B04-CON-003," FN72
                     ",1073,16,RAW,[REDACTED]"
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF SECONDARY-PHONE-COUNTRY OF OLD-REC NOT =
                 SECONDARY-PHONE-COUNTRY OF NEW-REC
                   DISPLAY "FIELD" CTX ",B04-CON-004," FN73
                     ",1089,3,RAW,[REDACTED]"
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF SECONDARY-PHONE-AREA OF OLD-REC NOT =
                 SECONDARY-PHONE-AREA OF NEW-REC
                   DISPLAY "FIELD" CTX ",B04-CON-005," FN74
                     ",1092,6,RAW,[REDACTED]"
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF SECONDARY-PHONE-NUMBER OF OLD-REC NOT =
                 SECONDARY-PHONE-NUMBER OF NEW-REC
                   DISPLAY "FIELD" CTX ",B04-CON-006," FN75
                     ",1098,16,RAW,[REDACTED]"
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 MOVE EMAIL-ADDRESS OF OLD-REC TO RAW-OLD
                 MOVE EMAIL-ADDRESS OF NEW-REC TO RAW-NEW
                 MOVE FUNCTION UPPER-CASE(
                   FUNCTION TRIM(EMAIL-ADDRESS OF OLD-REC TRAILING)
                   ) TO NORMAL-OLD
                 MOVE FUNCTION UPPER-CASE(
                   FUNCTION TRIM(EMAIL-ADDRESS OF NEW-REC TRAILING)
                   ) TO NORMAL-NEW
                 IF RAW-OLD NOT = RAW-NEW
                   AND NORMAL-OLD = NORMAL-NEW
                   ADD 1 TO NORM-EQUAL
                 END-IF
                 IF NORMAL-OLD NOT = NORMAL-NEW
           DISPLAY "FIELD" CTX ",B04-CON-007," FN76
             ",1114,64,TEXT-NORM,[REDACTED]"
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 MOVE ALTERNATE-EMAIL OF OLD-REC TO RAW-OLD
                 MOVE ALTERNATE-EMAIL OF NEW-REC TO RAW-NEW
                 MOVE FUNCTION UPPER-CASE(
                   FUNCTION TRIM(ALTERNATE-EMAIL OF OLD-REC TRAILING)
                   ) TO NORMAL-OLD
                 MOVE FUNCTION UPPER-CASE(
                   FUNCTION TRIM(ALTERNATE-EMAIL OF NEW-REC TRAILING)
                   ) TO NORMAL-NEW
                 IF RAW-OLD NOT = RAW-NEW
                   AND NORMAL-OLD = NORMAL-NEW
                   ADD 1 TO NORM-EQUAL
                 END-IF
                 IF NORMAL-OLD NOT = NORMAL-NEW
           DISPLAY "FIELD" CTX ",B04-CON-008," FN77
             ",1178,64,TEXT-NORM,[REDACTED]"
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF FAX-COUNTRY OF OLD-REC NOT = FAX-COUNTRY OF NEW-REC
                   DISPLAY "FIELD" CTX ",B04-CON-009," FN78
                     ",1242,3,RAW,[REDACTED]"
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF FAX-NUMBER OF OLD-REC NOT = FAX-NUMBER OF NEW-REC
                   DISPLAY "FIELD" CTX ",B04-CON-010," FN79
                     ",1245,16,RAW,[REDACTED]"
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF PREFERRED-CONTACT-CHANNEL OF OLD-REC NOT =
                 PREFERRED-CONTACT-CHANNEL OF NEW-REC
                   DISPLAY "FIELD" CTX ",B04-CON-011," FN80
                     ",1261,2,RAW,[REDACTED]"
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF CONTACT-TIME-FROM OF OLD-REC NOT = CONTACT-TIME-FROM
                 OF NEW-REC
                   DISPLAY "FIELD" CTX ",B04-CON-012," FN81
                     ",1263,4,RAW,[REDACTED]"
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF CONTACT-TIME-TO OF OLD-REC NOT = CONTACT-TIME-TO OF
                 NEW-REC
                   DISPLAY "FIELD" CTX ",B04-CON-013," FN82
                     ",1267,4,RAW,[REDACTED]"
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF CONTACT-LANGUAGE OF OLD-REC NOT = CONTACT-LANGUAGE
                 OF NEW-REC
                   DISPLAY "FIELD" CTX ",B04-CON-014," FN83
                     ",1271,2,RAW,[REDACTED]"
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF SMS-CONSENT OF OLD-REC NOT = SMS-CONSENT OF NEW-REC
                   DISPLAY "FIELD" CTX ",B04-CON-015," FN84
                     ",1273,1,RAW,[REDACTED]"
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF EMAIL-CONSENT OF OLD-REC NOT = EMAIL-CONSENT OF
                 NEW-REC
                   DISPLAY "FIELD" CTX ",B04-CON-016," FN85
                     ",1274,1,RAW,[REDACTED]"
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF VOICE-CONSENT OF OLD-REC NOT = VOICE-CONSENT OF
                 NEW-REC
                   DISPLAY "FIELD" CTX ",B04-CON-017," FN86
                     ",1275,1,RAW,[REDACTED]"
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF NOTICE-DELIVERY-METHOD OF OLD-REC NOT =
                 NOTICE-DELIVERY-METHOD OF NEW-REC
                   DISPLAY "FIELD" CTX ",B04-CON-018," FN87
                     ",1276,2,RAW,[REDACTED]"
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 MOVE EMERGENCY-CONTACT-NAME OF OLD-REC TO RAW-OLD
                 MOVE EMERGENCY-CONTACT-NAME OF NEW-REC TO RAW-NEW
                 MOVE FUNCTION UPPER-CASE(
                   FUNCTION TRIM(EMERGENCY-CONTACT-NAME OF OLD-REC
                   TRAILING)
                   ) TO NORMAL-OLD
                 MOVE FUNCTION UPPER-CASE(
                   FUNCTION TRIM(EMERGENCY-CONTACT-NAME OF NEW-REC
                   TRAILING)
                   ) TO NORMAL-NEW
                 IF RAW-OLD NOT = RAW-NEW
                   AND NORMAL-OLD = NORMAL-NEW
                   ADD 1 TO NORM-EQUAL
                 END-IF
                 IF NORMAL-OLD NOT = NORMAL-NEW
           DISPLAY "FIELD" CTX ",B04-CON-019," FN88
             ",1278,32,TEXT-NORM,[REDACTED]"
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF EMERGENCY-RELATION-CODE OF OLD-REC NOT =
                 EMERGENCY-RELATION-CODE OF NEW-REC
                   DISPLAY "FIELD" CTX ",B04-CON-020," FN89
                     ",1310,3,RAW,[REDACTED]"
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF EMERGENCY-PHONE OF OLD-REC NOT = EMERGENCY-PHONE OF
                 NEW-REC
                   DISPLAY "FIELD" CTX ",B04-CON-021," FN90
                     ",1313,24,RAW,[REDACTED]"
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 MOVE CONTACT-NOTE OF OLD-REC TO RAW-OLD
                 MOVE CONTACT-NOTE OF NEW-REC TO RAW-NEW
                 MOVE FUNCTION UPPER-CASE(
                   FUNCTION TRIM(CONTACT-NOTE OF OLD-REC TRAILING)
                   ) TO NORMAL-OLD
                 MOVE FUNCTION UPPER-CASE(
                   FUNCTION TRIM(CONTACT-NOTE OF NEW-REC TRAILING)
                   ) TO NORMAL-NEW
                 IF RAW-OLD NOT = RAW-NEW
                   AND NORMAL-OLD = NORMAL-NEW
                   ADD 1 TO NORM-EQUAL
                 END-IF
                 IF NORMAL-OLD NOT = NORMAL-NEW
           DISPLAY "FIELD" CTX ",B04-CON-022," FN91
             ",1337,64,TEXT-NORM,[REDACTED]"
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF RELATIONSHIP-COUNT OF OLD-REC NOT =
                 RELATIONSHIP-COUNT OF NEW-REC
           DISPLAY "FIELD" CTX ",B04-BAN-001," FN92
             ",1401,3,NUMERIC"
           DISPLAY "OLD|", RELATIONSHIP-COUNT OF OLD-REC
           DISPLAY "NEW|", RELATIONSHIP-COUNT OF NEW-REC
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF PRIMARY-ACCOUNT-MASKED OF OLD-REC NOT =
                 PRIMARY-ACCOUNT-MASKED OF NEW-REC
                   DISPLAY "FIELD" CTX ",B04-BAN-002," FN93
                     ",1404,16,RAW,[REDACTED]"
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF PRODUCT-FAMILY-CODE OF OLD-REC NOT =
                 PRODUCT-FAMILY-CODE OF NEW-REC
                   DISPLAY "FIELD" CTX ",B04-BAN-003," FN94
                     ",1420,4,RAW"
           DISPLAY "OLD|", PRODUCT-FAMILY-CODE OF OLD-REC
           DISPLAY "NEW|", PRODUCT-FAMILY-CODE OF NEW-REC
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF FIRST-ACCOUNT-OPEN-DATE OF OLD-REC NOT =
                 FIRST-ACCOUNT-OPEN-DATE OF NEW-REC
                   DISPLAY "FIELD" CTX ",B04-BAN-004," FN95
                     ",1424,8,RAW"
           DISPLAY "OLD|", FIRST-ACCOUNT-OPEN-DATE OF OLD-REC
           DISPLAY "NEW|", FIRST-ACCOUNT-OPEN-DATE OF NEW-REC
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF LAST-ACCOUNT-CLOSE-DATE OF OLD-REC NOT =
                 LAST-ACCOUNT-CLOSE-DATE OF NEW-REC
                   DISPLAY "FIELD" CTX ",B04-BAN-005," FN96
                     ",1432,8,RAW"
           DISPLAY "OLD|", LAST-ACCOUNT-CLOSE-DATE OF OLD-REC
           DISPLAY "NEW|", LAST-ACCOUNT-CLOSE-DATE OF NEW-REC
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF PRIMARY-CURRENCY OF OLD-REC NOT = PRIMARY-CURRENCY
                 OF NEW-REC
                   DISPLAY "FIELD" CTX ",B04-BAN-006," FN97
                     ",1440,3,RAW"
           DISPLAY "OLD|", PRIMARY-CURRENCY OF OLD-REC
           DISPLAY "NEW|", PRIMARY-CURRENCY OF NEW-REC
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF STATEMENT-CYCLE-CODE OF OLD-REC NOT =
                 STATEMENT-CYCLE-CODE OF NEW-REC
                   DISPLAY "FIELD" CTX ",B04-BAN-007," FN98
                     ",1443,2,RAW"
           DISPLAY "OLD|", STATEMENT-CYCLE-CODE OF OLD-REC
           DISPLAY "NEW|", STATEMENT-CYCLE-CODE OF NEW-REC
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF OVERDRAFT-PERMISSION OF OLD-REC NOT =
                 OVERDRAFT-PERMISSION OF NEW-REC
                   DISPLAY "FIELD" CTX ",B04-BAN-008," FN99
                     ",1445,1,RAW"
           DISPLAY "OLD|", OVERDRAFT-PERMISSION OF OLD-REC
           DISPLAY "NEW|", OVERDRAFT-PERMISSION OF NEW-REC
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF DEBIT-CARD-ENROLLED OF OLD-REC NOT =
                 DEBIT-CARD-ENROLLED OF NEW-REC
                   DISPLAY "FIELD" CTX ",B04-BAN-009," FN100
                     ",1446,1,RAW"
           DISPLAY "OLD|", DEBIT-CARD-ENROLLED OF OLD-REC
           DISPLAY "NEW|", DEBIT-CARD-ENROLLED OF NEW-REC
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF CREDIT-CARD-ENROLLED OF OLD-REC NOT =
                 CREDIT-CARD-ENROLLED OF NEW-REC
                   DISPLAY "FIELD" CTX ",B04-BAN-010," FN101
                     ",1447,1,RAW"
           DISPLAY "OLD|", CREDIT-CARD-ENROLLED OF OLD-REC
           DISPLAY "NEW|", CREDIT-CARD-ENROLLED OF NEW-REC
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF LOAN-RELATIONSHIP OF OLD-REC NOT = LOAN-RELATIONSHIP
                 OF NEW-REC
                   DISPLAY "FIELD" CTX ",B04-BAN-011," FN102
                     ",1448,1,RAW"
           DISPLAY "OLD|", LOAN-RELATIONSHIP OF OLD-REC
           DISPLAY "NEW|", LOAN-RELATIONSHIP OF NEW-REC
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF DEPOSIT-RELATIONSHIP OF OLD-REC NOT =
                 DEPOSIT-RELATIONSHIP OF NEW-REC
                   DISPLAY "FIELD" CTX ",B04-BAN-012," FN103
                     ",1449,1,RAW"
           DISPLAY "OLD|", DEPOSIT-RELATIONSHIP OF OLD-REC
           DISPLAY "NEW|", DEPOSIT-RELATIONSHIP OF NEW-REC
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF ACCOUNT-SERVICE-TIER OF OLD-REC NOT =
                 ACCOUNT-SERVICE-TIER OF NEW-REC
                   DISPLAY "FIELD" CTX ",B04-BAN-013," FN104
                     ",1450,2,RAW"
           DISPLAY "OLD|", ACCOUNT-SERVICE-TIER OF OLD-REC
           DISPLAY "NEW|", ACCOUNT-SERVICE-TIER OF NEW-REC
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF SERVICING-BRANCH-ID OF OLD-REC NOT =
                 SERVICING-BRANCH-ID OF NEW-REC
                   DISPLAY "FIELD" CTX ",B04-BAN-014," FN105
                     ",1452,6,RAW"
           DISPLAY "OLD|", SERVICING-BRANCH-ID OF OLD-REC
           DISPLAY "NEW|", SERVICING-BRANCH-ID OF NEW-REC
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF ACTIVE-LOAN-COUNT OF OLD-REC NOT = ACTIVE-LOAN-COUNT
                 OF NEW-REC
           DISPLAY "FIELD" CTX ",B04-BAN-015," FN106
             ",1458,3,NUMERIC"
           DISPLAY "OLD|", ACTIVE-LOAN-COUNT OF OLD-REC
           DISPLAY "NEW|", ACTIVE-LOAN-COUNT OF NEW-REC
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF OWNERSHIP-ROLE-CODE OF OLD-REC NOT =
                 OWNERSHIP-ROLE-CODE OF NEW-REC
                   DISPLAY "FIELD" CTX ",B04-BAN-016," FN107
                     ",1461,2,RAW"
           DISPLAY "OLD|", OWNERSHIP-ROLE-CODE OF OLD-REC
           DISPLAY "NEW|", OWNERSHIP-ROLE-CODE OF NEW-REC
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF ACCOUNT-DIGITAL-ACCESS OF OLD-REC NOT =
                 ACCOUNT-DIGITAL-ACCESS OF NEW-REC
                   DISPLAY "FIELD" CTX ",B04-BAN-017," FN108
                     ",1463,1,RAW"
           DISPLAY "OLD|", ACCOUNT-DIGITAL-ACCESS OF OLD-REC
           DISPLAY "NEW|", ACCOUNT-DIGITAL-ACCESS OF NEW-REC
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF ACCOUNT-RESTRICTION-CODE OF OLD-REC NOT =
                 ACCOUNT-RESTRICTION-CODE OF NEW-REC
                   DISPLAY "FIELD" CTX ",B04-BAN-018," FN109
                     ",1464,3,RAW"
           DISPLAY "OLD|", ACCOUNT-RESTRICTION-CODE OF OLD-REC
           DISPLAY "NEW|", ACCOUNT-RESTRICTION-CODE OF NEW-REC
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF RISK-SCORE OF OLD-REC NOT = RISK-SCORE OF NEW-REC
                   DISPLAY "FIELD" CTX ",B04-RIS-001," FN110
                     ",1467,4,NUMERIC,[REDACTED]"
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF PEP-INDICATOR OF OLD-REC NOT = PEP-INDICATOR OF
                 NEW-REC
                   DISPLAY "FIELD" CTX ",B04-RIS-002," FN111
                     ",1471,1,RAW,[REDACTED]"
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF SANCTIONS-SCREEN-STATUS OF OLD-REC NOT =
                 SANCTIONS-SCREEN-STATUS OF NEW-REC
                   DISPLAY "FIELD" CTX ",B04-RIS-003," FN112
                     ",1472,2,RAW,[REDACTED]"
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF AML-REVIEW-STATUS OF OLD-REC NOT = AML-REVIEW-STATUS
                 OF NEW-REC
                   DISPLAY "FIELD" CTX ",B04-RIS-004," FN113
                     ",1474,2,RAW,[REDACTED]"
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF ADVERSE-MEDIA-STATUS OF OLD-REC NOT =
                 ADVERSE-MEDIA-STATUS OF NEW-REC
                   DISPLAY "FIELD" CTX ",B04-RIS-005," FN114
                     ",1476,2,RAW,[REDACTED]"
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF RISK-REVIEW-DATE OF OLD-REC NOT = RISK-REVIEW-DATE
                 OF NEW-REC
                   DISPLAY "FIELD" CTX ",B04-RIS-006," FN115
                     ",1478,8,RAW,[REDACTED]"
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF NEXT-RISK-REVIEW-DATE OF OLD-REC NOT =
                 NEXT-RISK-REVIEW-DATE OF NEW-REC
                   DISPLAY "FIELD" CTX ",B04-RIS-007," FN116
                     ",1486,8,RAW,[REDACTED]"
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF RISK-SOURCE-SYSTEM OF OLD-REC NOT =
                 RISK-SOURCE-SYSTEM OF NEW-REC
                   DISPLAY "FIELD" CTX ",B04-RIS-008," FN117
                     ",1494,4,RAW,[REDACTED]"
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF KYC-DOCUMENT-COUNT OF OLD-REC NOT =
                 KYC-DOCUMENT-COUNT OF NEW-REC
                   DISPLAY "FIELD" CTX ",B04-RIS-009," FN118
                     ",1498,3,NUMERIC,[REDACTED]"
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF BENEFICIAL-OWNER-STATUS OF OLD-REC NOT =
                 BENEFICIAL-OWNER-STATUS OF NEW-REC
                   DISPLAY "FIELD" CTX ",B04-RIS-010," FN119
                     ",1501,2,RAW,[REDACTED]"
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF FATCA-STATUS OF OLD-REC NOT = FATCA-STATUS OF
                 NEW-REC
                   DISPLAY "FIELD" CTX ",B04-RIS-011," FN120
                     ",1503,2,RAW,[REDACTED]"
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF CRS-STATUS OF OLD-REC NOT = CRS-STATUS OF NEW-REC
                   DISPLAY "FIELD" CTX ",B04-RIS-012," FN121
                     ",1505,2,RAW,[REDACTED]"
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF TAX-COUNTRY-CODE OF OLD-REC NOT = TAX-COUNTRY-CODE
                 OF NEW-REC
                   DISPLAY "FIELD" CTX ",B04-RIS-013," FN122
                     ",1507,2,RAW,[REDACTED]"
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF IDENTITY-VERIFICATION-STATUS OF OLD-REC NOT =
                 IDENTITY-VERIFICATION-STATUS OF NEW-REC
                   DISPLAY "FIELD" CTX ",B04-RIS-014," FN123
                     ",1509,2,RAW,[REDACTED]"
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF WATCHLIST-INDICATOR OF OLD-REC NOT =
                 WATCHLIST-INDICATOR OF NEW-REC
                   DISPLAY "FIELD" CTX ",B04-RIS-015," FN124
                     ",1511,1,RAW,[REDACTED]"
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF FRAUD-RISK-INDICATOR OF OLD-REC NOT =
                 FRAUD-RISK-INDICATOR OF NEW-REC
                   DISPLAY "FIELD" CTX ",B04-RIS-016," FN125
                     ",1512,1,RAW,[REDACTED]"
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF LAST-FRAUD-CASE-DATE OF OLD-REC NOT =
                 LAST-FRAUD-CASE-DATE OF NEW-REC
                   DISPLAY "FIELD" CTX ",B04-RIS-017," FN126
                     ",1513,8,RAW,[REDACTED]"
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF OPEN-CASE-COUNT OF OLD-REC NOT = OPEN-CASE-COUNT OF
                 NEW-REC
                   DISPLAY "FIELD" CTX ",B04-RIS-018," FN127
                     ",1521,4,NUMERIC,[REDACTED]"
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF HIGH-RISK-REASON-CODE OF OLD-REC NOT =
                 HIGH-RISK-REASON-CODE OF NEW-REC
                   DISPLAY "FIELD" CTX ",B04-RIS-019," FN128
                     ",1525,4,RAW,[REDACTED]"
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF RISK-SCORE-ADJUSTMENT OF OLD-REC NOT =
                 RISK-SCORE-ADJUSTMENT OF NEW-REC
                   DISPLAY "FIELD" CTX ",B04-RIS-020," FN129
                     ",1529,6,NUMERIC,[REDACTED]"
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF DAILY-TRANSFER-LIMIT OF OLD-REC NOT =
                 DAILY-TRANSFER-LIMIT OF NEW-REC
           DISPLAY "FIELD" CTX ",B04-LIM-001," FN130
             ",1535,6,NUMERIC"
           DISPLAY "OLD|", DAILY-TRANSFER-LIMIT OF OLD-REC
           DISPLAY "NEW|", DAILY-TRANSFER-LIMIT OF NEW-REC
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF DAILY-CASH-LIMIT OF OLD-REC NOT = DAILY-CASH-LIMIT
                 OF NEW-REC
           DISPLAY "FIELD" CTX ",B04-LIM-002," FN131
             ",1541,6,NUMERIC"
           DISPLAY "OLD|", DAILY-CASH-LIMIT OF OLD-REC
           DISPLAY "NEW|", DAILY-CASH-LIMIT OF NEW-REC
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF MONTHLY-TRANSFER-LIMIT OF OLD-REC NOT =
                 MONTHLY-TRANSFER-LIMIT OF NEW-REC
           DISPLAY "FIELD" CTX ",B04-LIM-003," FN132
             ",1547,6,NUMERIC"
           DISPLAY "OLD|", MONTHLY-TRANSFER-LIMIT OF OLD-REC
           DISPLAY "NEW|", MONTHLY-TRANSFER-LIMIT OF NEW-REC
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF PER-TRANSACTION-LIMIT OF OLD-REC NOT =
                 PER-TRANSACTION-LIMIT OF NEW-REC
           DISPLAY "FIELD" CTX ",B04-LIM-004," FN133
             ",1553,6,NUMERIC"
           DISPLAY "OLD|", PER-TRANSACTION-LIMIT OF OLD-REC
           DISPLAY "NEW|", PER-TRANSACTION-LIMIT OF NEW-REC
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF ONLINE-TRANSFER-LIMIT OF OLD-REC NOT =
                 ONLINE-TRANSFER-LIMIT OF NEW-REC
           DISPLAY "FIELD" CTX ",B04-LIM-005," FN134
             ",1559,6,NUMERIC"
           DISPLAY "OLD|", ONLINE-TRANSFER-LIMIT OF OLD-REC
           DISPLAY "NEW|", ONLINE-TRANSFER-LIMIT OF NEW-REC
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF INTERNATIONAL-TRANSFER-LIMIT OF OLD-REC NOT =
                 INTERNATIONAL-TRANSFER-LIMIT OF NEW-REC
           DISPLAY "FIELD" CTX ",B04-LIM-006," FN135
             ",1565,6,NUMERIC"
           DISPLAY "OLD|", INTERNATIONAL-TRANSFER-LIMIT OF OLD-REC
           DISPLAY "NEW|", INTERNATIONAL-TRANSFER-LIMIT OF NEW-REC
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF ATM-WITHDRAWAL-LIMIT OF OLD-REC NOT =
                 ATM-WITHDRAWAL-LIMIT OF NEW-REC
           DISPLAY "FIELD" CTX ",B04-LIM-007," FN136
             ",1571,6,NUMERIC"
           DISPLAY "OLD|", ATM-WITHDRAWAL-LIMIT OF OLD-REC
           DISPLAY "NEW|", ATM-WITHDRAWAL-LIMIT OF NEW-REC
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF POS-PURCHASE-LIMIT OF OLD-REC NOT =
                 POS-PURCHASE-LIMIT OF NEW-REC
           DISPLAY "FIELD" CTX ",B04-LIM-008," FN137
             ",1577,6,NUMERIC"
           DISPLAY "OLD|", POS-PURCHASE-LIMIT OF OLD-REC
           DISPLAY "NEW|", POS-PURCHASE-LIMIT OF NEW-REC
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF WIRE-TRANSFER-LIMIT OF OLD-REC NOT =
                 WIRE-TRANSFER-LIMIT OF NEW-REC
           DISPLAY "FIELD" CTX ",B04-LIM-009," FN138
             ",1583,6,NUMERIC"
           DISPLAY "OLD|", WIRE-TRANSFER-LIMIT OF OLD-REC
           DISPLAY "NEW|", WIRE-TRANSFER-LIMIT OF NEW-REC
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF BRANCH-CASH-LIMIT OF OLD-REC NOT = BRANCH-CASH-LIMIT
                 OF NEW-REC
           DISPLAY "FIELD" CTX ",B04-LIM-010," FN139
             ",1589,6,NUMERIC"
           DISPLAY "OLD|", BRANCH-CASH-LIMIT OF OLD-REC
           DISPLAY "NEW|", BRANCH-CASH-LIMIT OF NEW-REC
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF NEW-BENEFICIARY-LIMIT OF OLD-REC NOT =
                 NEW-BENEFICIARY-LIMIT OF NEW-REC
           DISPLAY "FIELD" CTX ",B04-LIM-011," FN140
             ",1595,6,NUMERIC"
           DISPLAY "OLD|", NEW-BENEFICIARY-LIMIT OF OLD-REC
           DISPLAY "NEW|", NEW-BENEFICIARY-LIMIT OF NEW-REC
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF ROLLING-7DAY-LIMIT OF OLD-REC NOT =
                 ROLLING-7DAY-LIMIT OF NEW-REC
           DISPLAY "FIELD" CTX ",B04-LIM-012," FN141
             ",1601,6,NUMERIC"
           DISPLAY "OLD|", ROLLING-7DAY-LIMIT OF OLD-REC
           DISPLAY "NEW|", ROLLING-7DAY-LIMIT OF NEW-REC
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF ROLLING-30DAY-LIMIT OF OLD-REC NOT =
                 ROLLING-30DAY-LIMIT OF NEW-REC
           DISPLAY "FIELD" CTX ",B04-LIM-013," FN142
             ",1607,6,NUMERIC"
           DISPLAY "OLD|", ROLLING-30DAY-LIMIT OF OLD-REC
           DISPLAY "NEW|", ROLLING-30DAY-LIMIT OF NEW-REC
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF CARD-PURCHASE-LIMIT OF OLD-REC NOT =
                 CARD-PURCHASE-LIMIT OF NEW-REC
           DISPLAY "FIELD" CTX ",B04-LIM-014," FN143
             ",1613,6,NUMERIC"
           DISPLAY "OLD|", CARD-PURCHASE-LIMIT OF OLD-REC
           DISPLAY "NEW|", CARD-PURCHASE-LIMIT OF NEW-REC
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF CASH-ADVANCE-LIMIT OF OLD-REC NOT =
                 CASH-ADVANCE-LIMIT OF NEW-REC
           DISPLAY "FIELD" CTX ",B04-LIM-015," FN144
             ",1619,6,NUMERIC"
           DISPLAY "OLD|", CASH-ADVANCE-LIMIT OF OLD-REC
           DISPLAY "NEW|", CASH-ADVANCE-LIMIT OF NEW-REC
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF LOAN-PAYMENT-LIMIT OF OLD-REC NOT =
                 LOAN-PAYMENT-LIMIT OF NEW-REC
           DISPLAY "FIELD" CTX ",B04-LIM-016," FN145
             ",1625,6,NUMERIC"
           DISPLAY "OLD|", LOAN-PAYMENT-LIMIT OF OLD-REC
           DISPLAY "NEW|", LOAN-PAYMENT-LIMIT OF NEW-REC
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF MOBILE-TRANSFER-LIMIT OF OLD-REC NOT =
                 MOBILE-TRANSFER-LIMIT OF NEW-REC
           DISPLAY "FIELD" CTX ",B04-LIM-017," FN146
             ",1631,6,NUMERIC"
           DISPLAY "OLD|", MOBILE-TRANSFER-LIMIT OF OLD-REC
           DISPLAY "NEW|", MOBILE-TRANSFER-LIMIT OF NEW-REC
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF CASH-DEPOSIT-LIMIT OF OLD-REC NOT =
                 CASH-DEPOSIT-LIMIT OF NEW-REC
           DISPLAY "FIELD" CTX ",B04-LIM-018," FN147
             ",1637,6,NUMERIC"
           DISPLAY "OLD|", CASH-DEPOSIT-LIMIT OF OLD-REC
           DISPLAY "NEW|", CASH-DEPOSIT-LIMIT OF NEW-REC
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF WEB-BANKING-PERMISSION OF OLD-REC NOT =
                 WEB-BANKING-PERMISSION OF NEW-REC
                   DISPLAY "FIELD" CTX ",B04-CHA-001," FN148
                     ",1643,1,RAW"
           DISPLAY "OLD|", WEB-BANKING-PERMISSION OF OLD-REC
           DISPLAY "NEW|", WEB-BANKING-PERMISSION OF NEW-REC
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF MOBILE-BANKING-PERMISSION OF OLD-REC NOT =
                 MOBILE-BANKING-PERMISSION OF NEW-REC
                   DISPLAY "FIELD" CTX ",B04-CHA-002," FN149
                     ",1644,1,RAW"
           DISPLAY "OLD|", MOBILE-BANKING-PERMISSION OF OLD-REC
           DISPLAY "NEW|", MOBILE-BANKING-PERMISSION OF NEW-REC
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF ATM-ACCESS-PERMISSION OF OLD-REC NOT =
                 ATM-ACCESS-PERMISSION OF NEW-REC
                   DISPLAY "FIELD" CTX ",B04-CHA-003," FN150
                     ",1645,1,RAW"
           DISPLAY "OLD|", ATM-ACCESS-PERMISSION OF OLD-REC
           DISPLAY "NEW|", ATM-ACCESS-PERMISSION OF NEW-REC
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF PHONE-BANKING-PERMISSION OF OLD-REC NOT =
                 PHONE-BANKING-PERMISSION OF NEW-REC
                   DISPLAY "FIELD" CTX ",B04-CHA-004," FN151
                     ",1646,1,RAW"
           DISPLAY "OLD|", PHONE-BANKING-PERMISSION OF OLD-REC
           DISPLAY "NEW|", PHONE-BANKING-PERMISSION OF NEW-REC
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF BRANCH-SERVICE-PERMISSION OF OLD-REC NOT =
                 BRANCH-SERVICE-PERMISSION OF NEW-REC
                   DISPLAY "FIELD" CTX ",B04-CHA-005," FN152
                     ",1647,1,RAW"
           DISPLAY "OLD|", BRANCH-SERVICE-PERMISSION OF OLD-REC
           DISPLAY "NEW|", BRANCH-SERVICE-PERMISSION OF NEW-REC
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF API-ACCESS-PERMISSION OF OLD-REC NOT =
                 API-ACCESS-PERMISSION OF NEW-REC
                   DISPLAY "FIELD" CTX ",B04-CHA-006," FN153
                     ",1648,1,RAW"
           DISPLAY "OLD|", API-ACCESS-PERMISSION OF OLD-REC
           DISPLAY "NEW|", API-ACCESS-PERMISSION OF NEW-REC
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF OPEN-BANKING-PERMISSION OF OLD-REC NOT =
                 OPEN-BANKING-PERMISSION OF NEW-REC
                   DISPLAY "FIELD" CTX ",B04-CHA-007," FN154
                     ",1649,1,RAW"
           DISPLAY "OLD|", OPEN-BANKING-PERMISSION OF OLD-REC
           DISPLAY "NEW|", OPEN-BANKING-PERMISSION OF NEW-REC
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF EMAIL-NOTICE-PERMISSION OF OLD-REC NOT =
                 EMAIL-NOTICE-PERMISSION OF NEW-REC
                   DISPLAY "FIELD" CTX ",B04-CHA-008," FN155
                     ",1650,1,RAW,[REDACTED]"
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF SMS-NOTICE-PERMISSION OF OLD-REC NOT =
                 SMS-NOTICE-PERMISSION OF NEW-REC
                   DISPLAY "FIELD" CTX ",B04-CHA-009," FN156
                     ",1651,1,RAW"
           DISPLAY "OLD|", SMS-NOTICE-PERMISSION OF OLD-REC
           DISPLAY "NEW|", SMS-NOTICE-PERMISSION OF NEW-REC
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF PUSH-NOTICE-PERMISSION OF OLD-REC NOT =
                 PUSH-NOTICE-PERMISSION OF NEW-REC
                   DISPLAY "FIELD" CTX ",B04-CHA-010," FN157
                     ",1652,1,RAW"
           DISPLAY "OLD|", PUSH-NOTICE-PERMISSION OF OLD-REC
           DISPLAY "NEW|", PUSH-NOTICE-PERMISSION OF NEW-REC
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF BIOMETRIC-AUTH-PERMISSION OF OLD-REC NOT =
                 BIOMETRIC-AUTH-PERMISSION OF NEW-REC
                   DISPLAY "FIELD" CTX ",B04-CHA-011," FN158
                     ",1653,1,RAW"
           DISPLAY "OLD|", BIOMETRIC-AUTH-PERMISSION OF OLD-REC
           DISPLAY "NEW|", BIOMETRIC-AUTH-PERMISSION OF NEW-REC
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF MFA-REQUIRED OF OLD-REC NOT = MFA-REQUIRED OF
                 NEW-REC
                   DISPLAY "FIELD" CTX ",B04-CHA-012," FN159
                     ",1654,1,RAW"
           DISPLAY "OLD|", MFA-REQUIRED OF OLD-REC
           DISPLAY "NEW|", MFA-REQUIRED OF NEW-REC
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF VOICEPRINT-ENROLLED OF OLD-REC NOT =
                 VOICEPRINT-ENROLLED OF NEW-REC
                   DISPLAY "FIELD" CTX ",B04-CHA-013," FN160
                     ",1655,1,RAW"
           DISPLAY "OLD|", VOICEPRINT-ENROLLED OF OLD-REC
           DISPLAY "NEW|", VOICEPRINT-ENROLLED OF NEW-REC
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF CARD-NOT-PRESENT-PERMISSION OF OLD-REC NOT =
                 CARD-NOT-PRESENT-PERMISSION OF NEW-REC
                   DISPLAY "FIELD" CTX ",B04-CHA-014," FN161
                     ",1656,1,RAW"
           DISPLAY "OLD|", CARD-NOT-PRESENT-PERMISSION OF OLD-REC
           DISPLAY "NEW|", CARD-NOT-PRESENT-PERMISSION OF NEW-REC
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF INTERNATIONAL-CHANNEL-PERMISSION OF OLD-REC NOT =
                 INTERNATIONAL-CHANNEL-PERMISSION OF NEW-REC
                   DISPLAY "FIELD" CTX ",B04-CHA-015," FN162
                     ",1657,1,RAW"
           DISPLAY "OLD|", INTERNATIONAL-CHANNEL-PERMISSION OF OLD-REC
           DISPLAY "NEW|", INTERNATIONAL-CHANNEL-PERMISSION OF NEW-REC
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 IF CHANNEL-PERMISSION-EXPIRY OF OLD-REC NOT =
                 CHANNEL-PERMISSION-EXPIRY OF NEW-REC
                   DISPLAY "FIELD" CTX ",B04-CHA-016," FN163
                     ",1658,8,RAW"
           DISPLAY "OLD|", CHANNEL-PERMISSION-EXPIRY OF OLD-REC
           DISPLAY "NEW|", CHANNEL-PERMISSION-EXPIRY OF NEW-REC
                   ADD 1 TO DIFF-COUNT
                 END-IF
                 PERFORM READ-OLD
                 PERFORM READ-NEW
             END-EVALUATE
           END-PERFORM
           CLOSE OLD-FILE NEW-FILE
           DISPLAY "SUMMARY,OLD-RECORDS," OLD-COUNT
           DISPLAY "SUMMARY,NEW-RECORDS," NEW-COUNT
           DISPLAY "SUMMARY,MATCHED," MATCH-COUNT
           DISPLAY "SUMMARY,OLD-ONLY," ONLY-OLD
           DISPLAY "SUMMARY,NEW-ONLY," ONLY-NEW
           DISPLAY "SUMMARY,FIELD-DIFFERENCES," DIFF-COUNT
           DISPLAY "SUMMARY,NORMALIZED-EQUAL," NORM-EQUAL
           DISPLAY "SUMMARY,NUMERIC-REPRESENTATION-EQUAL," REP-EQUAL
           DISPLAY "SUMMARY,AUDIT-ONLY," AUDIT-ONLY
           IF DIFF-COUNT > 0 OR ONLY-OLD > 0 OR ONLY-NEW > 0
               MOVE 4 TO RETURN-CODE
           END-IF
           STOP RUN.
       READ-OLD.
           READ OLD-FILE
           IF OLD-STATUS = "10"
               MOVE "Y" TO OLD-EOF
           ELSE
             IF OLD-STATUS NOT = "00"
               MOVE 12 TO RETURN-CODE
               STOP RUN
             END-IF
             ADD 1 TO OLD-COUNT
             IF LAYOUT-VERSION OF OLD-REC NOT = "001"
               OR BINARY-ABI-CODE OF OLD-REC NOT = "GCOB32BE"
               OR CUSTOMER-ID OF OLD-REC IS NOT NUMERIC
               OR CUSTOMER-ID OF OLD-REC = "0000000000"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF OLD-SEEN = "Y" AND CUSTOMER-ID OF OLD-REC
               <= OLD-LAST-KEY
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF REVISION-NO OF OLD-REC IS NOT NUMERIC
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF RELATIONSHIP-COUNT OF OLD-REC IS NOT NUMERIC
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF ACTIVE-LOAN-COUNT OF OLD-REC IS NOT NUMERIC
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF RISK-SCORE OF OLD-REC IS NOT NUMERIC
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF RISK-SCORE OF OLD-REC < -100000 OR
               RISK-SCORE OF OLD-REC > 100000
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF KYC-DOCUMENT-COUNT OF OLD-REC IS NOT NUMERIC
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF OPEN-CASE-COUNT OF OLD-REC IS NOT NUMERIC
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF RISK-SCORE-ADJUSTMENT OF OLD-REC IS NOT NUMERIC
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF RISK-SCORE-ADJUSTMENT OF OLD-REC < -9999.99 OR
               RISK-SCORE-ADJUSTMENT OF OLD-REC > 9999.99
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF DAILY-TRANSFER-LIMIT OF OLD-REC IS NOT NUMERIC
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF DAILY-TRANSFER-LIMIT OF OLD-REC < 0
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF DAILY-CASH-LIMIT OF OLD-REC IS NOT NUMERIC
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF DAILY-CASH-LIMIT OF OLD-REC < 0
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF MONTHLY-TRANSFER-LIMIT OF OLD-REC IS NOT NUMERIC
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF MONTHLY-TRANSFER-LIMIT OF OLD-REC < 0
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF PER-TRANSACTION-LIMIT OF OLD-REC IS NOT NUMERIC
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF PER-TRANSACTION-LIMIT OF OLD-REC < 0
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF ONLINE-TRANSFER-LIMIT OF OLD-REC IS NOT NUMERIC
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF ONLINE-TRANSFER-LIMIT OF OLD-REC < 0
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF INTERNATIONAL-TRANSFER-LIMIT OF OLD-REC IS NOT NUMERIC
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF INTERNATIONAL-TRANSFER-LIMIT OF OLD-REC < 0
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF ATM-WITHDRAWAL-LIMIT OF OLD-REC IS NOT NUMERIC
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF ATM-WITHDRAWAL-LIMIT OF OLD-REC < 0
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF POS-PURCHASE-LIMIT OF OLD-REC IS NOT NUMERIC
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF POS-PURCHASE-LIMIT OF OLD-REC < 0
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF WIRE-TRANSFER-LIMIT OF OLD-REC IS NOT NUMERIC
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF WIRE-TRANSFER-LIMIT OF OLD-REC < 0
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF BRANCH-CASH-LIMIT OF OLD-REC IS NOT NUMERIC
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF BRANCH-CASH-LIMIT OF OLD-REC < 0
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF NEW-BENEFICIARY-LIMIT OF OLD-REC IS NOT NUMERIC
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF NEW-BENEFICIARY-LIMIT OF OLD-REC < 0
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF ROLLING-7DAY-LIMIT OF OLD-REC IS NOT NUMERIC
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF ROLLING-7DAY-LIMIT OF OLD-REC < 0
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF ROLLING-30DAY-LIMIT OF OLD-REC IS NOT NUMERIC
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF ROLLING-30DAY-LIMIT OF OLD-REC < 0
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF CARD-PURCHASE-LIMIT OF OLD-REC IS NOT NUMERIC
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF CARD-PURCHASE-LIMIT OF OLD-REC < 0
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF CASH-ADVANCE-LIMIT OF OLD-REC IS NOT NUMERIC
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF CASH-ADVANCE-LIMIT OF OLD-REC < 0
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF LOAN-PAYMENT-LIMIT OF OLD-REC IS NOT NUMERIC
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF LOAN-PAYMENT-LIMIT OF OLD-REC < 0
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF MOBILE-TRANSFER-LIMIT OF OLD-REC IS NOT NUMERIC
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF MOBILE-TRANSFER-LIMIT OF OLD-REC < 0
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF CASH-DEPOSIT-LIMIT OF OLD-REC IS NOT NUMERIC
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF CASH-DEPOSIT-LIMIT OF OLD-REC < 0
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF UPDATE-SEQUENCE-NO OF OLD-REC IS NOT NUMERIC
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF OLD-RAW(1:3) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE OLD-RAW(1:3) TO BYTE-BUFFER
             MOVE 3 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF OLD-RAW(4:8) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE OLD-RAW(4:8) TO BYTE-BUFFER
             MOVE 8 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF OLD-RAW(12:10) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE OLD-RAW(12:10) TO BYTE-BUFFER
             MOVE 10 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF OLD-RAW(22:1) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE OLD-RAW(22:1) TO BYTE-BUFFER
             MOVE 1 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF RECORD-STATUS OF OLD-REC NOT = "A"
               AND RECORD-STATUS OF OLD-REC NOT = "I"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF OLD-RAW(23:4) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE OLD-RAW(23:4) TO BYTE-BUFFER
             MOVE 4 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF OLD-RAW(27:8) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE OLD-RAW(27:8) TO BYTE-BUFFER
             MOVE 8 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF EFFECTIVE-DATE OF OLD-REC NOT = SPACES
               IF EFFECTIVE-DATE OF OLD-REC < "00000000" OR
                 EFFECTIVE-DATE OF OLD-REC > "99999999"
                 MOVE 8 TO RETURN-CODE
                 STOP RUN
               END-IF
               IF OLD-RAW(27:8) NOT = SPACES
               MOVE OLD-RAW(27:8) TO BYTE-BUFFER
               MOVE 8 TO BYTE-LENGTH
               PERFORM CHECK-DIGITS
             END-IF
             IF OLD-RAW(35:8) NOT = SPACES
               MOVE OLD-RAW(35:8) TO BYTE-BUFFER
               MOVE 8 TO BYTE-LENGTH
               PERFORM CHECK-DIGITS
             END-IF
             IF OLD-RAW(339:8) NOT = SPACES
               MOVE OLD-RAW(339:8) TO BYTE-BUFFER
               MOVE 8 TO BYTE-LENGTH
               PERFORM CHECK-DIGITS
             END-IF
             IF OLD-RAW(388:8) NOT = SPACES
               MOVE OLD-RAW(388:8) TO BYTE-BUFFER
               MOVE 8 TO BYTE-LENGTH
               PERFORM CHECK-DIGITS
             END-IF
             IF OLD-RAW(490:8) NOT = SPACES
               MOVE OLD-RAW(490:8) TO BYTE-BUFFER
               MOVE 8 TO BYTE-LENGTH
               PERFORM CHECK-DIGITS
             END-IF
             IF OLD-RAW(498:8) NOT = SPACES
               MOVE OLD-RAW(498:8) TO BYTE-BUFFER
               MOVE 8 TO BYTE-LENGTH
               PERFORM CHECK-DIGITS
             END-IF
             IF OLD-RAW(1036:8) NOT = SPACES
               MOVE OLD-RAW(1036:8) TO BYTE-BUFFER
               MOVE 8 TO BYTE-LENGTH
               PERFORM CHECK-DIGITS
             END-IF
             IF OLD-RAW(1044:8) NOT = SPACES
               MOVE OLD-RAW(1044:8) TO BYTE-BUFFER
               MOVE 8 TO BYTE-LENGTH
               PERFORM CHECK-DIGITS
             END-IF
             IF OLD-RAW(1056:8) NOT = SPACES
               MOVE OLD-RAW(1056:8) TO BYTE-BUFFER
               MOVE 8 TO BYTE-LENGTH
               PERFORM CHECK-DIGITS
             END-IF
             IF OLD-RAW(1424:8) NOT = SPACES
               MOVE OLD-RAW(1424:8) TO BYTE-BUFFER
               MOVE 8 TO BYTE-LENGTH
               PERFORM CHECK-DIGITS
             END-IF
             IF OLD-RAW(1432:8) NOT = SPACES
               MOVE OLD-RAW(1432:8) TO BYTE-BUFFER
               MOVE 8 TO BYTE-LENGTH
               PERFORM CHECK-DIGITS
             END-IF
             IF OLD-RAW(1478:8) NOT = SPACES
               MOVE OLD-RAW(1478:8) TO BYTE-BUFFER
               MOVE 8 TO BYTE-LENGTH
               PERFORM CHECK-DIGITS
             END-IF
             IF OLD-RAW(1486:8) NOT = SPACES
               MOVE OLD-RAW(1486:8) TO BYTE-BUFFER
               MOVE 8 TO BYTE-LENGTH
               PERFORM CHECK-DIGITS
             END-IF
             IF OLD-RAW(1513:8) NOT = SPACES
               MOVE OLD-RAW(1513:8) TO BYTE-BUFFER
               MOVE 8 TO BYTE-LENGTH
               PERFORM CHECK-DIGITS
             END-IF
             IF OLD-RAW(1658:8) NOT = SPACES
               MOVE OLD-RAW(1658:8) TO BYTE-BUFFER
               MOVE 8 TO BYTE-LENGTH
               PERFORM CHECK-DIGITS
             END-IF
             IF OLD-RAW(1676:14) NOT = SPACES
               MOVE OLD-RAW(1676:14) TO BYTE-BUFFER
               MOVE 14 TO BYTE-LENGTH
               PERFORM CHECK-DIGITS
             END-IF
             IF OLD-RAW(1700:14) NOT = SPACES
               MOVE OLD-RAW(1700:14) TO BYTE-BUFFER
               MOVE 14 TO BYTE-LENGTH
               PERFORM CHECK-DIGITS
             END-IF
             IF OLD-RAW(1750:14) NOT = SPACES
               MOVE OLD-RAW(1750:14) TO BYTE-BUFFER
               MOVE 14 TO BYTE-LENGTH
               PERFORM CHECK-DIGITS
             END-IF
             IF OLD-RAW(1764:14) NOT = SPACES
               MOVE OLD-RAW(1764:14) TO BYTE-BUFFER
               MOVE 14 TO BYTE-LENGTH
               PERFORM CHECK-DIGITS
             END-IF
             IF FUNCTION TEST-DATE-YYYYMMDD(
                 FUNCTION NUMVAL(
                   EFFECTIVE-DATE OF OLD-REC))
                 NOT = 0
                 MOVE 8 TO RETURN-CODE
                 STOP RUN
               END-IF
               IF LAST-REVIEW-TIMESTAMP OF OLD-REC(9:2) > "23" OR
                 LAST-REVIEW-TIMESTAMP OF OLD-REC(11:2) > "59" OR
                 LAST-REVIEW-TIMESTAMP OF OLD-REC(13:2) > "59"
                 MOVE 8 TO RETURN-CODE
                 STOP RUN
               END-IF
               IF APPROVED-TIMESTAMP OF OLD-REC(9:2) > "23" OR
                 APPROVED-TIMESTAMP OF OLD-REC(11:2) > "59" OR
                 APPROVED-TIMESTAMP OF OLD-REC(13:2) > "59"
                 MOVE 8 TO RETURN-CODE
                 STOP RUN
               END-IF
               IF UPDATED-TIMESTAMP OF OLD-REC(9:2) > "23" OR
                 UPDATED-TIMESTAMP OF OLD-REC(11:2) > "59" OR
                 UPDATED-TIMESTAMP OF OLD-REC(13:2) > "59"
                 MOVE 8 TO RETURN-CODE
                 STOP RUN
               END-IF
               IF CREATED-TIMESTAMP OF OLD-REC(9:2) > "23" OR
                 CREATED-TIMESTAMP OF OLD-REC(11:2) > "59" OR
                 CREATED-TIMESTAMP OF OLD-REC(13:2) > "59"
                 MOVE 8 TO RETURN-CODE
                 STOP RUN
               END-IF
             END-IF
             IF OLD-RAW(35:8) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE OLD-RAW(35:8) TO BYTE-BUFFER
             MOVE 8 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF RECORD-DATE OF OLD-REC NOT = SPACES
               IF RECORD-DATE OF OLD-REC < "00000000" OR
                 RECORD-DATE OF OLD-REC > "99999999"
                 MOVE 8 TO RETURN-CODE
                 STOP RUN
               END-IF
               IF FUNCTION TEST-DATE-YYYYMMDD(
                 FUNCTION NUMVAL(
                   RECORD-DATE OF OLD-REC))
                 NOT = 0
                 MOVE 8 TO RETURN-CODE
                 STOP RUN
               END-IF
             END-IF
             IF OLD-RAW(43:12) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE OLD-RAW(43:12) TO BYTE-BUFFER
             MOVE 12 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF OLD-RAW(59:32) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE OLD-RAW(59:32) TO BYTE-BUFFER
             MOVE 32 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF OLD-RAW(91:32) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE OLD-RAW(91:32) TO BYTE-BUFFER
             MOVE 32 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             MOVE OLD-RAW(123:24) TO BYTE-BUFFER
             MOVE 24 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF OLD-RAW(147:64) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE OLD-RAW(147:64) TO BYTE-BUFFER
             MOVE 64 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF OLD-RAW(211:32) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE OLD-RAW(211:32) TO BYTE-BUFFER
             MOVE 32 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF OLD-RAW(243:32) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE OLD-RAW(243:32) TO BYTE-BUFFER
             MOVE 32 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF OLD-RAW(275:32) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE OLD-RAW(275:32) TO BYTE-BUFFER
             MOVE 32 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF OLD-RAW(307:32) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE OLD-RAW(307:32) TO BYTE-BUFFER
             MOVE 32 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             MOVE OLD-RAW(339:8) TO BYTE-BUFFER
             MOVE 8 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF BIRTH-DATE OF OLD-REC NOT = SPACES
               IF BIRTH-DATE OF OLD-REC < "00000000" OR
                 BIRTH-DATE OF OLD-REC > "99999999"
                 MOVE 8 TO RETURN-CODE
                 STOP RUN
               END-IF
               IF FUNCTION TEST-DATE-YYYYMMDD(
                 FUNCTION NUMVAL(
                   BIRTH-DATE OF OLD-REC))
                 NOT = 0
                 MOVE 8 TO RETURN-CODE
                 STOP RUN
               END-IF
             END-IF
             IF OLD-RAW(347:2) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE OLD-RAW(347:2) TO BYTE-BUFFER
             MOVE 2 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF BIRTH-COUNTRY OF OLD-REC NOT = "JP"
               AND BIRTH-COUNTRY OF OLD-REC NOT = "US"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE OLD-RAW(349:3) TO BYTE-BUFFER
             MOVE 3 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF OLD-RAW(352:2) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE OLD-RAW(352:2) TO BYTE-BUFFER
             MOVE 2 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF NATIONALITY-CODE OF OLD-REC NOT = "JP"
               AND NATIONALITY-CODE OF OLD-REC NOT = "US"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF OLD-RAW(354:2) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE OLD-RAW(354:2) TO BYTE-BUFFER
             MOVE 2 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF CITIZENSHIP-CODE OF OLD-REC NOT = "JP"
               AND CITIZENSHIP-CODE OF OLD-REC NOT = "US"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF OLD-RAW(356:2) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE OLD-RAW(356:2) TO BYTE-BUFFER
             MOVE 2 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF RESIDENCY-CODE OF OLD-REC NOT = "JP"
               AND RESIDENCY-CODE OF OLD-REC NOT = "US"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF OLD-RAW(358:2) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE OLD-RAW(358:2) TO BYTE-BUFFER
             MOVE 2 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF TAX-RESIDENCY-CODE OF OLD-REC NOT = "JP"
               AND TAX-RESIDENCY-CODE OF OLD-REC NOT = "US"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF OLD-RAW(360:4) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE OLD-RAW(360:4) TO BYTE-BUFFER
             MOVE 4 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF ID-DOCUMENT-TYPE OF OLD-REC NOT = "PASS"
               AND ID-DOCUMENT-TYPE OF OLD-REC NOT = "DL"
               AND ID-DOCUMENT-TYPE OF OLD-REC NOT = "NAT"
               AND ID-DOCUMENT-TYPE OF OLD-REC NOT = "RES"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE OLD-RAW(364:24) TO BYTE-BUFFER
             MOVE 24 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             PERFORM CHECK-ID-MASK
             MOVE OLD-RAW(388:8) TO BYTE-BUFFER
             MOVE 8 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF ID-DOCUMENT-EXPIRY OF OLD-REC NOT = SPACES
               IF ID-DOCUMENT-EXPIRY OF OLD-REC < "00000000" OR
                 ID-DOCUMENT-EXPIRY OF OLD-REC > "99999999"
                 MOVE 8 TO RETURN-CODE
                 STOP RUN
               END-IF
               IF FUNCTION TEST-DATE-YYYYMMDD(
                 FUNCTION NUMVAL(
                   ID-DOCUMENT-EXPIRY OF OLD-REC))
                 NOT = 0
                 MOVE 8 TO RETURN-CODE
                 STOP RUN
               END-IF
             END-IF
             MOVE OLD-RAW(396:32) TO BYTE-BUFFER
             MOVE 32 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             MOVE OLD-RAW(428:32) TO BYTE-BUFFER
             MOVE 32 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF OLD-RAW(460:1) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE OLD-RAW(460:1) TO BYTE-BUFFER
             MOVE 1 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF CUSTOMER-CLASSIFICATION OF OLD-REC NOT = "A"
               AND CUSTOMER-CLASSIFICATION OF OLD-REC NOT = "B"
               AND CUSTOMER-CLASSIFICATION OF OLD-REC NOT = "C"
               AND CUSTOMER-CLASSIFICATION OF OLD-REC NOT = "D"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF OLD-RAW(461:3) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE OLD-RAW(461:3) TO BYTE-BUFFER
             MOVE 3 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF CUSTOMER-TYPE OF OLD-REC NOT = "IND"
               AND CUSTOMER-TYPE OF OLD-REC NOT = "ORG"
               AND CUSTOMER-TYPE OF OLD-REC NOT = "TRU"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF OLD-RAW(464:4) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE OLD-RAW(464:4) TO BYTE-BUFFER
             MOVE 4 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF OLD-RAW(468:6) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE OLD-RAW(468:6) TO BYTE-BUFFER
             MOVE 6 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF OLD-RAW(474:10) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE OLD-RAW(474:10) TO BYTE-BUFFER
             MOVE 10 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF OLD-RAW(484:6) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE OLD-RAW(484:6) TO BYTE-BUFFER
             MOVE 6 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF OLD-RAW(490:8) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE OLD-RAW(490:8) TO BYTE-BUFFER
             MOVE 8 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF CUSTOMER-SINCE-DATE OF OLD-REC NOT = SPACES
               IF CUSTOMER-SINCE-DATE OF OLD-REC < "00000000" OR
                 CUSTOMER-SINCE-DATE OF OLD-REC > "99999999"
                 MOVE 8 TO RETURN-CODE
                 STOP RUN
               END-IF
               IF FUNCTION TEST-DATE-YYYYMMDD(
                 FUNCTION NUMVAL(
                   CUSTOMER-SINCE-DATE OF OLD-REC))
                 NOT = 0
                 MOVE 8 TO RETURN-CODE
                 STOP RUN
               END-IF
             END-IF
             MOVE OLD-RAW(498:8) TO BYTE-BUFFER
             MOVE 8 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF CUSTOMER-END-DATE OF OLD-REC NOT = SPACES
               IF CUSTOMER-END-DATE OF OLD-REC < "00000000" OR
                 CUSTOMER-END-DATE OF OLD-REC > "99999999"
                 MOVE 8 TO RETURN-CODE
                 STOP RUN
               END-IF
               IF FUNCTION TEST-DATE-YYYYMMDD(
                 FUNCTION NUMVAL(
                   CUSTOMER-END-DATE OF OLD-REC))
                 NOT = 0
                 MOVE 8 TO RETURN-CODE
                 STOP RUN
               END-IF
             END-IF
             IF OLD-RAW(506:2) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE OLD-RAW(506:2) TO BYTE-BUFFER
             MOVE 2 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF PREFERRED-LANGUAGE OF OLD-REC NOT = "EN"
               AND PREFERRED-LANGUAGE OF OLD-REC NOT = "JA"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF OLD-RAW(508:2) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE OLD-RAW(508:2) TO BYTE-BUFFER
             MOVE 2 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF AGE-BAND-CODE OF OLD-REC NOT = "00"
               AND AGE-BAND-CODE OF OLD-REC NOT = "18"
               AND AGE-BAND-CODE OF OLD-REC NOT = "25"
               AND AGE-BAND-CODE OF OLD-REC NOT = "35"
               AND AGE-BAND-CODE OF OLD-REC NOT = "45"
               AND AGE-BAND-CODE OF OLD-REC NOT = "55"
               AND AGE-BAND-CODE OF OLD-REC NOT = "65"
               AND AGE-BAND-CODE OF OLD-REC NOT = "75"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF OLD-RAW(510:1) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE OLD-RAW(510:1) TO BYTE-BUFFER
             MOVE 1 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF MARKETING-PERMISSION OF OLD-REC NOT = "Y"
               AND MARKETING-PERMISSION OF OLD-REC NOT = "N"
               AND MARKETING-PERMISSION OF OLD-REC NOT = "U"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF OLD-RAW(511:2) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE OLD-RAW(511:2) TO BYTE-BUFFER
             MOVE 2 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF OLD-RAW(513:2) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE OLD-RAW(513:2) TO BYTE-BUFFER
             MOVE 2 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF KYC-STATUS OF OLD-REC NOT = "N"
               AND KYC-STATUS OF OLD-REC NOT = "P"
               AND KYC-STATUS OF OLD-REC NOT = "C"
               AND KYC-STATUS OF OLD-REC NOT = "R"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF OLD-RAW(515:2) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE OLD-RAW(515:2) TO BYTE-BUFFER
             MOVE 2 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF CUSTOMER-TIER OF OLD-REC NOT = "01"
               AND CUSTOMER-TIER OF OLD-REC NOT = "02"
               AND CUSTOMER-TIER OF OLD-REC NOT = "03"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF OLD-RAW(517:2) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE OLD-RAW(517:2) TO BYTE-BUFFER
             MOVE 2 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF ADDRESS-COUNTRY OF OLD-REC NOT = "JP"
               AND ADDRESS-COUNTRY OF OLD-REC NOT = "US"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF OLD-RAW(519:10) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE OLD-RAW(519:10) TO BYTE-BUFFER
             MOVE 10 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF OLD-RAW(529:4) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE OLD-RAW(529:4) TO BYTE-BUFFER
             MOVE 4 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF REGION-CODE OF OLD-REC NOT = "E01"
               AND REGION-CODE OF OLD-REC NOT = "W01"
               AND REGION-CODE OF OLD-REC NOT = "N01"
               AND REGION-CODE OF OLD-REC NOT = "S01"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE OLD-RAW(533:32) TO BYTE-BUFFER
             MOVE 32 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF OLD-RAW(565:4) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE OLD-RAW(565:4) TO BYTE-BUFFER
             MOVE 4 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             MOVE OLD-RAW(569:32) TO BYTE-BUFFER
             MOVE 32 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF OLD-RAW(601:6) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE OLD-RAW(601:6) TO BYTE-BUFFER
             MOVE 6 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF OLD-RAW(607:32) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE OLD-RAW(607:32) TO BYTE-BUFFER
             MOVE 32 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             MOVE OLD-RAW(639:32) TO BYTE-BUFFER
             MOVE 32 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF OLD-RAW(671:40) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE OLD-RAW(671:40) TO BYTE-BUFFER
             MOVE 40 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             MOVE OLD-RAW(711:40) TO BYTE-BUFFER
             MOVE 40 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             MOVE OLD-RAW(751:40) TO BYTE-BUFFER
             MOVE 40 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             MOVE OLD-RAW(791:40) TO BYTE-BUFFER
             MOVE 40 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             MOVE OLD-RAW(831:40) TO BYTE-BUFFER
             MOVE 40 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             MOVE OLD-RAW(871:4) TO BYTE-BUFFER
             MOVE 4 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             MOVE OLD-RAW(875:8) TO BYTE-BUFFER
             MOVE 8 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             MOVE OLD-RAW(883:40) TO BYTE-BUFFER
             MOVE 40 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             MOVE OLD-RAW(923:64) TO BYTE-BUFFER
             MOVE 64 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             MOVE OLD-RAW(987:12) TO BYTE-BUFFER
             MOVE 12 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF OLD-RAW(999:1) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE OLD-RAW(999:1) TO BYTE-BUFFER
             MOVE 1 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF MAILING-PREFERENCE OF OLD-REC NOT = "Y"
               AND MAILING-PREFERENCE OF OLD-REC NOT = "N"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE OLD-RAW(1000:32) TO BYTE-BUFFER
             MOVE 32 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF OLD-RAW(1032:4) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE OLD-RAW(1032:4) TO BYTE-BUFFER
             MOVE 4 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF TAX-JURISDICTION OF OLD-REC NOT = "JP01"
               AND TAX-JURISDICTION OF OLD-REC NOT = "US01"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF OLD-RAW(1036:8) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE OLD-RAW(1036:8) TO BYTE-BUFFER
             MOVE 8 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF ADDRESS-VALID-FROM OF OLD-REC NOT = SPACES
               IF ADDRESS-VALID-FROM OF OLD-REC < "00000000" OR
                 ADDRESS-VALID-FROM OF OLD-REC > "99999999"
                 MOVE 8 TO RETURN-CODE
                 STOP RUN
               END-IF
               IF FUNCTION TEST-DATE-YYYYMMDD(
                 FUNCTION NUMVAL(
                   ADDRESS-VALID-FROM OF OLD-REC))
                 NOT = 0
                 MOVE 8 TO RETURN-CODE
                 STOP RUN
               END-IF
             END-IF
             MOVE OLD-RAW(1044:8) TO BYTE-BUFFER
             MOVE 8 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF ADDRESS-VALID-TO OF OLD-REC NOT = SPACES
               IF ADDRESS-VALID-TO OF OLD-REC < "00000000" OR
                 ADDRESS-VALID-TO OF OLD-REC > "99999999"
                 MOVE 8 TO RETURN-CODE
                 STOP RUN
               END-IF
               IF FUNCTION TEST-DATE-YYYYMMDD(
                 FUNCTION NUMVAL(
                   ADDRESS-VALID-TO OF OLD-REC))
                 NOT = 0
                 MOVE 8 TO RETURN-CODE
                 STOP RUN
               END-IF
             END-IF
             IF OLD-RAW(1052:4) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE OLD-RAW(1052:4) TO BYTE-BUFFER
             MOVE 4 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF ADDRESS-SOURCE OF OLD-REC NOT = "CUS"
               AND ADDRESS-SOURCE OF OLD-REC NOT = "BRN"
               AND ADDRESS-SOURCE OF OLD-REC NOT = "KYC"
               AND ADDRESS-SOURCE OF OLD-REC NOT = "MIG"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF OLD-RAW(1056:8) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE OLD-RAW(1056:8) TO BYTE-BUFFER
             MOVE 8 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF ADDRESS-VERIFIED-DATE OF OLD-REC NOT = SPACES
               IF ADDRESS-VERIFIED-DATE OF OLD-REC < "00000000" OR
                 ADDRESS-VERIFIED-DATE OF OLD-REC > "99999999"
                 MOVE 8 TO RETURN-CODE
                 STOP RUN
               END-IF
               IF FUNCTION TEST-DATE-YYYYMMDD(
                 FUNCTION NUMVAL(
                   ADDRESS-VERIFIED-DATE OF OLD-REC))
                 NOT = 0
                 MOVE 8 TO RETURN-CODE
                 STOP RUN
               END-IF
             END-IF
             MOVE OLD-RAW(1064:3) TO BYTE-BUFFER
             MOVE 3 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             MOVE OLD-RAW(1067:6) TO BYTE-BUFFER
             MOVE 6 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             MOVE OLD-RAW(1073:16) TO BYTE-BUFFER
             MOVE 16 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             MOVE OLD-RAW(1089:3) TO BYTE-BUFFER
             MOVE 3 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             MOVE OLD-RAW(1092:6) TO BYTE-BUFFER
             MOVE 6 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             MOVE OLD-RAW(1098:16) TO BYTE-BUFFER
             MOVE 16 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             MOVE OLD-RAW(1114:64) TO BYTE-BUFFER
             MOVE 64 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             MOVE OLD-RAW(1178:64) TO BYTE-BUFFER
             MOVE 64 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             MOVE OLD-RAW(1242:3) TO BYTE-BUFFER
             MOVE 3 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             MOVE OLD-RAW(1245:16) TO BYTE-BUFFER
             MOVE 16 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF OLD-RAW(1261:2) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE OLD-RAW(1261:2) TO BYTE-BUFFER
             MOVE 2 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF PREFERRED-CONTACT-CHANNEL OF OLD-REC NOT = "BR"
               AND PREFERRED-CONTACT-CHANNEL OF OLD-REC NOT = "PH"
               AND PREFERRED-CONTACT-CHANNEL OF OLD-REC NOT = "EM"
               AND PREFERRED-CONTACT-CHANNEL OF OLD-REC NOT = "MB"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE OLD-RAW(1263:4) TO BYTE-BUFFER
             MOVE 4 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             MOVE OLD-RAW(1267:4) TO BYTE-BUFFER
             MOVE 4 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF OLD-RAW(1271:2) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE OLD-RAW(1271:2) TO BYTE-BUFFER
             MOVE 2 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF CONTACT-LANGUAGE OF OLD-REC NOT = "EN"
               AND CONTACT-LANGUAGE OF OLD-REC NOT = "JA"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF OLD-RAW(1273:1) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE OLD-RAW(1273:1) TO BYTE-BUFFER
             MOVE 1 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF SMS-CONSENT OF OLD-REC NOT = "Y"
               AND SMS-CONSENT OF OLD-REC NOT = "N"
               AND SMS-CONSENT OF OLD-REC NOT = "U"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF OLD-RAW(1274:1) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE OLD-RAW(1274:1) TO BYTE-BUFFER
             MOVE 1 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF EMAIL-CONSENT OF OLD-REC NOT = "Y"
               AND EMAIL-CONSENT OF OLD-REC NOT = "N"
               AND EMAIL-CONSENT OF OLD-REC NOT = "U"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF OLD-RAW(1275:1) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE OLD-RAW(1275:1) TO BYTE-BUFFER
             MOVE 1 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF VOICE-CONSENT OF OLD-REC NOT = "Y"
               AND VOICE-CONSENT OF OLD-REC NOT = "N"
               AND VOICE-CONSENT OF OLD-REC NOT = "U"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF OLD-RAW(1276:2) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE OLD-RAW(1276:2) TO BYTE-BUFFER
             MOVE 2 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF NOTICE-DELIVERY-METHOD OF OLD-REC NOT = "EM"
               AND NOTICE-DELIVERY-METHOD OF OLD-REC NOT = "SM"
               AND NOTICE-DELIVERY-METHOD OF OLD-REC NOT = "PT"
               AND NOTICE-DELIVERY-METHOD OF OLD-REC NOT = "PU"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE OLD-RAW(1278:32) TO BYTE-BUFFER
             MOVE 32 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             MOVE OLD-RAW(1310:3) TO BYTE-BUFFER
             MOVE 3 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF EMERGENCY-RELATION-CODE OF OLD-REC NOT = SPACES AND
               EMERGENCY-RELATION-CODE OF OLD-REC NOT = "FAM"
               AND EMERGENCY-RELATION-CODE OF OLD-REC NOT = "SPO"
               AND EMERGENCY-RELATION-CODE OF OLD-REC NOT = "FRI"
               AND EMERGENCY-RELATION-CODE OF OLD-REC NOT = "OTH"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE OLD-RAW(1313:24) TO BYTE-BUFFER
             MOVE 24 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             MOVE OLD-RAW(1337:64) TO BYTE-BUFFER
             MOVE 64 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             MOVE OLD-RAW(1404:16) TO BYTE-BUFFER
             MOVE 16 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF OLD-RAW(1420:4) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE OLD-RAW(1420:4) TO BYTE-BUFFER
             MOVE 4 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF PRODUCT-FAMILY-CODE OF OLD-REC NOT = "DEP"
               AND PRODUCT-FAMILY-CODE OF OLD-REC NOT = "CRD"
               AND PRODUCT-FAMILY-CODE OF OLD-REC NOT = "LON"
               AND PRODUCT-FAMILY-CODE OF OLD-REC NOT = "INV"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF OLD-RAW(1424:8) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE OLD-RAW(1424:8) TO BYTE-BUFFER
             MOVE 8 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF FIRST-ACCOUNT-OPEN-DATE OF OLD-REC NOT = SPACES
               IF FIRST-ACCOUNT-OPEN-DATE OF OLD-REC < "00000000" OR
                 FIRST-ACCOUNT-OPEN-DATE OF OLD-REC > "99999999"
                 MOVE 8 TO RETURN-CODE
                 STOP RUN
               END-IF
               IF FUNCTION TEST-DATE-YYYYMMDD(
                 FUNCTION NUMVAL(
                   FIRST-ACCOUNT-OPEN-DATE OF OLD-REC))
                 NOT = 0
                 MOVE 8 TO RETURN-CODE
                 STOP RUN
               END-IF
             END-IF
             MOVE OLD-RAW(1432:8) TO BYTE-BUFFER
             MOVE 8 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF LAST-ACCOUNT-CLOSE-DATE OF OLD-REC NOT = SPACES
               IF LAST-ACCOUNT-CLOSE-DATE OF OLD-REC < "00000000" OR
                 LAST-ACCOUNT-CLOSE-DATE OF OLD-REC > "99999999"
                 MOVE 8 TO RETURN-CODE
                 STOP RUN
               END-IF
               IF FUNCTION TEST-DATE-YYYYMMDD(
                 FUNCTION NUMVAL(
                   LAST-ACCOUNT-CLOSE-DATE OF OLD-REC))
                 NOT = 0
                 MOVE 8 TO RETURN-CODE
                 STOP RUN
               END-IF
             END-IF
             IF OLD-RAW(1440:3) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE OLD-RAW(1440:3) TO BYTE-BUFFER
             MOVE 3 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF PRIMARY-CURRENCY OF OLD-REC NOT = "JPY"
               AND PRIMARY-CURRENCY OF OLD-REC NOT = "USD"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF OLD-RAW(1443:2) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE OLD-RAW(1443:2) TO BYTE-BUFFER
             MOVE 2 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF STATEMENT-CYCLE-CODE OF OLD-REC NOT = "M"
               AND STATEMENT-CYCLE-CODE OF OLD-REC NOT = "Q"
               AND STATEMENT-CYCLE-CODE OF OLD-REC NOT = "A"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF OLD-RAW(1445:1) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE OLD-RAW(1445:1) TO BYTE-BUFFER
             MOVE 1 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF OVERDRAFT-PERMISSION OF OLD-REC NOT = "Y"
               AND OVERDRAFT-PERMISSION OF OLD-REC NOT = "N"
               AND OVERDRAFT-PERMISSION OF OLD-REC NOT = "U"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF OLD-RAW(1446:1) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE OLD-RAW(1446:1) TO BYTE-BUFFER
             MOVE 1 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF DEBIT-CARD-ENROLLED OF OLD-REC NOT = "Y"
               AND DEBIT-CARD-ENROLLED OF OLD-REC NOT = "N"
               AND DEBIT-CARD-ENROLLED OF OLD-REC NOT = "U"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF OLD-RAW(1447:1) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE OLD-RAW(1447:1) TO BYTE-BUFFER
             MOVE 1 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF CREDIT-CARD-ENROLLED OF OLD-REC NOT = "Y"
               AND CREDIT-CARD-ENROLLED OF OLD-REC NOT = "N"
               AND CREDIT-CARD-ENROLLED OF OLD-REC NOT = "U"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF OLD-RAW(1448:1) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE OLD-RAW(1448:1) TO BYTE-BUFFER
             MOVE 1 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF LOAN-RELATIONSHIP OF OLD-REC NOT = "Y"
               AND LOAN-RELATIONSHIP OF OLD-REC NOT = "N"
               AND LOAN-RELATIONSHIP OF OLD-REC NOT = "U"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF OLD-RAW(1449:1) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE OLD-RAW(1449:1) TO BYTE-BUFFER
             MOVE 1 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF DEPOSIT-RELATIONSHIP OF OLD-REC NOT = "Y"
               AND DEPOSIT-RELATIONSHIP OF OLD-REC NOT = "N"
               AND DEPOSIT-RELATIONSHIP OF OLD-REC NOT = "U"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF OLD-RAW(1450:2) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE OLD-RAW(1450:2) TO BYTE-BUFFER
             MOVE 2 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF ACCOUNT-SERVICE-TIER OF OLD-REC NOT = "01"
               AND ACCOUNT-SERVICE-TIER OF OLD-REC NOT = "02"
               AND ACCOUNT-SERVICE-TIER OF OLD-REC NOT = "03"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF OLD-RAW(1452:6) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE OLD-RAW(1452:6) TO BYTE-BUFFER
             MOVE 6 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF OLD-RAW(1461:2) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE OLD-RAW(1461:2) TO BYTE-BUFFER
             MOVE 2 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF OWNERSHIP-ROLE-CODE OF OLD-REC NOT = "PR"
               AND OWNERSHIP-ROLE-CODE OF OLD-REC NOT = "JO"
               AND OWNERSHIP-ROLE-CODE OF OLD-REC NOT = "AU"
               AND OWNERSHIP-ROLE-CODE OF OLD-REC NOT = "BE"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF OLD-RAW(1463:1) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE OLD-RAW(1463:1) TO BYTE-BUFFER
             MOVE 1 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF ACCOUNT-DIGITAL-ACCESS OF OLD-REC NOT = "Y"
               AND ACCOUNT-DIGITAL-ACCESS OF OLD-REC NOT = "N"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF OLD-RAW(1464:3) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE OLD-RAW(1464:3) TO BYTE-BUFFER
             MOVE 3 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF ACCOUNT-RESTRICTION-CODE OF OLD-REC NOT = "000"
               AND ACCOUNT-RESTRICTION-CODE OF OLD-REC NOT = "001"
               AND ACCOUNT-RESTRICTION-CODE OF OLD-REC NOT = "002"
               AND ACCOUNT-RESTRICTION-CODE OF OLD-REC NOT = "003"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF OLD-RAW(1471:1) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE OLD-RAW(1471:1) TO BYTE-BUFFER
             MOVE 1 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF PEP-INDICATOR OF OLD-REC NOT = "Y"
               AND PEP-INDICATOR OF OLD-REC NOT = "N"
               AND PEP-INDICATOR OF OLD-REC NOT = "U"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF OLD-RAW(1472:2) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE OLD-RAW(1472:2) TO BYTE-BUFFER
             MOVE 2 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF SANCTIONS-SCREEN-STATUS OF OLD-REC NOT = "C"
               AND SANCTIONS-SCREEN-STATUS OF OLD-REC NOT = "P"
               AND SANCTIONS-SCREEN-STATUS OF OLD-REC NOT = "H"
               AND SANCTIONS-SCREEN-STATUS OF OLD-REC NOT = "R"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF OLD-RAW(1474:2) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE OLD-RAW(1474:2) TO BYTE-BUFFER
             MOVE 2 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF AML-REVIEW-STATUS OF OLD-REC NOT = "C"
               AND AML-REVIEW-STATUS OF OLD-REC NOT = "P"
               AND AML-REVIEW-STATUS OF OLD-REC NOT = "H"
               AND AML-REVIEW-STATUS OF OLD-REC NOT = "R"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF OLD-RAW(1476:2) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE OLD-RAW(1476:2) TO BYTE-BUFFER
             MOVE 2 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF ADVERSE-MEDIA-STATUS OF OLD-REC NOT = "C"
               AND ADVERSE-MEDIA-STATUS OF OLD-REC NOT = "P"
               AND ADVERSE-MEDIA-STATUS OF OLD-REC NOT = "H"
               AND ADVERSE-MEDIA-STATUS OF OLD-REC NOT = "R"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE OLD-RAW(1478:8) TO BYTE-BUFFER
             MOVE 8 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF RISK-REVIEW-DATE OF OLD-REC NOT = SPACES
               IF RISK-REVIEW-DATE OF OLD-REC < "00000000" OR
                 RISK-REVIEW-DATE OF OLD-REC > "99999999"
                 MOVE 8 TO RETURN-CODE
                 STOP RUN
               END-IF
               IF FUNCTION TEST-DATE-YYYYMMDD(
                 FUNCTION NUMVAL(
                   RISK-REVIEW-DATE OF OLD-REC))
                 NOT = 0
                 MOVE 8 TO RETURN-CODE
                 STOP RUN
               END-IF
             END-IF
             MOVE OLD-RAW(1486:8) TO BYTE-BUFFER
             MOVE 8 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF NEXT-RISK-REVIEW-DATE OF OLD-REC NOT = SPACES
               IF NEXT-RISK-REVIEW-DATE OF OLD-REC < "00000000" OR
                 NEXT-RISK-REVIEW-DATE OF OLD-REC > "99999999"
                 MOVE 8 TO RETURN-CODE
                 STOP RUN
               END-IF
               IF FUNCTION TEST-DATE-YYYYMMDD(
                 FUNCTION NUMVAL(
                   NEXT-RISK-REVIEW-DATE OF OLD-REC))
                 NOT = 0
                 MOVE 8 TO RETURN-CODE
                 STOP RUN
               END-IF
             END-IF
             IF OLD-RAW(1494:4) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE OLD-RAW(1494:4) TO BYTE-BUFFER
             MOVE 4 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF OLD-RAW(1501:2) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE OLD-RAW(1501:2) TO BYTE-BUFFER
             MOVE 2 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF BENEFICIAL-OWNER-STATUS OF OLD-REC NOT = "N"
               AND BENEFICIAL-OWNER-STATUS OF OLD-REC NOT = "P"
               AND BENEFICIAL-OWNER-STATUS OF OLD-REC NOT = "C"
               AND BENEFICIAL-OWNER-STATUS OF OLD-REC NOT = "R"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF OLD-RAW(1503:2) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE OLD-RAW(1503:2) TO BYTE-BUFFER
             MOVE 2 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF FATCA-STATUS OF OLD-REC NOT = "N"
               AND FATCA-STATUS OF OLD-REC NOT = "P"
               AND FATCA-STATUS OF OLD-REC NOT = "C"
               AND FATCA-STATUS OF OLD-REC NOT = "R"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF OLD-RAW(1505:2) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE OLD-RAW(1505:2) TO BYTE-BUFFER
             MOVE 2 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF CRS-STATUS OF OLD-REC NOT = "N"
               AND CRS-STATUS OF OLD-REC NOT = "P"
               AND CRS-STATUS OF OLD-REC NOT = "C"
               AND CRS-STATUS OF OLD-REC NOT = "R"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF OLD-RAW(1507:2) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE OLD-RAW(1507:2) TO BYTE-BUFFER
             MOVE 2 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF TAX-COUNTRY-CODE OF OLD-REC NOT = "JP"
               AND TAX-COUNTRY-CODE OF OLD-REC NOT = "US"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF OLD-RAW(1509:2) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE OLD-RAW(1509:2) TO BYTE-BUFFER
             MOVE 2 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF IDENTITY-VERIFICATION-STATUS OF OLD-REC NOT = "N"
               AND IDENTITY-VERIFICATION-STATUS OF OLD-REC NOT = "P"
               AND IDENTITY-VERIFICATION-STATUS OF OLD-REC NOT = "C"
               AND IDENTITY-VERIFICATION-STATUS OF OLD-REC NOT = "R"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF OLD-RAW(1511:1) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE OLD-RAW(1511:1) TO BYTE-BUFFER
             MOVE 1 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF WATCHLIST-INDICATOR OF OLD-REC NOT = "Y"
               AND WATCHLIST-INDICATOR OF OLD-REC NOT = "N"
               AND WATCHLIST-INDICATOR OF OLD-REC NOT = "U"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF OLD-RAW(1512:1) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE OLD-RAW(1512:1) TO BYTE-BUFFER
             MOVE 1 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF FRAUD-RISK-INDICATOR OF OLD-REC NOT = "Y"
               AND FRAUD-RISK-INDICATOR OF OLD-REC NOT = "N"
               AND FRAUD-RISK-INDICATOR OF OLD-REC NOT = "U"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE OLD-RAW(1513:8) TO BYTE-BUFFER
             MOVE 8 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF LAST-FRAUD-CASE-DATE OF OLD-REC NOT = SPACES
               IF LAST-FRAUD-CASE-DATE OF OLD-REC < "00000000" OR
                 LAST-FRAUD-CASE-DATE OF OLD-REC > "99999999"
                 MOVE 8 TO RETURN-CODE
                 STOP RUN
               END-IF
               IF FUNCTION TEST-DATE-YYYYMMDD(
                 FUNCTION NUMVAL(
                   LAST-FRAUD-CASE-DATE OF OLD-REC))
                 NOT = 0
                 MOVE 8 TO RETURN-CODE
                 STOP RUN
               END-IF
             END-IF
             MOVE OLD-RAW(1525:4) TO BYTE-BUFFER
             MOVE 4 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF HIGH-RISK-REASON-CODE OF OLD-REC NOT = SPACES AND
               HIGH-RISK-REASON-CODE OF OLD-REC NOT = "0000"
               AND HIGH-RISK-REASON-CODE OF OLD-REC NOT = "0001"
               AND HIGH-RISK-REASON-CODE OF OLD-REC NOT = "0002"
               AND HIGH-RISK-REASON-CODE OF OLD-REC NOT = "0003"
               AND HIGH-RISK-REASON-CODE OF OLD-REC NOT = "0004"
               AND HIGH-RISK-REASON-CODE OF OLD-REC NOT = "0005"
               AND HIGH-RISK-REASON-CODE OF OLD-REC NOT = "0006"
               AND HIGH-RISK-REASON-CODE OF OLD-REC NOT = "0007"
               AND HIGH-RISK-REASON-CODE OF OLD-REC NOT = "0008"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF OLD-RAW(1643:1) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE OLD-RAW(1643:1) TO BYTE-BUFFER
             MOVE 1 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF WEB-BANKING-PERMISSION OF OLD-REC NOT = "Y"
               AND WEB-BANKING-PERMISSION OF OLD-REC NOT = "N"
               AND WEB-BANKING-PERMISSION OF OLD-REC NOT = "U"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF OLD-RAW(1644:1) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE OLD-RAW(1644:1) TO BYTE-BUFFER
             MOVE 1 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF MOBILE-BANKING-PERMISSION OF OLD-REC NOT = "Y"
               AND MOBILE-BANKING-PERMISSION OF OLD-REC NOT = "N"
               AND MOBILE-BANKING-PERMISSION OF OLD-REC NOT = "U"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF OLD-RAW(1645:1) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE OLD-RAW(1645:1) TO BYTE-BUFFER
             MOVE 1 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF ATM-ACCESS-PERMISSION OF OLD-REC NOT = "Y"
               AND ATM-ACCESS-PERMISSION OF OLD-REC NOT = "N"
               AND ATM-ACCESS-PERMISSION OF OLD-REC NOT = "U"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF OLD-RAW(1646:1) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE OLD-RAW(1646:1) TO BYTE-BUFFER
             MOVE 1 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF PHONE-BANKING-PERMISSION OF OLD-REC NOT = "Y"
               AND PHONE-BANKING-PERMISSION OF OLD-REC NOT = "N"
               AND PHONE-BANKING-PERMISSION OF OLD-REC NOT = "U"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF OLD-RAW(1647:1) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE OLD-RAW(1647:1) TO BYTE-BUFFER
             MOVE 1 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF BRANCH-SERVICE-PERMISSION OF OLD-REC NOT = "Y"
               AND BRANCH-SERVICE-PERMISSION OF OLD-REC NOT = "N"
               AND BRANCH-SERVICE-PERMISSION OF OLD-REC NOT = "U"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF OLD-RAW(1648:1) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE OLD-RAW(1648:1) TO BYTE-BUFFER
             MOVE 1 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF API-ACCESS-PERMISSION OF OLD-REC NOT = "Y"
               AND API-ACCESS-PERMISSION OF OLD-REC NOT = "N"
               AND API-ACCESS-PERMISSION OF OLD-REC NOT = "U"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF OLD-RAW(1649:1) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE OLD-RAW(1649:1) TO BYTE-BUFFER
             MOVE 1 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF OPEN-BANKING-PERMISSION OF OLD-REC NOT = "Y"
               AND OPEN-BANKING-PERMISSION OF OLD-REC NOT = "N"
               AND OPEN-BANKING-PERMISSION OF OLD-REC NOT = "U"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF OLD-RAW(1650:1) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE OLD-RAW(1650:1) TO BYTE-BUFFER
             MOVE 1 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF EMAIL-NOTICE-PERMISSION OF OLD-REC NOT = "Y"
               AND EMAIL-NOTICE-PERMISSION OF OLD-REC NOT = "N"
               AND EMAIL-NOTICE-PERMISSION OF OLD-REC NOT = "U"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF OLD-RAW(1651:1) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE OLD-RAW(1651:1) TO BYTE-BUFFER
             MOVE 1 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF SMS-NOTICE-PERMISSION OF OLD-REC NOT = "Y"
               AND SMS-NOTICE-PERMISSION OF OLD-REC NOT = "N"
               AND SMS-NOTICE-PERMISSION OF OLD-REC NOT = "U"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF OLD-RAW(1652:1) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE OLD-RAW(1652:1) TO BYTE-BUFFER
             MOVE 1 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF PUSH-NOTICE-PERMISSION OF OLD-REC NOT = "Y"
               AND PUSH-NOTICE-PERMISSION OF OLD-REC NOT = "N"
               AND PUSH-NOTICE-PERMISSION OF OLD-REC NOT = "U"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF OLD-RAW(1653:1) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE OLD-RAW(1653:1) TO BYTE-BUFFER
             MOVE 1 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF BIOMETRIC-AUTH-PERMISSION OF OLD-REC NOT = "Y"
               AND BIOMETRIC-AUTH-PERMISSION OF OLD-REC NOT = "N"
               AND BIOMETRIC-AUTH-PERMISSION OF OLD-REC NOT = "U"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF OLD-RAW(1654:1) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE OLD-RAW(1654:1) TO BYTE-BUFFER
             MOVE 1 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF MFA-REQUIRED OF OLD-REC NOT = "Y"
               AND MFA-REQUIRED OF OLD-REC NOT = "N"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF OLD-RAW(1655:1) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE OLD-RAW(1655:1) TO BYTE-BUFFER
             MOVE 1 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF VOICEPRINT-ENROLLED OF OLD-REC NOT = "Y"
               AND VOICEPRINT-ENROLLED OF OLD-REC NOT = "N"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF OLD-RAW(1656:1) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE OLD-RAW(1656:1) TO BYTE-BUFFER
             MOVE 1 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF CARD-NOT-PRESENT-PERMISSION OF OLD-REC NOT = "Y"
               AND CARD-NOT-PRESENT-PERMISSION OF OLD-REC NOT = "N"
               AND CARD-NOT-PRESENT-PERMISSION OF OLD-REC NOT = "U"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF OLD-RAW(1657:1) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE OLD-RAW(1657:1) TO BYTE-BUFFER
             MOVE 1 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF INTERNATIONAL-CHANNEL-PERMISSION OF OLD-REC NOT = "Y"
               AND INTERNATIONAL-CHANNEL-PERMISSION OF OLD-REC NOT = "N"
               AND INTERNATIONAL-CHANNEL-PERMISSION OF OLD-REC NOT = "U"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE OLD-RAW(1658:8) TO BYTE-BUFFER
             MOVE 8 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF CHANNEL-PERMISSION-EXPIRY OF OLD-REC NOT = SPACES
               IF CHANNEL-PERMISSION-EXPIRY OF OLD-REC < "00000000" OR
                 CHANNEL-PERMISSION-EXPIRY OF OLD-REC > "99999999"
                 MOVE 8 TO RETURN-CODE
                 STOP RUN
               END-IF
               IF FUNCTION TEST-DATE-YYYYMMDD(
                 FUNCTION NUMVAL(
                   CHANNEL-PERMISSION-EXPIRY OF OLD-REC))
                 NOT = 0
                 MOVE 8 TO RETURN-CODE
                 STOP RUN
               END-IF
             END-IF
             IF OLD-RAW(1666:10) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE OLD-RAW(1666:10) TO BYTE-BUFFER
             MOVE 10 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF OLD-RAW(1676:14) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE OLD-RAW(1676:14) TO BYTE-BUFFER
             MOVE 14 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF CREATED-TIMESTAMP OF OLD-REC(1:8) < "00000000" OR
               CREATED-TIMESTAMP OF OLD-REC(1:8) > "99999999"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF FUNCTION TEST-DATE-YYYYMMDD(
               FUNCTION NUMVAL(
                 CREATED-TIMESTAMP OF OLD-REC(1:8)))
               NOT = 0
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF OLD-RAW(1690:10) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE OLD-RAW(1690:10) TO BYTE-BUFFER
             MOVE 10 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF OLD-RAW(1700:14) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE OLD-RAW(1700:14) TO BYTE-BUFFER
             MOVE 14 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF UPDATED-TIMESTAMP OF OLD-REC(1:8) < "00000000" OR
               UPDATED-TIMESTAMP OF OLD-REC(1:8) > "99999999"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF FUNCTION TEST-DATE-YYYYMMDD(
               FUNCTION NUMVAL(
                 UPDATED-TIMESTAMP OF OLD-REC(1:8)))
               NOT = 0
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF OLD-RAW(1714:12) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE OLD-RAW(1714:12) TO BYTE-BUFFER
             MOVE 12 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF OLD-RAW(1726:4) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE OLD-RAW(1726:4) TO BYTE-BUFFER
             MOVE 4 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF OLD-RAW(1736:4) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE OLD-RAW(1736:4) TO BYTE-BUFFER
             MOVE 4 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF OLD-RAW(1740:10) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE OLD-RAW(1740:10) TO BYTE-BUFFER
             MOVE 10 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF OLD-RAW(1750:14) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE OLD-RAW(1750:14) TO BYTE-BUFFER
             MOVE 14 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF APPROVED-TIMESTAMP OF OLD-REC(1:8) < "00000000" OR
               APPROVED-TIMESTAMP OF OLD-REC(1:8) > "99999999"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF FUNCTION TEST-DATE-YYYYMMDD(
               FUNCTION NUMVAL(
                 APPROVED-TIMESTAMP OF OLD-REC(1:8)))
               NOT = 0
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF OLD-RAW(1764:14) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE OLD-RAW(1764:14) TO BYTE-BUFFER
             MOVE 14 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF LAST-REVIEW-TIMESTAMP OF OLD-REC(1:8) < "00000000" OR
               LAST-REVIEW-TIMESTAMP OF OLD-REC(1:8) > "99999999"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF FUNCTION TEST-DATE-YYYYMMDD(
               FUNCTION NUMVAL(
                 LAST-REVIEW-TIMESTAMP OF OLD-REC(1:8)))
               NOT = 0
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF OLD-RAW(1778:1) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE OLD-RAW(1778:1) TO BYTE-BUFFER
             MOVE 1 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF SYNC-STATE OF OLD-REC NOT = "P"
               AND SYNC-STATE OF OLD-REC NOT = "S"
               AND SYNC-STATE OF OLD-REC NOT = "E"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF CONTACT-TIME-FROM OF OLD-REC NOT = SPACES
               IF CONTACT-TIME-FROM OF OLD-REC < "0000" OR
                 CONTACT-TIME-FROM OF OLD-REC > "2359" OR
                 CONTACT-TIME-FROM OF OLD-REC(3:2) > "59" OR
                 CONTACT-TIME-FROM OF OLD-REC(1:2) > "23"
                 MOVE 8 TO RETURN-CODE
                 STOP RUN
               END-IF
             END-IF
             IF CONTACT-TIME-TO OF OLD-REC NOT = SPACES
               IF CONTACT-TIME-TO OF OLD-REC < "0000" OR
                 CONTACT-TIME-TO OF OLD-REC > "2359" OR
                 CONTACT-TIME-TO OF OLD-REC(3:2) > "59" OR
                 CONTACT-TIME-TO OF OLD-REC(1:2) > "23"
                 MOVE 8 TO RETURN-CODE
                 STOP RUN
               END-IF
             END-IF
             IF OLD-RAW(1064:3) = SPACES AND
               OLD-RAW(1067:6) = SPACES AND
               OLD-RAW(1073:16) = SPACES
               CONTINUE
             ELSE
               IF OLD-RAW(1064:3) = SPACES OR
                 OLD-RAW(1067:6) = SPACES OR
                 OLD-RAW(1073:16) = SPACES
                 MOVE 8 TO RETURN-CODE
                 STOP RUN
               END-IF
             END-IF
             IF OLD-RAW(1089:3) = SPACES AND
               OLD-RAW(1092:6) = SPACES AND
               OLD-RAW(1098:16) = SPACES
               CONTINUE
             ELSE
               IF OLD-RAW(1089:3) = SPACES OR
                 OLD-RAW(1092:6) = SPACES OR
                 OLD-RAW(1098:16) = SPACES
                 MOVE 8 TO RETURN-CODE
                 STOP RUN
               END-IF
             END-IF
             IF OLD-RAW(1263:4) NOT = SPACES
               MOVE OLD-RAW(1263:4) TO BYTE-BUFFER
               MOVE 4 TO BYTE-LENGTH
               PERFORM CHECK-DIGITS
               IF CONTACT-TIME-FROM OF OLD-REC(1:2) > "23" OR
                 CONTACT-TIME-FROM OF OLD-REC(3:2) > "59"
                 MOVE 8 TO RETURN-CODE
                 STOP RUN
               END-IF
             END-IF
             IF OLD-RAW(1267:4) NOT = SPACES
               MOVE OLD-RAW(1267:4) TO BYTE-BUFFER
               MOVE 4 TO BYTE-LENGTH
               PERFORM CHECK-DIGITS
               IF CONTACT-TIME-TO OF OLD-REC(1:2) > "23" OR
                 CONTACT-TIME-TO OF OLD-REC(3:2) > "59"
                 MOVE 8 TO RETURN-CODE
                 STOP RUN
               END-IF
             END-IF
             MOVE OLD-RAW(12:10) TO BYTE-BUFFER
             MOVE 10 TO BYTE-LENGTH
             PERFORM CHECK-DIGITS
             MOVE OLD-RAW(484:6) TO BYTE-BUFFER
             MOVE 6 TO BYTE-LENGTH
             PERFORM CHECK-DIGITS
             MOVE OLD-RAW(1452:6) TO BYTE-BUFFER
             MOVE 6 TO BYTE-LENGTH
             PERFORM CHECK-DIGITS
             MOVE OLD-RAW(511:2) TO BYTE-BUFFER
             MOVE 2 TO BYTE-LENGTH
             PERFORM CHECK-DIGITS
             IF OLD-RAW(1064:3) NOT = SPACES
               MOVE OLD-RAW(1064:3) TO BYTE-BUFFER
               MOVE 3 TO BYTE-LENGTH
               PERFORM CHECK-DIGITS
             END-IF
             IF OLD-RAW(1067:6) NOT = SPACES
               MOVE OLD-RAW(1067:6) TO BYTE-BUFFER
               MOVE 6 TO BYTE-LENGTH
               PERFORM CHECK-DIGITS
             END-IF
             IF OLD-RAW(1073:16) NOT = SPACES
               MOVE OLD-RAW(1073:16) TO BYTE-BUFFER
               MOVE 16 TO BYTE-LENGTH
               PERFORM CHECK-DIGITS
             END-IF
             IF OLD-RAW(1089:3) NOT = SPACES
               MOVE OLD-RAW(1089:3) TO BYTE-BUFFER
               MOVE 3 TO BYTE-LENGTH
               PERFORM CHECK-DIGITS
             END-IF
             IF OLD-RAW(1092:6) NOT = SPACES
               MOVE OLD-RAW(1092:6) TO BYTE-BUFFER
               MOVE 6 TO BYTE-LENGTH
               PERFORM CHECK-DIGITS
             END-IF
             IF OLD-RAW(1098:16) NOT = SPACES
               MOVE OLD-RAW(1098:16) TO BYTE-BUFFER
               MOVE 16 TO BYTE-LENGTH
               PERFORM CHECK-DIGITS
             END-IF
             IF OLD-RAW(1242:3) NOT = SPACES
               MOVE OLD-RAW(1242:3) TO BYTE-BUFFER
               MOVE 3 TO BYTE-LENGTH
               PERFORM CHECK-DIGITS
             END-IF
             IF OLD-RAW(1245:16) NOT = SPACES
               MOVE OLD-RAW(1245:16) TO BYTE-BUFFER
               MOVE 16 TO BYTE-LENGTH
               PERFORM CHECK-DIGITS
             END-IF
             IF HOME-BRANCH-ID OF OLD-REC = "000000"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF SERVICING-BRANCH-ID OF OLD-REC = "000000"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF CUSTOMER-RISK-GRADE OF OLD-REC < "01" OR
               CUSTOMER-RISK-GRADE OF OLD-REC > "09"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF OLD-RAW(1404:16) NOT = SPACES
               IF OLD-RAW(1404:4) NOT = "****"
                 MOVE 8 TO RETURN-CODE
                 STOP RUN
               END-IF
               MOVE OLD-RAW(1408:12) TO BYTE-BUFFER
               MOVE 12 TO BYTE-LENGTH
               PERFORM CHECK-DIGITS
             END-IF
             IF ADDRESS-COUNTRY OF OLD-REC = "JP"
               IF OLD-RAW(519:3) < "000" OR
                 OLD-RAW(519:3) > "999" OR
                 OLD-RAW(522:1) NOT = "-" OR
                 OLD-RAW(523:4) < "0000" OR
                 OLD-RAW(523:4) > "9999" OR
                 OLD-RAW(527:2) NOT = SPACES
                 MOVE 8 TO RETURN-CODE
                 STOP RUN
               END-IF
             ELSE
               IF OLD-RAW(519:5) < "00000" OR
                 OLD-RAW(519:5) > "99999" OR
                 OLD-RAW(524:5) NOT = SPACES
                 MOVE 8 TO RETURN-CODE
                 STOP RUN
               END-IF
             END-IF
             MOVE CUSTOMER-ID OF OLD-REC TO OLD-LAST-KEY
             MOVE "Y" TO OLD-SEEN
           END-IF.
       READ-NEW.
           READ NEW-FILE
           IF NEW-STATUS = "10"
               MOVE "Y" TO NEW-EOF
           ELSE
             IF NEW-STATUS NOT = "00"
               MOVE 12 TO RETURN-CODE
               STOP RUN
             END-IF
             ADD 1 TO NEW-COUNT
             IF LAYOUT-VERSION OF NEW-REC NOT = "001"
               OR BINARY-ABI-CODE OF NEW-REC NOT = "GCOB32BE"
               OR CUSTOMER-ID OF NEW-REC IS NOT NUMERIC
               OR CUSTOMER-ID OF NEW-REC = "0000000000"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF NEW-SEEN = "Y" AND CUSTOMER-ID OF NEW-REC
               <= NEW-LAST-KEY
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF REVISION-NO OF NEW-REC IS NOT NUMERIC
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF RELATIONSHIP-COUNT OF NEW-REC IS NOT NUMERIC
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF ACTIVE-LOAN-COUNT OF NEW-REC IS NOT NUMERIC
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF RISK-SCORE OF NEW-REC IS NOT NUMERIC
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF RISK-SCORE OF NEW-REC < -100000 OR
               RISK-SCORE OF NEW-REC > 100000
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF KYC-DOCUMENT-COUNT OF NEW-REC IS NOT NUMERIC
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF OPEN-CASE-COUNT OF NEW-REC IS NOT NUMERIC
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF RISK-SCORE-ADJUSTMENT OF NEW-REC IS NOT NUMERIC
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF RISK-SCORE-ADJUSTMENT OF NEW-REC < -9999.99 OR
               RISK-SCORE-ADJUSTMENT OF NEW-REC > 9999.99
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF DAILY-TRANSFER-LIMIT OF NEW-REC IS NOT NUMERIC
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF DAILY-TRANSFER-LIMIT OF NEW-REC < 0
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF DAILY-CASH-LIMIT OF NEW-REC IS NOT NUMERIC
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF DAILY-CASH-LIMIT OF NEW-REC < 0
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF MONTHLY-TRANSFER-LIMIT OF NEW-REC IS NOT NUMERIC
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF MONTHLY-TRANSFER-LIMIT OF NEW-REC < 0
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF PER-TRANSACTION-LIMIT OF NEW-REC IS NOT NUMERIC
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF PER-TRANSACTION-LIMIT OF NEW-REC < 0
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF ONLINE-TRANSFER-LIMIT OF NEW-REC IS NOT NUMERIC
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF ONLINE-TRANSFER-LIMIT OF NEW-REC < 0
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF INTERNATIONAL-TRANSFER-LIMIT OF NEW-REC IS NOT NUMERIC
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF INTERNATIONAL-TRANSFER-LIMIT OF NEW-REC < 0
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF ATM-WITHDRAWAL-LIMIT OF NEW-REC IS NOT NUMERIC
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF ATM-WITHDRAWAL-LIMIT OF NEW-REC < 0
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF POS-PURCHASE-LIMIT OF NEW-REC IS NOT NUMERIC
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF POS-PURCHASE-LIMIT OF NEW-REC < 0
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF WIRE-TRANSFER-LIMIT OF NEW-REC IS NOT NUMERIC
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF WIRE-TRANSFER-LIMIT OF NEW-REC < 0
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF BRANCH-CASH-LIMIT OF NEW-REC IS NOT NUMERIC
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF BRANCH-CASH-LIMIT OF NEW-REC < 0
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF NEW-BENEFICIARY-LIMIT OF NEW-REC IS NOT NUMERIC
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF NEW-BENEFICIARY-LIMIT OF NEW-REC < 0
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF ROLLING-7DAY-LIMIT OF NEW-REC IS NOT NUMERIC
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF ROLLING-7DAY-LIMIT OF NEW-REC < 0
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF ROLLING-30DAY-LIMIT OF NEW-REC IS NOT NUMERIC
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF ROLLING-30DAY-LIMIT OF NEW-REC < 0
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF CARD-PURCHASE-LIMIT OF NEW-REC IS NOT NUMERIC
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF CARD-PURCHASE-LIMIT OF NEW-REC < 0
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF CASH-ADVANCE-LIMIT OF NEW-REC IS NOT NUMERIC
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF CASH-ADVANCE-LIMIT OF NEW-REC < 0
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF LOAN-PAYMENT-LIMIT OF NEW-REC IS NOT NUMERIC
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF LOAN-PAYMENT-LIMIT OF NEW-REC < 0
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF MOBILE-TRANSFER-LIMIT OF NEW-REC IS NOT NUMERIC
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF MOBILE-TRANSFER-LIMIT OF NEW-REC < 0
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF CASH-DEPOSIT-LIMIT OF NEW-REC IS NOT NUMERIC
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF CASH-DEPOSIT-LIMIT OF NEW-REC < 0
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF UPDATE-SEQUENCE-NO OF NEW-REC IS NOT NUMERIC
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF NEW-RAW(1:3) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE NEW-RAW(1:3) TO BYTE-BUFFER
             MOVE 3 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF NEW-RAW(4:8) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE NEW-RAW(4:8) TO BYTE-BUFFER
             MOVE 8 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF NEW-RAW(12:10) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE NEW-RAW(12:10) TO BYTE-BUFFER
             MOVE 10 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF NEW-RAW(22:1) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE NEW-RAW(22:1) TO BYTE-BUFFER
             MOVE 1 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF RECORD-STATUS OF NEW-REC NOT = "A"
               AND RECORD-STATUS OF NEW-REC NOT = "I"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF NEW-RAW(23:4) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE NEW-RAW(23:4) TO BYTE-BUFFER
             MOVE 4 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF NEW-RAW(27:8) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE NEW-RAW(27:8) TO BYTE-BUFFER
             MOVE 8 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF EFFECTIVE-DATE OF NEW-REC NOT = SPACES
               IF EFFECTIVE-DATE OF NEW-REC < "00000000" OR
                 EFFECTIVE-DATE OF NEW-REC > "99999999"
                 MOVE 8 TO RETURN-CODE
                 STOP RUN
               END-IF
               IF NEW-RAW(27:8) NOT = SPACES
               MOVE NEW-RAW(27:8) TO BYTE-BUFFER
               MOVE 8 TO BYTE-LENGTH
               PERFORM CHECK-DIGITS
             END-IF
             IF NEW-RAW(35:8) NOT = SPACES
               MOVE NEW-RAW(35:8) TO BYTE-BUFFER
               MOVE 8 TO BYTE-LENGTH
               PERFORM CHECK-DIGITS
             END-IF
             IF NEW-RAW(339:8) NOT = SPACES
               MOVE NEW-RAW(339:8) TO BYTE-BUFFER
               MOVE 8 TO BYTE-LENGTH
               PERFORM CHECK-DIGITS
             END-IF
             IF NEW-RAW(388:8) NOT = SPACES
               MOVE NEW-RAW(388:8) TO BYTE-BUFFER
               MOVE 8 TO BYTE-LENGTH
               PERFORM CHECK-DIGITS
             END-IF
             IF NEW-RAW(490:8) NOT = SPACES
               MOVE NEW-RAW(490:8) TO BYTE-BUFFER
               MOVE 8 TO BYTE-LENGTH
               PERFORM CHECK-DIGITS
             END-IF
             IF NEW-RAW(498:8) NOT = SPACES
               MOVE NEW-RAW(498:8) TO BYTE-BUFFER
               MOVE 8 TO BYTE-LENGTH
               PERFORM CHECK-DIGITS
             END-IF
             IF NEW-RAW(1036:8) NOT = SPACES
               MOVE NEW-RAW(1036:8) TO BYTE-BUFFER
               MOVE 8 TO BYTE-LENGTH
               PERFORM CHECK-DIGITS
             END-IF
             IF NEW-RAW(1044:8) NOT = SPACES
               MOVE NEW-RAW(1044:8) TO BYTE-BUFFER
               MOVE 8 TO BYTE-LENGTH
               PERFORM CHECK-DIGITS
             END-IF
             IF NEW-RAW(1056:8) NOT = SPACES
               MOVE NEW-RAW(1056:8) TO BYTE-BUFFER
               MOVE 8 TO BYTE-LENGTH
               PERFORM CHECK-DIGITS
             END-IF
             IF NEW-RAW(1424:8) NOT = SPACES
               MOVE NEW-RAW(1424:8) TO BYTE-BUFFER
               MOVE 8 TO BYTE-LENGTH
               PERFORM CHECK-DIGITS
             END-IF
             IF NEW-RAW(1432:8) NOT = SPACES
               MOVE NEW-RAW(1432:8) TO BYTE-BUFFER
               MOVE 8 TO BYTE-LENGTH
               PERFORM CHECK-DIGITS
             END-IF
             IF NEW-RAW(1478:8) NOT = SPACES
               MOVE NEW-RAW(1478:8) TO BYTE-BUFFER
               MOVE 8 TO BYTE-LENGTH
               PERFORM CHECK-DIGITS
             END-IF
             IF NEW-RAW(1486:8) NOT = SPACES
               MOVE NEW-RAW(1486:8) TO BYTE-BUFFER
               MOVE 8 TO BYTE-LENGTH
               PERFORM CHECK-DIGITS
             END-IF
             IF NEW-RAW(1513:8) NOT = SPACES
               MOVE NEW-RAW(1513:8) TO BYTE-BUFFER
               MOVE 8 TO BYTE-LENGTH
               PERFORM CHECK-DIGITS
             END-IF
             IF NEW-RAW(1658:8) NOT = SPACES
               MOVE NEW-RAW(1658:8) TO BYTE-BUFFER
               MOVE 8 TO BYTE-LENGTH
               PERFORM CHECK-DIGITS
             END-IF
             IF NEW-RAW(1676:14) NOT = SPACES
               MOVE NEW-RAW(1676:14) TO BYTE-BUFFER
               MOVE 14 TO BYTE-LENGTH
               PERFORM CHECK-DIGITS
             END-IF
             IF NEW-RAW(1700:14) NOT = SPACES
               MOVE NEW-RAW(1700:14) TO BYTE-BUFFER
               MOVE 14 TO BYTE-LENGTH
               PERFORM CHECK-DIGITS
             END-IF
             IF NEW-RAW(1750:14) NOT = SPACES
               MOVE NEW-RAW(1750:14) TO BYTE-BUFFER
               MOVE 14 TO BYTE-LENGTH
               PERFORM CHECK-DIGITS
             END-IF
             IF NEW-RAW(1764:14) NOT = SPACES
               MOVE NEW-RAW(1764:14) TO BYTE-BUFFER
               MOVE 14 TO BYTE-LENGTH
               PERFORM CHECK-DIGITS
             END-IF
             IF FUNCTION TEST-DATE-YYYYMMDD(
                 FUNCTION NUMVAL(
                   EFFECTIVE-DATE OF NEW-REC))
                 NOT = 0
                 MOVE 8 TO RETURN-CODE
                 STOP RUN
               END-IF
               IF LAST-REVIEW-TIMESTAMP OF NEW-REC(9:2) > "23" OR
                 LAST-REVIEW-TIMESTAMP OF NEW-REC(11:2) > "59" OR
                 LAST-REVIEW-TIMESTAMP OF NEW-REC(13:2) > "59"
                 MOVE 8 TO RETURN-CODE
                 STOP RUN
               END-IF
               IF APPROVED-TIMESTAMP OF NEW-REC(9:2) > "23" OR
                 APPROVED-TIMESTAMP OF NEW-REC(11:2) > "59" OR
                 APPROVED-TIMESTAMP OF NEW-REC(13:2) > "59"
                 MOVE 8 TO RETURN-CODE
                 STOP RUN
               END-IF
               IF UPDATED-TIMESTAMP OF NEW-REC(9:2) > "23" OR
                 UPDATED-TIMESTAMP OF NEW-REC(11:2) > "59" OR
                 UPDATED-TIMESTAMP OF NEW-REC(13:2) > "59"
                 MOVE 8 TO RETURN-CODE
                 STOP RUN
               END-IF
               IF CREATED-TIMESTAMP OF NEW-REC(9:2) > "23" OR
                 CREATED-TIMESTAMP OF NEW-REC(11:2) > "59" OR
                 CREATED-TIMESTAMP OF NEW-REC(13:2) > "59"
                 MOVE 8 TO RETURN-CODE
                 STOP RUN
               END-IF
             END-IF
             IF NEW-RAW(35:8) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE NEW-RAW(35:8) TO BYTE-BUFFER
             MOVE 8 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF RECORD-DATE OF NEW-REC NOT = SPACES
               IF RECORD-DATE OF NEW-REC < "00000000" OR
                 RECORD-DATE OF NEW-REC > "99999999"
                 MOVE 8 TO RETURN-CODE
                 STOP RUN
               END-IF
               IF FUNCTION TEST-DATE-YYYYMMDD(
                 FUNCTION NUMVAL(
                   RECORD-DATE OF NEW-REC))
                 NOT = 0
                 MOVE 8 TO RETURN-CODE
                 STOP RUN
               END-IF
             END-IF
             IF NEW-RAW(43:12) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE NEW-RAW(43:12) TO BYTE-BUFFER
             MOVE 12 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF NEW-RAW(59:32) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE NEW-RAW(59:32) TO BYTE-BUFFER
             MOVE 32 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF NEW-RAW(91:32) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE NEW-RAW(91:32) TO BYTE-BUFFER
             MOVE 32 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             MOVE NEW-RAW(123:24) TO BYTE-BUFFER
             MOVE 24 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF NEW-RAW(147:64) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE NEW-RAW(147:64) TO BYTE-BUFFER
             MOVE 64 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF NEW-RAW(211:32) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE NEW-RAW(211:32) TO BYTE-BUFFER
             MOVE 32 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF NEW-RAW(243:32) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE NEW-RAW(243:32) TO BYTE-BUFFER
             MOVE 32 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF NEW-RAW(275:32) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE NEW-RAW(275:32) TO BYTE-BUFFER
             MOVE 32 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF NEW-RAW(307:32) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE NEW-RAW(307:32) TO BYTE-BUFFER
             MOVE 32 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             MOVE NEW-RAW(339:8) TO BYTE-BUFFER
             MOVE 8 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF BIRTH-DATE OF NEW-REC NOT = SPACES
               IF BIRTH-DATE OF NEW-REC < "00000000" OR
                 BIRTH-DATE OF NEW-REC > "99999999"
                 MOVE 8 TO RETURN-CODE
                 STOP RUN
               END-IF
               IF FUNCTION TEST-DATE-YYYYMMDD(
                 FUNCTION NUMVAL(
                   BIRTH-DATE OF NEW-REC))
                 NOT = 0
                 MOVE 8 TO RETURN-CODE
                 STOP RUN
               END-IF
             END-IF
             IF NEW-RAW(347:2) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE NEW-RAW(347:2) TO BYTE-BUFFER
             MOVE 2 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF BIRTH-COUNTRY OF NEW-REC NOT = "JP"
               AND BIRTH-COUNTRY OF NEW-REC NOT = "US"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE NEW-RAW(349:3) TO BYTE-BUFFER
             MOVE 3 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF NEW-RAW(352:2) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE NEW-RAW(352:2) TO BYTE-BUFFER
             MOVE 2 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF NATIONALITY-CODE OF NEW-REC NOT = "JP"
               AND NATIONALITY-CODE OF NEW-REC NOT = "US"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF NEW-RAW(354:2) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE NEW-RAW(354:2) TO BYTE-BUFFER
             MOVE 2 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF CITIZENSHIP-CODE OF NEW-REC NOT = "JP"
               AND CITIZENSHIP-CODE OF NEW-REC NOT = "US"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF NEW-RAW(356:2) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE NEW-RAW(356:2) TO BYTE-BUFFER
             MOVE 2 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF RESIDENCY-CODE OF NEW-REC NOT = "JP"
               AND RESIDENCY-CODE OF NEW-REC NOT = "US"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF NEW-RAW(358:2) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE NEW-RAW(358:2) TO BYTE-BUFFER
             MOVE 2 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF TAX-RESIDENCY-CODE OF NEW-REC NOT = "JP"
               AND TAX-RESIDENCY-CODE OF NEW-REC NOT = "US"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF NEW-RAW(360:4) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE NEW-RAW(360:4) TO BYTE-BUFFER
             MOVE 4 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF ID-DOCUMENT-TYPE OF NEW-REC NOT = "PASS"
               AND ID-DOCUMENT-TYPE OF NEW-REC NOT = "DL"
               AND ID-DOCUMENT-TYPE OF NEW-REC NOT = "NAT"
               AND ID-DOCUMENT-TYPE OF NEW-REC NOT = "RES"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE NEW-RAW(364:24) TO BYTE-BUFFER
             MOVE 24 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             PERFORM CHECK-ID-MASK
             MOVE NEW-RAW(388:8) TO BYTE-BUFFER
             MOVE 8 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF ID-DOCUMENT-EXPIRY OF NEW-REC NOT = SPACES
               IF ID-DOCUMENT-EXPIRY OF NEW-REC < "00000000" OR
                 ID-DOCUMENT-EXPIRY OF NEW-REC > "99999999"
                 MOVE 8 TO RETURN-CODE
                 STOP RUN
               END-IF
               IF FUNCTION TEST-DATE-YYYYMMDD(
                 FUNCTION NUMVAL(
                   ID-DOCUMENT-EXPIRY OF NEW-REC))
                 NOT = 0
                 MOVE 8 TO RETURN-CODE
                 STOP RUN
               END-IF
             END-IF
             MOVE NEW-RAW(396:32) TO BYTE-BUFFER
             MOVE 32 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             MOVE NEW-RAW(428:32) TO BYTE-BUFFER
             MOVE 32 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF NEW-RAW(460:1) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE NEW-RAW(460:1) TO BYTE-BUFFER
             MOVE 1 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF CUSTOMER-CLASSIFICATION OF NEW-REC NOT = "A"
               AND CUSTOMER-CLASSIFICATION OF NEW-REC NOT = "B"
               AND CUSTOMER-CLASSIFICATION OF NEW-REC NOT = "C"
               AND CUSTOMER-CLASSIFICATION OF NEW-REC NOT = "D"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF NEW-RAW(461:3) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE NEW-RAW(461:3) TO BYTE-BUFFER
             MOVE 3 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF CUSTOMER-TYPE OF NEW-REC NOT = "IND"
               AND CUSTOMER-TYPE OF NEW-REC NOT = "ORG"
               AND CUSTOMER-TYPE OF NEW-REC NOT = "TRU"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF NEW-RAW(464:4) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE NEW-RAW(464:4) TO BYTE-BUFFER
             MOVE 4 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF NEW-RAW(468:6) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE NEW-RAW(468:6) TO BYTE-BUFFER
             MOVE 6 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF NEW-RAW(474:10) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE NEW-RAW(474:10) TO BYTE-BUFFER
             MOVE 10 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF NEW-RAW(484:6) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE NEW-RAW(484:6) TO BYTE-BUFFER
             MOVE 6 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF NEW-RAW(490:8) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE NEW-RAW(490:8) TO BYTE-BUFFER
             MOVE 8 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF CUSTOMER-SINCE-DATE OF NEW-REC NOT = SPACES
               IF CUSTOMER-SINCE-DATE OF NEW-REC < "00000000" OR
                 CUSTOMER-SINCE-DATE OF NEW-REC > "99999999"
                 MOVE 8 TO RETURN-CODE
                 STOP RUN
               END-IF
               IF FUNCTION TEST-DATE-YYYYMMDD(
                 FUNCTION NUMVAL(
                   CUSTOMER-SINCE-DATE OF NEW-REC))
                 NOT = 0
                 MOVE 8 TO RETURN-CODE
                 STOP RUN
               END-IF
             END-IF
             MOVE NEW-RAW(498:8) TO BYTE-BUFFER
             MOVE 8 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF CUSTOMER-END-DATE OF NEW-REC NOT = SPACES
               IF CUSTOMER-END-DATE OF NEW-REC < "00000000" OR
                 CUSTOMER-END-DATE OF NEW-REC > "99999999"
                 MOVE 8 TO RETURN-CODE
                 STOP RUN
               END-IF
               IF FUNCTION TEST-DATE-YYYYMMDD(
                 FUNCTION NUMVAL(
                   CUSTOMER-END-DATE OF NEW-REC))
                 NOT = 0
                 MOVE 8 TO RETURN-CODE
                 STOP RUN
               END-IF
             END-IF
             IF NEW-RAW(506:2) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE NEW-RAW(506:2) TO BYTE-BUFFER
             MOVE 2 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF PREFERRED-LANGUAGE OF NEW-REC NOT = "EN"
               AND PREFERRED-LANGUAGE OF NEW-REC NOT = "JA"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF NEW-RAW(508:2) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE NEW-RAW(508:2) TO BYTE-BUFFER
             MOVE 2 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF AGE-BAND-CODE OF NEW-REC NOT = "00"
               AND AGE-BAND-CODE OF NEW-REC NOT = "18"
               AND AGE-BAND-CODE OF NEW-REC NOT = "25"
               AND AGE-BAND-CODE OF NEW-REC NOT = "35"
               AND AGE-BAND-CODE OF NEW-REC NOT = "45"
               AND AGE-BAND-CODE OF NEW-REC NOT = "55"
               AND AGE-BAND-CODE OF NEW-REC NOT = "65"
               AND AGE-BAND-CODE OF NEW-REC NOT = "75"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF NEW-RAW(510:1) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE NEW-RAW(510:1) TO BYTE-BUFFER
             MOVE 1 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF MARKETING-PERMISSION OF NEW-REC NOT = "Y"
               AND MARKETING-PERMISSION OF NEW-REC NOT = "N"
               AND MARKETING-PERMISSION OF NEW-REC NOT = "U"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF NEW-RAW(511:2) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE NEW-RAW(511:2) TO BYTE-BUFFER
             MOVE 2 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF NEW-RAW(513:2) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE NEW-RAW(513:2) TO BYTE-BUFFER
             MOVE 2 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF KYC-STATUS OF NEW-REC NOT = "N"
               AND KYC-STATUS OF NEW-REC NOT = "P"
               AND KYC-STATUS OF NEW-REC NOT = "C"
               AND KYC-STATUS OF NEW-REC NOT = "R"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF NEW-RAW(515:2) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE NEW-RAW(515:2) TO BYTE-BUFFER
             MOVE 2 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF CUSTOMER-TIER OF NEW-REC NOT = "01"
               AND CUSTOMER-TIER OF NEW-REC NOT = "02"
               AND CUSTOMER-TIER OF NEW-REC NOT = "03"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF NEW-RAW(517:2) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE NEW-RAW(517:2) TO BYTE-BUFFER
             MOVE 2 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF ADDRESS-COUNTRY OF NEW-REC NOT = "JP"
               AND ADDRESS-COUNTRY OF NEW-REC NOT = "US"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF NEW-RAW(519:10) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE NEW-RAW(519:10) TO BYTE-BUFFER
             MOVE 10 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF NEW-RAW(529:4) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE NEW-RAW(529:4) TO BYTE-BUFFER
             MOVE 4 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF REGION-CODE OF NEW-REC NOT = "E01"
               AND REGION-CODE OF NEW-REC NOT = "W01"
               AND REGION-CODE OF NEW-REC NOT = "N01"
               AND REGION-CODE OF NEW-REC NOT = "S01"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE NEW-RAW(533:32) TO BYTE-BUFFER
             MOVE 32 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF NEW-RAW(565:4) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE NEW-RAW(565:4) TO BYTE-BUFFER
             MOVE 4 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             MOVE NEW-RAW(569:32) TO BYTE-BUFFER
             MOVE 32 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF NEW-RAW(601:6) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE NEW-RAW(601:6) TO BYTE-BUFFER
             MOVE 6 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF NEW-RAW(607:32) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE NEW-RAW(607:32) TO BYTE-BUFFER
             MOVE 32 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             MOVE NEW-RAW(639:32) TO BYTE-BUFFER
             MOVE 32 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF NEW-RAW(671:40) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE NEW-RAW(671:40) TO BYTE-BUFFER
             MOVE 40 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             MOVE NEW-RAW(711:40) TO BYTE-BUFFER
             MOVE 40 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             MOVE NEW-RAW(751:40) TO BYTE-BUFFER
             MOVE 40 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             MOVE NEW-RAW(791:40) TO BYTE-BUFFER
             MOVE 40 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             MOVE NEW-RAW(831:40) TO BYTE-BUFFER
             MOVE 40 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             MOVE NEW-RAW(871:4) TO BYTE-BUFFER
             MOVE 4 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             MOVE NEW-RAW(875:8) TO BYTE-BUFFER
             MOVE 8 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             MOVE NEW-RAW(883:40) TO BYTE-BUFFER
             MOVE 40 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             MOVE NEW-RAW(923:64) TO BYTE-BUFFER
             MOVE 64 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             MOVE NEW-RAW(987:12) TO BYTE-BUFFER
             MOVE 12 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF NEW-RAW(999:1) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE NEW-RAW(999:1) TO BYTE-BUFFER
             MOVE 1 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF MAILING-PREFERENCE OF NEW-REC NOT = "Y"
               AND MAILING-PREFERENCE OF NEW-REC NOT = "N"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE NEW-RAW(1000:32) TO BYTE-BUFFER
             MOVE 32 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF NEW-RAW(1032:4) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE NEW-RAW(1032:4) TO BYTE-BUFFER
             MOVE 4 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF TAX-JURISDICTION OF NEW-REC NOT = "JP01"
               AND TAX-JURISDICTION OF NEW-REC NOT = "US01"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF NEW-RAW(1036:8) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE NEW-RAW(1036:8) TO BYTE-BUFFER
             MOVE 8 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF ADDRESS-VALID-FROM OF NEW-REC NOT = SPACES
               IF ADDRESS-VALID-FROM OF NEW-REC < "00000000" OR
                 ADDRESS-VALID-FROM OF NEW-REC > "99999999"
                 MOVE 8 TO RETURN-CODE
                 STOP RUN
               END-IF
               IF FUNCTION TEST-DATE-YYYYMMDD(
                 FUNCTION NUMVAL(
                   ADDRESS-VALID-FROM OF NEW-REC))
                 NOT = 0
                 MOVE 8 TO RETURN-CODE
                 STOP RUN
               END-IF
             END-IF
             MOVE NEW-RAW(1044:8) TO BYTE-BUFFER
             MOVE 8 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF ADDRESS-VALID-TO OF NEW-REC NOT = SPACES
               IF ADDRESS-VALID-TO OF NEW-REC < "00000000" OR
                 ADDRESS-VALID-TO OF NEW-REC > "99999999"
                 MOVE 8 TO RETURN-CODE
                 STOP RUN
               END-IF
               IF FUNCTION TEST-DATE-YYYYMMDD(
                 FUNCTION NUMVAL(
                   ADDRESS-VALID-TO OF NEW-REC))
                 NOT = 0
                 MOVE 8 TO RETURN-CODE
                 STOP RUN
               END-IF
             END-IF
             IF NEW-RAW(1052:4) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE NEW-RAW(1052:4) TO BYTE-BUFFER
             MOVE 4 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF ADDRESS-SOURCE OF NEW-REC NOT = "CUS"
               AND ADDRESS-SOURCE OF NEW-REC NOT = "BRN"
               AND ADDRESS-SOURCE OF NEW-REC NOT = "KYC"
               AND ADDRESS-SOURCE OF NEW-REC NOT = "MIG"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF NEW-RAW(1056:8) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE NEW-RAW(1056:8) TO BYTE-BUFFER
             MOVE 8 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF ADDRESS-VERIFIED-DATE OF NEW-REC NOT = SPACES
               IF ADDRESS-VERIFIED-DATE OF NEW-REC < "00000000" OR
                 ADDRESS-VERIFIED-DATE OF NEW-REC > "99999999"
                 MOVE 8 TO RETURN-CODE
                 STOP RUN
               END-IF
               IF FUNCTION TEST-DATE-YYYYMMDD(
                 FUNCTION NUMVAL(
                   ADDRESS-VERIFIED-DATE OF NEW-REC))
                 NOT = 0
                 MOVE 8 TO RETURN-CODE
                 STOP RUN
               END-IF
             END-IF
             MOVE NEW-RAW(1064:3) TO BYTE-BUFFER
             MOVE 3 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             MOVE NEW-RAW(1067:6) TO BYTE-BUFFER
             MOVE 6 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             MOVE NEW-RAW(1073:16) TO BYTE-BUFFER
             MOVE 16 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             MOVE NEW-RAW(1089:3) TO BYTE-BUFFER
             MOVE 3 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             MOVE NEW-RAW(1092:6) TO BYTE-BUFFER
             MOVE 6 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             MOVE NEW-RAW(1098:16) TO BYTE-BUFFER
             MOVE 16 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             MOVE NEW-RAW(1114:64) TO BYTE-BUFFER
             MOVE 64 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             MOVE NEW-RAW(1178:64) TO BYTE-BUFFER
             MOVE 64 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             MOVE NEW-RAW(1242:3) TO BYTE-BUFFER
             MOVE 3 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             MOVE NEW-RAW(1245:16) TO BYTE-BUFFER
             MOVE 16 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF NEW-RAW(1261:2) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE NEW-RAW(1261:2) TO BYTE-BUFFER
             MOVE 2 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF PREFERRED-CONTACT-CHANNEL OF NEW-REC NOT = "BR"
               AND PREFERRED-CONTACT-CHANNEL OF NEW-REC NOT = "PH"
               AND PREFERRED-CONTACT-CHANNEL OF NEW-REC NOT = "EM"
               AND PREFERRED-CONTACT-CHANNEL OF NEW-REC NOT = "MB"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE NEW-RAW(1263:4) TO BYTE-BUFFER
             MOVE 4 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             MOVE NEW-RAW(1267:4) TO BYTE-BUFFER
             MOVE 4 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF NEW-RAW(1271:2) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE NEW-RAW(1271:2) TO BYTE-BUFFER
             MOVE 2 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF CONTACT-LANGUAGE OF NEW-REC NOT = "EN"
               AND CONTACT-LANGUAGE OF NEW-REC NOT = "JA"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF NEW-RAW(1273:1) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE NEW-RAW(1273:1) TO BYTE-BUFFER
             MOVE 1 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF SMS-CONSENT OF NEW-REC NOT = "Y"
               AND SMS-CONSENT OF NEW-REC NOT = "N"
               AND SMS-CONSENT OF NEW-REC NOT = "U"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF NEW-RAW(1274:1) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE NEW-RAW(1274:1) TO BYTE-BUFFER
             MOVE 1 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF EMAIL-CONSENT OF NEW-REC NOT = "Y"
               AND EMAIL-CONSENT OF NEW-REC NOT = "N"
               AND EMAIL-CONSENT OF NEW-REC NOT = "U"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF NEW-RAW(1275:1) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE NEW-RAW(1275:1) TO BYTE-BUFFER
             MOVE 1 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF VOICE-CONSENT OF NEW-REC NOT = "Y"
               AND VOICE-CONSENT OF NEW-REC NOT = "N"
               AND VOICE-CONSENT OF NEW-REC NOT = "U"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF NEW-RAW(1276:2) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE NEW-RAW(1276:2) TO BYTE-BUFFER
             MOVE 2 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF NOTICE-DELIVERY-METHOD OF NEW-REC NOT = "EM"
               AND NOTICE-DELIVERY-METHOD OF NEW-REC NOT = "SM"
               AND NOTICE-DELIVERY-METHOD OF NEW-REC NOT = "PT"
               AND NOTICE-DELIVERY-METHOD OF NEW-REC NOT = "PU"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE NEW-RAW(1278:32) TO BYTE-BUFFER
             MOVE 32 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             MOVE NEW-RAW(1310:3) TO BYTE-BUFFER
             MOVE 3 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF EMERGENCY-RELATION-CODE OF NEW-REC NOT = SPACES AND
               EMERGENCY-RELATION-CODE OF NEW-REC NOT = "FAM"
               AND EMERGENCY-RELATION-CODE OF NEW-REC NOT = "SPO"
               AND EMERGENCY-RELATION-CODE OF NEW-REC NOT = "FRI"
               AND EMERGENCY-RELATION-CODE OF NEW-REC NOT = "OTH"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE NEW-RAW(1313:24) TO BYTE-BUFFER
             MOVE 24 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             MOVE NEW-RAW(1337:64) TO BYTE-BUFFER
             MOVE 64 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             MOVE NEW-RAW(1404:16) TO BYTE-BUFFER
             MOVE 16 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF NEW-RAW(1420:4) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE NEW-RAW(1420:4) TO BYTE-BUFFER
             MOVE 4 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF PRODUCT-FAMILY-CODE OF NEW-REC NOT = "DEP"
               AND PRODUCT-FAMILY-CODE OF NEW-REC NOT = "CRD"
               AND PRODUCT-FAMILY-CODE OF NEW-REC NOT = "LON"
               AND PRODUCT-FAMILY-CODE OF NEW-REC NOT = "INV"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF NEW-RAW(1424:8) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE NEW-RAW(1424:8) TO BYTE-BUFFER
             MOVE 8 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF FIRST-ACCOUNT-OPEN-DATE OF NEW-REC NOT = SPACES
               IF FIRST-ACCOUNT-OPEN-DATE OF NEW-REC < "00000000" OR
                 FIRST-ACCOUNT-OPEN-DATE OF NEW-REC > "99999999"
                 MOVE 8 TO RETURN-CODE
                 STOP RUN
               END-IF
               IF FUNCTION TEST-DATE-YYYYMMDD(
                 FUNCTION NUMVAL(
                   FIRST-ACCOUNT-OPEN-DATE OF NEW-REC))
                 NOT = 0
                 MOVE 8 TO RETURN-CODE
                 STOP RUN
               END-IF
             END-IF
             MOVE NEW-RAW(1432:8) TO BYTE-BUFFER
             MOVE 8 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF LAST-ACCOUNT-CLOSE-DATE OF NEW-REC NOT = SPACES
               IF LAST-ACCOUNT-CLOSE-DATE OF NEW-REC < "00000000" OR
                 LAST-ACCOUNT-CLOSE-DATE OF NEW-REC > "99999999"
                 MOVE 8 TO RETURN-CODE
                 STOP RUN
               END-IF
               IF FUNCTION TEST-DATE-YYYYMMDD(
                 FUNCTION NUMVAL(
                   LAST-ACCOUNT-CLOSE-DATE OF NEW-REC))
                 NOT = 0
                 MOVE 8 TO RETURN-CODE
                 STOP RUN
               END-IF
             END-IF
             IF NEW-RAW(1440:3) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE NEW-RAW(1440:3) TO BYTE-BUFFER
             MOVE 3 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF PRIMARY-CURRENCY OF NEW-REC NOT = "JPY"
               AND PRIMARY-CURRENCY OF NEW-REC NOT = "USD"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF NEW-RAW(1443:2) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE NEW-RAW(1443:2) TO BYTE-BUFFER
             MOVE 2 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF STATEMENT-CYCLE-CODE OF NEW-REC NOT = "M"
               AND STATEMENT-CYCLE-CODE OF NEW-REC NOT = "Q"
               AND STATEMENT-CYCLE-CODE OF NEW-REC NOT = "A"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF NEW-RAW(1445:1) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE NEW-RAW(1445:1) TO BYTE-BUFFER
             MOVE 1 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF OVERDRAFT-PERMISSION OF NEW-REC NOT = "Y"
               AND OVERDRAFT-PERMISSION OF NEW-REC NOT = "N"
               AND OVERDRAFT-PERMISSION OF NEW-REC NOT = "U"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF NEW-RAW(1446:1) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE NEW-RAW(1446:1) TO BYTE-BUFFER
             MOVE 1 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF DEBIT-CARD-ENROLLED OF NEW-REC NOT = "Y"
               AND DEBIT-CARD-ENROLLED OF NEW-REC NOT = "N"
               AND DEBIT-CARD-ENROLLED OF NEW-REC NOT = "U"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF NEW-RAW(1447:1) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE NEW-RAW(1447:1) TO BYTE-BUFFER
             MOVE 1 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF CREDIT-CARD-ENROLLED OF NEW-REC NOT = "Y"
               AND CREDIT-CARD-ENROLLED OF NEW-REC NOT = "N"
               AND CREDIT-CARD-ENROLLED OF NEW-REC NOT = "U"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF NEW-RAW(1448:1) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE NEW-RAW(1448:1) TO BYTE-BUFFER
             MOVE 1 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF LOAN-RELATIONSHIP OF NEW-REC NOT = "Y"
               AND LOAN-RELATIONSHIP OF NEW-REC NOT = "N"
               AND LOAN-RELATIONSHIP OF NEW-REC NOT = "U"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF NEW-RAW(1449:1) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE NEW-RAW(1449:1) TO BYTE-BUFFER
             MOVE 1 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF DEPOSIT-RELATIONSHIP OF NEW-REC NOT = "Y"
               AND DEPOSIT-RELATIONSHIP OF NEW-REC NOT = "N"
               AND DEPOSIT-RELATIONSHIP OF NEW-REC NOT = "U"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF NEW-RAW(1450:2) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE NEW-RAW(1450:2) TO BYTE-BUFFER
             MOVE 2 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF ACCOUNT-SERVICE-TIER OF NEW-REC NOT = "01"
               AND ACCOUNT-SERVICE-TIER OF NEW-REC NOT = "02"
               AND ACCOUNT-SERVICE-TIER OF NEW-REC NOT = "03"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF NEW-RAW(1452:6) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE NEW-RAW(1452:6) TO BYTE-BUFFER
             MOVE 6 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF NEW-RAW(1461:2) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE NEW-RAW(1461:2) TO BYTE-BUFFER
             MOVE 2 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF OWNERSHIP-ROLE-CODE OF NEW-REC NOT = "PR"
               AND OWNERSHIP-ROLE-CODE OF NEW-REC NOT = "JO"
               AND OWNERSHIP-ROLE-CODE OF NEW-REC NOT = "AU"
               AND OWNERSHIP-ROLE-CODE OF NEW-REC NOT = "BE"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF NEW-RAW(1463:1) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE NEW-RAW(1463:1) TO BYTE-BUFFER
             MOVE 1 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF ACCOUNT-DIGITAL-ACCESS OF NEW-REC NOT = "Y"
               AND ACCOUNT-DIGITAL-ACCESS OF NEW-REC NOT = "N"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF NEW-RAW(1464:3) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE NEW-RAW(1464:3) TO BYTE-BUFFER
             MOVE 3 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF ACCOUNT-RESTRICTION-CODE OF NEW-REC NOT = "000"
               AND ACCOUNT-RESTRICTION-CODE OF NEW-REC NOT = "001"
               AND ACCOUNT-RESTRICTION-CODE OF NEW-REC NOT = "002"
               AND ACCOUNT-RESTRICTION-CODE OF NEW-REC NOT = "003"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF NEW-RAW(1471:1) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE NEW-RAW(1471:1) TO BYTE-BUFFER
             MOVE 1 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF PEP-INDICATOR OF NEW-REC NOT = "Y"
               AND PEP-INDICATOR OF NEW-REC NOT = "N"
               AND PEP-INDICATOR OF NEW-REC NOT = "U"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF NEW-RAW(1472:2) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE NEW-RAW(1472:2) TO BYTE-BUFFER
             MOVE 2 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF SANCTIONS-SCREEN-STATUS OF NEW-REC NOT = "C"
               AND SANCTIONS-SCREEN-STATUS OF NEW-REC NOT = "P"
               AND SANCTIONS-SCREEN-STATUS OF NEW-REC NOT = "H"
               AND SANCTIONS-SCREEN-STATUS OF NEW-REC NOT = "R"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF NEW-RAW(1474:2) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE NEW-RAW(1474:2) TO BYTE-BUFFER
             MOVE 2 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF AML-REVIEW-STATUS OF NEW-REC NOT = "C"
               AND AML-REVIEW-STATUS OF NEW-REC NOT = "P"
               AND AML-REVIEW-STATUS OF NEW-REC NOT = "H"
               AND AML-REVIEW-STATUS OF NEW-REC NOT = "R"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF NEW-RAW(1476:2) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE NEW-RAW(1476:2) TO BYTE-BUFFER
             MOVE 2 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF ADVERSE-MEDIA-STATUS OF NEW-REC NOT = "C"
               AND ADVERSE-MEDIA-STATUS OF NEW-REC NOT = "P"
               AND ADVERSE-MEDIA-STATUS OF NEW-REC NOT = "H"
               AND ADVERSE-MEDIA-STATUS OF NEW-REC NOT = "R"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE NEW-RAW(1478:8) TO BYTE-BUFFER
             MOVE 8 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF RISK-REVIEW-DATE OF NEW-REC NOT = SPACES
               IF RISK-REVIEW-DATE OF NEW-REC < "00000000" OR
                 RISK-REVIEW-DATE OF NEW-REC > "99999999"
                 MOVE 8 TO RETURN-CODE
                 STOP RUN
               END-IF
               IF FUNCTION TEST-DATE-YYYYMMDD(
                 FUNCTION NUMVAL(
                   RISK-REVIEW-DATE OF NEW-REC))
                 NOT = 0
                 MOVE 8 TO RETURN-CODE
                 STOP RUN
               END-IF
             END-IF
             MOVE NEW-RAW(1486:8) TO BYTE-BUFFER
             MOVE 8 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF NEXT-RISK-REVIEW-DATE OF NEW-REC NOT = SPACES
               IF NEXT-RISK-REVIEW-DATE OF NEW-REC < "00000000" OR
                 NEXT-RISK-REVIEW-DATE OF NEW-REC > "99999999"
                 MOVE 8 TO RETURN-CODE
                 STOP RUN
               END-IF
               IF FUNCTION TEST-DATE-YYYYMMDD(
                 FUNCTION NUMVAL(
                   NEXT-RISK-REVIEW-DATE OF NEW-REC))
                 NOT = 0
                 MOVE 8 TO RETURN-CODE
                 STOP RUN
               END-IF
             END-IF
             IF NEW-RAW(1494:4) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE NEW-RAW(1494:4) TO BYTE-BUFFER
             MOVE 4 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF NEW-RAW(1501:2) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE NEW-RAW(1501:2) TO BYTE-BUFFER
             MOVE 2 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF BENEFICIAL-OWNER-STATUS OF NEW-REC NOT = "N"
               AND BENEFICIAL-OWNER-STATUS OF NEW-REC NOT = "P"
               AND BENEFICIAL-OWNER-STATUS OF NEW-REC NOT = "C"
               AND BENEFICIAL-OWNER-STATUS OF NEW-REC NOT = "R"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF NEW-RAW(1503:2) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE NEW-RAW(1503:2) TO BYTE-BUFFER
             MOVE 2 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF FATCA-STATUS OF NEW-REC NOT = "N"
               AND FATCA-STATUS OF NEW-REC NOT = "P"
               AND FATCA-STATUS OF NEW-REC NOT = "C"
               AND FATCA-STATUS OF NEW-REC NOT = "R"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF NEW-RAW(1505:2) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE NEW-RAW(1505:2) TO BYTE-BUFFER
             MOVE 2 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF CRS-STATUS OF NEW-REC NOT = "N"
               AND CRS-STATUS OF NEW-REC NOT = "P"
               AND CRS-STATUS OF NEW-REC NOT = "C"
               AND CRS-STATUS OF NEW-REC NOT = "R"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF NEW-RAW(1507:2) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE NEW-RAW(1507:2) TO BYTE-BUFFER
             MOVE 2 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF TAX-COUNTRY-CODE OF NEW-REC NOT = "JP"
               AND TAX-COUNTRY-CODE OF NEW-REC NOT = "US"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF NEW-RAW(1509:2) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE NEW-RAW(1509:2) TO BYTE-BUFFER
             MOVE 2 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF IDENTITY-VERIFICATION-STATUS OF NEW-REC NOT = "N"
               AND IDENTITY-VERIFICATION-STATUS OF NEW-REC NOT = "P"
               AND IDENTITY-VERIFICATION-STATUS OF NEW-REC NOT = "C"
               AND IDENTITY-VERIFICATION-STATUS OF NEW-REC NOT = "R"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF NEW-RAW(1511:1) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE NEW-RAW(1511:1) TO BYTE-BUFFER
             MOVE 1 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF WATCHLIST-INDICATOR OF NEW-REC NOT = "Y"
               AND WATCHLIST-INDICATOR OF NEW-REC NOT = "N"
               AND WATCHLIST-INDICATOR OF NEW-REC NOT = "U"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF NEW-RAW(1512:1) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE NEW-RAW(1512:1) TO BYTE-BUFFER
             MOVE 1 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF FRAUD-RISK-INDICATOR OF NEW-REC NOT = "Y"
               AND FRAUD-RISK-INDICATOR OF NEW-REC NOT = "N"
               AND FRAUD-RISK-INDICATOR OF NEW-REC NOT = "U"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE NEW-RAW(1513:8) TO BYTE-BUFFER
             MOVE 8 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF LAST-FRAUD-CASE-DATE OF NEW-REC NOT = SPACES
               IF LAST-FRAUD-CASE-DATE OF NEW-REC < "00000000" OR
                 LAST-FRAUD-CASE-DATE OF NEW-REC > "99999999"
                 MOVE 8 TO RETURN-CODE
                 STOP RUN
               END-IF
               IF FUNCTION TEST-DATE-YYYYMMDD(
                 FUNCTION NUMVAL(
                   LAST-FRAUD-CASE-DATE OF NEW-REC))
                 NOT = 0
                 MOVE 8 TO RETURN-CODE
                 STOP RUN
               END-IF
             END-IF
             MOVE NEW-RAW(1525:4) TO BYTE-BUFFER
             MOVE 4 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF HIGH-RISK-REASON-CODE OF NEW-REC NOT = SPACES AND
               HIGH-RISK-REASON-CODE OF NEW-REC NOT = "0000"
               AND HIGH-RISK-REASON-CODE OF NEW-REC NOT = "0001"
               AND HIGH-RISK-REASON-CODE OF NEW-REC NOT = "0002"
               AND HIGH-RISK-REASON-CODE OF NEW-REC NOT = "0003"
               AND HIGH-RISK-REASON-CODE OF NEW-REC NOT = "0004"
               AND HIGH-RISK-REASON-CODE OF NEW-REC NOT = "0005"
               AND HIGH-RISK-REASON-CODE OF NEW-REC NOT = "0006"
               AND HIGH-RISK-REASON-CODE OF NEW-REC NOT = "0007"
               AND HIGH-RISK-REASON-CODE OF NEW-REC NOT = "0008"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF NEW-RAW(1643:1) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE NEW-RAW(1643:1) TO BYTE-BUFFER
             MOVE 1 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF WEB-BANKING-PERMISSION OF NEW-REC NOT = "Y"
               AND WEB-BANKING-PERMISSION OF NEW-REC NOT = "N"
               AND WEB-BANKING-PERMISSION OF NEW-REC NOT = "U"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF NEW-RAW(1644:1) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE NEW-RAW(1644:1) TO BYTE-BUFFER
             MOVE 1 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF MOBILE-BANKING-PERMISSION OF NEW-REC NOT = "Y"
               AND MOBILE-BANKING-PERMISSION OF NEW-REC NOT = "N"
               AND MOBILE-BANKING-PERMISSION OF NEW-REC NOT = "U"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF NEW-RAW(1645:1) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE NEW-RAW(1645:1) TO BYTE-BUFFER
             MOVE 1 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF ATM-ACCESS-PERMISSION OF NEW-REC NOT = "Y"
               AND ATM-ACCESS-PERMISSION OF NEW-REC NOT = "N"
               AND ATM-ACCESS-PERMISSION OF NEW-REC NOT = "U"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF NEW-RAW(1646:1) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE NEW-RAW(1646:1) TO BYTE-BUFFER
             MOVE 1 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF PHONE-BANKING-PERMISSION OF NEW-REC NOT = "Y"
               AND PHONE-BANKING-PERMISSION OF NEW-REC NOT = "N"
               AND PHONE-BANKING-PERMISSION OF NEW-REC NOT = "U"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF NEW-RAW(1647:1) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE NEW-RAW(1647:1) TO BYTE-BUFFER
             MOVE 1 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF BRANCH-SERVICE-PERMISSION OF NEW-REC NOT = "Y"
               AND BRANCH-SERVICE-PERMISSION OF NEW-REC NOT = "N"
               AND BRANCH-SERVICE-PERMISSION OF NEW-REC NOT = "U"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF NEW-RAW(1648:1) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE NEW-RAW(1648:1) TO BYTE-BUFFER
             MOVE 1 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF API-ACCESS-PERMISSION OF NEW-REC NOT = "Y"
               AND API-ACCESS-PERMISSION OF NEW-REC NOT = "N"
               AND API-ACCESS-PERMISSION OF NEW-REC NOT = "U"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF NEW-RAW(1649:1) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE NEW-RAW(1649:1) TO BYTE-BUFFER
             MOVE 1 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF OPEN-BANKING-PERMISSION OF NEW-REC NOT = "Y"
               AND OPEN-BANKING-PERMISSION OF NEW-REC NOT = "N"
               AND OPEN-BANKING-PERMISSION OF NEW-REC NOT = "U"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF NEW-RAW(1650:1) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE NEW-RAW(1650:1) TO BYTE-BUFFER
             MOVE 1 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF EMAIL-NOTICE-PERMISSION OF NEW-REC NOT = "Y"
               AND EMAIL-NOTICE-PERMISSION OF NEW-REC NOT = "N"
               AND EMAIL-NOTICE-PERMISSION OF NEW-REC NOT = "U"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF NEW-RAW(1651:1) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE NEW-RAW(1651:1) TO BYTE-BUFFER
             MOVE 1 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF SMS-NOTICE-PERMISSION OF NEW-REC NOT = "Y"
               AND SMS-NOTICE-PERMISSION OF NEW-REC NOT = "N"
               AND SMS-NOTICE-PERMISSION OF NEW-REC NOT = "U"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF NEW-RAW(1652:1) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE NEW-RAW(1652:1) TO BYTE-BUFFER
             MOVE 1 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF PUSH-NOTICE-PERMISSION OF NEW-REC NOT = "Y"
               AND PUSH-NOTICE-PERMISSION OF NEW-REC NOT = "N"
               AND PUSH-NOTICE-PERMISSION OF NEW-REC NOT = "U"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF NEW-RAW(1653:1) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE NEW-RAW(1653:1) TO BYTE-BUFFER
             MOVE 1 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF BIOMETRIC-AUTH-PERMISSION OF NEW-REC NOT = "Y"
               AND BIOMETRIC-AUTH-PERMISSION OF NEW-REC NOT = "N"
               AND BIOMETRIC-AUTH-PERMISSION OF NEW-REC NOT = "U"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF NEW-RAW(1654:1) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE NEW-RAW(1654:1) TO BYTE-BUFFER
             MOVE 1 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF MFA-REQUIRED OF NEW-REC NOT = "Y"
               AND MFA-REQUIRED OF NEW-REC NOT = "N"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF NEW-RAW(1655:1) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE NEW-RAW(1655:1) TO BYTE-BUFFER
             MOVE 1 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF VOICEPRINT-ENROLLED OF NEW-REC NOT = "Y"
               AND VOICEPRINT-ENROLLED OF NEW-REC NOT = "N"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF NEW-RAW(1656:1) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE NEW-RAW(1656:1) TO BYTE-BUFFER
             MOVE 1 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF CARD-NOT-PRESENT-PERMISSION OF NEW-REC NOT = "Y"
               AND CARD-NOT-PRESENT-PERMISSION OF NEW-REC NOT = "N"
               AND CARD-NOT-PRESENT-PERMISSION OF NEW-REC NOT = "U"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF NEW-RAW(1657:1) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE NEW-RAW(1657:1) TO BYTE-BUFFER
             MOVE 1 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF INTERNATIONAL-CHANNEL-PERMISSION OF NEW-REC NOT = "Y"
               AND INTERNATIONAL-CHANNEL-PERMISSION OF NEW-REC NOT = "N"
               AND INTERNATIONAL-CHANNEL-PERMISSION OF NEW-REC NOT = "U"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE NEW-RAW(1658:8) TO BYTE-BUFFER
             MOVE 8 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF CHANNEL-PERMISSION-EXPIRY OF NEW-REC NOT = SPACES
               IF CHANNEL-PERMISSION-EXPIRY OF NEW-REC < "00000000" OR
                 CHANNEL-PERMISSION-EXPIRY OF NEW-REC > "99999999"
                 MOVE 8 TO RETURN-CODE
                 STOP RUN
               END-IF
               IF FUNCTION TEST-DATE-YYYYMMDD(
                 FUNCTION NUMVAL(
                   CHANNEL-PERMISSION-EXPIRY OF NEW-REC))
                 NOT = 0
                 MOVE 8 TO RETURN-CODE
                 STOP RUN
               END-IF
             END-IF
             IF NEW-RAW(1666:10) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE NEW-RAW(1666:10) TO BYTE-BUFFER
             MOVE 10 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF NEW-RAW(1676:14) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE NEW-RAW(1676:14) TO BYTE-BUFFER
             MOVE 14 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF CREATED-TIMESTAMP OF NEW-REC(1:8) < "00000000" OR
               CREATED-TIMESTAMP OF NEW-REC(1:8) > "99999999"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF FUNCTION TEST-DATE-YYYYMMDD(
               FUNCTION NUMVAL(
                 CREATED-TIMESTAMP OF NEW-REC(1:8)))
               NOT = 0
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF NEW-RAW(1690:10) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE NEW-RAW(1690:10) TO BYTE-BUFFER
             MOVE 10 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF NEW-RAW(1700:14) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE NEW-RAW(1700:14) TO BYTE-BUFFER
             MOVE 14 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF UPDATED-TIMESTAMP OF NEW-REC(1:8) < "00000000" OR
               UPDATED-TIMESTAMP OF NEW-REC(1:8) > "99999999"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF FUNCTION TEST-DATE-YYYYMMDD(
               FUNCTION NUMVAL(
                 UPDATED-TIMESTAMP OF NEW-REC(1:8)))
               NOT = 0
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF NEW-RAW(1714:12) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE NEW-RAW(1714:12) TO BYTE-BUFFER
             MOVE 12 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF NEW-RAW(1726:4) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE NEW-RAW(1726:4) TO BYTE-BUFFER
             MOVE 4 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF NEW-RAW(1736:4) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE NEW-RAW(1736:4) TO BYTE-BUFFER
             MOVE 4 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF NEW-RAW(1740:10) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE NEW-RAW(1740:10) TO BYTE-BUFFER
             MOVE 10 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF NEW-RAW(1750:14) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE NEW-RAW(1750:14) TO BYTE-BUFFER
             MOVE 14 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF APPROVED-TIMESTAMP OF NEW-REC(1:8) < "00000000" OR
               APPROVED-TIMESTAMP OF NEW-REC(1:8) > "99999999"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF FUNCTION TEST-DATE-YYYYMMDD(
               FUNCTION NUMVAL(
                 APPROVED-TIMESTAMP OF NEW-REC(1:8)))
               NOT = 0
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF NEW-RAW(1764:14) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE NEW-RAW(1764:14) TO BYTE-BUFFER
             MOVE 14 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF LAST-REVIEW-TIMESTAMP OF NEW-REC(1:8) < "00000000" OR
               LAST-REVIEW-TIMESTAMP OF NEW-REC(1:8) > "99999999"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF FUNCTION TEST-DATE-YYYYMMDD(
               FUNCTION NUMVAL(
                 LAST-REVIEW-TIMESTAMP OF NEW-REC(1:8)))
               NOT = 0
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF NEW-RAW(1778:1) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE NEW-RAW(1778:1) TO BYTE-BUFFER
             MOVE 1 TO BYTE-LENGTH
             PERFORM CHECK-ASCII
             IF SYNC-STATE OF NEW-REC NOT = "P"
               AND SYNC-STATE OF NEW-REC NOT = "S"
               AND SYNC-STATE OF NEW-REC NOT = "E"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF CONTACT-TIME-FROM OF NEW-REC NOT = SPACES
               IF CONTACT-TIME-FROM OF NEW-REC < "0000" OR
                 CONTACT-TIME-FROM OF NEW-REC > "2359" OR
                 CONTACT-TIME-FROM OF NEW-REC(3:2) > "59" OR
                 CONTACT-TIME-FROM OF NEW-REC(1:2) > "23"
                 MOVE 8 TO RETURN-CODE
                 STOP RUN
               END-IF
             END-IF
             IF CONTACT-TIME-TO OF NEW-REC NOT = SPACES
               IF CONTACT-TIME-TO OF NEW-REC < "0000" OR
                 CONTACT-TIME-TO OF NEW-REC > "2359" OR
                 CONTACT-TIME-TO OF NEW-REC(3:2) > "59" OR
                 CONTACT-TIME-TO OF NEW-REC(1:2) > "23"
                 MOVE 8 TO RETURN-CODE
                 STOP RUN
               END-IF
             END-IF
             IF NEW-RAW(1064:3) = SPACES AND
               NEW-RAW(1067:6) = SPACES AND
               NEW-RAW(1073:16) = SPACES
               CONTINUE
             ELSE
               IF NEW-RAW(1064:3) = SPACES OR
                 NEW-RAW(1067:6) = SPACES OR
                 NEW-RAW(1073:16) = SPACES
                 MOVE 8 TO RETURN-CODE
                 STOP RUN
               END-IF
             END-IF
             IF NEW-RAW(1089:3) = SPACES AND
               NEW-RAW(1092:6) = SPACES AND
               NEW-RAW(1098:16) = SPACES
               CONTINUE
             ELSE
               IF NEW-RAW(1089:3) = SPACES OR
                 NEW-RAW(1092:6) = SPACES OR
                 NEW-RAW(1098:16) = SPACES
                 MOVE 8 TO RETURN-CODE
                 STOP RUN
               END-IF
             END-IF
             IF NEW-RAW(1263:4) NOT = SPACES
               MOVE NEW-RAW(1263:4) TO BYTE-BUFFER
               MOVE 4 TO BYTE-LENGTH
               PERFORM CHECK-DIGITS
               IF CONTACT-TIME-FROM OF NEW-REC(1:2) > "23" OR
                 CONTACT-TIME-FROM OF NEW-REC(3:2) > "59"
                 MOVE 8 TO RETURN-CODE
                 STOP RUN
               END-IF
             END-IF
             IF NEW-RAW(1267:4) NOT = SPACES
               MOVE NEW-RAW(1267:4) TO BYTE-BUFFER
               MOVE 4 TO BYTE-LENGTH
               PERFORM CHECK-DIGITS
               IF CONTACT-TIME-TO OF NEW-REC(1:2) > "23" OR
                 CONTACT-TIME-TO OF NEW-REC(3:2) > "59"
                 MOVE 8 TO RETURN-CODE
                 STOP RUN
               END-IF
             END-IF
             MOVE NEW-RAW(12:10) TO BYTE-BUFFER
             MOVE 10 TO BYTE-LENGTH
             PERFORM CHECK-DIGITS
             MOVE NEW-RAW(484:6) TO BYTE-BUFFER
             MOVE 6 TO BYTE-LENGTH
             PERFORM CHECK-DIGITS
             MOVE NEW-RAW(1452:6) TO BYTE-BUFFER
             MOVE 6 TO BYTE-LENGTH
             PERFORM CHECK-DIGITS
             MOVE NEW-RAW(511:2) TO BYTE-BUFFER
             MOVE 2 TO BYTE-LENGTH
             PERFORM CHECK-DIGITS
             IF NEW-RAW(1064:3) NOT = SPACES
               MOVE NEW-RAW(1064:3) TO BYTE-BUFFER
               MOVE 3 TO BYTE-LENGTH
               PERFORM CHECK-DIGITS
             END-IF
             IF NEW-RAW(1067:6) NOT = SPACES
               MOVE NEW-RAW(1067:6) TO BYTE-BUFFER
               MOVE 6 TO BYTE-LENGTH
               PERFORM CHECK-DIGITS
             END-IF
             IF NEW-RAW(1073:16) NOT = SPACES
               MOVE NEW-RAW(1073:16) TO BYTE-BUFFER
               MOVE 16 TO BYTE-LENGTH
               PERFORM CHECK-DIGITS
             END-IF
             IF NEW-RAW(1089:3) NOT = SPACES
               MOVE NEW-RAW(1089:3) TO BYTE-BUFFER
               MOVE 3 TO BYTE-LENGTH
               PERFORM CHECK-DIGITS
             END-IF
             IF NEW-RAW(1092:6) NOT = SPACES
               MOVE NEW-RAW(1092:6) TO BYTE-BUFFER
               MOVE 6 TO BYTE-LENGTH
               PERFORM CHECK-DIGITS
             END-IF
             IF NEW-RAW(1098:16) NOT = SPACES
               MOVE NEW-RAW(1098:16) TO BYTE-BUFFER
               MOVE 16 TO BYTE-LENGTH
               PERFORM CHECK-DIGITS
             END-IF
             IF NEW-RAW(1242:3) NOT = SPACES
               MOVE NEW-RAW(1242:3) TO BYTE-BUFFER
               MOVE 3 TO BYTE-LENGTH
               PERFORM CHECK-DIGITS
             END-IF
             IF NEW-RAW(1245:16) NOT = SPACES
               MOVE NEW-RAW(1245:16) TO BYTE-BUFFER
               MOVE 16 TO BYTE-LENGTH
               PERFORM CHECK-DIGITS
             END-IF
             IF HOME-BRANCH-ID OF NEW-REC = "000000"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF SERVICING-BRANCH-ID OF NEW-REC = "000000"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF CUSTOMER-RISK-GRADE OF NEW-REC < "01" OR
               CUSTOMER-RISK-GRADE OF NEW-REC > "09"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             IF NEW-RAW(1404:16) NOT = SPACES
               IF NEW-RAW(1404:4) NOT = "****"
                 MOVE 8 TO RETURN-CODE
                 STOP RUN
               END-IF
               MOVE NEW-RAW(1408:12) TO BYTE-BUFFER
               MOVE 12 TO BYTE-LENGTH
               PERFORM CHECK-DIGITS
             END-IF
             IF ADDRESS-COUNTRY OF NEW-REC = "JP"
               IF NEW-RAW(519:3) < "000" OR
                 NEW-RAW(519:3) > "999" OR
                 NEW-RAW(522:1) NOT = "-" OR
                 NEW-RAW(523:4) < "0000" OR
                 NEW-RAW(523:4) > "9999" OR
                 NEW-RAW(527:2) NOT = SPACES
                 MOVE 8 TO RETURN-CODE
                 STOP RUN
               END-IF
             ELSE
               IF NEW-RAW(519:5) < "00000" OR
                 NEW-RAW(519:5) > "99999" OR
                 NEW-RAW(524:5) NOT = SPACES
                 MOVE 8 TO RETURN-CODE
                 STOP RUN
               END-IF
             END-IF
             MOVE CUSTOMER-ID OF NEW-REC TO NEW-LAST-KEY
             MOVE "Y" TO NEW-SEEN
           END-IF.
       CHECK-ASCII.
           PERFORM VARYING BYTE-INDEX FROM 1 BY 1
             UNTIL BYTE-INDEX > BYTE-LENGTH
             IF FUNCTION ORD(BYTE-BUFFER(BYTE-INDEX:1)) < 33 OR
                FUNCTION ORD(BYTE-BUFFER(BYTE-INDEX:1)) > 127
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
           END-PERFORM.
       CHECK-DIGITS.
           PERFORM VARYING BYTE-INDEX FROM 1 BY 1
             UNTIL BYTE-INDEX > BYTE-LENGTH
             IF BYTE-BUFFER(BYTE-INDEX:1) < "0" OR
                BYTE-BUFFER(BYTE-INDEX:1) > "9"
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
           END-PERFORM.
       CHECK-ID-MASK.
           IF BYTE-BUFFER NOT = SPACES
             IF BYTE-BUFFER(1:4) = SPACES
               MOVE 8 TO RETURN-CODE
               STOP RUN
             END-IF
             MOVE "N" TO SPACE-SEEN
             PERFORM VARYING BYTE-INDEX FROM 1 BY 1
               UNTIL BYTE-INDEX > BYTE-LENGTH
               EVALUATE TRUE
                 WHEN BYTE-BUFFER(BYTE-INDEX:1) = SPACE
                   MOVE "Y" TO SPACE-SEEN
                 WHEN SPACE-SEEN = "Y"
                   MOVE 8 TO RETURN-CODE
                   STOP RUN
                 WHEN BYTE-BUFFER(BYTE-INDEX:1) >= "A" AND
                      BYTE-BUFFER(BYTE-INDEX:1) <= "Z"
                   CONTINUE
                 WHEN BYTE-BUFFER(BYTE-INDEX:1) >= "0" AND
                      BYTE-BUFFER(BYTE-INDEX:1) <= "9"
                   CONTINUE
                 WHEN BYTE-BUFFER(BYTE-INDEX:1) = "*" OR
                      BYTE-BUFFER(BYTE-INDEX:1) = "-"
                   CONTINUE
                 WHEN OTHER
                   MOVE 8 TO RETURN-CODE
                   STOP RUN
               END-EVALUATE
             END-PERFORM
           END-IF.
