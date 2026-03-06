variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "asia-east1"
}

variable "zone" {
  description = "GCP zone"
  type        = string
  default     = "asia-east1-b"
}

variable "rhel_machine_type" {
  description = "Machine type for RHEL admin VM"
  type        = string
  default     = "e2-medium"
}

variable "crc_machine_type" {
  description = "Machine type for CRC VM (needs 8 vCPU / 32GB RAM + nested virtualization, must be N1/N2/C2 series)"
  type        = string
  default     = "n2-standard-8"
}
