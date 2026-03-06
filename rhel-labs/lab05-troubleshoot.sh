#!/bin/bash
# =============================================================
# Lab 05: Troubleshooting Scenarios on RHEL
# =============================================================
# Skills demonstrated:
#   - Diagnosing service failures
#   - Network troubleshooting
#   - Disk and performance issues
#   - Log analysis
#
# Run on: VM1 (rhel-admin-vm)
# =============================================================

set -euo pipefail

echo "============================================"
echo "  Lab 05: Troubleshooting Scenarios"
echo "============================================"
echo ""

# --- Scenario 1: Diagnose a broken service ---
echo "[Scenario 1] Creating a broken service to diagnose..."

sudo cat > /etc/systemd/system/broken-app.service << 'EOF'
[Unit]
Description=Intentionally Broken App

[Service]
Type=simple
ExecStart=/usr/local/bin/broken-app.sh
Restart=on-failure
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

# Create the script with a deliberate error (wrong shebang path)
sudo cat > /usr/local/bin/broken-app.sh << 'EOF'
#!/usr/bin/bosh
echo "This will fail because /usr/bin/bosh does not exist"
EOF
sudo chmod +x /usr/local/bin/broken-app.sh

sudo systemctl daemon-reload
sudo systemctl start broken-app.service 2>/dev/null || true

echo "  The service 'broken-app' has failed. Diagnose it!"
echo ""
echo "  Hint commands:"
echo "    sudo systemctl status broken-app"
echo "    sudo journalctl -u broken-app --no-pager"
echo "    cat /usr/local/bin/broken-app.sh"
echo "    file /usr/local/bin/broken-app.sh"
echo ""
echo "  Fix: change #!/usr/bin/bosh to #!/bin/bash"
echo ""

# --- Scenario 2: Network diagnostics ---
echo "[Scenario 2] Network diagnostic commands..."
echo ""
echo "  Hostname:        $(hostname)"
echo "  IP addresses:"
ip -4 addr show | grep inet | grep -v 127.0.0.1
echo ""
echo "  Routing table:"
ip route
echo ""
echo "  DNS resolution test:"
dig google.com +short 2>/dev/null || nslookup google.com 2>/dev/null | tail -2
echo ""
echo "  Open ports:"
sudo ss -tlnp | head -15
echo ""

# --- Scenario 3: Disk usage analysis ---
echo "[Scenario 3] Disk usage analysis..."
echo ""
echo "  Filesystem usage:"
df -h
echo ""
echo "  Top 10 largest directories in /var:"
sudo du -sh /var/*/ 2>/dev/null | sort -rh | head -10
echo ""
echo "  Inode usage:"
df -i / | head -5
echo ""

# --- Scenario 4: Process and performance ---
echo "[Scenario 4] Process and performance check..."
echo ""
echo "  System load:"
uptime
echo ""
echo "  Memory usage:"
free -h
echo ""
echo "  Top 5 CPU-consuming processes:"
ps aux --sort=-%cpu | head -6
echo ""
echo "  Top 5 memory-consuming processes:"
ps aux --sort=-%mem | head -6
echo ""

# --- Scenario 5: Log investigation ---
echo "[Scenario 5] Log investigation..."
echo ""
echo "  Recent error/warning messages in system journal:"
sudo journalctl -p err --since "1 hour ago" --no-pager | tail -20
echo ""
echo "  Failed systemd units:"
systemctl --failed --no-pager
echo ""

echo "============================================"
echo "  Lab 05 Complete!"
echo ""
echo "  Additional troubleshooting tools to try:"
echo "    top / htop          - real-time process monitoring"
echo "    iostat              - I/O statistics"
echo "    vmstat 1 5          - virtual memory stats"
echo "    strace -p <PID>     - trace system calls"
echo "    tcpdump -i eth0     - packet capture"
echo "    sudo dmesg | tail   - kernel messages"
echo "============================================"
