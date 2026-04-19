---
service: "cloud-jenkins-main"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "jenkins-efs"
    type: "AWS EFS (NFS)"
    purpose: "Persistent Jenkins home directory — job configs, build history, workspace data, credentials"
  - id: "terraform-state-s3"
    type: "AWS S3 + DynamoDB"
    purpose: "Terraform remote state storage and locking"
---

# Data Stores

## Overview

Cloud Jenkins Main uses AWS EFS (Elastic File System) as its primary persistent store — the Jenkins home directory (`JENKINS_HOME`) is mounted from EFS so that job configurations, build history, and plugin data survive controller restarts and redeployments. Terraform state is persisted in S3 with DynamoDB-backed state locking. The controller itself does not own a relational database.

## Stores

### Jenkins Home (EFS) (`jenkins-efs`)

| Property | Value |
|----------|-------|
| Type | AWS EFS (NFS) |
| Architecture ref | `continuumJenkinsController` |
| Purpose | Persistent storage for Jenkins home directory: job definitions, build history, workspace data, plugin configs, credentials cache |
| Ownership | owned |
| Migrations path | Not applicable — managed by Jenkins controller on startup |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Job definitions | Stores JCasC-seeded and DSL-created job XML | job name, pipeline script reference, trigger config |
| Build history | Persists build logs, artifacts metadata, and results | build number, result (SUCCESS/FAILURE/ABORTED), timestamp |
| Plugin data | Per-plugin configuration state between restarts | plugin ID, config blob |
| Credentials | Encrypted credential store (secrets loaded from AWS Secrets Manager at startup) | credential ID, type, scope |

#### Access Patterns

- **Read**: Jenkins controller mounts EFS at startup; reads job XML, build history, and plugin configuration continuously during operation.
- **Write**: Jenkins writes build logs and job state synchronously during pipeline execution; JCasC and init scripts write configuration at startup.
- **Indexes**: Not applicable — filesystem-based storage.

### Terraform Remote State (`terraform-state-s3`)

| Property | Value |
|----------|-------|
| Type | AWS S3 + AWS DynamoDB |
| Architecture ref | `cloudPlatform` |
| Purpose | Stores Terragrunt/Terraform state files for all Jenkins stack modules; DynamoDB table provides distributed state lock |
| Ownership | shared (managed by cloud-jenkins Terraform modules) |
| Migrations path | `terraform/environments/` |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| S3 state file | Terraform plan state per module | `rapt-cloud-jenkins-787676117833/main/grpn-internal-prod/us-west-2/cloud-jenkins/main/jenkins/terraform.tfstate` |
| DynamoDB lock table | Prevents concurrent Terraform operations | `Path` (state path), `Operation`, `Who`, `Created` |

#### Access Patterns

- **Read**: Terraform reads state before each plan/apply operation.
- **Write**: Terraform writes updated state after each apply; DynamoDB lock is acquired and released per operation.
- **Indexes**: DynamoDB primary key is the state `Path`.

## Caches

> No evidence found in codebase. No dedicated cache layer (Redis, Memcached, etc.) is used by this service.

## Data Flows

- On controller startup, Jenkins mounts the EFS volume and loads all job definitions, plugin state, and credentials from disk.
- During pipeline execution, build logs are written to EFS and simultaneously shipped to the central Logging Stack via Filebeat.
- On redeployment (`make apply-all`), Terraform reads the S3 state file, acquires a DynamoDB lock, computes the diff, and applies changes to AWS resources (ECS task, EFS mount targets, security groups, etc.).
- EFS is backed up on a scheduled basis via AWS Backup; recovery points can be restored to a new EFS file system using the procedure documented in `doc/efs_restore.md`.
