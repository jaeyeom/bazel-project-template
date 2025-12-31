#!/bin/bash
# Update an existing project from the template
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS] <destination>

Update an existing project created from this template.

Arguments:
  destination          Project directory to update (required)

Options:
  -n, --pretend        Show what would be done without making changes
  --local              Use local template (for testing before pushing)
  --head               Use latest commit instead of latest tag (for CI/CD)
  -y, --yes            Skip confirmation and use defaults
  -h, --help           Show this help message

Note: Previously answered questions are skipped by default (uses .copier-answers.yml).
      By default, updates to the latest tagged version. Use --head for untagged commits.

Examples:
  $(basename "$0") .                  # Update to latest tagged version
  $(basename "$0") ~/projects/my-app  # Update specific project
  $(basename "$0") --head .           # Update to latest commit (CI/CD)
  $(basename "$0") --local .          # Update from local template (for testing)
EOF
    exit "${1:-0}"
}

DESTINATION=""
COPIER_ARGS=("--skip-answered")  # Always skip questions that have answers in .copier-answers.yml
USE_LOCAL=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -n|--pretend)
            COPIER_ARGS+=("--pretend")
            shift
            ;;
        -y|--yes)
            COPIER_ARGS+=("--defaults")
            shift
            ;;
        --head)
            COPIER_ARGS+=("--vcs-ref=HEAD")
            shift
            ;;
        --local)
            USE_LOCAL=true
            shift
            ;;
        -h|--help)
            usage 0
            ;;
        -*)
            echo "Unknown option: $1" >&2
            usage 1
            ;;
        *)
            DESTINATION="$1"
            shift
            ;;
    esac
done

# Check if destination is provided
if [[ -z "$DESTINATION" ]]; then
    echo "Error: destination is required" >&2
    usage 1
fi

# Check if destination has .copier-answers.yml
if [[ ! -f "$DESTINATION/.copier-answers.yml" ]]; then
    echo "Error: $DESTINATION does not appear to be a project created from this template" >&2
    echo "(missing .copier-answers.yml)" >&2
    exit 1
fi

echo "Updating project at: $DESTINATION"
echo ""

ANSWERS_FILE="$DESTINATION/.copier-answers.yml"

# Run copier update
if [[ "$USE_LOCAL" = true ]]; then
    # For local mode, we need to temporarily commit the _src_path change
    # because copier refuses to update dirty repositories
    ORIGINAL_SRC=$(grep '^_src_path:' "$ANSWERS_FILE")
    sed -i.bak "s|^_src_path:.*|_src_path: $SCRIPT_DIR|" "$ANSWERS_FILE"
    rm -f "$ANSWERS_FILE.bak"

    # Commit the temporary change (will be amended/reverted after copier runs)
    ORIGINAL_DIR="$(pwd)"
    cd "$DESTINATION"
    git add .copier-answers.yml
    git commit -m "chore: temporarily use local template source for update"
    cd "$ORIGINAL_DIR"

    # Set up cleanup trap to restore original _src_path (always runs)
    cleanup() {
        sed -i.bak "s|^_src_path:.*|$ORIGINAL_SRC|" "$ANSWERS_FILE"
        rm -f "$ANSWERS_FILE.bak"
    }
    trap cleanup EXIT

    COPIER_RUNNING=1 copier update "${COPIER_ARGS[@]}" "$DESTINATION"

    # Update _commit to current template HEAD (only after successful update)
    TEMPLATE_COMMIT=$(git -C "$SCRIPT_DIR" rev-parse HEAD)
    sed -i.bak "s|^_commit:.*|_commit: $TEMPLATE_COMMIT|" "$ANSWERS_FILE"
    rm -f "$ANSWERS_FILE.bak"
else
    COPIER_RUNNING=1 copier update "${COPIER_ARGS[@]}" "$DESTINATION"
fi

echo ""
echo "Project updated successfully!"
