---
service: "tableau-terraform"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "tableauStorageBucket"
    type: "gcs"
    purpose: "Tableau Server backups and log storage"
  - id: "terraform-state-gcs"
    type: "gcs"
    purpose: "Terraform remote state backend"
  - id: "tableau-config-disk"
    type: "gce-persistent-disk"
    purpose: "Tableau cluster/TSM configuration shared from primary node"
---

# Data Stores

## Overview

`tableau-terraform` provisions two categories of storage. The primary object store is a GCS bucket that receives Tableau Server backups and log files. A separate GCS bucket (per environment, managed by Terragrunt remote state config) holds the Terraform state files. A persistent SSD disk attached to the primary VM stores Tableau cluster and TSM configuration that is shared across the cluster.

---

### Tableau Storage Bucket (`tableauStorageBucket`)

| Property | Value |
|----------|-------|
| Type | GCS (Google Cloud Storage) |
| Architecture ref | `tableauStorageBucket` |
| Purpose | Store Tableau Server backups under `backups/` prefix and log files under `logs/` prefix |
| Ownership | owned |
| Bucket naming | `grpn-<env_short_name>-<env_stage>-bucket` (e.g., `grpn-tableau-prod-bucket`) |
| Location | `us-central1` |
| Versioning | disabled |

#### Key Entities

| Prefix / Path | Purpose | Retention |
|----------------|---------|-----------|
| `backups/` | Tableau Server backup archives | 5 days (configurable via `backup_retention_period`) |
| `logs/` | Tableau Server log archives | 5 days (configurable via `log_retention_period`) |

#### Access Patterns

- **Read**: Backup restoration — operators download backup archives from GCS to perform disaster recovery
- **Write**: Tableau VM maintenance scripts write backup and log archives into the bucket
- **Indexes**: Not applicable — object storage

#### Lifecycle Rules

- Objects with prefix `backups/` are deleted after `backup_retention_period` days (default: 5)
- Objects with prefix `logs/` are deleted after `log_retention_period` days (default: 5)
- Object versioning is disabled (`uniform_bucket_level_access = true`)

---

### Terraform Remote State (`terraform-state-gcs`)

| Property | Value |
|----------|-------|
| Type | GCS (Google Cloud Storage) |
| Architecture ref | `tableauTerraformRunner` |
| Purpose | Store Terraform state files for each environment and module combination |
| Ownership | shared (managed by CloudCore Terraform tooling convention) |
| Bucket naming | `grpn-gcp-<TF_VAR_PROJECTNAME>-state-<TF_VAR_GCP_PROJECT_NUMBER>` |
| State prefix | `<env>/<region>/<module>` (via `path_relative_to_include()`) |

#### Access Patterns

- **Read**: Terraform reads state on every `plan` and `apply` to determine resource drift
- **Write**: Terraform writes updated state after each successful `apply`

---

### Tableau Config Persistent Disk (`tableau-config-disk`)

| Property | Value |
|----------|-------|
| Type | GCE Persistent Disk (`pd-ssd`) |
| Architecture ref | `tableauInstanceGroup` / `primaryNode` |
| Purpose | Stores Tableau cluster and TSM configuration, shared from the primary node to workers |
| Ownership | owned |
| Size | 100 GB |
| Zone | `us-central1-a` |

#### Access Patterns

- **Read/Write**: Attached to the primary GCE VM in `READ_WRITE` mode
- **Write**: TSM configuration and cluster state are written at initialisation time

---

## Caches

> No evidence found in codebase. No caching layer is provisioned by this repository.

## Data Flows

Terraform state is read before and written after every `plan`/`apply` operation. During Tableau Server initialisation, the primary node writes backup and bootstrap files; backup and log data flows from the Tableau VM to the GCS bucket. The config persistent disk stores TSM configuration that persists across VM restarts for the primary node cluster configuration.
