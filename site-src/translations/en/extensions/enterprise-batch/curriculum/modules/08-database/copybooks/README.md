# Copybooks: versioned interfaces

| Copybook | Contract | Description |
|---|---|---|
| `CUSTOMER-V1.CPY` | CUSTOMER v1 = **27B** | Interface for this module's 08.3 snapshot and reconciliation (`customer_id 8 + name 10 + balance_demo 8 + status 1`) |

The canonical sources for `ACCOUNT v1 = 47B` and `TRANSACTION v1 = 55B` remain in [`curriculum/bank/copybooks/`](../../../bank/copybooks/) (`ACCOUNT-V1.CPY`, `TRANSACTION-V1.CPY`). They are **not maintained here a second time**, avoiding divergence between interfaces with the same name. `scripts/build.sh` adds both this directory and the canonical directory to `cobc -I`, so programs can `COPY ACCOUNT-V1` / `COPY TRANSACTION-V1`.

`APPLY.COB` reads the 55B transaction by numeric offsets (`account 1-10`, `transaction_id 11-26`, `date 27-34`, `sequence 35-40`, `direction 41`, `amount 42-54`, `status 55`). Its byte layout is frozen by the fixed-width assertions in `scripts/check.py` and [DESIGN.md](../DESIGN.md).
