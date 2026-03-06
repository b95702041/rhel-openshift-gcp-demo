#!/bin/bash
# =============================================================
# Lab 04: Systemd Service Management on RHEL
# =============================================================
# Skills demonstrated:
#   - Managing services (start/stop/enable/disable)
#   - Viewing service status and logs
#   - Creating custom systemd units
#   - Analyzing boot and service dependencies
#
# Run on: VM1 (rhel-admin-vm)
# =============================================================

set -euo pipefail

echo "============================================"
echo "  Lab 04: Systemd Service Management"
echo "============================================"
echo ""

# --- Exercise 1: Service status ---
echo "[Exercise 1] Checking service status..."
echo "  Listing active services:"
systemctl list-units --type=service --state=running --no-pager | head -15
echo "  ..."
echo ""

# --- Exercise 2: Manage the demo-healthcheck service ---
echo "[Exercise 2] Managing demo-healthcheck service..."
echo "  Status:"
sudo systemctl status demo-healthcheck --no-pager -l
echo ""
echo "  Stopping service..."
sudo systemctl stop demo-healthcheck
echo "  Status after stop: $(systemctl is-active demo-healthcheck)"
echo ""
echo "  Starting service..."
sudo systemctl start demo-healthcheck
echo "  Status after start: $(systemctl is-active demo-healthcheck)"
echo ""

# --- Exercise 3: View logs with journalctl ---
echo "[Exercise 3] Viewing service logs..."
echo "  Last 10 log entries for demo-healthcheck:"
sudo journalctl -u demo-healthcheck --no-pager -n 10
echo ""
echo "  Logs since last boot:"
sudo journalctl -u demo-healthcheck -b --no-pager | tail -5
echo ""

# --- Exercise 4: Create a new custom service ---
echo "[Exercise 4] Creating a custom timer + service..."

# Create a one-shot service
sudo cat > /etc/systemd/system/disk-report.service << 'EOF'
[Unit]
Description=Disk Usage Report Generator

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'echo "$(date): $(df -h / | tail -1)" >> /var/log/disk-report.log'
EOF

# Create a timer to run it every 5 minutes
sudo cat > /etc/systemd/system/disk-report.timer << 'EOF'
[Unit]
Description=Run Disk Report every 5 minutes

[Timer]
OnBootSec=1min
OnUnitActiveSec=5min
AccuracySec=1s

[Install]
WantedBy=timers.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now disk-report.timer
echo "  Timer status:"
systemctl list-timers disk-report.timer --no-pager
echo ""

# --- Exercise 5: Analyze boot ---
echo "[Exercise 5] Boot analysis..."
echo "  Boot time breakdown:"
systemd-analyze
echo ""
echo "  Slowest services to start:"
systemd-analyze blame --no-pager | head -10
echo ""

echo "============================================"
echo "  Lab 04 Complete!"
echo ""
echo "  Try these commands to explore:"
echo "    systemctl status demo-healthcheck"
echo "    journalctl -u demo-healthcheck -f    (follow live)"
echo "    systemctl list-timers"
echo "    systemd-analyze critical-chain"
echo "============================================"
