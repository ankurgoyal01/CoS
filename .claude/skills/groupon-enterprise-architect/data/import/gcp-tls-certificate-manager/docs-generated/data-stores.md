---
service: "gcp-tls-certificate-manager"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "gcpSecretManager_cc4b72"
    type: "gcp-secret-manager"
    purpose: "Stores versioned TLS certificate material (certificate, private key, certificate chain) as JSON payloads for consumption by GCP-hosted services"
  - id: "gitRepository"
    type: "git"
    purpose: "Stores the authoritative set of certificate request files; git history is the source of truth for change detection"
---

# Data Stores

## Overview

This service uses two data stores: GCP Secret Manager as the primary output store for provisioned TLS material, and its own GitHub repository as the state store for certificate request declarations. The service itself owns no database, cache, or traditional data store — the git repository is the source of truth for desired state, and GCP Secret Manager holds the resulting provisioned artefacts. All state outside these two systems is ephemeral (existing only during pipeline execution in Conveyor Cloud Kubernetes namespaces).

## Stores

### GCP Secret Manager (`gcpSecretManager_cc4b72`)

| Property | Value |
|----------|-------|
| Type | gcp-secret-manager |
| Architecture ref | `gcpSecretManager_cc4b72` |
| Purpose | Stores versioned TLS certificate material (certificate, private key, and certificate chain including Groupon root CA) as JSON payloads; granting access to GCP service accounts listed in each request's `accessors` field |
| Ownership | external (GCP-managed, per-project) |
| Migrations path | Not applicable |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `tls--{org}-{service}` | Standard TLS certificate secret (one per request file per environment) | `certificate`, `key`, `certificate_chain`, `environment` |
| `tls--{org}-{service}-legacy` | Legacy mTLS certificate secret for services with `cntype: legacy` | `certificate`, `key`, `certificate_chain`, `environment` |

#### Access Patterns

- **Read**: GCP service accounts listed in the request's `accessors` array are granted `roles/secretmanager.secretAccessor`. Consumers read the latest version of the secret at startup or on a refresh cycle.
- **Write**: DeployBot (running as the environment's GCP service account, e.g., `grpn-sa-deploybot-mtls@prj-grp-central-sa-stable-66eb.iam.gserviceaccount.com`) creates or updates secrets and secret versions via the `gcloud` CLI during pipeline execution.
- **Indexes**: Not applicable — secrets are addressed by name using the pattern `tls--{org}-{service}`.

### Git Repository (`gitRepository`)

| Property | Value |
|----------|-------|
| Type | git |
| Architecture ref | `githubEnterprise` |
| Purpose | Authoritative declaration of desired certificate state; git commit history drives change detection (add/modify/delete actions) |
| Ownership | owned |
| Migrations path | Not applicable |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `requests/**/*.json` | One JSON file per certificate request; each file declares the org, service, target GCP projects, and accessor principals for all environments | `org`, `service`, `cntype`, `environments`, `seq` |

#### Access Patterns

- **Read**: `has-cert-requests.sh` and `get-cert-requests.sh` use `git show --name-status -m HEAD` to read the diff of the latest commit against its parent, detecting file changes under `requests/`.
- **Write**: Engineering teams commit new or modified request files via Pull Requests to the `main` branch.
- **Indexes**: Not applicable — files are located by path prefix (`requests/`).

## Caches

> Not applicable — this service uses no caches.

## Data Flows

Certificate request files committed to the git repository (`requests/**/*.json`) drive the provisioning of TLS material into GCP Secret Manager. The flow is one-directional: git is the input (desired state), and GCP Secret Manager is the output (actual state). No ETL, CDC, or replication between stores occurs. Conveyor Cloud Kubernetes acts as an ephemeral intermediary — cert-manager Certificate and Kubernetes Secret resources exist only within the deployment namespace and are not persisted outside the pipeline execution.
