# FoundryVTT on Proxmox with Terraform & Ansible

This project automates the deployment of a FoundryVTT server on Proxmox using Terraform for infrastructure provisioning and Ansible for application configuration.

## Overview

The project consists of two main components:
- **Terraform**: Provisions a Ubuntu VM on Proxmox with appropriate specifications for FoundryVTT
- **Ansible**: Configures the VM, installs Node.js, and sets up FoundryVTT as a systemd service

## Prerequisites

### Required Software
- Terraform >= 1.0
- Ansible >= 2.9
- SSH client
- Access to a Proxmox server

### Required Accounts/Downloads
- FoundryVTT license and download from [foundryvtt.com](https://foundryvtt.com/)
- Proxmox server with API access

## Project Structure

```
prox-foundryvtt/
├── terraform/              # Infrastructure as Code
│   ├── main.tf             # Main Terraform configuration
│   ├── variables.tf        # Variable definitions
│   ├── outputs.tf          # Output definitions
│   ├── providers.tf        # Provider configurations
│   ├── foundryvtt.tf       # FoundryVTT VM resource
│   ├── firblab.tfvars      # Environment-specific variables
│   └── files/              # Static files for VM initialization
│       ├── foundryvtt-user-data.yaml
│       └── foundryvtt_ssh_key.pem
└── ansible/                # Configuration Management
    ├── ansible.cfg         # Ansible configuration
    ├── inventory/          # Inventory files
    │   └── hosts.yml       # Host definitions
    ├── playbooks/          # Ansible playbooks
    │   └── foundryvtt.yml  # Main FoundryVTT playbook
    └── roles/              # Ansible roles
        └── foundryvtt/     # FoundryVTT role
            ├── defaults/   # Default variables
            ├── tasks/      # Tasks to execute
            ├── templates/  # Jinja2 templates
            └── handlers/   # Event handlers
```

## Quick Start

### 1. Clone and Configure

```bash
git clone https://github.com/firblab-blog/prox-foundryvtt.git
cd prox-foundryvtt
```

### 2. Configure Terraform

```bash
cd terraform
cp firblab.tfvars.example firblab.tfvars
```

Edit `firblab.tfvars` with your Proxmox details:

```hcl
# Proxmox connection details
pm_api_url     = "https://YOUR_PROXMOX_IP:8006/api2/json"
proxmox_node   = "YOUR_NODE_NAME"
pm_user        = "YOUR_USERNAME@pam"
pm_password    = "YOUR_PASSWORD"

# VM configuration
foundryvtt_vm_id        = 666
foundryvtt_cpu_cores    = 2
foundryvtt_memory       = 4096
foundryvtt_disk_size    = 40
foundryvtt_data_disk_size = 50
foundryvtt_static_ip    = "192.168.4.100"  # Optional: leave empty for DHCP
network_gateway         = "192.168.4.1"
network_bridge          = "vmbr0"
```

### 3. Deploy Infrastructure

```bash
# Initialize Terraform
terraform init

# Plan the deployment
terraform plan -var-file="firblab.tfvars"

# Apply the configuration
terraform apply -var-file="firblab.tfvars"
```

### 4. Configure Ansible Inventory

After Terraform completes, update the Ansible inventory with the VM's IP:

```bash
cd ../ansible
```

Edit `inventory/hosts.yml`:

```yaml
all:
  children:
    foundryvtt:
      hosts:
        foundryvtt-server:
          ansible_host: 192.168.4.100  # Use the IP from Terraform output
          ansible_user: foundry
          ansible_ssh_private_key_file: ../terraform/files/foundryvtt_ssh_key.pem
```

### 5. Install FoundryVTT

#### Option A: Download FoundryVTT separately (Recommended)

1. Download FoundryVTT from your account at https://foundryvtt.com/
2. Place the Node.js zip file on the server or in the project files
3. Run the playbook:

```bash
ansible-playbook playbooks/foundryvtt.yml -e foundryvtt_zip_present=true
```

#### Option B: Use local FoundryVTT file

1. Place your FoundryVTT zip file at `terraform/files/foundryvtt.zip`
2. Run the playbook:

```bash
ansible-playbook playbooks/foundryvtt.yml -e foundryvtt_zip_path=../terraform/files/foundryvtt.zip
```

## Configuration

### VM Specifications

Default VM configuration (customizable in `firblab.tfvars`):
- **CPU**: 2 cores
- **Memory**: 4GB RAM
- **System Disk**: 40GB
- **Data Disk**: 50GB (for FoundryVTT worlds/assets)
- **Network**: Static IP or DHCP
- **OS**: Ubuntu 22.04 LTS

### FoundryVTT Configuration

Default FoundryVTT settings (customizable in `ansible/roles/foundryvtt/defaults/main.yml`):
- **Port**: 30000
- **Install Directory**: `/opt/foundryvtt`
- **Data Directory**: `/var/lib/foundryvtt`
- **Config Directory**: `/etc/foundryvtt`
- **Node.js Version**: 22

### Service Management

FoundryVTT runs as a systemd service:

```bash
# Check status
sudo systemctl status foundryvtt

# View logs
sudo journalctl -u foundryvtt -f

# Restart service
sudo systemctl restart foundryvtt

# Start/stop service
sudo systemctl start foundryvtt
sudo systemctl stop foundryvtt
```

## Accessing FoundryVTT

After successful deployment:

1. **Web Interface**: `http://VM_IP:30000`
2. **Initial Setup**: Follow FoundryVTT's first-run wizard
3. **License**: Enter your FoundryVTT license key
4. **Admin Password**: Set up your admin password

## Network Configuration

### Firewall
The Ansible playbook automatically configures UFW to allow:
- SSH (port 22)
- FoundryVTT (port 30000)

### Reverse Proxy (Optional)
For production use with SSL, consider setting up a reverse proxy (Nginx/Caddy) on the VM or using Nginx Proxy Manager.

## Customization

### VM Resources
Modify `terraform/firblab.tfvars`:

```hcl
foundryvtt_cpu_cores = 4      # Increase CPU for larger campaigns
foundryvtt_memory = 8192      # Increase RAM for better performance
foundryvtt_data_disk_size = 100  # More storage for assets/worlds
```

### FoundryVTT Settings
Modify `ansible/roles/foundryvtt/defaults/main.yml`:

```yaml
foundryvtt_port: "443"                    # Change port
foundryvtt_hostname: "your.domain.com"    # Set hostname
foundryvtt_extra_args: "--ssl"            # Add SSL support
```

## Troubleshooting

### Common Issues

**Terraform fails to connect to Proxmox:**
- Verify API URL, credentials, and network connectivity
- Check Proxmox API permissions

**Ansible cannot connect to VM:**
- Ensure VM is running and SSH is accessible
- Verify SSH key permissions (`chmod 600 foundryvtt_ssh_key.pem`)
- Check firewall settings

**FoundryVTT won't start:**
- Check service logs: `sudo journalctl -u foundryvtt -f`
- Verify FoundryVTT zip file was properly extracted
- Ensure Node.js is installed correctly

**Cannot access FoundryVTT web interface:**
- Check if service is running: `sudo systemctl status foundryvtt`
- Verify firewall allows port 30000
- Confirm VM IP and port configuration

### Log Locations
- **Ansible logs**: Terminal output during playbook run
- **FoundryVTT logs**: `sudo journalctl -u foundryvtt`
- **System logs**: `/var/log/syslog`

## Maintenance

### Updates

**Update FoundryVTT:**
1. Download new version from foundryvtt.com
2. Stop the service: `sudo systemctl stop foundryvtt`
3. Replace files in `/opt/foundryvtt/`
4. Start the service: `sudo systemctl start foundryvtt`

**Update system packages:**
```bash
sudo apt update && sudo apt upgrade -y
```

### Backups

**Important directories to backup:**
- `/var/lib/foundryvtt` - User data, worlds, modules
- `/etc/foundryvtt` - Configuration files
- VM snapshots via Proxmox

## Security Considerations

- Change default SSH keys
- Use strong passwords for FoundryVTT admin
- Consider VPN access for remote play
- Regular system updates
- Firewall configuration review

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

[Your License Here]

## Support

For issues and questions:
- Check the troubleshooting section
- Review FoundryVTT documentation
- Open an issue on GitHub