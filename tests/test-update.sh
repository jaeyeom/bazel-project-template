#!/bin/bash
# Test update script
# Usage: ./tests/test-update.sh [--local|--tagged]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

MODE="local"

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
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

TEMP_DIR="${RUNNER_TEMP:-$(mktemp -d)}"
PROJECT_DIR="$TEMP_DIR/test-project"

echo "=== Testing update script ($MODE mode) ==="

# Create project from template
if [[ "$MODE" == "local" ]]; then
    "$PROJECT_ROOT/create-project.sh" -y --local -n test-project "$PROJECT_DIR"
else
    "$PROJECT_ROOT/create-project.sh" -y -n test-project "$PROJECT_DIR"
fi

# Initialize git repo (required for update)
cd "$PROJECT_DIR"
git init -b main
git config user.name "CI"
git config user.email "ci@example.com"
git add .
git commit -m "Initial commit"

# Run update
cd "$PROJECT_ROOT"
if [[ "$MODE" == "local" ]]; then
    "$PROJECT_ROOT/update-project.sh" -y --local "$PROJECT_DIR"
else
    "$PROJECT_ROOT/update-project.sh" -y "$PROJECT_DIR"
fi

echo "=== Update test passed ($MODE mode) ==="
