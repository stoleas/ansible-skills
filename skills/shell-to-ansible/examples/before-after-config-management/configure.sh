#!/bin/bash
# configure.sh - Configure application settings

set -e

APP_HOME=/opt/myapp
CONFIG_FILE=$APP_HOME/config/app.conf

# Create application user if not exists
if ! id -u appuser > /dev/null 2>&1; then
  useradd -r -s /sbin/nologin appuser
fi

# Create directory structure
mkdir -p $APP_HOME/{config,data,logs}
chown -R appuser:appuser $APP_HOME
chmod 750 $APP_HOME/data

# Configure application
cat > $CONFIG_FILE <<EOF
# Application Configuration
APP_ENV=production
APP_PORT=8080
APP_DB_HOST=localhost
APP_DB_PORT=5432
APP_LOG_LEVEL=info
APP_MAX_CONNECTIONS=50
EOF

chmod 640 $CONFIG_FILE

# Configure log rotation
cat > /etc/logrotate.d/myapp <<EOF
$APP_HOME/logs/*.log {
  daily
  rotate 7
  compress
  delaycompress
  missingok
  notifempty
  create 0640 appuser appuser
}
EOF

# Add systemd service
cat > /etc/systemd/system/myapp.service <<EOF
[Unit]
Description=My Application
After=network.target postgresql.service

[Service]
Type=simple
User=appuser
Group=appuser
WorkingDirectory=$APP_HOME
EnvironmentFile=$CONFIG_FILE
ExecStart=$APP_HOME/bin/myapp
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd and enable service
systemctl daemon-reload
systemctl enable myapp
systemctl start myapp

echo "Configuration complete"
