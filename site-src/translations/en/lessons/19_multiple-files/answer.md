# Lesson 19 Modification Exercise Reference Answers

These answers cover only the two modification exercises in `exercise.md`; no answer is provided for the Take It Further exercise. Make both changes to fixture copies in a temporary directory:

```sh
scratch=$(mktemp -d)
cp lesson.cob accounts.txt transactions.txt "$scratch/"
cd "$scratch"
cobc -fsyntax-only lesson.cob
cobc -x -Wall -o lesson_19 lesson.cob
```

## 1. Transaction File Ends Early

Keep only the first two lines of `transactions.txt` in the copy. The program continues to read the third master record independently, even though the transaction stream has already reached EOF. The final summary is:

```text
关闭完成 账户记录数=003 交易记录数=002
```

Transaction EOF sets only `WS-TRANSACTION-EOF`; the master EOF flag remains `N`, so the master continues to be read on the next loop. The first two master lines and both transactions are echoed as usual, and the exit code is `0`.

## 2. Empty Account Master File

Empty the copy of `accounts.txt` and keep all four transactions. The account file reaches EOF on its first `READ`; the program continues reading the transaction file one record at a time. The final summary is:

```text
关闭完成 账户记录数=000 交易记录数=004
```

The empty master file does not set `WS-TRANSACTION-EOF` to `Y` and does not skip transaction records. All four transactions are echoed, and the exit code is `0`.

Neither modification requires changing the source: as long as each input has independent EOF, status, and count, the stream that finishes first does not stop the other one.
