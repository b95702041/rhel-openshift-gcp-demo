#!/bin/bash
# =============================================================
# Lab 01: User & Group Management on RHEL
# =============================================================
# Skills demonstrated:
#   - Creating users and groups
#   - Setting passwords and password policies
#   - Managing sudo access
#   - Checking user info
#
# Run on: VM1 (rhel-admin-vm)
# =============================================================

set -euo pipefail

echo "============================================"
echo "  Lab 01: User & Group Management"
echo "============================================"
echo ""

# --- Exercise 1: Create a group ---
echo "[Exercise 1] Creating 'devops' group..."
sudo groupadd devops 2>/dev/null || echo "  Group 'devops' already exists"
getent group devops
echo ""

# --- Exercise 2: Create users ---
echo "[Exercise 2] Creating users..."
for user in alice bob charlie; do
  sudo useradd -m -G devops -s /bin/bash "$user" 2>/dev/null || echo "  User '$user' already exists"
  echo "${user}:DemoPass123!" | sudo chpasswd
  echo "  Created user: $user (password: DemoPass123!)"
done
echo ""

# --- Exercise 3: Verify users ---
echo "[Exercise 3] Verifying users..."
echo "  Members of 'devops' group:"
getent group devops
echo ""
echo "  User details for 'alice':"
id alice
echo ""

# --- Exercise 4: Configure sudo access ---
echo "[Exercise 4] Granting sudo to 'devops' group..."
echo '%devops ALL=(ALL) NOPASSWD: ALL' | sudo tee /etc/sudoers.d/devops > /dev/null
sudo chmod 440 /etc/sudoers.d/devops
echo "  /etc/sudoers.d/devops created"
echo ""

# --- Exercise 5: Password policy ---
echo "[Exercise 5] Setting password policy for 'alice'..."
sudo chage -M 90 -W 14 -m 7 alice
echo "  Password aging info for alice:"
sudo chage -l alice
echo ""

echo "============================================"
echo "  Lab 01 Complete!"
echo ""
echo "  Try these commands to explore:"
echo "    id alice"
echo "    groups bob"
echo "    sudo -l -U charlie"
echo "    cat /etc/passwd | grep devops"
echo "============================================"
