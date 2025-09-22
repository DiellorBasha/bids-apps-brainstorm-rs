#!/bin/bash
# Internal dispatcher for BIDS Apps Brainstorm
# Optional - handles routing to MATLAB implementation

set -e

# Default values
BIDS_DIR=""
OUTPUT_DIR=""
ANALYSIS_LEVEL="participant"
PARTICIPANT_LABEL=""

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --participant_label)
            PARTICIPANT_LABEL="$2"
            shift 2
            ;;
        --analysis_level)
            ANALYSIS_LEVEL="$2"
            shift 2
            ;;
        *)
            if [[ -z "$BIDS_DIR" ]]; then
                BIDS_DIR="$1"
            elif [[ -z "$OUTPUT_DIR" ]]; then
                OUTPUT_DIR="$1"
            else
                echo "Unknown argument: $1"
                exit 1
            fi
            shift
            ;;
    esac
done

# Validate required arguments
if [[ -z "$BIDS_DIR" || -z "$OUTPUT_DIR" ]]; then
    echo "Usage: $0 <bids_dir> <output_dir> [options]"
    echo "  --participant_label LABEL"
    echo "  --analysis_level {participant,group}"
    exit 1
fi

# Call MATLAB implementation
matlab -batch "addpath('/app/matlab'); end_to_end('$BIDS_DIR', '$OUTPUT_DIR', '$ANALYSIS_LEVEL', '$PARTICIPANT_LABEL')"