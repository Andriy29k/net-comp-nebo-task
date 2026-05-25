# Network Compute Task 

Stack: Azure VNet, 3 subnets, bastion host, private app + DB VMs, NAT for the app tier, Flask TODO app + PostgreSQL.

---

## What this setup does

- **Bastion** — only VM with a public IP. You SSH here from your home IP.
- **App VM** — private IP, no direct internet access. Outbound traffic (updates) goes through **NAT Gateway**.
- **DB VM** — private IP, PostgreSQL. Only the app VM can connect on port 5432.

---

## IP plan

| Subnet | CIDR | Example IP |
|--------|------|------------|
| VNet | `10.0.0.0/16` | — |
| Public (bastion) | `10.0.1.0/24` | dynamic |
| App | `10.0.2.0/24` | `10.0.2.10` |
| DB | `10.0.3.0/24` | `10.0.3.10` |

Edit values in `terraform/terraform.tfvars` (see `terraform.tfvars.example`).

---

## Repo layout

| Folder / file | What it is |
|---------------|------------|
| `app/` | Flask app + systemd unit |
| `scripts/cloud-init-app.tpl` | App VM boot: env file + start service |
| `scripts/install-db.sh` | DB VM boot: install PostgreSQL |
| `scripts/install-app.sh` | Build golden image (optional) |
| `terraform/` | Network + VMs |

---

## Firewall rules

**Subnet NSG** = subnet-level filter (like AWS NACL).  
**ASG** = groups VMs by role (bastion / app / db).

| NSG | Rule | Why |
|-----|------|-----|
| bastion | SSH in from `admin_source_cidr` | Only you can SSH to bastion |
| app | SSH + port 5000 from bastion ASG | Admin and health checks via jump host |
| app | Out 5432 to db ASG | App talks to database |
| app | Out 443 to Internet | Package updates via NAT |
| db | In 5432 from app ASG | DB only for the app |
| db | In 22 from bastion ASG | Optional DB maintenance |

---

## Deploy

**You need:** Azure CLI, Terraform, SSH key, `az login`.

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Set: subscription, db_password, admin_source_cidr = YOUR_IP/32

terraform init
terraform plan
terraform apply
```

**Useful commands after apply:**

```bash
terraform output ssh_to_bastion
terraform output ssh_port_forward_app
terraform output health_check_via_bastion
```

---

## Tests 

**Should work**

| Test | How | Expected |
|------|-----|----------|
| SSH bastion | `terraform output ssh_to_bastion` | OK |
| App health | `terraform output health_check_via_bastion` | `"connected": true` |
| App UI | SSH tunnel, open `http://127.0.0.1:5000` | TODO page |
| App → DB | From app VM: `nc -zv 10.0.3.10 5432` | open |

**Should fail**

| Test | Expected |
|------|----------|
| Hit DB from internet | no public IP — fails |
| Hit app:5000 from internet | no public IP — fails |
| SSH to app without bastion | fails |

---
