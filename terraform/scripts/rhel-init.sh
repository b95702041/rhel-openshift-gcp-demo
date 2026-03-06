#!/bin/bash
# cloud-init script for RHEL Admin VM
# This script sets up a RHEL environment for system administration exercises

set -uo pipefail
exec > /var/log/rhel-init.log 2>&1

echo "=========================================="
echo "RHEL Admin VM initialization starting..."
echo "=========================================="

# ------------------------------------------
# 1. System update
# ------------------------------------------
echo "[1/6] Updating system packages..."
dnf update -y

# ------------------------------------------
# 2. Enable EPEL repository (needed for htop and other tools)
# ------------------------------------------
echo "[2/6] Enabling EPEL repository..."
dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm || true

# ------------------------------------------
# 3. Install essential admin tools
# ------------------------------------------
echo "[3/6] Installing admin tools..."
dnf install -y \
  vim \
  tmux \
  htop \
  net-tools \
  bind-utils \
  tcpdump \
  strace \
  lsof \
  wget \
  curl \
  git \
  jq \
  podman \
  bash-completion

# ------------------------------------------
# 3. Enable and configure firewalld
# ------------------------------------------
echo "[4/6] Configuring firewalld..."
systemctl enable --now firewalld
firewall-cmd --permanent --add-service=ssh
firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --add-service=https
firewall-cmd --reload

# ------------------------------------------
# 4. Ensure SELinux is enforcing
# ------------------------------------------
echo "[5/6] Verifying SELinux..."
setenforce 1 || true
sed -i 's/^SELINUX=.*/SELINUX=enforcing/' /etc/selinux/config

# ------------------------------------------
# 5. Create a practice service for systemd lab
# ------------------------------------------
echo "[6/6] Creating practice systemd service..."

cat > /usr/local/bin/demo-healthcheck.sh << 'SCRIPT'
#!/bin/bash
while true; do
  echo "$(date '+%Y-%m-%d %H:%M:%S') - Health check OK" >> /var/log/demo-healthcheck.log
  sleep 30
done
SCRIPT
chmod +x /usr/local/bin/demo-healthcheck.sh

cat > /etc/systemd/system/demo-healthcheck.service << 'UNIT'
[Unit]
Description=Demo Health Check Service
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/demo-healthcheck.sh
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
UNIT

systemctl daemon-reload
systemctl enable --now demo-healthcheck.service

echo "=========================================="
echo "RHEL Admin VM initialization complete!"
echo "=========================================="
