---
service: "tableau-terraform"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: [tableauTerraformRunner, tableauInstanceGroup, tableauLoadBalancer, tableauStorageBucket, tableauCertificates]
---

# Architecture Context

## System Context

`tableau-terraform` sits within the Continuum Platform (`continuumSystem`) as the infrastructure provisioning layer for Groupon's internal Tableau Server analytics cluster. The Terraform Runner applies declarative HCL configurations to a set of GCP resources in the `us-central1` region. Internal analytics consumers access Tableau through an internal TCP load balancer that fronts the managed instance group. The repository does not itself serve traffic — it is the control plane that creates and updates the runtime infrastructure.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Terraform Runner | `tableauTerraformRunner` | Infrastructure | Terraform / Terragrunt | 0.15.5 / 0.30.7 | Runs Terragrunt/Terraform commands to provision all Tableau GCP resources |
| Tableau Instance Group | `tableauInstanceGroup` | Compute | GCE Managed Instance Group | — | GCE instance group housing the Tableau primary and worker nodes |
| Tableau Internal Load Balancer | `tableauLoadBalancer` | Networking | GCP Internal Load Balancer | — | Internal TCP load balancer forwarding traffic to the instance group on ports 80 and 443 |
| Tableau Storage Bucket | `tableauStorageBucket` | Storage | GCS Bucket | — | Object storage bucket for Tableau backups and log files |
| Tableau TLS Certificates | `tableauCertificates` | Security | GCP Certificate Manager | — | Self-managed TLS certificate for Tableau load balancing |

## Components by Container

### Tableau Instance Group (`tableauInstanceGroup`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Primary VM (`primaryNode`) | Hosts the Tableau primary node; runs TSM, installs Tableau Server RPM, configures LDAP, activates license, generates bootstrap file for worker nodes | GCE VM (n2-highmem-32, Rocky Linux 9, `pd-ssd` 2250 GB boot) |
| Worker VMs (`workerNodes`) | Join the Tableau cluster by consuming the bootstrap file transferred via SCP from the primary node | GCE VM (n2-highmem-32, Rocky Linux 9, `pd-ssd` 750 GB boot) |
| Startup Scripts (`startupScripts`) | Metadata startup scripts rendered from Terraform templates; configure LDAP identity store, TSM credentials, SSH access, SFTP, Tableau installation, and cluster bootstrap | Shell scripts (`.sh.tpl` templates) |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `tableauTerraformRunner` | `tableauInstanceGroup` | Creates and updates GCE VM instances, config disk, and unmanaged instance group | Terraform (GCP API) |
| `tableauTerraformRunner` | `tableauLoadBalancer` | Creates and updates internal load balancer, backend service, health check, and forwarding rule | Terraform (GCP API) |
| `tableauTerraformRunner` | `tableauStorageBucket` | Creates and updates the GCS bucket with lifecycle policies | Terraform (GCP API) |
| `tableauTerraformRunner` | `tableauCertificates` | Creates and updates the self-managed TLS certificate | Terraform (GCP API) |
| `tableauLoadBalancer` | `tableauInstanceGroup` | Routes incoming TCP traffic on ports 80/443 to the instance group | TCP |
| `tableauLoadBalancer` | `tableauCertificates` | References the TLS certificate for HTTPS termination | TLS |
| `tableauInstanceGroup` | `tableauStorageBucket` | Stores Tableau backups and log files | GCS |

## Architecture Diagram References

- Container: `containers-tableauTerraform`
- Component: `components-tableauInstanceGroup`
