#!/bin/bash
# Create a new Bazel mono repo project from the template
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS] <destination>

Create a new Bazel mono repo project.

Arguments:
  destination          Directory to create the project in

Options:
  -n, --name NAME      Repository name (default: destination basename)
  -o, --owner OWNER    GitHub owner/organization
  -l, --languages LANG Languages: go,python,typescript,proto (default: go)
  -d, --description D  Project description
  --go-version VER     Go version (default: auto-detect or 1.24.2)
  --python-version VER Python version (default: auto-detect or 3.12)
  --bazel-version VER  Bazel version (default: 7.4.1)
  --local              Use local template path (for testing before pushing)
  --head               Use latest commit instead of latest tag (for CI/CD)
  -y, --yes            Skip confirmation and use defaults
  -h, --help           Show this help message

Note: By default, uses the latest tagged version. Use --head for untagged commits.

Examples:
  $(basename "$0") my-project
  $(basename "$0") -n my-app -o myorg -l go,python my-project
  $(basename "$0") --owner myorg ~/projects/my-project
  $(basename "$0") -y my-project  # Non-interactive
EOF
    exit "${1:-0}"
}

# Detect Go version from system
detect_go_version() {
    if command -v go &>/dev/null; then
        go version | sed -E 's/go version go([0-9]+\.[0-9]+(\.[0-9]+)?).*/\1/'
    else
        echo "1.24.2"
    fi
}

# Detect Python version from system (major.minor only)
detect_python_version() {
    if command -v python3 &>/dev/null; then
        python3 --version | sed -E 's/Python ([0-9]+\.[0-9]+).*/\1/'
    else
        echo "3.12"
    fi
}

# Defaults from git config
AUTHOR_NAME=$(git config user.name 2>/dev/null || echo "")
AUTHOR_EMAIL=$(git config user.email 2>/dev/null || echo "")
GITHUB_USER=$(git config github.user 2>/dev/null || echo "")
if [[ -z "$GITHUB_USER" ]] && command -v gh &>/dev/null; then
    GITHUB_USER=$(gh auth status --json hosts --jq '.hosts[][] | select(.active) | .login' 2>/dev/null || echo "")
fi

# Auto-detect versions
GO_VERSION=$(detect_go_version)
PYTHON_VERSION=$(detect_python_version)

# Default values
REPO_NAME=""
GITHUB_OWNER="$GITHUB_USER"
LANGUAGES="go"
DESCRIPTION="A Bazel-based mono repo project"
BAZEL_VERSION="7.4.1"
DESTINATION=""
SKIP_CONFIRM=false
USE_LOCAL=false
USE_HEAD=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -n|--name)
            REPO_NAME="$2"
            shift 2
            ;;
        -o|--owner)
            GITHUB_OWNER="$2"
            shift 2
            ;;
        -l|--languages)
            LANGUAGES="$2"
            shift 2
            ;;
        -d|--description)
            DESCRIPTION="$2"
            shift 2
            ;;
        --go-version)
            GO_VERSION="$2"
            shift 2
            ;;
        --python-version)
            PYTHON_VERSION="$2"
            shift 2
            ;;
        --bazel-version)
            BAZEL_VERSION="$2"
            shift 2
            ;;
        -y|--yes)
            SKIP_CONFIRM=true
            shift
            ;;
        --local)
            USE_LOCAL=true
            shift
            ;;
        --head)
            USE_HEAD=true
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
            if [[ -z "$DESTINATION" ]]; then
                DESTINATION="$1"
            else
                echo "Unexpected argument: $1" >&2
                usage 1
            fi
            shift
            ;;
    esac
done

if [[ -z "$DESTINATION" ]]; then
    echo "Error: destination is required" >&2
    usage 1
fi

# Default repo_name to destination basename
if [[ -z "$REPO_NAME" ]]; then
    REPO_NAME=$(basename "$DESTINATION")
fi

# Build go_module_path
GO_MODULE_PATH="github.com/${GITHUB_OWNER}/${REPO_NAME}"
if [[ -z "$GITHUB_OWNER" ]]; then
    GO_MODULE_PATH="github.com/example/${REPO_NAME}"
fi

# Create answers file
ANSWERS_FILE=$(mktemp "${TMPDIR:-/tmp}/answers.XXXXXX.yml")
trap 'rm -f "$ANSWERS_FILE"' EXIT

# Convert comma-separated languages to YAML list format
LANGUAGES_YAML="${LANGUAGES//,/, }"

cat > "$ANSWERS_FILE" << EOF
repo_name: "${REPO_NAME}"
project_description: "${DESCRIPTION}"
github_owner: "${GITHUB_OWNER}"
languages: [${LANGUAGES_YAML}]
go_version: "${GO_VERSION}"
go_module_path: "${GO_MODULE_PATH}"
python_version: "${PYTHON_VERSION}"
bazel_version: "${BAZEL_VERSION}"
author_name: "${AUTHOR_NAME}"
author_email: "${AUTHOR_EMAIL}"
EOF

if [[ "$SKIP_CONFIRM" = true ]]; then
    echo "Creating project at: $DESTINATION"
else
    echo "Project configuration:"
    echo "----------------------------------------"
    cat "$ANSWERS_FILE"
    echo "----------------------------------------"
    echo ""
    echo "Destination: $DESTINATION"
    echo ""

    # Check for editor
    if [[ -n "$EDITOR" ]]; then
        read -rp "Press Enter to continue, 'e' to edit, or Ctrl+C to cancel: " response
        if [[ "$response" = "e" || "$response" = "E" ]]; then
            $EDITOR "$ANSWERS_FILE"
            echo ""
            echo "Updated configuration:"
            echo "----------------------------------------"
            cat "$ANSWERS_FILE"
            echo "----------------------------------------"
            read -rp "Press Enter to continue or Ctrl+C to cancel: "
        fi
    else
        read -rp "Press Enter to continue or Ctrl+C to cancel: "
    fi
fi

# Run copier (creates .copier-answers.yml via template)
COPIER_ARGS=("--data-file" "$ANSWERS_FILE")
if [[ "$USE_HEAD" = true ]]; then
    COPIER_ARGS+=("--vcs-ref=HEAD")
fi
if [[ "$USE_LOCAL" = true ]]; then
    TEMPLATE_SRC="$SCRIPT_DIR"
else
    TEMPLATE_SRC="gh:jaeyeom/bazel-project-template"
fi
copier copy "${COPIER_ARGS[@]}" "$TEMPLATE_SRC" "$DESTINATION"

echo ""
echo "Project created at: $DESTINATION"
echo ""
echo "Next steps:"
echo "  cd $DESTINATION"
echo "  git init"
echo "  make"
