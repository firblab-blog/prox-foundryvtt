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
│   ├── firblab.tfvars.example  # Example variables file
│   └── files/              # Static files for VM initialization
│       ├── foundryvtt-user-data.yaml.example
│       └── user-data.example
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
cp files/user-data.example files/user-data
cp files/foundryvtt-user-data.yaml.example files/foundryvtt-user-data.yaml
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

**Important**: Also edit the `files/user-data` and `files/foundryvtt-user-data.yaml` files to include your SSH public key and customize the user configuration.

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

The Ansible inventory is already configured to dynamically get the VM IP from Terraform output. No manual editing required unless you want to customize the connection settings.

If you need to modify the inventory, edit `ansible/inventory/hosts.yml`:

```yaml
all:
  children:
    foundryvtt:
      hosts:
        foundryvtt-01:
          ansible_host: "{{ lookup('pipe', 'cd ../../terraform && terraform output -raw foundryvtt_vm_ip') }}"
          ansible_user: foundry
          ansible_ssh_private_key_file: "../terraform/files/foundryvtt_ssh_key.pem"
          ansible_ssh_common_args: '-o StrictHostKeyChecking=no'
```

### 5. Install FoundryVTT

```bash
cd ../ansible
```

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
- **OS**: Ubuntu 24.04 LTS

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

- **Never commit sensitive files**: The `.gitignore` is configured to exclude SSH keys, passwords, and configuration files with sensitive data
- **Change default SSH keys**: Generate new SSH keys for production use
- **Use strong passwords**: Set strong passwords for FoundryVTT admin and Proxmox access
- **Consider VPN access**: For remote play, consider VPN access instead of exposing FoundryVTT directly to the internet
- **Regular system updates**: Keep the VM and FoundryVTT updated
- **Firewall configuration**: Review and customize UFW rules as needed
- **File permissions**: Ensure proper file permissions on SSH keys (`chmod 600`)

### Important Files to Keep Secure

These files contain sensitive information and should never be committed to version control:
- `terraform/firblab.tfvars` - Contains Proxmox credentials
- `terraform/files/foundryvtt_ssh_key.pem` - SSH private key
- `terraform/files/user-data` - Contains SSH public keys and user passwords
- `terraform/files/foundryvtt-user-data.yaml` - Contains SSH keys and configuration
- `terraform/terraform.tfstate*` - Contains infrastructure state and potentially sensitive data

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is provided as-is for educational and personal use. Please ensure you have proper licenses for:
- FoundryVTT software from [foundryvtt.com](https://foundryvtt.com/)
- Any game systems, modules, or assets you use

## Support

For issues and questions:
- Check the troubleshooting section above
- Review [FoundryVTT documentation](https://foundryvtt.com/kb/)
- Check [Terraform Proxmox Provider documentation](https://registry.terraform.io/providers/Telmate/proxmox/latest/docs)
- Open an issue on GitHub
