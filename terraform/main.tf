terraform {
  required_version = ">= 1.5"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

# ============================================================
# Network
# ============================================================

resource "google_compute_network" "demo_vpc" {
  name                    = "ocp-demo-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "demo_subnet" {
  name          = "ocp-demo-subnet"
  ip_cidr_range = "10.0.1.0/24"
  region        = var.region
  network       = google_compute_network.demo_vpc.id
}

# ============================================================
# Firewall Rules
# ============================================================

resource "google_compute_firewall" "allow_ssh" {
  name    = "ocp-demo-allow-ssh"
  network = google_compute_network.demo_vpc.id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["ocp-demo"]
}

resource "google_compute_firewall" "allow_http" {
  name    = "ocp-demo-allow-http"
  network = google_compute_network.demo_vpc.id

  allow {
    protocol = "tcp"
    ports    = ["80", "443", "8080", "8443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["ocp-demo"]
}

resource "google_compute_firewall" "allow_internal" {
  name    = "ocp-demo-allow-internal"
  network = google_compute_network.demo_vpc.id

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = ["10.0.1.0/24"]
  target_tags   = ["ocp-demo"]
}

# ============================================================
# VM1: RHEL Administration
# ============================================================

resource "google_compute_instance" "rhel_admin" {
  name         = "rhel-admin-vm"
  machine_type = var.rhel_machine_type
  zone         = var.zone
  tags         = ["ocp-demo"]

  boot_disk {
    initialize_params {
      image = "rhel-cloud/rhel-9"
      size  = 30
      type  = "pd-balanced"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.demo_subnet.id

    access_config {
      # Ephemeral public IP
    }
  }

  metadata_startup_script = file("${path.module}/scripts/rhel-init.sh")

  labels = {
    purpose = "rhel-admin-demo"
    project = "ocp-demo"
  }
}

# ============================================================
# VM2: OpenShift CRC
# ============================================================

resource "google_compute_instance" "openshift_crc" {
  name         = "openshift-crc-vm"
  machine_type = var.crc_machine_type
  zone         = var.zone
  tags         = ["ocp-demo"]

  boot_disk {
    initialize_params {
      image = "rhel-cloud/rhel-9"
      size  = 100
      type  = "pd-ssd"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.demo_subnet.id

    access_config {
      # Ephemeral public IP
    }
  }

  metadata_startup_script = file("${path.module}/scripts/crc-init.sh")

  # CRC needs nested virtualization (only N1/N2/C2 series support this, NOT E2)
  advanced_machine_features {
    enable_nested_virtualization = true
  }

  scheduling {
    # Required: Intel Cascade Lake or later for N2 series nested virtualization
    min_node_cpus = 0
  }

  min_cpu_platform = "Intel Cascade Lake"

  labels = {
    purpose = "openshift-crc-demo"
    project = "ocp-demo"
  }
}
