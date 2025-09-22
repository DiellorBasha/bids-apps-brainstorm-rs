#!/bin/bash
# BIDS validation tool for BIDS Apps Brainstorm
# Validates BIDS dataset structure before processing

set -e

# Default values
DATASET_DIR=""
VERBOSE=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [options] <dataset_directory>"
            echo "Options:"
            echo "  -v, --verbose    Verbose output"
            echo "  -h, --help       Show this help"
            exit 0
            ;;
        *)
            if [[ -z "$DATASET_DIR" ]]; then
                DATASET_DIR="$1"
            else
                echo "Unknown argument: $1"
                exit 1
            fi
            shift
            ;;
    esac
done

# Validate required arguments
if [[ -z "$DATASET_DIR" ]]; then
    echo "Error: Dataset directory required"
    echo "Usage: $0 [options] <dataset_directory>"
    exit 1
fi

# Check if dataset directory exists
if [[ ! -d "$DATASET_DIR" ]]; then
    echo "Error: Dataset directory does not exist: $DATASET_DIR"
    exit 1
fi

echo "Validating BIDS dataset: $DATASET_DIR"

# Check for required files
echo "Checking required files..."

required_files=(
    "dataset_description.json"
)

for file in "${required_files[@]}"; do
    if [[ ! -f "$DATASET_DIR/$file" ]]; then
        echo "  ❌ Missing required file: $file"
        exit 1
    else
        echo "  ✅ Found: $file"
    fi
done

# Check for participant directories
echo "Checking participant directories..."
participant_count=$(find "$DATASET_DIR" -maxdepth 1 -type d -name "sub-*" | wc -l)

if [[ $participant_count -eq 0 ]]; then
    echo "  ❌ No participant directories found (sub-*)"
    exit 1
else
    echo "  ✅ Found $participant_count participant(s)"
fi

# List participants if verbose
if [[ "$VERBOSE" == "true" ]]; then
    echo "Participants:"
    find "$DATASET_DIR" -maxdepth 1 -type d -name "sub-*" -printf "  %f\n"
fi

# Check for MEG/EEG data
echo "Checking for MEG/EEG data..."
meg_count=0
eeg_count=0

for participant_dir in "$DATASET_DIR"/sub-*; do
    if [[ -d "$participant_dir" ]]; then
        # Check for MEG data
        if find "$participant_dir" -name "*.ds" -o -name "*.fif" -o -name "*.pdf" | grep -q .; then
            ((meg_count++))
        fi
        
        # Check for EEG data
        if find "$participant_dir" -name "*.edf" -o -name "*.vhdr" -o -name "*.set" | grep -q .; then
            ((eeg_count++))
        fi
    fi
done

echo "  MEG participants: $meg_count"
echo "  EEG participants: $eeg_count"

if [[ $meg_count -eq 0 && $eeg_count -eq 0 ]]; then
    echo "  ⚠️  No MEG or EEG data found"
else
    echo "  ✅ Found MEG/EEG data"
fi

# Check dataset_description.json content
echo "Checking dataset description..."
if command -v python3 &> /dev/null; then
    python3 -c "
import json
import sys

try:
    with open('$DATASET_DIR/dataset_description.json', 'r') as f:
        desc = json.load(f)
    
    required_fields = ['Name', 'BIDSVersion']
    for field in required_fields:
        if field not in desc:
            print(f'  ❌ Missing required field in dataset_description.json: {field}')
            sys.exit(1)
        else:
            print(f'  ✅ Found {field}: {desc[field]}')
            
except json.JSONDecodeError as e:
    print(f'  ❌ Invalid JSON in dataset_description.json: {e}')
    sys.exit(1)
except Exception as e:
    print(f'  ❌ Error reading dataset_description.json: {e}')
    sys.exit(1)
"
else
    echo "  ⚠️  Python not found, skipping JSON validation"
fi

# Try to run official BIDS validator if available
if command -v bids-validator &> /dev/null; then
    echo "Running official BIDS validator..."
    bids-validator "$DATASET_DIR" --verbose
elif docker --version &> /dev/null 2>&1; then
    echo "Running BIDS validator via Docker..."
    docker run --rm -v "$DATASET_DIR":/data bids/validator /data
else
    echo "  ⚠️  BIDS validator not available (install bids-validator or Docker)"
fi

echo "✅ Basic BIDS validation completed successfully"