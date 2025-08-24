provider "proxmox" {
  endpoint = var.pm_api_url
  username = var.pm_user
  password = var.pm_password
  
  # Skip TLS verification for self-signed certificates
  insecure = true
}

provider "random" {
  # No configuration needed
}

provider "tls" {
  # No configuration needed
}