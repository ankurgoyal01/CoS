---
service: "ghe-gcp-migration"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources:
  - "terraform-tfvars"
  - "env-vars"
---

# Configuration

## Overview

The `ghe-gcp-migration` project is configured via Terraform variables. Values are supplied either through a `terraform.tfvars` file (checked into the repository with non-secret defaults) or through environment variables (`TF_VAR_*` prefix convention). The GCP service account credentials path is a required secret supplied outside of version control.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `GOOGLE_APPLICATION_CREDENTIALS` | Path to GCP service account JSON key file used by the Terraform provider | yes | — | env / tfvars |
| `GOOGLE_PROJECT` | GCP project ID | yes | — | env (declared in `providers.tf`) |
| `GOOGLE_REGION` | GCP region for resource creation | yes | — | env (declared in `providers.tf`) |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are shown here.

## Feature Flags

> No evidence found in codebase.

This project uses no feature flags.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `terraform.tfvars` | HCL key-value | Supplies concrete values for all Terraform input variables; includes project ID, region, machine types, image names, and load balancer names |
| `variables.tf` | HCL | Declares all root-module input variable definitions with types, descriptions, and defaults |
| `providers.tf` | HCL | Pins the `hashicorp/google` provider to version 5.25.0 and configures provider credentials |
| `modules/compute/variables.tf` | HCL | Compute-module variable declarations (machine types, images, zones, VPC link) |
| `modules/vpc/varibles.tf` | HCL | VPC-module variable declarations (VPC name, CIDR, subnet name/CIDR, region) |
| `modules/loadbalancer/varibles.tf` | HCL | Load balancer module variable declarations (backend names, URL map, proxy names, forwarding rule names) |
| `modules/firewall/variables.tf` | HCL | Firewall-module variable declarations (VPC self-link) |

## Terraform Variable Reference

| Variable | Default / Example Value | Description |
|----------|------------------------|-------------|
| `region` | `us-central1` | GCP region for resource creation |
| `project_id` | `prj-grp-general-sandbox-7f70` | GCP project ID |
| `vpc_name` | `ghe-vpc` | Name of the GCP VPC to create |
| `vpc_cidr` | `172.31.0.0/16` | CIDR block for the VPC |
| `nginx_machine_type` | `n1-standard-1` | GCE machine type for the Nginx proxy instance |
| `nginx_image` | `ubuntu-os-cloud/ubuntu-2004-lts` | Boot disk image for the Nginx instance |
| `github_machine_type` | `n2-highmem-16` | GCE machine type for the GHE instance |
| `github_image` | `github-enterprise-public/github-enterprise-3-10-6` | Boot disk image for the GHE instance |
| `nginx_backend_name` | `nginx-backend` | Name for the Nginx GCP backend service |
| `github_backend_name` | `github-backend` | Name for the GHE GCP backend service |
| `url_map_name` | `lb-url-map` | Name for the GCP URL map |
| `path_matcher_name` | `lb-path-matcher` | Name for the URL map path matcher |
| `lb_proxy_name` | `lb-proxy` | Name for the HTTP target proxy |
| `github_proxy_name` | `github-proxy` | Name for the GitHub TCP target proxy |
| `http_lb_name` | `http-lb` | Name for the HTTP global forwarding rule |
| `https_lb_name` | `https-lb` | Name for the HTTPS global forwarding rule |
| `custom_https_lb_name` | `custom-https-lb` | Name for the custom HTTPS (port 8443) forwarding rule |
| `github_ssh_lb_name` | `github-ssh-lb` | Name for the SSH TCP global forwarding rule |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `GOOGLE_APPLICATION_CREDENTIALS` | Path to GCP service account key JSON file authorizing Terraform to create GCP resources | Local file / CI secret |

> Secret values are NEVER documented. Only names are listed here.

## Per-Environment Overrides

This repository targets a single GCP sandbox project (`prj-grp-general-sandbox-7f70`) in region `us-central1`. No multi-environment configuration (e.g., dev/staging/prod) is defined in the Terraform code. To target a different environment, a separate `terraform.tfvars` file with different `project_id`, `region`, and resource name values would be required.
