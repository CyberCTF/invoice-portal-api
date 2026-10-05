# Settings and passwords

Settings syntax guardrails in Dockerfile ENV, systemd units and isoloom.yml; always quote special-char passwords.

Docker machines have no `environment:` key. Settings live in the Dockerfile (`ENV`) or in app
defaults. VMs set the same values in the systemd unit (`Environment=`) or a config file.

## Special characters in passwords

Quote every value that contains special characters (`#`, `@`, `$`, `%`, `!`, `&`, spaces).

### Dockerfile

```dockerfile
# INCORRECT: the shell and the parser split or expand it
ENV DB_PASS=FtgY#WCXnZT5@#c$x

# CORRECT
ENV MYSQL_ROOT_PASSWORD="root-pass-9f2c" \
    MYSQL_DATABASE=portal \
    MYSQL_USER=portal \
    DB_PASS="FtgY#WCXnZT5@#c:"
```

- `$` in a Dockerfile `ENV` value is expanded. Avoid `$` in lab passwords, or escape it (`\$`).

### systemd unit (VM)

```ini
Environment="DB_PASS=FtgY#WCXnZT5@#c:"
```

### Shell scripts

```sh
mysql -uroot -p"${MYSQL_ROOT_PASSWORD}" ...
```

## Rules

- Use the same values in the Dockerfile, the VM provision step, the init SQL and the app
  defaults. A mismatch is a connection failure on one edition only.
- `isoloom.yml` is YAML: quote strings that start with special characters.
