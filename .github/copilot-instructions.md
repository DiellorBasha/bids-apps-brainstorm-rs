# BIDS Apps Brainstorm AI Coding Instructions

## Project Overview

This is a BIDS-compliant neuroimaging application for MEG/EEG preprocessing and source analysis using Brainstorm. The project follows a multi-language architecture with MATLAB as the core processing engine, containerized for reproducible execution. The core MATLAB pipeline is based on Brainstorm's resting-state tutorial (https://neuroimage.usc.edu/brainstorm/Tutorials/RestingOmega) and adapted for BIDS datasets. The full MATLAB script of the tutorial is available at https://github.com/brainstorm-tools/brainstorm3/blob/master/toolbox/script/tutorial_omega.m and in the codebase at /tools/tutorial_omega.m. 

## Architecture & Key Components

### Entry Points & Execution Flow
- **`run`** - POSIX entrypoint (main BIDS Apps interface)
- **`run.sh`** - Internal dispatcher that calls MATLAB functions
- **`run.py`** - Optional Python CLI shim (minimal, delegates to MATLAB)
- **Flow**: `run` → `run.sh` → MATLAB `end_to_end.m` → processing pipeline

### Core MATLAB Pipeline (matlab/)
- **`end_to_end.m`** - Main orchestrator, handles participant vs group analysis. 
- **`import.m`** - BIDS dataset import and validation. Use Brainstorm's tutorial_omega.m as a reference for importing BIDS datasets: sections %% ===== FILES TO IMPORT =====, %% ===== CREATE PROTOCOL =====, and %% ===== IMPORT BIDS DATASET =====.
- **`preprocess.m`** - MEG/EEG preprocessing (filtering, artifact detection, epoching). Use Brainstorm's tutorial_omega.m as a reference for preprocessing steps: sections %% ===== PRE-PROCESSING ===== and %% ===== ARTIFACT CLEANING =====.
- **`sensor_space.m`** - Sensor-level analysis (time-frequency, connectivity, ERPs)
- **`source_space.m`** - Source reconstruction and analysis (forward modeling, inverse solutions). Use Brainstorm's tutorial_omega.m as a reference for source space analysis: sections %% ===== SOURCE ESTIMATION ===== and %% ===== POWER MAPS =====.

Use Brainstorm's bst_process functions as building blocks within these modules, as is done in tutorial_omega.m.

### Configuration System (config/)
- **YAML-based**: `default.yaml` (full processing), `minimal.yaml` (fast testing)
- **JSON Schema**: `schema.json` validates configuration parameters
- **Hierarchical**: preprocessing → source_analysis → output → quality_control sections

### Docker Strategy
- **Dual Dockerfiles**: `Dockerfile.mcr` (runtime), `Dockerfile.matlab` (development)
- **MCR version** for production deployment (no MATLAB license required)
- **MATLAB version** for development and testing

## Development Workflows

### Testing & Validation
```bash
# Generate synthetic test data
python3 tools/gen_synth_meg.py tests/tiny_bids_meg --n-participants 2 --include-anat

# Run smoke tests  
./tests/smoke.sh

# BIDS validation
./tools/bids_validate.sh /path/to/dataset

# Build and test containers
make docker-mcr && make test-smoke
```

### Configuration Updates
- Modify `config/default.yaml` for processing parameters
- Validate against `config/schema.json` 
- Test with `config/minimal.yaml` for rapid iteration

### MATLAB Development
- Functions use consistent naming: `process_*`, `compute_*`, `analyze_*`
- Data structures follow Brainstorm conventions
- Error handling with try/catch and participant-level isolation
- All processing generates JSON sidecars for BIDS derivatives compliance

## Project-Specific Patterns

### BIDS Derivatives Compliance
- Output structure: `derivatives/brainstorm/sub-<id>/[ses-<id>/]{meg,eeg,anat,sensor,source,figures}/`
- Naming: `*_proc-brainstorm_*` (preprocessed), `*_space-{sensor,source}_*` (analysis level)
- Metadata: Every `.mat` file has corresponding `.json` sidecar

### File Format Strategy  
- **Primary data**: MATLAB `.mat` files (Brainstorm native)
- **Metadata**: JSON sidecars (BIDS compliance)
- **Visualizations**: PNG images in `figures/` subdirectory
- **Reports**: HTML format for comprehensive summaries

### Error Handling & Logging
- Participant-level isolation (one failure doesn't stop others)
- Timestamped logs in `output_dir/logs/`
- Separate participant reports in `logs/participant_reports/`

### Multi-Modal Support
- Unified pipeline handles MEG (.ds, .fif, .pdf) and EEG (.edf, .vhdr, .set)
- Format detection based on file extensions
- Shared preprocessing and analysis workflows

## Critical Integration Points

### Brainstorm Dependencies
- Functions assume Brainstorm is available: `brainstorm nogui`
- Template anatomy fallback when subject-specific MRI unavailable
- Database structure follows Brainstorm conventions

### Container Resource Management
- Memory-intensive source analysis requires adequate Docker memory allocation
- Processing parameters tunable via config files for resource constraints
- Parallel processing handled at participant level, not trial level

### External Tool Integration
- BIDS Validator: Optional but recommended for input validation
- FreeSurfer: For anatomical processing (when available)
- MNE-Python: For synthetic data generation and format conversion

## Development Guidelines

### When Adding New Features
1. Update configuration schema in `config/schema.json`
2. Add parameters to `config/default.yaml` and `config/minimal.yaml`  
3. Implement in appropriate MATLAB module (`preprocess.m`, `sensor_space.m`, etc.)
4. Update output metadata and BIDS compliance
5. Add to smoke tests in `tests/smoke.sh`

### MATLAB Function Conventions
- Use consistent error handling: `try/catch` with participant continuation
- Generate processing metadata for JSON sidecars
- Follow BIDS entity-label naming conventions
- Include verbose logging with `fprintf` status messages

### Container Updates
- Test both MCR and MATLAB Dockerfiles
- Verify with synthetic test data before real datasets
- Update CI/CD pipeline in `ci/workflow.yml`

This codebase prioritizes BIDS compliance, containerized reproducibility, and robust error handling over performance optimization. The architecture supports both development flexibility (MATLAB) and production deployment (MCR containers).