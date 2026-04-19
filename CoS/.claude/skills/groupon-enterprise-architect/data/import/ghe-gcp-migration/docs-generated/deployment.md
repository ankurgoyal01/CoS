---
service: "ghe-gcp-migration"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: false
orchestration: "vm"
environments:
  - "sandbox"
---

# Deployment

## Overview

The `ghe-gcp-migration` project deploys GitHub Enterprise and its supporting infrastructure directly onto GCP Compute Engine virtual machines (not containers). Terraform manages all resource lifecycle operations (`init`, `plan`, `apply`, `destroy`). No Kubernetes, ECS, or container orchestration is used; the GHE application runs inside a GCE VM launched from the official GHE disk image.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | None | No Docker or container runtime — GHE runs as a GCE VM |
| Orchestration | GCP Managed Instance Group | `github-core-manager` wraps the GHE instance template; autoscaler manages replica count |
| Compute — GHE | GCE VM `github-core` | Machine type `n2-highmem-16`, image `github-enterprise-public/github-enterprise-3-10-6`, zone `us-central1-b`, 500 GB boot disk + 1536 GB external disk |
| Compute — Nginx | GCE VM `nginx-core` | Machine type `n1-standard-1`, image `ubuntu-os-cloud/ubuntu-2004-lts`, zone `us-central1-a`, 50 GB boot disk |
| Load balancer (HTTP/S) | GCP Global HTTP(S) Load Balancer | Forwarding rules `http-lb` (port 80), `https-lb` (port 443), `custom-https-lb` (port 8443) → HTTP target proxy `lb-proxy` → URL map `lb-url-map` → Nginx backend `nginx-backend` |
| Load balancer (SSH) | GCP Global TCP Load Balancer | Forwarding rule `github-ssh-lb` (ports 22, 122) → TCP proxy `github-proxy` → GHE backend `github-backend` → `github-core-manager` instance group |
| Networking | GCP VPC + Subnet | VPC `ghe-vpc`, subnet `public-subnet` CIDR `172.31.1.0/24`, routing mode `GLOBAL`, region `us-central1` |
| Firewall | GCP Firewall Rules | `allow-world-access`: TCP 22, 80, 443, 8443, 122 from allowlisted IP ranges; `allow-icmp-ssh`: ICMP and TCP 22 from `0.0.0.0/0`; `allow-http-https`: TCP 80, 443 from `0.0.0.0/0` |
| IaC tool | Terraform | Provider `hashicorp/google` 5.25.0; modules: `vpc`, `compute`, `loadbalancer`, `firewall` |
| CDN | None | No CDN configured |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| sandbox | GHE migration target environment (`prj-grp-general-sandbox-7f70`) | `us-central1` | Determined by GCP forwarding rule external IPs at provisioning time |

## CI/CD Pipeline

- **Tool**: Manual Terraform CLI
- **Config**: `README.md` documents the manual workflow
- **Trigger**: Manual (`terraform apply` / `terraform destroy`)

### Pipeline Stages

1. **Init**: Run `terraform init` to download the `hashicorp/google` provider and initialize local module references
2. **Plan**: Run `terraform plan` to preview resource changes against GCP state
3. **Apply**: Run `terraform apply` to create or update all GCP resources (VPC, subnet, firewall, VMs, disks, load balancers, autoscaler)
4. **Destroy**: Run `terraform destroy` to remove all provisioned resources from GCP

> No automated CI/CD pipeline (e.g., GitHub Actions, Jenkins) configuration is present in this repository. Deployment is performed manually by a platform engineer.

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal (GHE) | GCP Autoscaler on managed instance group | Min 1 replica, max 3 replicas, CPU utilization target 60% (`github-core-autoscaler`) |
| Horizontal (Nginx) | Manual (single instance) | Single `nginx-core` VM; instance group manager is commented out in Terraform |
| Memory | Not configured via Terraform | Determined by GCE machine type (`n2-highmem-16` for GHE, `n1-standard-1` for Nginx) |
| CPU | Not configured via Terraform | Determined by GCE machine type |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| GHE VM CPU | `n2-highmem-16` (16 vCPUs) | Fixed by machine type |
| GHE VM Memory | `n2-highmem-16` (~128 GB) | Fixed by machine type |
| GHE Boot Disk | 500 GB | Fixed at provision time |
| GHE External Disk | 1536 GB (pd-standard) | Fixed at provision time |
| Nginx VM CPU | `n1-standard-1` (1 vCPU) | Fixed by machine type |
| Nginx VM Memory | `n1-standard-1` (~3.75 GB) | Fixed by machine type |
| Nginx Boot Disk | 50 GB | Fixed at provision time |
