#!/bin/bash
# cloud-init script for OpenShift CRC VM
# This script prepares the VM for CodeReady Containers installation
# CRC itself must be set up manually (requires interactive pull secret input)

set -euo pipefail
exec > /var/log/crc-init.log 2>&1

echo "=========================================="
echo "OpenShift CRC VM initialization starting..."
echo "=========================================="

# ------------------------------------------
# 1. System update
# ------------------------------------------
echo "[1/6] Updating system packages..."
dnf update -y

# ------------------------------------------
# 2. Install dependencies
# ------------------------------------------
echo "[2/6] Installing dependencies..."
dnf install -y \
  vim \
  tmux \
  git \
  jq \
  wget \
  curl \
  bash-completion \
  libvirt \
  qemu-kvm \
  NetworkManager

# ------------------------------------------
# 3. Enable libvirt for nested virtualization
# ------------------------------------------
echo "[3/6] Configuring libvirt..."
systemctl enable --now libvirtd

# ------------------------------------------
# 4. Download CRC binary
# ------------------------------------------
echo "[4/6] Downloading CRC..."
CRC_VERSION="2.43.0"
CRC_URL="https://developers.redhat.com/content-gateway/rest/mirror/pub/openshift-v4/clients/crc/${CRC_VERSION}/crc-linux-amd64.tar.xz"

cd /opt
wget -q "${CRC_URL}" -O crc.tar.xz || echo "NOTICE: CRC download requires Red Hat account. Download manually from https://console.redhat.com/openshift/create/local"

if [ -f crc.tar.xz ]; then
  tar xf crc.tar.xz
  ln -sf /opt/crc-linux-*-amd64/crc /usr/local/bin/crc
  rm -f crc.tar.xz
  echo "CRC binary installed at /usr/local/bin/crc"
else
  echo "CRC binary not downloaded. Manual installation needed."
fi

# ------------------------------------------
# 5. Create CRC setup helper script
# ------------------------------------------
echo "[5/6] Creating CRC setup helper..."

cat > /usr/local/bin/setup-crc.sh << 'SCRIPT'
#!/bin/bash
# Run this script manually after SSH into the VM
# You need a pull secret from https://console.redhat.com/openshift/create/local

set -euo pipefail

echo "============================================"
echo "  OpenShift CRC Setup Helper"
echo "============================================"
echo ""
echo "Prerequisites:"
echo "  1. Download CRC if not already present:"
echo "     https://console.redhat.com/openshift/create/local"
echo "  2. Get your pull secret from the same page"
echo ""

# Check if crc is available
if ! command -v crc &> /dev/null; then
  echo "ERROR: crc binary not found."
  echo "Download from: https://console.redhat.com/openshift/create/local"
  exit 1
fi

echo "Step 1: Setting up CRC prerequisites..."
crc setup

echo ""
echo "Step 2: Starting CRC cluster..."
echo "Paste your pull secret when prompted."
crc start

echo ""
echo "Step 3: Configuring oc CLI..."
eval $(crc oc-env)
echo 'eval $(crc oc-env)' >> ~/.bashrc

echo ""
echo "Step 4: Login as developer..."
oc login -u developer -p developer https://api.crc.testing:6443

echo ""
echo "============================================"
echo "  CRC is ready!"
echo "  Console: https://console-openshift-console.apps-crc.testing"
echo "  Username: developer / developer"
echo "  Admin:    kubeadmin / $(crc console --credentials | grep kubeadmin | awk '{print $NF}')"
echo "============================================"
SCRIPT
chmod +x /usr/local/bin/setup-crc.sh

# ------------------------------------------
# 6. Create post-CRC app deployment helper
# ------------------------------------------
echo "[6/6] Creating app deployment helper..."

cat > /usr/local/bin/deploy-demo-app.sh << 'SCRIPT'
#!/bin/bash
# Run this AFTER CRC is started and oc is configured

set -euo pipefail

echo "Creating demo project..."
oc new-project demo-app || oc project demo-app

echo "Deploying demo Flask app..."
oc apply -f /home/$(whoami)/app/openshift/

echo "Waiting for deployment..."
oc rollout status deployment/demo-api -n demo-app --timeout=120s

echo ""
echo "App route:"
oc get route demo-api -n demo-app -o jsonpath='{.spec.host}'
echo ""
SCRIPT
chmod +x /usr/local/bin/deploy-demo-app.sh

echo "=========================================="
echo "OpenShift CRC VM initialization complete!"
echo ""
echo "NEXT STEPS:"
echo "  1. SSH into this VM"
echo "  2. Run: setup-crc.sh"
echo "  3. Paste your pull secret when prompted"
echo "  4. Run: deploy-demo-app.sh"
echo "=========================================="
