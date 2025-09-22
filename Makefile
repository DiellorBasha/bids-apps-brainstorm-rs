# Makefile for BIDS Apps Brainstorm
# Phase 3 - To be implemented

.PHONY: build test clean docker-mcr docker-matlab

# Default target
all: build

# Build targets
build:
	@echo "Building BIDS Apps Brainstorm..."
	# TODO: Implement build steps

# Test targets
test: test-smoke test-integration
	@echo "All tests passed"

test-smoke:
	@echo "Running smoke tests..."
	./tests/smoke.sh

test-integration:
	@echo "Running integration tests..."
	# TODO: Implement integration tests

# Docker targets
docker-mcr:
	docker build -f Dockerfile.mcr -t bids-apps-brainstorm:mcr .

docker-matlab:
	docker build -f Dockerfile.matlab -t bids-apps-brainstorm:matlab .

# Cleanup
clean:
	@echo "Cleaning up..."
	# TODO: Implement cleanup steps

# Development helpers
validate-bids:
	./tools/bids_validate.sh

generate-test-data:
	python ./tools/gen_synth_meg.py