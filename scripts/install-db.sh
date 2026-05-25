#!/bin/bash

set -euo pipefail

LOG_FILE="/var/log/db-setup.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "[$(date)] Starting PostgreSQL setup..."

apt-get update -y
apt-get install -y postgresql postgresql-contrib

systemctl enable postgresql
systemctl start postgresql

echo "[$(date)] Configuring database and user..."

sudo -u postgres psql <<EOF
DO \$\$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '${db_user}') THEN
    CREATE ROLE ${db_user} WITH LOGIN PASSWORD '${db_password_sql_safe}';
  END IF;
END
\$\$;

SELECT 'CREATE DATABASE ${db_name} OWNER ${db_user}'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '${db_name}')
\gexec

GRANT ALL PRIVILEGES ON DATABASE ${db_name} TO ${db_user};
EOF

PG_VERSION=$(pg_lsclusters -h | awk '{print $1}' | head -1)
PG_CONF="/etc/postgresql/$PG_VERSION/main/postgresql.conf"
PG_HBA="/etc/postgresql/$PG_VERSION/main/pg_hba.conf"

sed -i "s/^#*listen_addresses\s*=.*/listen_addresses = '*'/" "$PG_CONF"

cat >> "$PG_HBA" <<EOF
host    ${db_name}    ${db_user}    ${app_subnet_cidr}    scram-sha-256
EOF

systemctl restart postgresql

echo "[$(date)] PostgreSQL setup complete."
echo "[$(date)]   DB:   ${db_name}"
echo "[$(date)]   User: ${db_user}"
echo "[$(date)]   Access allowed from: ${app_subnet_cidr}"