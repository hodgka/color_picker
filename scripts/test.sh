#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

resolve_odin() {
    if [[ -n "${ODIN:-}" ]]; then echo "$ODIN"; return; fi
    if command -v odin &>/dev/null; then command -v odin; return; fi
    local fallback="$HOME/odin/odin"
    if [[ -x "$fallback" ]]; then echo "$fallback"; return; fi
    return 1
}

ODIN="$(resolve_odin)" || {
    echo "Error: Odin compiler not found." >&2
    echo "Install Odin (https://odin-lang.org/docs/install/) or set the ODIN env var." >&2
    exit 1
}

TEST_PACKAGES=(
    "src/color"
    "src/data"
    "src/ui/layout"
    "src/test_across_modules"
)

FAILED=0

for pkg in "${TEST_PACKAGES[@]}"; do
    echo "--- Testing $pkg ---"
    if "$ODIN" test "$PROJECT_ROOT/$pkg/"; then
        echo "    PASS"
    else
        echo "    FAIL"
        FAILED=1
    fi
    echo
done

if [[ "$FAILED" -ne 0 ]]; then
    echo "Some tests failed."
    exit 1
fi

echo "All tests passed."
