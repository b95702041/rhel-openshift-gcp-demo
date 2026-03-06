#!/bin/bash
# =============================================================
# Lab 03: SELinux Management on RHEL
# =============================================================
# Skills demonstrated:
#   - Checking SELinux status and modes
#   - Viewing and changing file contexts
#   - Troubleshooting SELinux denials with audit log
#   - Managing SELinux booleans
#
# Run on: VM1 (rhel-admin-vm)
# =============================================================

set -euo pipefail

echo "============================================"
echo "  Lab 03: SELinux Management"
echo "============================================"
echo ""

# --- Exercise 1: Check SELinux status ---
echo "[Exercise 1] SELinux status..."
echo "  Mode: $(getenforce)"
echo "  Full status:"
sestatus
echo ""

# --- Exercise 2: View file contexts ---
echo "[Exercise 2] File contexts..."
echo "  Context of /var/www (if exists):"
ls -Z /var/www/ 2>/dev/null || echo "  /var/www does not exist, creating for demo..."
sudo mkdir -p /var/www/html
echo "Hello SELinux Demo" | sudo tee /var/www/html/index.html > /dev/null
ls -Z /var/www/html/
echo ""

# --- Exercise 3: Change file context ---
echo "[Exercise 3] Changing file context..."
sudo mkdir -p /opt/demo-web
echo "Demo content" | sudo tee /opt/demo-web/index.html > /dev/null
echo "  Before (wrong context):"
ls -Z /opt/demo-web/
echo ""
echo "  Applying httpd_sys_content_t context..."
sudo semanage fcontext -a -t httpd_sys_content_t "/opt/demo-web(/.*)?" 2>/dev/null || true
sudo restorecon -Rv /opt/demo-web/
echo "  After (correct context):"
ls -Z /opt/demo-web/
echo ""

# --- Exercise 4: SELinux booleans ---
echo "[Exercise 4] SELinux booleans..."
echo "  HTTP-related booleans:"
sudo getsebool -a | grep httpd | head -10
echo ""
echo "  Enabling httpd_can_network_connect..."
sudo setsebool -P httpd_can_network_connect on
echo "  httpd_can_network_connect = $(getsebool httpd_can_network_connect)"
echo ""

# --- Exercise 5: Check audit log for denials ---
echo "[Exercise 5] Recent SELinux denials..."
echo "  Last 5 AVC denials (if any):"
sudo ausearch -m avc --start recent 2>/dev/null | tail -20 || echo "  No recent denials found (good!)"
echo ""

echo "============================================"
echo "  Lab 03 Complete!"
echo ""
echo "  Try these commands to explore:"
echo "    getenforce"
echo "    sestatus"
echo "    ls -Z /var/www/html/"
echo "    sudo ausearch -m avc --start today"
echo "    sudo getsebool -a | grep httpd"
echo "============================================"
