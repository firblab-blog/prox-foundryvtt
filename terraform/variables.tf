# Proxmox connection variables
variable "proxmox_node" {
  description = "Proxmox node name"
  type        = string
}

variable "network_bridge" {
  description = "Network bridge for VMs"
  type        = string
  default     = "vmbr0"
}

# FoundryVTT VM configuration
variable "foundryvtt_vm_id" {
  description = "VM ID for FoundryVTT"
  type        = number
  default     = 666
}

variable "foundryvtt_cpu_cores" {
  description = "Number of CPU cores for FoundryVTT VM"
  type        = number
  default     = 2
}

variable "foundryvtt_memory" {
  description = "Memory allocation for FoundryVTT VM (MB)"
  type        = number
  default     = 4096
}

variable "foundryvtt_disk_size" {
  description = "System disk size for FoundryVTT VM (GB)"
  type        = number
  default     = 40
}

variable "foundryvtt_data_disk_size" {
  description = "Data disk size for FoundryVTT data (GB)"
  type        = number
  default     = 50
}

variable "foundryvtt_username" {
  description = "Username for FoundryVTT VM"
  type        = string
  default     = "foundry"
}

# Network configuration
variable "foundryvtt_static_ip" {
  description = "Static IP for FoundryVTT VM (leave empty for DHCP)"
  type        = string
  default     = ""
}

variable "network_cidr" {
  description = "Network CIDR (e.g., 24 for /24)"
  type        = number
  default     = 24
}

variable "network_gateway" {
  description = "Network gateway IP"
  type        = string
  default     = "192.168.4.1"
}

variable "dns_servers" {
  description = "DNS servers for the VM"
  type        = list(string)
  default     = ["8.8.8.8", "8.8.4.4"]
}

variable "pm_api_url" {
  description = "Proxmox API URL"
  type        = string
}

variable "pm_user" {
  description = "Proxmox API user"
  type        = string
}

variable "pm_password" {
  description = "Proxmox API password"
  type        = string
  sensitive   = true
}
