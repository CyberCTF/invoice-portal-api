# Isoloom and Docker Critical Errors

Isoloom and Docker critical errors in the points-based enforcement system.

**These errors are ABSOLUTELY FORBIDDEN and result in massive point loss (-500 points each):**

1. **Writing orchestration by hand** (-500 points)
   - Creating `docker-compose.yml`, `build/docker-compose.dev.yml`, a `deploy/` folder,
     Vagrantfiles, Terraform, cloud-init or `range.yaml`
   - Editing anything under `.isoloom/`
   - **CORRECT**: Describe the lab in `isoloom.yml`, run `isoloom generate`, commit `.isoloom/`

2. **Stale or invalid generated files** (-500 points)
   - `isoloom validate` or `isoloom check` fails
   - `isoloom.yml` changed without re-running `isoloom generate`
   - **CORRECT**: Regenerate after every spec change; both commands pass

3. **Missing an edition** (-500 points)
   - A machine with only `docker:` or only `vm:` without a recorded reason (Windows, kernel
     features make a lab VM-only)
   - The two editions behaving differently (ports, data, evidence placement)
   - **CORRECT**: Every machine has `docker:` and `vm:`; both pass the same `checks:`

4. **Dockerfile Syntax Errors** (-500 points)
   - Using raw `<VirtualHost>` or `<Directory>` tags in RUN commands without escaping
   - Causing "unknown instruction" errors in Dockerfile
   - Using heredoc patterns (`RUN cat <<'EOF'`) that break Docker parsing
   - **CORRECT**: Use `COPY` for config files OR escape with `\n\` and quotes

5. **Port Mismatches** (-500 points)
   - Service not listening on the port declared in `services:`
   - Apache/Nginx only listening on 80
   - Env-driven host ports or hand-written port mappings
   - **CORRECT**: The service listens on its declared port on both editions; `publish:` uses the
     same number

6. **Using an `environment:` key or runtime settings** (-500 points)
   - Adding `environment:` to a machine (it does not exist in Isoloom)
   - Expecting settings other than declared `inputs` at runtime
   - **CORRECT**: Settings in Dockerfile `ENV` or app defaults (and the VM unit)

7. **Missing dependencies** (-500 points)
   - A machine querying another without listing it in `depends_on`
   - **CORRECT**: `depends_on: [database]` on the app machine

8. **Database machine from a bare image** (-500 points)
   - `docker: { image: mysql:8.0 }` for the database
   - **CORRECT**: `docker: { build: build/database }`, a Dockerfile that `COPY`s `init/` and the
     evidence scripts
