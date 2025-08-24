# Cloud-init configuration for FoundryVTT
resource "proxmox_virtual_environment_file" "foundryvtt_cloud_config" {
  content_type = "snippets"
  datastore_id = "local"
  node_name    = var.proxmox_node

  source_raw {
    data = templatefile("${path.module}/files/foundryvtt-user-data.yaml", {
      hostname = "foundryvtt"
      ssh_key  = trimspace(tls_private_key.foundryvtt_vm_key.public_key_openssh)
    })
    file_name = "foundryvtt-user-data.yaml"
  }
}

# FoundryVTT VM
resource "proxmox_virtual_environment_vm" "foundryvtt" {
  name        = "foundryvtt"
  description = "FoundryVTT Game Server - Managed by Terraform"
  tags        = ["terraform", "foundryvtt", "gameserver"]

  node_name = var.proxmox_node
  vm_id     = var.foundryvtt_vm_id

  depends_on = [
    proxmox_virtual_environment_file.foundryvtt_cloud_config
  ]

  agent {
    enabled = true
  }
  stop_on_destroy = true

  startup {
    order      = "3"
    up_delay   = "60"
    down_delay = "30"
  }

  cpu {
    cores = var.foundryvtt_cpu_cores
    type  = "x86-64-v2-AES"
  }

  memory {
    dedicated = var.foundryvtt_memory
    floating  = var.foundryvtt_memory
  }

  # Main system disk - reference existing image by name
  disk {
    datastore_id = "vmdata"
    file_id      = "local:import/noble-server-cloudimg-amd64.qcow2"
    interface    = "scsi0"
    size         = var.foundryvtt_disk_size
  }

  # Additional disk for FoundryVTT data and worlds
  disk {
    datastore_id = "hdd-storage"
    interface    = "scsi1"
    size         = var.foundryvtt_data_disk_size
  }

  initialization {
    ip_config {
      ipv4 {
        address = var.foundryvtt_static_ip != "" ? "${var.foundryvtt_static_ip}/${var.network_cidr}" : "dhcp"
        gateway = var.foundryvtt_static_ip != "" ? var.network_gateway : null
      }
    }

    dns {
      servers = var.dns_servers
    }

    user_account {
      keys     = [trimspace(tls_private_key.foundryvtt_vm_key.public_key_openssh)]
      password = random_password.foundryvtt_vm_password.result
      username = var.foundryvtt_username
    }

    user_data_file_id = proxmox_virtual_environment_file.foundryvtt_cloud_config.id
  }

  network_device {
    bridge = var.network_bridge
  }

  operating_system {
    type = "l26"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Generate secure password for VM
resource "random_password" "foundryvtt_vm_password" {
  length           = 16
  override_special = "_%@"
  special          = true
}

# Generate SSH key pair for VM access
resource "tls_private_key" "foundryvtt_vm_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}
