---
service: "tableau-terraform"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: false
orchestration: "vm"
environments: [dev, stable, prod]
---

# Deployment

## Overview

`tableau-terraform` deploys Tableau Server as a cluster of GCE virtual machines — not containers. Infrastructure is managed with Terragrunt/Terraform and applied manually by an operator (or via CI) using Make targets. There are three named environments (`dev`, `stable`, `prod`), all deployed to GCP region `us-central1`, zone `us-central1-a`. Each environment is logically isolated in its own GCP project with its own Shared VPC, DNS zone, and GCS state bucket. No Kubernetes or container orchestration is used.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | None | VMs are used; no Docker containers |
| Orchestration | GCE Managed Instance Group | Unmanaged instance group (`google_compute_instance_group`) grouping primary and worker VMs |
| Compute | GCE VM (`google_compute_instance`) | Rocky Linux 9 (`rocky-linux-9-optimized-gcp-v20250709`), `pd-ssd` boot disk |
| Load balancer | GCP Internal TCP Load Balancer | `INTERNAL` scheme, ports 80/443, regional backend service, TCP health check on port 80 every 5 s |
| Storage | GCS Bucket | `grpn-<env>-tableau-bucket`, `us-central1`, lifecycle rules for backups and logs |
| TLS | GCP Certificate Manager | Self-managed certificate (`google_certificate_manager_certificate`) |
| DNS | GCP Cloud DNS | A-record for `<instance_name>.<dns_zone_dns_name>` pointing to the load balancer IP, TTL 300 |
| Config disk | GCE Persistent Disk SSD | 100 GB `pd-ssd` attached to primary VM for Tableau cluster/TSM config |
| State backend | GCS | `grpn-gcp-<PROJECTNAME>-state-<PROJECT_NUMBER>` bucket, prefix per module path |
| CDN | None | Not configured |

## Environments

| Environment | Purpose | Region | GCP Project ID | Worker Count |
|-------------|---------|--------|---------------|-------------|
| dev | Development and testing | `us-central1` (`us-central1-a`) | `prj-grp-tableau-dev-4a9c` | 1 |
| stable | Pre-production / staging | `us-central1` (`us-central1-a`) | `prj-grp-tableau-stable-5c24` | 1 |
| prod | Production Tableau Server | `us-central1` (`us-central1-a`) | `prj-grp-tableau-prod-6424` | 2 |

## CI/CD Pipeline

- **Tool**: Make + Terragrunt (manual operator execution; no dedicated CI pipeline file found in repository)
- **Config**: `envs/Makefile`, `envs/.terraform-tooling/Makefiles/`
- **Trigger**: Manual (operator runs Make targets from `envs/`)

### Pipeline Stages

1. **Login**: Authenticate to GCP via service account impersonation (`make <env>/<region>/<module>/gcp-login`)
2. **Validate**: Run `terraform validate` to check HCL syntax and variable completeness
3. **Plan**: Run `terragrunt plan`; output written to `plan.json` via after-hook (`terraform show -json plan.output`)
4. **Apply**: Run `terragrunt apply` with compact warnings; state written to GCS remote state bucket
5. **Format check**: `pre-commit` hook with JIRA ticket reference check enforced on commit

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal (workers) | Manual — instance count set in `cluster.json` | dev: 1 worker, stable: 1 worker, prod: 2 workers |
| Primary node | Single instance per environment (no HA) | 1 primary per environment |
| Memory | Fixed VM machine type | `n2-highmem-32` (prod/dev), `n2-highmem-16` (stable) |
| CPU | Fixed VM machine type | `n2-highmem-32` = 32 vCPUs; `n2-highmem-16` = 16 vCPUs |

## Resource Requirements

| Environment | Node | Machine Type | vCPU | RAM | Boot Disk | Config Disk |
|-------------|------|-------------|------|-----|-----------|-------------|
| dev | Primary | `n2-highmem-32` | 32 | 256 GB | 2,250 GB SSD | 100 GB SSD |
| dev | Worker | `n2-highmem-32` | 32 | 256 GB | 750 GB SSD | — |
| stable | Primary | `n2-highmem-16` | 16 | 128 GB | 2,250 GB SSD | 100 GB SSD |
| stable | Worker | `n2-highmem-16` | 16 | 128 GB | 750 GB SSD | — |
| prod | Primary | `n2-highmem-32` | 32 | 256 GB | 2,250 GB SSD | 100 GB SSD |
| prod | Worker | `n2-highmem-32` | 32 | 256 GB | 750 GB SSD | — |
