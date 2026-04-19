---
service: "ghe-gcp-migration"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumGithubExternalDisk"
    type: "GCP Persistent Disk"
    purpose: "GitHub Enterprise repository and application data storage"
---

# Data Stores

## Overview

The `ghe-gcp-migration` infrastructure provisions one persistent data store: an attached GCP persistent disk for GitHub Enterprise. The Terraform project itself does not own any application databases or caches; all data persistence is delegated to the GHE application running on the provisioned instance.

## Stores

### GitHub External Disk (`continuumGithubExternalDisk`)

| Property | Value |
|----------|-------|
| Type | GCP Persistent Disk (pd-standard) |
| Architecture ref | `continuumGithubExternalDisk` |
| Purpose | Persistent storage for GitHub Enterprise repository data and application state |
| Ownership | owned |
| Migrations path | Not applicable — managed by GHE application internally |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| GitHub Enterprise data volume | Stores all GHE repositories, LFS objects, MySQL data, and application configuration | Attached as `/dev/disk/by-id/google-external-disk` on the `github-core` instance |

#### Access Patterns

- **Read**: GitHub Enterprise application reads repository objects, database records, and configuration directly from disk
- **Write**: GitHub Enterprise application writes commits, pull request data, issues, and LFS objects continuously
- **Indexes**: Managed by GHE internally; not configurable via Terraform

#### Instance Boot Disks

In addition to the external disk, each compute instance has a boot disk:

| Instance | Disk Type | Size |
|----------|-----------|------|
| `github-core` | Boot disk (GHE 3.10.6 image) | 500 GB |
| `nginx-core` | Boot disk (Ubuntu 20.04) | 50 GB |

## Caches

> No evidence found in codebase.

No dedicated cache infrastructure is provisioned by this Terraform project.

## Data Flows

The external disk (`github-core-external-disk`, 1536 GB, `pd-standard`) is attached to the `github-core` GCE VM as a secondary device named `external-disk`. Data written by the GHE application persists across instance restarts. The disk is defined in zone `us-central1-b` and is not replicated.
