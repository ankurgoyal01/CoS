---
service: "ghe-gcp-migration"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Developer Infrastructure"
platform: "Continuum / GCP"
team: "github"
status: active
tech_stack:
  language: "HCL"
  language_version: "Terraform 1.x"
  framework: "hashicorp/google"
  framework_version: "5.25.0"
  runtime: "Terraform CLI"
  runtime_version: "1.x"
  build_tool: "Terraform"
  package_manager: "Terraform Registry"
---

# GHE GCP Migration Overview

## Purpose

The `ghe-gcp-migration` repository contains Terraform infrastructure-as-code to provision a self-hosted GitHub Enterprise (GHE) instance on Google Cloud Platform (GCP). It creates all required cloud resources — VPC, compute instances, load balancers, firewall rules, and persistent storage — necessary to run GHE at production scale. The repository supports Groupon's migration of GitHub Enterprise from its previous hosting environment to GCP.

## Scope

### In scope

- Provisioning a dedicated GCP VPC (`ghe-vpc`) with a private subnet (`172.31.0.0/16`)
- Creating a GHE compute instance (`github-core`, `n2-highmem-16`) running `github-enterprise-3-10-6`
- Attaching a 1.5 TB (`1536 GB`) persistent disk for GitHub Enterprise data storage
- Creating a managed instance group (`github-core-manager`) and autoscaler (min 1, max 3, CPU target 60%) for GHE
- Provisioning an Nginx reverse-proxy instance (`nginx-core`, `n1-standard-1`) for HTTP/HTTPS traffic
- Configuring a global HTTP(S) load balancer for web traffic (ports 80, 443, 8443)
- Configuring a global TCP load balancer for SSH traffic (ports 22, 122)
- Defining ingress firewall rules that allowlist specific IP ranges for SSH, HTTP, HTTPS, and custom ports

### Out of scope

- GitHub Enterprise application configuration (admin console setup, license installation, SAML SSO)
- DNS record management
- TLS certificate provisioning
- Nginx application-layer configuration (virtual hosts, proxy rules within the OS)
- GitHub Actions runner infrastructure

## Domain Context

- **Business domain**: Developer Infrastructure
- **Platform**: Continuum / GCP
- **Upstream consumers**: Groupon engineers and CI/CD systems that connect to GitHub Enterprise via HTTP(S) and SSH
- **Downstream dependencies**: GCP project `prj-grp-general-sandbox-7f70` (compute, networking, storage APIs); GCP service account credentials via `GOOGLE_APPLICATION_CREDENTIALS`

## Stakeholders

| Role | Description |
|------|-------------|
| Platform / DevInfra Engineer | Operates and extends Terraform modules; runs `terraform apply` and `terraform destroy` |
| GitHub Enterprise Admin | Configures GHE at the application layer once infrastructure is provisioned |
| Security / Networking | Maintains the firewall IP allowlist in `modules/firewall/main.tf` |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | HCL (Terraform) | 1.x | `main.tf`, `variables.tf`, `providers.tf` |
| Provider | hashicorp/google | 5.25.0 | `providers.tf` |
| Build tool | Terraform CLI | 1.x | `README.md` |
| Package manager | Terraform Registry | — | `providers.tf` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| hashicorp/google (Terraform provider) | 5.25.0 | cloud-provider | Manages all GCP resources (VPC, compute, load balancer, firewall, disks) |

> This repository is infrastructure-as-code only. There are no application-language libraries. The single key dependency is the GCP Terraform provider.
