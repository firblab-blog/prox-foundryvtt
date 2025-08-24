# Output the VM's IP address once it's assigned
output "foundryvtt_vm_ip" {
  description = "IP address of the FoundryVTT VM"
  value       = proxmox_virtual_environment_vm.foundryvtt.ipv4_addresses[1][0]
}

# Output SSH private key for Ansible
output "foundryvtt_vm_private_key" {
  description = "Private SSH key for FoundryVTT VM"
  value       = tls_private_key.foundryvtt_vm_key.private_key_pem
  sensitive   = true
}

# Output VM password
output "foundryvtt_vm_password" {
  description = "Password for FoundryVTT VM user"
  value       = random_password.foundryvtt_vm_password.result
  sensitive   = true
}

# Output FoundryVTT access URL
output "foundryvtt_url" {
  description = "URL to access FoundryVTT"
  value       = "http://${proxmox_virtual_environment_vm.foundryvtt.ipv4_addresses[1][0]}:30000"
}