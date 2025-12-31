# Makefile for bazel-project-template
# Provides targets for linting and testing

.PHONY: all shellcheck test-template test-update test-migrate test clean

# Default target runs all tests
all: shellcheck test-template-go test-update test-migrate-go
	@echo "=== All tests passed ==="

# Run shellcheck on all shell scripts
shellcheck:
	@echo "=== Running shellcheck ==="
	shellcheck create-project.sh update-project.sh tests/*.sh

# Template tests (use LANGUAGES and MODE variables)
# Examples:
#   make test-template LANGUAGES=go
#   make test-template LANGUAGES=go,python MODE=tagged
test-template:
	./tests/test-template.sh $(if $(MODE),--$(MODE),--local) $(LANGUAGES)

# Convenience targets for common template test configurations
test-template-go:
	./tests/test-template.sh --local go

test-template-python:
	./tests/test-template.sh --local python

test-template-go-python:
	./tests/test-template.sh --local go,python

test-template-all:
	./tests/test-template.sh --local go,python,proto

test-template-tagged:
	./tests/test-template.sh --tagged go

# Update tests
test-update:
	./tests/test-update.sh $(if $(MODE),--$(MODE),--local)

test-update-tagged:
	./tests/test-update.sh --tagged

# Migration tests (use LANG_TYPE, MODE, and IGNORE_ALL variables)
# Examples:
#   make test-migrate LANG_TYPE=go
#   make test-migrate LANG_TYPE=python IGNORE_ALL=1
test-migrate:
	./tests/test-migrate.sh $(if $(MODE),--$(MODE),--local) $(if $(IGNORE_ALL),--ignore-all) $(LANG_TYPE)

# Convenience targets for common migration test configurations
test-migrate-go:
	./tests/test-migrate.sh --local go

test-migrate-go-gradual:
	./tests/test-migrate.sh --local --ignore-all go

test-migrate-python:
	./tests/test-migrate.sh --local python

test-migrate-mixed:
	./tests/test-migrate.sh --local mixed

test-migrate-tagged:
	./tests/test-migrate.sh --tagged go

# Run comprehensive tests (takes longer, includes all language combinations)
test-all: shellcheck test-template-go test-template-python test-template-go-python test-template-all \
          test-update test-migrate-go test-migrate-go-gradual test-migrate-python test-migrate-mixed
	@echo "=== All comprehensive tests passed ==="

# Clean up any temporary files
clean:
	@echo "=== Cleaning up ==="
	rm -rf /tmp/test-project /tmp/existing-project
