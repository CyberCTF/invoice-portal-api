# Scripts and System Compliance

Shell script hygiene: LF endings, executable perms (755), avoid ^M issues; ensure scripts runnable.

## Shell Script Requirements

- All shell scripts (build scripts, `init` jobs, `provision/` steps, checks) must use LF line endings and `#!/bin/sh` with `set -eu`.
- Avoid `/bin/sh^M` errors by applying `.gitattributes` or conversion at build time if necessary.

## Script Execution

- **Permission Errors**: Use `chmod 755` instead of `chmod +x` for script files
- **Script Execution**: Ensure init scripts are executable and have correct permissions

## Example
```bash
# In Dockerfile
COPY scripts/ /usr/local/bin/
RUN chmod 755 /usr/local/bin/*.sh
```
