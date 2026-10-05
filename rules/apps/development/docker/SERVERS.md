# Apache and Nginx Port Configuration

Ensure web server listens on assigned internal port; align Listen/VirtualHost with the port declared in isoloom.yml.

## Critical Rule: Service Must Listen on Assigned Port

- **The port declared in `isoloom.yml` `services:` must match the listen port** (Isoloom's health check connects to it)
- **Apache**: Must explicitly listen on the configured port (not just 80)
- **Configuration required**: Add `Listen` directive and VirtualHost configuration

## Apache Configuration for Custom Ports

### INCORRECT - Apache Only Listens on Port 80
```dockerfile
RUN a2enmod rewrite
EXPOSE 3206
CMD ["apache2-foreground"]
#  Apache will only listen on port 80, the machine never becomes healthy
```

### CORRECT - Configure Apache to Listen on Custom Port
```dockerfile
# Install required packages
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    make \
    libmariadb-dev \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install PHP extensions
RUN docker-php-ext-install mysqli pdo_mysql

# Configure Apache
RUN a2enmod rewrite
RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf

#  CRITICAL: Configure Apache to listen on port 3206
RUN sed -i 's/Listen 80/Listen 80\nListen 3206/' /etc/apache2/ports.conf

# Create custom VirtualHost for port 3206
# CRITICAL: Use escaped newlines (\n\) to prevent Docker parse errors
# See DOCKERFILE-SYNTAX.md for details on why raw <VirtualHost> causes "unknown instruction" errors
RUN echo "<VirtualHost *:3206>\n\
    DocumentRoot /var/www/html\n\
    <Directory /var/www/html>\n\
        AllowOverride All\n\
        Require all granted\n\
    </Directory>\n\
</VirtualHost>" > /etc/apache2/sites-available/000-default.conf

EXPOSE 3206
CMD ["apache2-foreground"]
```

## Port Configuration Checklist

- [ ] Apache `Listen` directive includes the custom port
- [ ] VirtualHost configuration binds to the custom port
- [ ] The `services:` port in `isoloom.yml` matches the listen port
- [ ] The VM step (`provision/<machine>.sh`) configures the same port
- [ ] PHP configuration listens on the correct port

## Apache .htaccess Requirement

For Apache-based labs, ensure a `.htaccess` file exists at the web root and matches the lab's routing needs. At minimum, include a safe fallback to `index.php` for non-existent files and directories:

```apache
RewriteEngine On
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule ^ index.php [QSA,L]
```

Notes
- Adapt additional rewrite rules to the specific vulnerability only when required by the scenario.
- Keep rules minimal and compatible with the black-only UI (no impact on Tailwind CDN loading).
