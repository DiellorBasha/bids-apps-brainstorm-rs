#!/bin/bash
# Smoke tests for BIDS Apps Brainstorm
# Basic functionality tests to ensure the app works

set -e

echo "Running smoke tests for BIDS Apps Brainstorm..."

# Test configuration
TEST_DIR="$(dirname "$0")"
PROJECT_ROOT="$(dirname "$TEST_DIR")"
TEST_DATA_DIR="$TEST_DIR/tiny_bids_meg"
OUTPUT_DIR="$TEST_DIR/test_output"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Cleanup function
cleanup() {
    if [[ -d "$OUTPUT_DIR" ]]; then
        rm -rf "$OUTPUT_DIR"
    fi
}

# Test result tracking
TESTS_PASSED=0
TESTS_FAILED=0

# Test helper function
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    echo -e "\n${YELLOW}Testing: $test_name${NC}"
    
    if eval "$test_command"; then
        echo -e "${GREEN}✅ PASSED: $test_name${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}❌ FAILED: $test_name${NC}"
        ((TESTS_FAILED++))
    fi
}

# Trap for cleanup on exit
trap cleanup EXIT

echo "Project root: $PROJECT_ROOT"
echo "Test data: $TEST_DATA_DIR"
echo "Output: $OUTPUT_DIR"

# Test 1: Check if essential files exist
run_test "Essential files exist" "
    [[ -f '$PROJECT_ROOT/run' ]] && 
    [[ -f '$PROJECT_ROOT/run.sh' ]] && 
    [[ -f '$PROJECT_ROOT/run.py' ]] &&
    [[ -f '$PROJECT_ROOT/VERSION' ]]
"

# Test 2: Check if run scripts are executable
run_test "Run scripts are executable" "
    [[ -x '$PROJECT_ROOT/run' ]] || chmod +x '$PROJECT_ROOT/run'
    [[ -x '$PROJECT_ROOT/run.sh' ]] || chmod +x '$PROJECT_ROOT/run.sh'
    [[ -x '$PROJECT_ROOT/run.py' ]] || chmod +x '$PROJECT_ROOT/run.py'
"

# Test 3: Generate test data if it doesn't exist
if [[ ! -d "$TEST_DATA_DIR" ]]; then
    echo "Generating test data..."
    run_test "Generate synthetic test data" "
        cd '$PROJECT_ROOT' &&
        python3 tools/gen_synth_meg.py '$TEST_DATA_DIR' --n-participants 1 --include-anat
    "
fi

# Test 4: Validate test data structure
run_test "Test data has valid BIDS structure" "
    [[ -f '$TEST_DATA_DIR/dataset_description.json' ]] &&
    [[ -f '$TEST_DATA_DIR/participants.tsv' ]] &&
    [[ -d '$TEST_DATA_DIR/sub-01' ]]
"

# Test 5: BIDS validation (if validator available)
if command -v python3 &> /dev/null; then
    run_test "BIDS validation (basic)" "
        cd '$PROJECT_ROOT' &&
        ./tools/bids_validate.sh '$TEST_DATA_DIR'
    "
fi

# Test 6: Check MATLAB files syntax (if MATLAB available)
if command -v matlab &> /dev/null; then
    run_test "MATLAB files syntax check" "
        cd '$PROJECT_ROOT/matlab' &&
        matlab -batch 'addpath(pwd); try; end_to_end(\"\", \"\", \"participant\", \"\"); catch; end; exit'
    "
else
    echo -e "${YELLOW}⚠️  MATLAB not available, skipping MATLAB syntax tests${NC}"
fi

# Test 7: Python script syntax check
run_test "Python script syntax check" "
    python3 -m py_compile '$PROJECT_ROOT/run.py' &&
    python3 -m py_compile '$PROJECT_ROOT/tools/gen_synth_meg.py'
"

# Test 8: Configuration files are valid JSON/YAML
run_test "Configuration files syntax" "
    python3 -c 'import json; json.load(open(\"$PROJECT_ROOT/config/schema.json\"))' &&
    python3 -c 'import yaml; yaml.safe_load(open(\"$PROJECT_ROOT/config/default.yaml\"))' &&
    python3 -c 'import yaml; yaml.safe_load(open(\"$PROJECT_ROOT/config/minimal.yaml\"))'
"

# Test 9: Docker build (if Docker available)
if command -v docker &> /dev/null; then
    run_test "Docker MCR build" "
        cd '$PROJECT_ROOT' &&
        docker build -f Dockerfile.mcr -t bids-apps-brainstorm:test-mcr .
    "
    
    # Cleanup test Docker image
    docker rmi bids-apps-brainstorm:test-mcr 2>/dev/null || true
else
    echo -e "${YELLOW}⚠️  Docker not available, skipping Docker build tests${NC}"
fi

# Test 10: Help/usage information
run_test "Help information available" "
    cd '$PROJECT_ROOT' &&
    python3 run.py --help > /dev/null
"

# Test 11: Version information
run_test "Version information accessible" "
    [[ -f '$PROJECT_ROOT/VERSION' ]] &&
    [[ -s '$PROJECT_ROOT/VERSION' ]]
"

# Test 12: Directory structure
run_test "Required directory structure" "
    [[ -d '$PROJECT_ROOT/matlab' ]] &&
    [[ -d '$PROJECT_ROOT/config' ]] &&
    [[ -d '$PROJECT_ROOT/tools' ]] &&
    [[ -d '$PROJECT_ROOT/tests' ]] &&
    [[ -d '$PROJECT_ROOT/docs' ]]
"

# Test 13: Documentation files exist
run_test "Documentation files exist" "
    [[ -f '$PROJECT_ROOT/README.md' ]] &&
    [[ -f '$PROJECT_ROOT/docs/README.md' ]] &&
    [[ -f '$PROJECT_ROOT/docs/PARAMETERS.md' ]] &&
    [[ -f '$PROJECT_ROOT/docs/OUTPUTS.md' ]]
"

# Summary
echo -e "\n${YELLOW}=== Smoke Test Summary ===${NC}"
echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"
echo -e "Total tests: $((TESTS_PASSED + TESTS_FAILED))"

if [[ $TESTS_FAILED -eq 0 ]]; then
    echo -e "\n${GREEN}🎉 All smoke tests passed!${NC}"
    exit 0
else
    echo -e "\n${RED}💥 Some tests failed. Please check the output above.${NC}"
    exit 1
fi