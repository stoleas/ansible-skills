#!/bin/bash
# install.sh - Install and configure PostgreSQL database

set -e

echo "Starting PostgreSQL installation..."

# Update package cache
if [ -f /etc/redhat-release ]; then
  yum update -y
  yum install -y postgresql-server postgresql-contrib
elif [ -f /etc/debian_version ]; then
  apt-get update
  apt-get install -y postgresql postgresql-contrib
else
  echo "Unsupported distribution"
  exit 1
fi

# Initialize database (only if not already initialized)
if [ ! -d /var/lib/pgsql/data/base ]; then
  postgresql-setup initdb
fi

# Configure PostgreSQL
cat > /var/lib/pgsql/data/postgresql.conf <<EOF
listen_addresses = '*'
port = 5432
max_connections = 100
shared_buffers = 256MB
EOF

# Configure authentication
cat > /var/lib/pgsql/data/pg_hba.conf <<EOF
local   all             postgres                                peer
host    all             all             127.0.0.1/32            md5
host    all             all             ::1/128                 md5
EOF

# Enable and start service
systemctl enable postgresql
systemctl start postgresql

# Configure firewall
firewall-cmd --permanent --add-service=postgresql
firewall-cmd --reload

echo "PostgreSQL installation complete"
