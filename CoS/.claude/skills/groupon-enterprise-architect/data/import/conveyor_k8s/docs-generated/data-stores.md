---
service: "conveyor_k8s"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "conveyor-s3-state-buckets"
    type: "s3"
    purpose: "Cluster state and metadata indexed by SHA/version tags"
  - id: "terraform-s3-remote-state"
    type: "s3"
    purpose: "Terraform remote state for EKS cluster modules"
  - id: "terraform-gcs-remote-state"
    type: "gcs"
    purpose: "Terraform remote state for GKE cluster modules"
  - id: "k8s-configmap-promotion-metadata"
    type: "kubernetes-configmap"
    purpose: "Per-cluster promotion status and metadata"
---

# Data Stores

## Overview

Conveyor K8s does not own a relational or NoSQL database. State is distributed across AWS S3 (cluster discovery, Terraform EKS state), GCS (Terraform GKE state), and Kubernetes ConfigMaps (promotion metadata). These stores are operational in nature — they record infrastructure configuration and lifecycle state, not business domain data.

## Stores

### Conveyor Cluster State S3 Buckets (`conveyor-s3-state-buckets`)

| Property | Value |
|----------|-------|
| Type | s3 |
| Architecture ref | `conveyorK8sPipelineUtils` |
| Purpose | Per-cluster S3 buckets tagged with `KubernetesCluster`, `SHA`, `Version`, and `Region` — used by `find_clusters` binary to discover existing clusters |
| Ownership | owned |
| Migrations path | Not applicable |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| S3 Bucket (per cluster) | Stores cluster metadata as bucket tags | `KubernetesCluster`, `SHA`, `Version`, `Region`, `CreationDate` |

#### Access Patterns

- **Read**: `find_clusters` binary queries all Conveyor S3 buckets in `us-west-2` via `GetConveyorBuckets`, then filters by SHA, version, name prefix, region, and exclusion list
- **Write**: Cluster creation pipelines create and tag S3 buckets as part of cluster bootstrap
- **Indexes**: AWS S3 bucket tags used as metadata index; no secondary indexes

---

### Terraform EKS Remote State (`terraform-s3-remote-state`)

| Property | Value |
|----------|-------|
| Type | s3 |
| Architecture ref | `conveyorK8sTerraformEks` |
| Purpose | Terraform state files for EKS cluster modules (eks-cluster, iam, s3, key-pair, encryption-key, git_info, lambda, uuid) |
| Ownership | owned |
| Migrations path | `terra-eks/cluster_definitions/` |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `terraform.tfstate` (per module) | Tracks provisioned AWS resources for each EKS module | Resource IDs, ARNs, configuration values |

#### Access Patterns

- **Read**: Terraform reads remote state from S3 to resolve cross-module dependencies (e.g., `key-pair`, `s3`, `iam`, `git_info` state referenced in `eks-cluster` module)
- **Write**: Terraform writes updated state after each `apply` operation
- **Indexes**: S3 key path (`${remote_state_key_prefix}/<module>/terraform.tfstate`)

---

### Terraform GKE Remote State (`terraform-gcs-remote-state`)

| Property | Value |
|----------|-------|
| Type | gcs |
| Architecture ref | `conveyorK8sTerraformGke` |
| Purpose | Terraform state files for GKE cluster modules (gke-cluster, gcs, git_info, uuid) |
| Ownership | owned |
| Migrations path | `terra-gke/cluster_definitions/` |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `terraform.tfstate` (per module) | Tracks provisioned GCP resources for each GKE module | Resource IDs, endpoint, CA certificate |

#### Access Patterns

- **Read**: Terraform reads cross-module remote state from GCS (gcs, git_info, uuid referenced in gke-cluster module)
- **Write**: Terraform writes updated state after each `apply`
- **Indexes**: GCS prefix path (`${remote_state_key_prefix}/<module>/terraform.tfstate`)

---

### Kubernetes ConfigMap Promotion Metadata (`k8s-configmap-promotion-metadata`)

| Property | Value |
|----------|-------|
| Type | kubernetes-configmap |
| Architecture ref | `conveyorK8sPipelineUtils` |
| Purpose | Stores promotion lifecycle state per cluster: status (IN_PROGRESS / SUCCEEDED / FAILED), source/destination cluster names, next-promotion-eligible-time, and Wavefront event ID |
| Ownership | owned |
| Migrations path | Not applicable |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Promotion ConfigMap | Per-cluster promotion metadata | `SourceCluster`, `DestinationCluster`, `Status`, `NextPromotionEligibleTime`, `WavefrontEventID` |

#### Access Patterns

- **Read**: `promotion get metadata` CLI reads the ConfigMap from the target Kubernetes cluster
- **Write**: `promotion set metadata` CLI writes or updates the ConfigMap fields
- **Indexes**: ConfigMap name and namespace on the Kubernetes API

## Caches

> No explicit cache layer. No Redis or Memcached used.

## Data Flows

- Cluster creation writes S3 state buckets → `find_clusters` reads them during promotion to identify source/destination clusters
- Terraform `apply` writes EKS state to S3 / GKE state to GCS → subsequent Terraform runs read cross-module state via `terraform_remote_state` data sources
- Promotion pipeline writes metadata to Kubernetes ConfigMap → readiness checker and promotion monitor read it back to track progress
