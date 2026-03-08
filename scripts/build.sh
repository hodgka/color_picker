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
RELEASE=false

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Build the Color Picker binary for the current platform.

Options:
  --release       Optimized build (-o:speed, assertions disabled)
  --help          Show this help message

Environment:
  ODIN            Path to the Odin compiler (default: odin on \$PATH)

Examples:
  ./scripts/build.sh
  ./scripts/build.sh --release
  ODIN=/usr/local/bin/odin ./scripts/build.sh --release
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --release) RELEASE=true; shift ;;
        --help)    usage ;;
        *)         echo "Unknown option: $1" >&2; exit 1 ;;
    esac
done

OS="$(uname -s)"
case "$OS" in
    Darwin) PLATFORM="macOS" ;;
    Linux)  PLATFORM="Linux" ;;
    *)      echo "Unsupported OS: $OS" >&2; exit 1 ;;
esac

mkdir -p "$PROJECT_ROOT/bin"

BUILD_FLAGS=(-out:"$PROJECT_ROOT/bin/color_picker")

if [[ "$RELEASE" == true ]]; then
    BUILD_FLAGS+=(-o:speed -disable-assert)
    echo "Building Color Picker ($PLATFORM, release)..."
else
    echo "Building Color Picker ($PLATFORM, debug)..."
fi

"$ODIN" build "$PROJECT_ROOT/src/" "${BUILD_FLAGS[@]}"

echo "Built: bin/color_picker"
