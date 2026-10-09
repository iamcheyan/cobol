# B02 evidence

- [B02 07.1/07.2 pressure and spill evidence](B02-pressure-2026-10-10.json) records version/source/copybook/config hashes, input hashes and bytes, fixed 2M SORT pool, core-only wait4 RSS, actual `cobsort` temporary file observations, and observed read-only TMPDIR / size-limit failure mappings.
- Each lesson's [07.1 template](../01-sort/evidence/TEMPLATE.md) and [07.2 template](../02-merge/evidence/TEMPLATE.md) captures repeatable author runs and output hashes.
- JSON states only completed runs. If a pressure run fails, the driver writes partial results plus `status: FAIL` before returning failure; a partial file is not passing evidence.
