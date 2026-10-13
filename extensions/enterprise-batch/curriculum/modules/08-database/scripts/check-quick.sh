#!/usr/bin/env bash
# Docker-free quick acceptance for module 08 (offline contracts + independent
# oracle + source/fixture SHA).  The real Embedded-SQL end-to-end experiment is
# a separate, environment-dependent entry:
#   bash curriculum/modules/08-database/scripts/check.sh   (needs Docker)
set -Eeuo pipefail
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
python3 "$here/check.py"
echo 'NOTE: real DB end-to-end is separate: bash curriculum/modules/08-database/scripts/check.sh'
