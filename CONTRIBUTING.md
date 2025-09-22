# Contributing to BIDS Apps Brainstorm

Thank you for your interest in contributing to BIDS Apps Brainstorm! This document provides guidelines for contributing to the project.

## Development Setup

1. Clone the repository
2. Ensure MATLAB is installed (for development)
3. Install Docker (for containerized testing)
4. Run initial tests: `make test-smoke`

## Development Workflow

1. **Fork** the repository
2. **Create** a feature branch from `dev`
3. **Make** your changes
4. **Test** your changes thoroughly
5. **Submit** a pull request

## Code Style

### MATLAB Code
- Use descriptive variable names
- Add comments for complex algorithms
- Follow MATLAB best practices for function organization
- Keep functions focused and modular

### Shell Scripts
- Use `set -e` for error handling
- Add comments for complex logic
- Follow POSIX standards where possible

### Python Code (minimal usage)
- Follow PEP 8 style guidelines
- Use type hints where appropriate
- Keep Python components minimal - delegate to MATLAB

## Testing

- All changes must pass smoke tests
- Add integration tests for new features
- Test with sample BIDS datasets
- Verify Docker containers build successfully

## Documentation

- Update relevant documentation in `docs/`
- Update `CHANGELOG.md` for notable changes
- Ensure README remains current

## Submitting Changes

1. Ensure all tests pass
2. Update documentation as needed
3. Create a descriptive pull request
4. Reference any related issues

## Questions?

Feel free to open an issue for questions or clarifications.