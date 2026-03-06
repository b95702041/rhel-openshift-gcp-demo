output "rhel_admin_external_ip" {
  description = "External IP of RHEL admin VM"
  value       = google_compute_instance.rhel_admin.network_interface[0].access_config[0].nat_ip
}

output "openshift_crc_external_ip" {
  description = "External IP of OpenShift CRC VM"
  value       = google_compute_instance.openshift_crc.network_interface[0].access_config[0].nat_ip
}

output "ssh_rhel" {
  description = "SSH command for RHEL VM"
  value       = "gcloud compute ssh rhel-admin-vm --zone=${var.zone}"
}

output "ssh_crc" {
  description = "SSH command for CRC VM"
  value       = "gcloud compute ssh openshift-crc-vm --zone=${var.zone}"
}
