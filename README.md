# Bazel Mono Repo Template

A [copier](https://copier.readthedocs.io/) template for generating Bazel-based
mono repo projects with multi-language support and Claude Code integration.

## Features

- **Multi-language support**: Go, Python, TypeScript, Protocol Buffers
- **Bazel build system**: Modern bzlmod dependency management
- **Makefile wrapper**: Simple `make` commands for common tasks
- **Claude Code integration**: Pre-configured AI assistant rules
- **Code quality tools**: golangci-lint, ruff, buildifier

## Usage

### Using the helper script (recommended)

The helper script auto-detects author info from git config and uses sensible defaults:

```bash
# Clone the template
git clone https://github.com/jaeyeom/bazel-monorepo-template.git
cd bazel-monorepo-template

# Create a new project
./create-project.sh ~/projects/my-project

# With options
./create-project.sh -n my-app -o myorg -l go,python ~/projects/my-project

# See all options
./create-project.sh --help
```

### Using copier directly

```bash
# Install copier
pip install copier

# Generate a new project (interactive prompts)
copier copy gh:jaeyeom/bazel-monorepo-template my-project

# Or with answers file for non-interactive use
copier copy --data-file answers.yml --defaults gh:jaeyeom/bazel-monorepo-template my-project
```

## Template Questions

| Question              | Description                                 | Default                           |
|-----------------------|---------------------------------------------|-----------------------------------|
| `repo_name`           | Repository name (for module naming)         | (required)                        |
| `project_description` | Short description                           | "A Bazel-based mono repo project" |
| `github_owner`        | GitHub org/user                             | ""                                |
| `languages`           | Comma-separated: go,python,typescript,proto | "go"                              |
| `go_version`          | Go version (if Go selected)                 | "1.24.2"                          |
| `go_module_path`      | Go module path (if Go selected)             | "github.com/{owner}/{repo_name}"  |
| `python_version`      | Python version (if Python selected)         | "3.12"                            |
| `bazel_version`       | Bazel version                               | "7.4.1"                           |
| `author_name`         | Author name                                 | ""                                |
| `author_email`        | Author email                                | ""                                |

## Generated Structure

```
my-project/
├── .bazeliskrc          # Bazel version pinning
├── .bazelrc             # Bazel build configuration
├── MODULE.bazel         # Bazel module dependencies
├── BUILD.bazel          # Root BUILD file
├── Makefile             # Development workflow
├── .gitignore
├── README.md
├── CLAUDE.md            # Claude Code instructions
├── .claude/
│   └── settings.local.json
├── docs/claude/rules/
│   ├── general.md
│   ├── bazel.md
│   └── make.md
├── go.mod               # (if Go selected)
├── .golangci.yml        # (if Go selected)
├── pyproject.toml       # (if Python selected)
└── requirements.in      # (if Python selected)
```

## Development Commands

After generating a project:

```bash
cd my-project
make           # Format, test, and lint
make format    # Format code
make test      # Run tests
make lint      # Run linters
```
