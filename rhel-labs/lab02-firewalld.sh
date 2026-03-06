#!/bin/bash
# =============================================================
# Lab 02: Firewalld Management on RHEL
# =============================================================
# Skills demonstrated:
#   - Viewing firewall status and zones
#   - Adding/removing services and ports
#   - Creating custom zones
#   - Rich rules
#
# Run on: VM1 (rhel-admin-vm)
# =============================================================

set -euo pipefail

echo "============================================"
echo "  Lab 02: Firewalld Management"
echo "============================================"
echo ""

# --- Exercise 1: Check status ---
echo "[Exercise 1] Firewall status..."
sudo systemctl status firewalld --no-pager -l
echo ""

# --- Exercise 2: List zones and active zone ---
echo "[Exercise 2] Listing zones..."
echo "  Active zones:"
sudo firewall-cmd --get-active-zones
echo ""
echo "  Default zone:"
sudo firewall-cmd --get-default-zone
echo ""

# --- Exercise 3: List current rules ---
echo "[Exercise 3] Current rules in default zone..."
sudo firewall-cmd --list-all
echo ""

# --- Exercise 4: Add a custom service port ---
echo "[Exercise 4] Adding port 8080/tcp (for demo app)..."
sudo firewall-cmd --permanent --add-port=8080/tcp
sudo firewall-cmd --reload
echo "  Open ports:"
sudo firewall-cmd --list-ports
echo ""

# --- Exercise 5: Create a custom zone ---
echo "[Exercise 5] Creating 'demo-zone'..."
sudo firewall-cmd --permanent --new-zone=demo-zone 2>/dev/null || echo "  Zone already exists"
sudo firewall-cmd --permanent --zone=demo-zone --add-service=http
sudo firewall-cmd --permanent --zone=demo-zone --add-service=https
sudo firewall-cmd --permanent --zone=demo-zone --add-port=8080/tcp
sudo firewall-cmd --reload
echo "  demo-zone rules:"
sudo firewall-cmd --zone=demo-zone --list-all
echo ""

# --- Exercise 6: Rich rules ---
echo "[Exercise 6] Adding a rich rule (rate limit SSH)..."
sudo firewall-cmd --permanent --add-rich-rule='rule service name="ssh" accept limit value="10/m"' 2>/dev/null || echo "  Rule already exists"
sudo firewall-cmd --reload
echo "  Rich rules:"
sudo firewall-cmd --list-rich-rules
echo ""

echo "============================================"
echo "  Lab 02 Complete!"
echo ""
echo "  Try these commands to explore:"
echo "    sudo firewall-cmd --list-all"
echo "    sudo firewall-cmd --get-zones"
echo "    sudo firewall-cmd --zone=demo-zone --list-all"
echo "    sudo firewall-cmd --list-rich-rules"
echo "============================================"
