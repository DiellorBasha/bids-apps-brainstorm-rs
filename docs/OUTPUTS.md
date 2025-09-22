# Outputs

This document describes the output files and directory structure produced by BIDS Apps Brainstorm.

## Output Directory Structure

```
output_dir/
├── derivatives/
│   └── brainstorm/
│       ├── dataset_description.json
│       └── sub-<label>/
│           ├── ses-<session>/
│           │   ├── meg/
│           │   │   ├── sub-<label>_ses-<session>_task-<task>_proc-brainstorm_meg.json
│           │   │   └── sub-<label>_ses-<session>_task-<task>_proc-brainstorm_meg.mat
│           │   └── anat/
│           │       ├── sub-<label>_ses-<session>_T1w_proc-brainstorm_anat.json
│           │       └── sub-<label>_ses-<session>_T1w_proc-brainstorm_anat.mat
│           └── figures/
│               ├── sub-<label>_preprocessing_summary.png
│               └── sub-<label>_source_analysis.png
└── logs/
    ├── brainstorm_<timestamp>.log
    └── participant_reports/
        └── sub-<label>_report.html
```

## File Descriptions

### Preprocessed Data

#### `*_proc-brainstorm_meg.mat`
- **Format**: MATLAB data file
- **Content**: Preprocessed MEG/EEG data with applied filters, artifact rejection, and epoching
- **Structure**: Brainstorm database format compatible files

#### `*_proc-brainstorm_meg.json`
- **Format**: JSON sidecar
- **Content**: Processing metadata including filter parameters, rejected trials, and processing steps

### Anatomical Processing

#### `*_proc-brainstorm_anat.mat`
- **Format**: MATLAB data file  
- **Content**: Processed anatomical data including cortical surface meshes and head models

### Source Analysis Results

#### `*_sources.mat`
- **Format**: MATLAB data file
- **Content**: Source-level analysis results including dipole orientations and time series

### Quality Control

#### `*_preprocessing_summary.png`
- **Format**: PNG image
- **Content**: Visual summary of preprocessing steps and data quality metrics

#### `*_source_analysis.png`
- **Format**: PNG image
- **Content**: Source analysis results visualization

### Reports

#### `sub-<label>_report.html`
- **Format**: HTML report
- **Content**: Comprehensive processing report with figures and quality metrics

## BIDS Derivatives Compliance

All outputs follow BIDS derivatives specification:
- Proper naming conventions with entity-label pairs
- JSON sidecars with processing metadata
- `dataset_description.json` at the root level
- Consistent directory structure

## Data Formats

- **Primary data**: MATLAB `.mat` files for Brainstorm compatibility
- **Metadata**: JSON sidecars following BIDS specification
- **Visualizations**: PNG images for quality control
- **Reports**: HTML format for comprehensive summaries