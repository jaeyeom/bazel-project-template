#!/bin/bash
# Update an existing project from the template
set -e

usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS] <destination>

Update an existing project created from this template.

Arguments:
  destination          Project directory to update (required)

Options:
  -A, --skip-answered  Skip questions that have already been answered
  -n, --pretend        Show what would be done without making changes
  -y, --yes            Skip confirmation and use defaults
  -h, --help           Show this help message

Examples:
  $(basename "$0") .                  # Update current directory
  $(basename "$0") ~/projects/my-app  # Update specific project
  $(basename "$0") -A .               # Update, keeping existing answers
EOF
    exit "${1:-0}"
}

DESTINATION=""
COPIER_ARGS=()

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -A|--skip-answered)
            COPIER_ARGS+=("--skip-answered")
            shift
            ;;
        -n|--pretend)
            COPIER_ARGS+=("--pretend")
            shift
            ;;
        -y|--yes)
            COPIER_ARGS+=("--defaults")
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

# Run copier update
copier update "${COPIER_ARGS[@]}" "$DESTINATION"

echo ""
echo "Project updated successfully!"
