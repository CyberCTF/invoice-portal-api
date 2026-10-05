# Extensions and Runtimes

Runtime requirements per stack: PHP extensions, Python wheels, Node lockfiles.

## PHP Extensions
- Explicitly list and install required extensions (e.g., `mysqli`, `pdo_mysql`, `gd`, `zip`). Build fails if missing.
- Example:
```dockerfile
RUN docker-php-ext-install mysqli pdo_mysql
```

## Python
- Document/install toolchain if native wheels are required.
- Ensure requirements.txt is present and complete.

## Node.js
- Locked dependencies (lockfile). The port defaults to the one declared in `isoloom.yml`.
- Use package-lock.json or yarn.lock for dependency versions.
