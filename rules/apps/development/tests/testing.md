# Docker and Application Testing Framework

Testing framework overview: root-level tests dir, categories, principles, and related docs.

## Test Directory Structure

### Tests Location
- **Tests Directory**: Must be at **root level** (same level as `/build` directory)
- **Structure**: `/tests/` alongside `/build/` and `isoloom.yml`. Tests run against `.isoloom/docker/compose.yml`
- **Organization**: Tests should be organized by functionality and test type
- **Configuration**: Test configuration files (pytest.ini, conftest.py) at root level

## Test Requirements

Create focused pytest tests to validate Docker container functionality and basic application operations.

## Quick Reference

### Test Categories
- **Docker Tests**: Container status, health checks, port accessibility
- **Service Tests**: Web application, database, and other services availability
- **Application Tests**: Basic functionality, user interface, API endpoints
- **Integration Tests**: End-to-end application workflow

### Core Principles
- **Focused**: Cover essential Docker and application functionality
- **Reliable**: Tests must be deterministic and repeatable
- **Fast**: Quick execution for rapid feedback
- **Clear**: Test names and assertions should be self-documenting
- **Maintainable**: Easy to update when application changes

## Related Documentation

- **Test Requirements**: See `test-requirements.md` for detailed coverage requirements
- **Test Execution**: See `test-execution.md` for execution and cleanup procedures
- **Test Retry**: See `test-retry.md` for retry logic and error correction
- **Review Phase**: See `review-phase.md` for review-specific rules
- **Phase Timing**: See `phase-timing.md` for timing and logging
- **Environment Variables**: See `test-env-vars.md` for configuration
