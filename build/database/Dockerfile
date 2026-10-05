# The portal's database: MySQL on 3207 with the invoices schema and seed rows.
FROM mysql:8.0
ENV MYSQL_ROOT_PASSWORD=root-pass-9f2c \
    MYSQL_DATABASE=portal \
    MYSQL_USER=portal \
    MYSQL_PASSWORD=portal-pass \
    MYSQL_TCP_PORT=3207
COPY init/ /docker-entrypoint-initdb.d/
COPY place-evidence.sh /opt/ctf/place-evidence.sh
COPY claim-evidence.sh /opt/ctf/claim-evidence.sh
