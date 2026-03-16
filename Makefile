# Simple Makefile for agent-adr confidence testing

.PHONY: test test-confidence test-keep-artifacts clean help

# Default target
test: test-confidence

# Run confidence test suite
test-confidence:
	@echo "🚀 Running confidence test suite..."
	./tests/smoke-test-confidence.sh

# Run confidence tests and keep artifacts for inspection
test-keep-artifacts:
	@echo "🚀 Running confidence test suite (keeping artifacts)..."
	KEEP_TEST_ARTIFACTS=1 ./tests/smoke-test-confidence.sh

# Run legacy smoke test
test-legacy:
	@echo "🚀 Running legacy smoke test..."
	./tests/smoke-test.sh

# Clean up any test artifacts
clean:
	@echo "🧹 Cleaning up test artifacts..."
	rm -rf /tmp/agent-adr-*
	rm -rf /tmp/agent-adr-confidence-*
	rm -rf /tmp/agent-adr-fixtures-*

# Show help
help:
	@echo "agent-adr Confidence Testing"
	@echo ""
	@echo "Available targets:"
	@echo "  test              Run confidence test suite (default)"
	@echo "  test-keep-artifacts Run tests and keep artifacts for inspection"
	@echo "  test-legacy       Run legacy smoke test"
	@echo "  clean             Clean up test artifacts"
	@echo "  help              Show this help message"
	@echo ""
	@echo "Examples:"
	@echo "  make                    # Run confidence tests"
	@echo "  make test-keep-artifacts # Keep artifacts to inspect results"
	@echo "  KEEP_TEST_ARTIFACTS=1 make test  # Alternative way to keep artifacts"
