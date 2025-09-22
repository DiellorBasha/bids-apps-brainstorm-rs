# Parameters

This document describes all available parameters for BIDS Apps Brainstorm.

## Required Parameters

### `bids_dir`
- **Type**: String (path)
- **Description**: Path to BIDS dataset directory
- **Example**: `/data/bids_dataset`

### `output_dir`
- **Type**: String (path)
- **Description**: Path to output directory
- **Example**: `/output`

### `analysis_level`
- **Type**: String
- **Choices**: `participant`, `group`
- **Description**: Level of analysis to perform
- **Default**: `participant`

## Optional Parameters

### `--participant_label`
- **Type**: String
- **Description**: Participant label(s) to process (space-separated)
- **Example**: `sub-01 sub-02`
- **Default**: Process all participants

## Configuration Parameters
Provide a YAML/JSON with `--params`, outlining input parameters for the pipeline.
Keys mirror MATLAB structs. 
#### Example `--params`
```yaml
preproc:
  notch: [60, 120, 180]   # Hz (example)
  bandpass: [1, 150]      # Hz
  ssp:
    ecg: true
    eog: true
sensor:
  psd:
    welch_win: 2.0
    welch_ovlp: 0.5
  tfr:
    method: "morlet"
    fmin: 1
    fmax: 40
source:
  inverse:
    method: "minnorm-2018"
    snr: 3
    loose: 0.2
    depth_weighting: 0.8
general:
  headmodel: "bem"  # or "spherical"
```

## Configuration Files

Parameters can also be specified via YAML configuration files in the `config/` directory:

- `default.yaml` - Default processing parameters
- `minimal.yaml` - Minimal processing for quick testing
- `schema.json` - Parameter validation schema