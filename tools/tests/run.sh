#!/bin/sh
# Run all tools/tests/test_*.sh. Cds to the repo root first.
set -u
cd "$(dirname "$0")/../.."
status=0
for t in tools/tests/test_*.sh; do
    echo "== $t"
    if ! sh "$t"; then status=1; fi
done
[ "$status" -eq 0 ] && echo "ALL TESTS PASSED"
exit "$status"
