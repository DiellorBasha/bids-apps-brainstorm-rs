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

### Preprocessing Options
- **Filtering**: Configurable high-pass and low-pass filters
- **Artifact rejection**: Automatic and manual artifact detection
- **Epoching**: Event-based epoch extraction

### Source Analysis Options
- **Forward modeling**: Head model computation
- **Inverse solutions**: Multiple source estimation methods
- **Time-frequency analysis**: Power and connectivity metrics

## Examples

```bash
# Process single participant
./run /data /output participant --participant_label sub-01

# Process all participants
./run /data /output participant

# Group-level analysis
./run /data /output group
```

## Configuration Files

Parameters can also be specified via YAML configuration files in the `config/` directory:

- `default.yaml` - Default processing parameters
- `minimal.yaml` - Minimal processing for quick testing
- `schema.json` - Parameter validation schema