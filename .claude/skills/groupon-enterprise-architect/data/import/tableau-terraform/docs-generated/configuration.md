---
service: "tableau-terraform"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars, hcl-files, json-files, secrets-files]
---

# Configuration

## Overview

Configuration is split across four layers. Terragrunt reads environment-scoped HCL files (`global.hcl`, `account.hcl`, `region.hcl`) that supply GCP project IDs, network names, and environment stage. The Makefile sets the Terragrunt version and project identity. Sensitive values (TSM credentials, LDAP credentials, SSH keys, and TLS certificates) are read from a `secrets/` directory (not committed to this repository) at `apply` time. Operating environment context is supplied through shell environment variables consumed by Terragrunt.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `TF_VAR_PROJECTNAME` | Unique project name used to name the Terraform remote state GCS bucket | yes | `INVALID` | shell / CI |
| `TF_VAR_GCP_PROJECT_NUMBER` | GCP project number for the target environment | yes | `INVALID` | shell / CI |
| `TF_VAR_GCP_PROJECT_ID` | GCP project ID for the target environment | yes | `INVALID` | shell / CI |
| `TF_VAR_GCP_ENV_STAGE` | Environment stage (`dev`, `stable`, `prod`) used for service account selection | yes | `INVALID` | shell / CI |

> IMPORTANT: Never document actual secret values. Only variable names and purposes.

## Feature Flags

> No evidence found in codebase. No runtime feature flags are configured.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `envs/global.hcl` | HCL | Global labels (`service`, `owner`), Terraform service account name (`grpn-sa-terraform-tableau`), ops-agent service account name |
| `envs/terragrunt.hcl` | HCL | Remote state backend configuration (GCS bucket, prefix, impersonation); common Terraform extra arguments and lifecycle hooks |
| `envs/<env>/account.hcl` | HCL | Per-environment GCP project number, project ID, environment stage, zone, VPC network, VPC host project, subnet, and DNS zone name |
| `envs/<env>/us-central1/region.hcl` | HCL | Region-level configuration (`us-central1`) |
| `envs/<env>/us-central1/instance_group/terragrunt.hcl` | HCL | Instance group module source reference, OS image pin (`rocky-linux-9-optimized-gcp-v20250709`), cluster JSON reference, bucket URL dependency |
| `envs/<env>/us-central1/instance_group/cluster.json` | JSON | Per-environment VM sizing: machine type and disk size for primary and worker nodes, and worker instance count |
| `envs/<env>/us-central1/load-balancer/terragrunt.hcl` | HCL | Load balancer module source, dependency on instance group output |
| `envs/<env>/us-central1/bucket/terragrunt.hcl` | HCL | Bucket module source, backup retention period (default 5), log retention period (default 5) |
| `envs/Makefile` | Makefile | Project name (`dnd-tools::test260424::9548`), service name (`tableau-production`), owner email, Terragrunt version pin, compliance test settings |
| `modules/template/common.tf` | HCL | Shared Terraform GCS backend, common variable declarations, GCP provider configuration with service account impersonation logic |
| `modules/instance_group/primary_user_data.sh.tpl` | Shell template | Startup script template for the primary Tableau node: LDAP config, TSM secrets, TSM initialisation, license activation, cluster bootstrap file generation and distribution to workers |
| `modules/instance_group/worker_user_data.sh.tpl` | Shell template | Startup script template for worker Tableau nodes: TSM secrets, SFTP setup, cluster join via bootstrap file received from primary |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `secrets/tableau/gcp/<env>/tsm/tsm.json` | TSM admin username (`tableauadmin`) and password for Tableau Services Manager | Local secrets directory (not committed to repository) |
| `secrets/tableau/gcp/<env>/smtp/smtp.json` | LDAP bind username (`svc_tableaubind`) and password for Active Directory integration | Local secrets directory (not committed to repository) |
| `secrets/tableau/gcp/<env>/ssl/tableau-ssh.pem` | SSH private key used by the primary node to SCP bootstrap files to worker nodes | Local secrets directory (not committed to repository) |
| `secrets/tableau/gcp/<env>/tls/groupondev_cert.pem` | TLS certificate PEM for Tableau load balancer (self-managed via GCP Certificate Manager) | Local secrets directory (not committed to repository) |
| `secrets/tableau/gcp/<env>/tls/groupondev_key.key` | TLS private key for Tableau load balancer | Local secrets directory (not committed to repository) |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

| Setting | dev | stable | prod |
|---------|-----|--------|------|
| GCP Project ID | `prj-grp-tableau-dev-4a9c` | `prj-grp-tableau-stable-5c24` | `prj-grp-tableau-prod-6424` |
| GCP Project Number | `768594121756` | `1057759788111` | `795748186279` |
| VPC Host Project | `prj-grp-shared-vpc-dev-d89e` | `prj-grp-shared-vpc-stable-134f` | `prj-grp-shared-vpc-prod-2511` |
| Subnet | `sub-vpc-dev-sharedvpc01-us-central1-private` | `sub-vpc-stable-sharedvpc01-us-central1-private` | `sub-vpc-prod-sharedvpc01-us-central1-private` |
| DNS Zone Name | `dz-dev-sharedvpc01-tableau-dev` | `dz-stable-sharedvpc01-tableau-stable` | `dz-prod-sharedvpc01-tableau-prod` |
| Primary machine type | `n2-highmem-32` | `n2-highmem-16` | `n2-highmem-32` |
| Worker machine type | `n2-highmem-32` | `n2-highmem-16` | `n2-highmem-32` |
| Worker instance count | 1 | 1 | 2 |
| Backup retention (days) | 5 | 5 | 5 |
| Log retention (days) | 5 | 5 | 5 |
| Service account impersonation project | `prj-grp-central-sa-dev-e453` | `prj-grp-central-sa-stable-66eb` | `prj-grp-central-sa-prod-0b25` |
