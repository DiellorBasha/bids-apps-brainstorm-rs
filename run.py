#!/usr/bin/env python3
"""
Optional Python CLI shim for BIDS Apps Brainstorm
Kept minimal - primarily delegates to MATLAB implementation
"""

import argparse
import subprocess
import sys
from pathlib import Path


def main():
    parser = argparse.ArgumentParser(
        description="BIDS Apps Brainstorm - MEG/EEG preprocessing and source analysis"
    )
    parser.add_argument("bids_dir", help="BIDS dataset directory")
    parser.add_argument("output_dir", help="Output directory")
    parser.add_argument(
        "analysis_level",
        choices=["participant", "group"],
        help="Level of analysis to perform"
    )
    parser.add_argument(
        "--participant_label",
        help="Participant label(s) to process"
    )
    
    args = parser.parse_args()
    
    # Build command for run.sh
    cmd = ["/app/run.sh", args.bids_dir, args.output_dir]
    
    if args.participant_label:
        cmd.extend(["--participant_label", args.participant_label])
    
    cmd.extend(["--analysis_level", args.analysis_level])
    
    # Execute
    try:
        subprocess.run(cmd, check=True)
    except subprocess.CalledProcessError as e:
        sys.exit(e.returncode)


if __name__ == "__main__":
    main()