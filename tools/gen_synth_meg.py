#!/usr/bin/env python3
"""
Generate synthetic MEG data for testing BIDS Apps Brainstorm

This script creates a minimal BIDS-formatted MEG dataset for testing purposes.
The generated data is synthetic and suitable only for pipeline testing.
"""

import argparse
import json
import os
import sys
from pathlib import Path
import numpy as np
from datetime import datetime


def create_dataset_description(output_dir):
    """Create dataset_description.json"""
    description = {
        "Name": "Synthetic MEG Test Dataset",
        "BIDSVersion": "1.8.0",
        "License": "CC0",
        "Authors": ["BIDS Apps Brainstorm"],
        "DatasetType": "raw",
        "GeneratedBy": {
            "Name": "gen_synth_meg.py",
            "Version": "0.1.0",
            "Description": "Synthetic data generator for testing"
        }
    }
    
    with open(output_dir / "dataset_description.json", "w") as f:
        json.dump(description, f, indent=2)


def create_participants_tsv(output_dir, n_participants):
    """Create participants.tsv"""
    header = "participant_id\tage\tsex\n"
    rows = []
    
    for i in range(1, n_participants + 1):
        participant_id = f"sub-{i:02d}"
        age = np.random.randint(20, 60)
        sex = np.random.choice(["M", "F"])
        rows.append(f"{participant_id}\t{age}\t{sex}")
    
    with open(output_dir / "participants.tsv", "w") as f:
        f.write(header)
        f.write("\n".join(rows) + "\n")


def create_meg_data(participant_dir, participant_id, session="01"):
    """Create synthetic MEG data"""
    if session:
        meg_dir = participant_dir / f"ses-{session}" / "meg"
    else:
        meg_dir = participant_dir / "meg"
    
    meg_dir.mkdir(parents=True, exist_ok=True)
    
    # Create synthetic FIF file (Neuromag format placeholder)
    # In real implementation, this would use MNE-Python to create actual FIF
    task = "rest"
    run = "01"
    
    if session:
        base_name = f"{participant_id}_ses-{session}_task-{task}_run-{run}"
    else:
        base_name = f"{participant_id}_task-{task}_run-{run}"
    
    # Create placeholder MEG file
    meg_file = meg_dir / f"{base_name}_meg.fif"
    with open(meg_file, "wb") as f:
        # Write minimal FIF header (placeholder)
        f.write(b"FIFF_FILE_ID")
        f.write(b"\x00" * 1000)  # Placeholder data
    
    # Create JSON sidecar
    meg_json = {
        "TaskName": task,
        "SamplingFrequency": 1000.0,
        "PowerLineFrequency": 50,
        "DewarPosition": "upright",
        "DigitizedLandmarks": True,
        "DigitizedHeadPoints": True,
        "MEGChannelCount": 306,
        "MEGREFChannelCount": 0,
        "EEGChannelCount": 0,
        "EOGChannelCount": 2,
        "ECGChannelCount": 1,
        "EMGChannelCount": 0,
        "MiscChannelCount": 0,
        "TriggerChannelCount": 16,
        "RecordingDuration": 600.0,
        "RecordingType": "continuous",
        "InstitutionName": "Test Institution",
        "Manufacturer": "Elekta",
        "ManufacturersModelName": "VectorView"
    }
    
    with open(meg_dir / f"{base_name}_meg.json", "w") as f:
        json.dump(meg_json, f, indent=2)
    
    # Create channels.tsv
    channels = []
    # MEG channels
    for i in range(306):
        if i % 3 == 2:  # Magnetometer
            ch_type = "MEGGMAG"
            units = "T"
        else:  # Gradiometer
            ch_type = "MEGGPLANAR"
            units = "T/m"
        
        channels.append({
            "name": f"MEG{i+1:04d}",
            "type": ch_type,
            "units": units,
            "low_cutoff": 0.1,
            "high_cutoff": 330.0,
            "sampling_frequency": 1000.0,
            "status": "good"
        })
    
    # EOG channels
    for i in range(2):
        channels.append({
            "name": f"EOG{i+1:03d}",
            "type": "EOG",
            "units": "V",
            "low_cutoff": 0.1,
            "high_cutoff": 330.0,
            "sampling_frequency": 1000.0,
            "status": "good"
        })
    
    # ECG channel
    channels.append({
        "name": "ECG063",
        "type": "ECG",
        "units": "V",
        "low_cutoff": 0.1,
        "high_cutoff": 330.0,
        "sampling_frequency": 1000.0,
        "status": "good"
    })
    
    # Write channels.tsv
    with open(meg_dir / f"{base_name}_channels.tsv", "w") as f:
        f.write("name\ttype\tunits\tlow_cutoff\thigh_cutoff\tsampling_frequency\tstatus\n")
        for ch in channels:
            f.write(f"{ch['name']}\t{ch['type']}\t{ch['units']}\t{ch['low_cutoff']}\t{ch['high_cutoff']}\t{ch['sampling_frequency']}\t{ch['status']}\n")
    
    print(f"Created MEG data for {participant_id}")


