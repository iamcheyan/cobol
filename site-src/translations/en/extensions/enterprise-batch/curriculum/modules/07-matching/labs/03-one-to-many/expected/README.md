# Independent expectations

The text files are determined from business policy and a manual transaction-by-transaction calculation. In `normal.txt`: account 1 ends at 1000+500−200−500=800; the reversal locates the first transaction even though it is not adjacent; transaction four is rejected for overdraft. The frozen account balance stays at 50, and account 3 has no transactions and balance 0. Input 5 = 3 accepted + 2 rejected; total opening 1050 + credits 500 − debits 700 = closing 850.

`boundary-aggregate-over-13.txt` has two rounds on account 1, each with credit/debit 9,000,000,000,000. Each account closing is valid each time, while credit and debit totals each reach 18,000,000,000,000. Account 2 then receives another credit of 9,000,000,000,000. Thus global credit is 27,000,000,000,000, debit 18,000,000,000,000, and closing balance 9,000,000,000,000. This case catches implementations that incorrectly use 13 digits for global amounts.

Each business-rejection expected file explicitly lists the rejection reason and the balance after rejection. RC8 fixtures have no expected published report because the expected result is no published directory. `check.py` compares every output byte for byte; whole-file trimming must not hide fixed-width differences.
