# RHEL & OpenShift Demo on GCP

A hands-on demo project showcasing Red Hat Enterprise Linux (RHEL) system administration and Red Hat OpenShift container platform skills, deployed on Google Cloud Platform using Terraform.

## Architecture Overview

```
┌─────────────────────────────────────────────────┐
│                  GCP Project                     │
│                                                  │
│  ┌──────────────────┐  ┌──────────────────────┐  │
│  │  VM1: RHEL Admin │  │  VM2: OpenShift CRC  │  │
│  │  (e2-medium)     │  │  (e2-standard-8)     │  │
│  │                  │  │                       │  │
│  │  - User Mgmt     │  │  - Demo Flask App     │  │
│  │  - Firewalld     │  │  - Tekton CI/CD       │  │
│  │  - SELinux       │  │  - Prometheus/Grafana  │  │
│  │  - Systemd       │  │  - Routes & Services  │  │
│  │  - Journalctl    │  │                       │  │
│  └──────────────────┘  └──────────────────────┘  │
│                                                  │
│  Managed by Terraform + cloud-init               │
└─────────────────────────────────────────────────┘
```

## Skills Demonstrated

| Area | Tools & Topics |
|------|---------------|
| **RHEL Administration** | User management, firewalld, SELinux, systemd, journalctl, troubleshooting |
| **OpenShift / Containers** | CRC deployment, Pods, Deployments, Services, Routes |
| **CI/CD** | Tekton Pipelines, BuildConfig, automated testing & deployment |
| **Monitoring** | Prometheus metrics, Grafana dashboards, alerting |
| **IaC** | Terraform on GCP, cloud-init provisioning |

## Prerequisites

- [Google Cloud SDK](https://cloud.google.com/sdk/docs/install) (`gcloud`)
- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.5
- A GCP account with billing enabled (free $300 trial works)
- A [Red Hat account](https://console.redhat.com/) (free) for CRC pull secret

## Quick Start

```bash
# 1. Clone this repo
git clone https://github.com/<your-username>/rhel-openshift-gcp-demo.git
cd rhel-openshift-gcp-demo

# 2. Authenticate with GCP
gcloud auth login
gcloud auth application-default login

# 3. Set your GCP project
export TF_VAR_project_id="your-gcp-project-id"

# 4. Deploy infrastructure
cd terraform
terraform init
terraform plan
terraform apply

# 5. SSH into VMs
gcloud compute ssh rhel-admin-vm --zone=asia-east1-b
gcloud compute ssh openshift-crc-vm --zone=asia-east1-b
```

> **Cost Tip**: Each practice session (~2-3 hours) costs about $0.60-0.90.
> Always run `terraform destroy` when done to avoid unnecessary charges.

## Project Structure

```
openshift-demo/
├── README.md
├── .gitignore
├── terraform/              # GCP infrastructure (Terraform)
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── scripts/
│       ├── rhel-init.sh    # cloud-init for RHEL VM
│       └── crc-init.sh     # cloud-init for CRC VM
├── app/                    # Demo application
│   ├── main.py
│   ├── requirements.txt
│   └── Dockerfile
├── openshift/              # OpenShift manifests
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── route.yaml
│   └── pipeline/
│       ├── pipeline.yaml
│       ├── task-build.yaml
│       └── pipelinerun.yaml
├── monitoring/             # Observability stack
│   ├── servicemonitor.yaml
│   └── grafana-dashboard.json
├── rhel-labs/              # RHEL troubleshooting exercises
│   ├── lab01-user-mgmt.sh
│   ├── lab02-firewalld.sh
│   ├── lab03-selinux.sh
│   ├── lab04-systemd.sh
│   └── lab05-troubleshoot.sh
└── docs/
    └── WALKTHROUGH.md      # Step-by-step interview demo guide
```

## Walkthrough

See [docs/WALKTHROUGH.md](docs/WALKTHROUGH.md) for a complete step-by-step guide covering infrastructure setup, app deployment, CI/CD pipeline configuration, monitoring, and RHEL administration exercises.

## Cleanup

```bash
# Destroy all GCP resources when done
cd terraform
terraform destroy
```

## License

MIT