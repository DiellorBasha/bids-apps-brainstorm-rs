# BIDS Apps Brainstorm Documentation

This directory contains comprehensive documentation for the BIDS Apps Brainstorm project.

## Documentation Structure

- **[PARAMETERS.md](PARAMETERS.md)** - Detailed parameter documentation
- **[OUTPUTS.md](OUTPUTS.md)** - Output file descriptions and formats
- **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)** - Common issues and solutions
- **[SECURITY.md](SECURITY.md)** - Security considerations and best practices

## Quick Start

1. Prepare your BIDS-formatted MEG/EEG dataset
2. Run the container: `docker run -v /path/to/data:/data bids-apps-brainstorm /data /output participant`
3. Check outputs in the specified output directory

## Requirements

- BIDS-formatted MEG/EEG dataset
- Docker or MATLAB installation
- Sufficient computational resources for source analysis

## Support

For questions and issues, please refer to the troubleshooting guide or open an issue on GitHub.