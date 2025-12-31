#!/bin/bash
# Test template creation and build
# Usage: ./tests/test-template.sh [--local|--tagged] [LANGUAGES]
# Examples:
#   ./tests/test-template.sh --local go
#   ./tests/test-template.sh --tagged go,python

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

MODE="local"
LANGUAGES="go"

while [[ $# -gt 0 ]]; do
    case $1 in
        --local)
            MODE="local"
            shift
            ;;
        --tagged)
            MODE="tagged"
            shift
            ;;
        *)
            LANGUAGES="$1"
            shift
            ;;
    esac
done

TEMP_DIR="${RUNNER_TEMP:-$(mktemp -d)}"
PROJECT_DIR="$TEMP_DIR/test-project"

echo "=== Testing template ($MODE mode) with languages: $LANGUAGES ==="

# Create project from template
if [[ "$MODE" == "local" ]]; then
    "$PROJECT_ROOT/create-project.sh" -y --local \
        -n test-project \
        -o testorg \
        -l "$LANGUAGES" \
        "$PROJECT_DIR"
else
    "$PROJECT_ROOT/create-project.sh" -y \
        -n test-project \
        -o testorg \
        -l "$LANGUAGES" \
        "$PROJECT_DIR"
fi

# Create placeholder Go file for linting if Go is enabled
if [[ "$LANGUAGES" == *"go"* ]]; then
    mkdir -p "$PROJECT_DIR/cmd/hello"
    printf 'package main\n\nfunc main() { println("hello") }\n' > "$PROJECT_DIR/cmd/hello/main.go"
fi

# Build and test generated project
echo "=== Building and testing generated project ==="
cd "$PROJECT_DIR"
make all

echo "=== Template test passed ($MODE mode, languages: $LANGUAGES) ==="
