# Maintenance Change 11.5: Widen Enterprise Customer Classification from 1 to 2 Characters (Student Task)

> This is the **investigation phase** of a LEGACY maintenance change. Submit the impact investigation first; implement the change and migration/rollback only after review. **Do not change the PIC before completing the investigation.**
> Interface change specification: [LAYOUT-V1-V2.md](LAYOUT-V1-V2.md).

## 1. Request

The upstream business wants to widen the **enterprise customer master** classification from **1 character** to **2 characters**. This classification is in a **separate, versioned enterprise customer layout**. It is **not** byte 27 of the 27-byte canonical CUSTOMER v1 record (byte 27 is record status A/D; the teaching interface remains unchanged):

- V1: `CUSTOMER-CLASSIFICATION PIC X(1)`, values `A/B/C/D`, layout version `001`, record width **23 bytes** (baseline contract).
- V2: `CUSTOMER-CLASSIFICATION PIC X(2)`, values `A1/B1/C1/D1`, layout version `002`, record width **24 bytes**.
- **Do not rewrite old V1 files in place**; migration must use parallel validation and support rollback.

> Why not use byte 27 of CUSTOMER v1? The canonical contract defines that byte as **record status** (A active / D inactive). Treating it as “customer classification” would break the frozen contract. See `curriculum/bank/README.md` and `../../../../docs/curriculum/BANK-SYSTEM.md` §2. The course's canonical large record is Module 07 L4 `ENTERPRISE-CUSTOMER-V1` (175 fields / 1778 bytes); this exercise's 23-byte layout deliberately uses the separate name `ENTERPRISE-CLASS-V1` (see its Copybook header comment), preserving only the same classification-field semantics. It does **not** share the canonical name, avoiding version drift.

## 2. System under investigation

The system under investigation is the frozen Module 11 snapshot in `system/`. Enterprise customer classification appears in the **separate versioned enterprise layout** and its read/migration flow:

- Baseline Copybook: `maintenance/copybooks/ENTERPRISE-CLASS-V1.CPY` (layout `001`, 23 bytes: version/id/status/name/classification).
- Reference program that reads and outputs the classification: `instructor/modules/11-incidents/maintenance/M11CUST2.COB` (V2, 24 bytes).
- Migration/rollback/parallel-validation tool: `instructor/modules/11-incidents/maintenance/migrate-customer.py`.
- Input: `fixtures/enterprise-customer/customer.v1` (V1, 23 bytes).
- Downstream interface (enterprise-classification extract): line format `CLASS|<id>|<class>` (1→2 characters).
- **Note**: `system/cobol/M11CUST.COB` in the nightly flow reads the canonical CUSTOMER v1 **record status**; its downstream publication is `publish/<run_id>/customer-status.txt` (`STATUS|<id>|<status>`). This is separate from enterprise classification; do not change it.
- Documentation: repository-root `../../../../docs/curriculum/BANK-SYSTEM.md` (frozen contract), `../../../../docs/curriculum/AUTHORING-STANDARD.md` §6 (change-delivery requirements).

## 3. Deliverables (before review)

1. **Impact investigation report** (must include):
   - Field definition: field name, PIC, byte offset, length, valid values, version;
   - **All usage locations**: Copybook, program, sort/compare key, file, DB, Shell, JOB, report, downstream interface (give file path and line number for each);
   - **Dependency graph**: who reads/writes what, and the upstream/downstream direction;
   - **Unknowns**: items that are uncertain or unverified (for example, actual DB column definition or external consumers).
2. **Change target list**: Copybook/program/file/DB/Shell/JOB/design document/downstream interface/owner role; list what changes, why, and the risk for each.
3. **Change strategy**: V1/V2 compatibility approach; migration steps; rollback steps; data cutover and parallel-validation plan (V1/V2 comparison).
4. **Test cases**: normal, boundary, failure, cross-version, end-to-end, and recovery; for each provide `input → expected RC/output → evidence location`.
5. **Evidence plan**: expected result and evidence location for every test.

> Submit deliverables in Markdown; you may create `TEMPLATES/` here for table skeletons. After review (implementation phase), the reference implementation and evidence are in `instructor/modules/11-incidents/maintenance/`.

## 4. After review (implementation phase) reference

Implementation requirements: add/implement `ENTERPRISE-CLASS-V2` (24 bytes, `X(2)`), update the reader and downstream interface format, provide migration and rollback tools, validate V1/V2 in parallel, and verify end-to-end regression and recovery. **Keep CUSTOMER v1 (27 bytes) unchanged.** The reference implementation and evidence are in `instructor/modules/11-incidents/maintenance/`; the starting skeleton is `starter/M11CUST2.COB` (buildable, returns RC12 until completed).

## 5. Run the existing implementation and regression (read-only evidence for investigation)

> The migration/rollback tool is a **Python script** (`migrate-customer.py`, shebang `#!/usr/bin/env python3`). Run it with `python3` or execute the script directly; **do not run it with `bash`** (bash will interpret Python source as shell and report syntax errors). Run these commands from the repository root; all paths are relative to the repository.

```bash
cd "$(git rev-parse --show-toplevel)/extensions/enterprise-batch"   # extension curriculum root
mod=curriculum/modules/11-incidents
ins=instructor/modules/11-incidents

# Migrate V1 -> V2 (python3; writes a new file, leaves original V1 intact)
python3 "$ins/maintenance/migrate-customer.py" \
  to-v2 "$mod/fixtures/enterprise-customer/customer.v1" /tmp/ent.v2
cat /tmp/ent.v2                      # 00200000001AALICE     A1 ...

# Build and run the reference v2 extractor
rm -f /tmp/m11cust2
bash "$mod/system/scripts/build.sh" /tmp/m11cust2 "$ins/maintenance/M11CUST2.COB"
M11CUST_INPUT=/tmp/ent.v2 M11CUST_EXTRACT=/tmp/class.v2 \
M11CUST_REPORT=/tmp/rep.v2 /tmp/m11cust2 && cat /tmp/class.v2
# CLASS|00000001|A1 ...

# Canonical CUSTOMER v1 status extraction (regression: unaffected by this change)
rm -f /tmp/m11cust
bash "$mod/system/scripts/build.sh" /tmp/m11cust "$mod/system/cobol/M11CUST.COB"
M11CUST_INPUT="$mod/fixtures/normal/customer_seed.dat" \
M11CUST_EXTRACT=/tmp/status.v1 M11CUST_REPORT=/tmp/rep.v1 /tmp/m11cust
cat /tmp/status.v1          # STATUS|00000001|A ...

# Maintenance self-check for the reference implementation (migration/rollback/parallel/cross-version/failure/offset and golden bytes)
bash "$ins/maintenance/check.sh"
```

## 6. Questions to answer (AUTHORING §6)

- What are the field definition, all usage locations, dependency graph, and unknowns?
- Which following fields/offsets move when a field width changes? What is the impact on sort keys and comparisons?
- How should V1 files be handled (reject/convert)? Why must they not be rewritten in place?
- How will migration, cutover, and rollback work? How will parallel validation prove equivalence?
- How are byte 27 of CUSTOMER v1 and this enterprise classification related? Why must they not be conflated?
- Which external interfaces and downstream consumers were covered? How are unverified items labeled?