def create_anatomical_data(participant_dir, participant_id, session="01"):
    """Create placeholder anatomical data"""
    if session:
        anat_dir = participant_dir / f"ses-{session}" / "anat"
    else:
        anat_dir = participant_dir / "anat"
    
    anat_dir.mkdir(parents=True, exist_ok=True)
    
    # Create placeholder T1w NIfTI file
    if session:
        t1_name = f"{participant_id}_ses-{session}_T1w"
    else:
        t1_name = f"{participant_id}_T1w"
    
    # Create minimal NIfTI header (placeholder)
    t1_file = anat_dir / f"{t1_name}.nii.gz"
    with open(t1_file, "wb") as f:
        # Write minimal NIfTI header (348 bytes)
        header = bytearray(348)
        header[0:4] = (348).to_bytes(4, 'little')  # sizeof_hdr
        header[40:48] = b"n+1\x00\x00\x00\x00\x00"  # magic
        f.write(header)
        f.write(b"\x00" * 1000)  # Placeholder image data
    
    # Create JSON sidecar
    t1_json = {
        "MagneticFieldStrength": 3.0,
        "Manufacturer": "Siemens",
        "ManufacturersModelName": "Prisma",
        "RepetitionTime": 2.3,
        "EchoTime": 0.00456,
        "FlipAngle": 8,
        "InversionTime": 0.9,
        "SliceThickness": 1.0,
        "SpacingBetweenSlices": 1.0,
        "PixelBandwidth": 200,
        "PhaseEncodingDirection": "j-"
    }
    
    with open(anat_dir / f"{t1_name}.json", "w") as f:
        json.dump(t1_json, f, indent=2)
    
    print(f"Created anatomical data for {participant_id}")


def main():
    parser = argparse.ArgumentParser(
        description="Generate synthetic MEG data for testing BIDS Apps Brainstorm"
    )
    parser.add_argument(
        "output_dir",
        help="Output directory for synthetic dataset"
    )
    parser.add_argument(
        "--n-participants",
        type=int,
        default=2,
        help="Number of participants to generate (default: 2)"
    )
    parser.add_argument(
        "--sessions",
        action="store_true",
        help="Include session subdirectories"
    )
    parser.add_argument(
        "--include-anat",
        action="store_true",
        help="Include anatomical data"
    )
    
    args = parser.parse_args()
    
    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)
    
    print(f"Generating synthetic MEG dataset in: {output_dir}")
    print(f"Participants: {args.n_participants}")
    print(f"Sessions: {args.sessions}")
    print(f"Anatomical data: {args.include_anat}")
    
    # Create dataset-level files
    create_dataset_description(output_dir)
    create_participants_tsv(output_dir, args.n_participants)
    
    # Create participant data
    for i in range(1, args.n_participants + 1):
        participant_id = f"sub-{i:02d}"
        participant_dir = output_dir / participant_id
        participant_dir.mkdir(exist_ok=True)
        
        # Create MEG data
        if args.sessions:
            create_meg_data(participant_dir, participant_id, session="01")
            if args.include_anat:
                create_anatomical_data(participant_dir, participant_id, session="01")
        else:
            create_meg_data(participant_dir, participant_id, session=None)
            if args.include_anat:
                create_anatomical_data(participant_dir, participant_id, session=None)
    
    print(f"✅ Synthetic dataset created successfully in {output_dir}")
    print("\nTo validate the dataset, run:")
    print(f"  ./tools/bids_validate.sh {output_dir}")


if __name__ == "__main__":
    main()