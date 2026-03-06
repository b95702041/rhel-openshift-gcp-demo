# Walkthrough: RHEL & OpenShift Demo on GCP

Complete step-by-step guide for setting up and demonstrating the entire project.

## Table of Contents

1. [Prerequisites Setup](#1-prerequisites-setup)
2. [Deploy Infrastructure with Terraform](#2-deploy-infrastructure-with-terraform)
3. [RHEL Administration Labs (VM1)](#3-rhel-administration-labs-vm1)
4. [Set Up OpenShift CRC (VM2)](#4-set-up-openshift-crc-vm2)
5. [Deploy Demo Application](#5-deploy-demo-application)
6. [Set Up CI/CD Pipeline with Tekton](#6-set-up-cicd-pipeline-with-tekton)
7. [Configure Monitoring](#7-configure-monitoring)
8. [Cleanup](#8-cleanup)

---

## 1. Prerequisites Setup

### 1.1 Install Google Cloud SDK

```bash
# macOS
brew install google-cloud-sdk

# Windows - download installer from:
# https://cloud.google.com/sdk/docs/install

# Linux
curl https://sdk.cloud.google.com | bash
```

### 1.2 Install Terraform

```bash
# macOS
brew install terraform

# Windows - download from:
# https://developer.hashicorp.com/terraform/install

# Verify
terraform --version
```

### 1.3 Authenticate with GCP

```bash
gcloud auth login
gcloud auth application-default login

# Create a new project (or use existing)
gcloud projects create rhel-ocp-demo --name="RHEL OpenShift Demo"
gcloud config set project rhel-ocp-demo

# Enable required APIs
gcloud services enable compute.googleapis.com
```

### 1.4 Get Red Hat Pull Secret

1. Go to https://console.redhat.com/openshift/create/local
2. Create a free Red Hat account if needed
3. Download the pull secret (save as `pull-secret.json`)
4. **Do NOT commit this file to git**

---

## 2. Deploy Infrastructure with Terraform

```bash
cd terraform

# Create your tfvars
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your project ID

# Initialize and deploy
terraform init
terraform plan
terraform apply
```

Expected output:
```
Apply complete! Resources: 6 added, 0 changed, 0 destroyed.

Outputs:
rhel_admin_external_ip = "34.xx.xx.xx"
openshift_crc_external_ip = "35.xx.xx.xx"
ssh_rhel = "gcloud compute ssh rhel-admin-vm --zone=asia-east1-b"
ssh_crc  = "gcloud compute ssh openshift-crc-vm --zone=asia-east1-b"
```

Wait ~3 minutes for cloud-init scripts to finish, then SSH in:

```bash
# Check cloud-init status
gcloud compute ssh rhel-admin-vm --zone=asia-east1-b -- 'cloud-init status --wait'
gcloud compute ssh openshift-crc-vm --zone=asia-east1-b -- 'cloud-init status --wait'
```

---

## 3. RHEL Administration Labs (VM1)

SSH into the RHEL admin VM:

```bash
gcloud compute ssh rhel-admin-vm --zone=asia-east1-b
```

### Run the labs in order:

```bash
# Copy lab scripts to VM (or clone repo)
git clone https://github.com/<your-username>/rhel-openshift-gcp-demo.git
cd rhel-openshift-gcp-demo/rhel-labs

# Lab 01: User & Group Management
chmod +x lab01-user-mgmt.sh
sudo bash lab01-user-mgmt.sh

# Lab 02: Firewalld
sudo bash lab02-firewalld.sh

# Lab 03: SELinux
sudo bash lab03-selinux.sh

# Lab 04: Systemd Services
sudo bash lab04-systemd.sh

# Lab 05: Troubleshooting
sudo bash lab05-troubleshoot.sh
```

### Key things to demonstrate in interview:

- Show `id alice` and explain user/group structure
- Show `firewall-cmd --list-all` and explain zones
- Show `getenforce` and explain SELinux modes
- Show `journalctl -u demo-healthcheck -f` for live log tailing
- Fix the broken service in Lab 05 and explain your thought process

---

## 4. Set Up OpenShift CRC (VM2)

SSH into the CRC VM:

```bash
gcloud compute ssh openshift-crc-vm --zone=asia-east1-b
```

### 4.1 Run CRC Setup

```bash
# Run the setup helper
setup-crc.sh
```

When prompted, paste your pull secret from step 1.4.

CRC setup takes about 15-20 minutes. Once done:

```bash
# Verify cluster is running
crc status

# Set up oc CLI
eval $(crc oc-env)

# Login as developer
oc login -u developer -p developer https://api.crc.testing:6443

# Verify
oc whoami
oc get nodes
```

### 4.2 Access OpenShift Web Console

CRC runs locally on the VM, so you need an SSH tunnel to access the console:

```bash
# From your LOCAL machine (not the VM), set up SSH tunnel:
gcloud compute ssh openshift-crc-vm --zone=asia-east1-b -- -L 8443:api.crc.testing:6443 -L 443:console-openshift-console.apps-crc.testing:443

# Then add to your local /etc/hosts (or C:\Windows\System32\drivers\etc\hosts):
# 127.0.0.1 console-openshift-console.apps-crc.testing
# 127.0.0.1 oauth-openshift.apps-crc.testing
# 127.0.0.1 api.crc.testing
```

Open browser: https://console-openshift-console.apps-crc.testing

---

## 5. Deploy Demo Application

On the CRC VM:

```bash
# Clone repo if not already done
git clone https://github.com/<your-username>/rhel-openshift-gcp-demo.git
cd rhel-openshift-gcp-demo

# Create project
oc new-project demo-app

# Create BuildConfig and ImageStream
oc apply -f openshift/buildconfig.yaml

# Start the build using local source
oc start-build demo-api --from-dir=./app --wait --follow

# Deploy the application
oc apply -f openshift/deployment.yaml
oc apply -f openshift/service.yaml
oc apply -f openshift/route.yaml

# Wait for rollout
oc rollout status deployment/demo-api

# Get the route URL
oc get route demo-api
```

### Verify the app:

```bash
ROUTE=$(oc get route demo-api -o jsonpath='{.spec.host}')

# Test endpoints
curl -k https://${ROUTE}/
curl -k https://${ROUTE}/health
curl -k https://${ROUTE}/info
curl -k https://${ROUTE}/metrics
```

---

## 6. Set Up CI/CD Pipeline with Tekton

### 6.1 Install Tekton (if not already on CRC)

```bash
# Login as admin
oc login -u kubeadmin -p $(crc console --credentials 2>/dev/null | grep kubeadmin | awk -F"'" '{print $2}') https://api.crc.testing:6443

# Install Tekton Pipelines operator
# In CRC, use the OperatorHub in web console:
# Operators -> OperatorHub -> Search "OpenShift Pipelines" -> Install

# Or via CLI:
oc apply -f https://raw.githubusercontent.com/tektoncd/pipeline/main/docs/install/00-crds.yaml 2>/dev/null || echo "Using built-in pipelines operator"

# Switch back to developer
oc login -u developer -p developer https://api.crc.testing:6443
oc project demo-app
```

### 6.2 Create Pipeline Resources

```bash
cd rhel-openshift-gcp-demo

# Apply Tekton tasks
oc apply -f openshift/pipeline/task-build.yaml
oc apply -f openshift/pipeline/task-deploy.yaml

# Apply pipeline
oc apply -f openshift/pipeline/pipeline.yaml

# Verify
oc get tasks
oc get pipelines
```

### 6.3 Run the Pipeline

```bash
# Trigger a pipeline run
oc create -f openshift/pipeline/pipelinerun.yaml

# Watch progress
tkn pipelinerun logs -f --last

# Or with oc
oc get pipelinerun
oc logs -f $(oc get pipelinerun -o jsonpath='{.items[-1].metadata.name}') 2>/dev/null || echo "Check pipeline status with: oc get pipelinerun"
```

---

## 7. Configure Monitoring

### 7.1 Enable User Workload Monitoring

```bash
# Login as admin
oc login -u kubeadmin -p $(crc console --credentials 2>/dev/null | grep kubeadmin | awk -F"'" '{print $2}') https://api.crc.testing:6443

# Enable user workload monitoring
cat << 'EOF' | oc apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: cluster-monitoring-config
  namespace: openshift-monitoring
data:
  config.yaml: |
    enableUserWorkload: true
EOF

# Wait for monitoring stack
oc -n openshift-user-workload-monitoring get pods -w
```

### 7.2 Deploy ServiceMonitor

```bash
oc login -u developer -p developer https://api.crc.testing:6443
oc project demo-app

# Apply ServiceMonitor
oc apply -f monitoring/servicemonitor.yaml

# Verify Prometheus is scraping
oc -n openshift-user-workload-monitoring exec -it $(oc -n openshift-user-workload-monitoring get pod -l app.kubernetes.io/name=prometheus -o name | head -1) -- curl -s 'localhost:9090/api/v1/targets' | jq '.data.activeTargets[] | select(.labels.app=="demo-api")'
```

### 7.3 Import Grafana Dashboard

The Grafana dashboard JSON is in `monitoring/grafana-dashboard.json`.

In the OpenShift web console:
1. Navigate to **Observe -> Dashboards**
2. Or access Grafana directly if installed
3. Import the JSON dashboard file

---

## 8. Cleanup

**Always destroy resources when done practicing!**

```bash
# From your local machine
cd terraform
terraform destroy

# Type 'yes' to confirm
```