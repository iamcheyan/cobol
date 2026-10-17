# INC-2026-005 Hint Ladder (Read One Level at a Time)

## Level 1: What kind of failure?

- Failure occurred in JOB003, RC12. The course defines RC12 as a system/environment failure (permissions, disk, temporary space, unexpected child-process exit, etc.), not a business rejection.

## Level 2: What resources does the node need?

- Read `scene/source/job003-sort.sh`: it creates a sort workspace with `mktemp -d` under the parent directory and writes candidate files there. Which resource is indicated by the failure message?

## Level 3: Reproduction evidence

- The reproduction script places a `mktemp` that always fails earlier in PATH to recreate the scene.
- Compare the error line in `scene/logs/nightly.log` and confirm the trigger point.

## Level 4: Integrity of the scene after failure

- Is a temporary directory left after failure? Was `publish/<run_id>` created? Was the business-date lock released? Give the command and result for each, and explain “no publication on failure, no leftover lock.”

## Level 5: Recovery and prevention

- Recovery: fix temporary space/permissions (or choose a different TMPDIR), then rerun with a new run_id; explain why you must not reuse the failed directory.
- Prevention: preflight resource checks at JOB entry (disk usage, writability), a shared temporary directory, cleanup on failure, and alerts.
