# Migration Guide

This guide explains how to migrate an existing project to use Bazel as the build system.

## Quick Start

To migrate an existing project to Bazel:

```bash
./migrate-project.sh [--ignore-all] /path/to/your/project
```

This copies the necessary Bazel configuration files to your project. A `BAZEL-MIGRATION.md` file will be copied to your project with post-migration guidance.

## Migration Strategies

### Strategy 1: All-at-Once (Small Projects)

For smaller projects or those with few dependencies:

```bash
# 1. Run the migration
./migrate-project.sh /path/to/project

# 2. Generate BUILD files
cd /path/to/project
bazel run //:gazelle

# 3. Build everything
bazel build //...

# 4. Run tests
bazel test //...
```

### Strategy 2: Gradual Migration (Large Projects)

For larger projects, use `.bazelignore` to migrate incrementally:

```bash
# 1. Run migration with --ignore-all
./migrate-project.sh --ignore-all /path/to/project

# 2. Edit .bazelignore to start with foundational packages
# (see "Migration Order" below)

# 3. Generate BUILD files for non-ignored packages
bazel run //:gazelle

# 4. Build and verify
bazel build //...
```

## Migration Order

**Critical**: Migrate packages in dependency order, starting from the foundation.

```
Foundational packages    <- Migrate FIRST (no internal dependencies)
        ^
   Core packages         <- Migrate SECOND (depend on foundational)
        ^
Application packages     <- Migrate LAST (depend on core)
```

### Finding Your Dependency Order

For Go projects:

```bash
# List all packages
go list ./...

# See what a package imports
go list -f '{{.Imports}}' ./pkg/mypackage

# Find packages with no internal dependencies (good starting points)
go list -f '{{if not .Imports}}{{.ImportPath}}{{end}}' ./...
```

For Python projects:

```bash
# Analyze imports (requires pipdeptree or similar)
pipdeptree --local-only

# Or manually check imports in each module
grep -r "^from \. import\|^from \.\." src/
```

## Post-Migration

After running the migration script, see [BAZEL-MIGRATION.md](BAZEL-MIGRATION.md) for:

- Common issues and solutions
- Verifying migration
- Gradual migration checklist
- Rollback instructions
- Next steps
