# Simple Makefile for agent-adr confidence testing

.PHONY: test test-confidence test-keep-artifacts clean help

# Default target
test: test-confidence ## 🚀 Run confidence test suite (default)

# Run confidence test suite
test-confidence: ## 🧪 Run confidence test suite
	@echo "🚀 Running confidence test suite..."
	./tests/smoke-test-confidence.sh

# Run confidence tests and keep artifacts for inspection
test-keep-artifacts: ## 🔍 Run tests and keep artifacts for inspection
	@echo "🚀 Running confidence test suite (keeping artifacts)..."
	KEEP_TEST_ARTIFACTS=1 ./tests/smoke-test-confidence.sh

# Clean up any test artifacts
clean: ## 🧹 Clean up test artifacts
	@echo "🧹 Cleaning up test artifacts..."
	rm -rf /tmp/agent-adr-*
	rm -rf /tmp/agent-adr-confidence-*
	rm -rf /tmp/agent-adr-fixtures-*

# Show help
help: ## 💬 This help message :)
	@figlet $@ || true
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'
