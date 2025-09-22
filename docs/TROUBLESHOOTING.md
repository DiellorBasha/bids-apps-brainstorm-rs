# Troubleshooting

This guide covers common issues and their solutions when using BIDS Apps Brainstorm.

## Installation Issues

### Docker Container Won't Start

**Problem**: Container fails to start or exits immediately

**Solutions**:
1. Check Docker is running: `docker --version`
2. Verify image was built successfully: `docker images | grep brainstorm`
3. Check container logs: `docker logs <container_id>`
4. Ensure sufficient disk space and memory

### MATLAB License Issues

**Problem**: MATLAB licensing errors in container

**Solutions**:
1. For MCR version: Use `Dockerfile.mcr` which doesn't require license
2. For development: Ensure MATLAB license is properly mounted
3. Check license server connectivity if using network licensing

## Data Issues

### BIDS Validation Errors

**Problem**: Dataset fails BIDS validation

**Solutions**:
1. Run BIDS validator: `./tools/bids_validate.sh /path/to/dataset`
2. Common issues:
   - Missing `dataset_description.json`
   - Incorrect file naming
   - Missing required metadata files
3. Refer to [BIDS specification](https://bids-specification.readthedocs.io/)

### MEG/EEG File Format Issues

**Problem**: MEG/EEG files not recognized

**Supported formats**:
- CTF (.ds directories)
- Neuromag/Elekta (.fif files)
- BTi/4D (.pdf/.m4d files)
- EEG: EDF, BrainVision, EEGLAB

**Solutions**:
1. Convert data to supported BIDS format
2. Check file extensions match BIDS conventions
3. Verify data integrity with `file` command

## Processing Issues

### Memory Errors

**Problem**: Out of memory during processing

**Solutions**:
1. Increase Docker memory allocation
2. Process fewer participants simultaneously
3. Use `--participant_label` to process subset
4. Check available system memory

### Processing Hangs

**Problem**: Processing appears to hang indefinitely

**Solutions**:
1. Check system resources (CPU, memory, disk)
2. Review logs for error messages
3. Try with minimal configuration (`config/minimal.yaml`)
4. Process single participant for debugging

## Output Issues

### Missing Output Files

**Problem**: Expected output files not generated

**Solutions**:
1. Check processing completed successfully (exit code 0)
2. Review log files in `output_dir/logs/`
3. Verify input data quality
4. Check disk space in output directory

### Corrupted Output

**Problem**: Output files appear corrupted or incomplete

**Solutions**:
1. Re-run processing with verbose logging
2. Check source data integrity
3. Verify sufficient computational resources
4. Review preprocessing parameters

## Performance Issues

### Slow Processing

**Problem**: Processing takes excessive time

**Optimization strategies**:
1. Use appropriate analysis level (`participant` vs `group`)
2. Optimize filtering parameters
3. Adjust epoch length and overlap
4. Consider parallel processing options

## Getting Help

### Log Files

Always check log files first:
```bash
# Main processing log
cat output_dir/logs/brainstorm_*.log

# Participant-specific logs
cat output_dir/logs/participant_reports/sub-*_report.html
```

### Debugging Mode

Run with debug flags:
```bash
# Enable verbose logging
DEBUG=1 ./run /data /output participant

# Test with minimal dataset
./run tests/tiny_bids_meg output_test participant
```

### Reporting Issues

When reporting issues, include:
1. Complete error message and stack trace
2. Input data structure (`tree /path/to/bids_dir`)
3. Command used to run the container
4. System information (OS, Docker version, memory)
5. Log files (if available)

### Common Commands for Diagnosis

```bash
# Check BIDS structure
tree -L 3 /path/to/bids_dataset

# Validate BIDS dataset
docker run --rm -v /path/to/data:/data bids/validator /data

# Test with sample data
make test-smoke

# Check container resources
docker stats <container_name>
```