# Test Execution and Docker Cleanup

Test execution contract: pytest runs the generated .isoloom/docker/compose.yml, env-controlled cleanup, robust handling.

## Test Execution

### Execution Modes
- **Run all tests**: Execute complete test suite
- **Docker-specific tests**: Run only Docker container tests
- **Application tests**: Run only application functionality tests
- **Verbose output**: Detailed test execution information

## The lab under test

pytest runs the Docker edition: `.isoloom/docker/compose.yml`, generated from `isoloom.yml`.
Run `isoloom generate` first if `isoloom.yml` changed. The session fixture brings it up and
tears it down (see `invoice-portal-api/tests/conftest.py`):

```python
COMPOSE = ["docker", "compose", "-f", ".isoloom/docker/compose.yml"]
subprocess.run(COMPOSE + ["up", "-d", "--build", "--wait", "--wait-timeout", "300"], cwd=ROOT, check=True)
# ... wait for the health endpoint at APP_BASE_URL, yield, then:
subprocess.run(COMPOSE + ["down", "-v"], cwd=ROOT, check=False)
```

No token is set, so the lab uses its development evidence. The VM edition is checked by the
review (`vagrant up` + `build/check/check.sh`), not by pytest.

## Automatic Docker Cleanup

### Pre-Test Cleanup

#### Purpose
- Stop all running containers
- Remove volumes for fresh database/service state
- Prevent test interference from previous runs

#### Configuration
- Cleanup behavior configurable via environment variables (no hardcoded values)
- Graceful handling of cleanup failures

#### Cleanup Steps
Before every test run, execute `docker compose -f .isoloom/docker/compose.yml down -v` to ensure clean state:
1. Stop all running containers
2. Remove volumes for fresh state
3. Clean up networks
4. Reset environment to known state

### Cleanup Configuration

#### Environment Variables
- `CLEANUP_BEFORE_TESTS` (default: true): execute cleanup before tests
- `REMOVE_VOLUMES` (default: true): remove volumes during cleanup
- `CLEANUP_NETWORKS` (default: true): clean networks during cleanup

#### Implementation
- Use environment variables for all configuration
- No hardcoded cleanup behavior
- Configurable per test run
- Graceful error handling if cleanup fails

## Best Practices

### Clean State
- Always start tests from a clean state
- Remove all volumes before test execution
- Clean up networks to avoid conflicts

### Error Handling
- Handle cleanup failures gracefully
- Log cleanup operations for debugging
- Continue test execution even if cleanup has issues

### Performance
- Optimize cleanup operations
- Minimize cleanup time
- Parallel cleanup when possible
