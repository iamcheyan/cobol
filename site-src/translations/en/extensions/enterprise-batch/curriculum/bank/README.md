# Canonical Bank Interfaces (Single Source of Truth)

This directory contains the canonical definitions of the **frozen bank interfaces** shared by all modules. Every experiment, course, or JOB must reuse these definitions or reference them by version; **do not create separate copies of interfaces with the same names that can drift**. Field semantics and byte layouts are defined in [BANK-SYSTEM.md](../../docs/curriculum/BANK-SYSTEM.md).

| File | Record | Width | Description |
|---|---|---:|---|
| [ACCOUNT-V1.CPY](copybooks/ACCOUNT-V1.CPY) | ACCOUNT v1 | 47 B | Account master; account_id/customer/currency/sign/opening_balance/status/date/version |
| [TRANSACTION-V1.CPY](copybooks/TRANSACTION-V1.CPY) | TRANSACTION v1 | 55 B | Daily transaction; account/txid/date/sequence/direction/amount/status |
| [CUSTOMER-V1.CPY](copybooks/CUSTOMER-V1.CPY) | CUSTOMER v1 | 27 B | Basic instructional customer object; id/name/balance_demo/**status** |

Text fixed-width interfaces use ASCII, with an LF after each logical record; LF is not included in the record length. Amounts are integers in explicitly defined minor units; dates use `YYYYMMDD` and are validated against the course calendar.

## About “Customer Classification from 1 Digit to 2 Digits” Maintenance

Byte 27 of CUSTOMER v1 is the **record status, status** (A active / D disabled), **not** customer classification. Section 2 of BANK-SYSTEM explicitly states that the existing 27-byte CUSTOMER has **no** customer classification field. The maintenance lesson must **first define a separate, versioned enterprise customer layout and its 1-digit baseline**, preserve the 27-byte instructional interface, explain how the two relate, and then perform the v2 migration. **Do not treat the status field as customer classification.**

A valid precedent already in this repository is module 07 L4’s `ENTERPRISE-CUSTOMER-V1` (1778-byte fixed binary layout): `CUSTOMER-CLASSIFICATION` is `PIC X(1)` (A/B/C/D) in v1 and widened to `PIC X(2)` (A1/B1/C1/D1) in v2, with layout versions 001→002. Customer classification maintenance exercises in modules 11/12 must reference an **independently versioned enterprise layout** like this (it may reuse or follow this naming/version convention), rather than rewriting byte 27 of CUSTOMER v1.

## Interpreter Measurement Summary (Linux x86-64 / GnuCOBOL 3.2.0)

- `ACCOUNT-V1` = 47 B, `TRANSACTION-V1` = 55 B, `CUSTOMER-V1` = 27 B (measured with `LENGTH OF`).
- PIC COMP measured big-endian; COMP-5 native little-endian; COMP-3 validates every half-byte and accepts only C/D signs. Raw binary/Packed bytes must not be parsed as text.
