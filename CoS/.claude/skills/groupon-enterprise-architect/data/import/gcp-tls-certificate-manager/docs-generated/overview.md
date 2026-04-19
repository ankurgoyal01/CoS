---
service: "gcp-tls-certificate-manager"
title: Overview
generated: "2026-03-03"
type: overview
domain: "GCP Migration Infrastructure"
platform: "Continuum"
team: "dnd-gcp-migration-infra"
status: active
tech_stack:
  language: "Shell / Groovy"
  language_version: "POSIX sh / Groovy 2.x"
  framework: "Jenkins Declarative Pipeline"
  framework_version: "latest (Conveyor CI)"
  runtime: "Jenkins"
  runtime_version: "dind_2gb_2cpu agent"
  build_tool: "Jenkins (Conveyor CI)"
  package_manager: "none"
---

# GCP TLS Certificate Manager Overview

## Purpose

GCP TLS Certificate Manager is a GitOps-driven certificate provisioning pipeline that manages TLS certificates for GCP-hosted Groupon services needing access to non-GCP internal infrastructure via Hybrid Boundary. It reads declarative JSON request files committed to the `requests/` directory, detects additions, modifications, and deletions via git history, and invokes DeployBot to apply cert-manager Certificate resources in Conveyor Cloud Kubernetes namespaces, then publishes the resulting TLS material into GCP Secret Manager for consumption by downstream services. Certificates are also refreshed on a monthly schedule (first Monday of each month) to maintain validity across all environments.

## Scope

### In scope

- Provisioning new TLS certificates in response to new request files added to `requests/`
- Refreshing existing certificates on a monthly cron schedule (first Monday of the month)
- Removing certificates and GCP secrets when request files are deleted
- Updating certificate accessor permissions when request files are modified
- Generating optional legacy mTLS certificates (via `cntype: legacy`) compatible with AWS ACM naming conventions
- Storing certificate material (certificate, private key, certificate chain) as versioned JSON payloads in GCP Secret Manager
- Managing environment promotion: dev → staging → production

### Out of scope

- Long-running application servers or HTTP APIs (this service has no persistent runtime)
- Certificate lifecycle management for non-GCP internal services (handled by cert-manager in Conveyor Cloud)
- Direct management of Hybrid Boundary access policies (the TLS CN value is set to follow Hybrid Boundary naming conventions; policy enforcement is external)
- Kafka MSK TLS authentication management (consumers of this service handle their own authentication setup)

## Domain Context

- **Business domain**: GCP Migration Infrastructure
- **Platform**: Continuum (Groupon core commerce platform)
- **Upstream consumers**: GCP-hosted services across multiple organizations (cls, seo, subscription, dnd-ingestion, marketing, crm, emerging-channels, relevance, dssi-airflow-platform, etc.) that consume secrets from GCP Secret Manager
- **Downstream dependencies**: GitHub Enterprise (source of request files), DeployBot (deployment orchestrator), Conveyor Cloud Kubernetes (cert-manager), GCP Secret Manager, GCP IAM Service Accounts, AWS ACM (for legacy mTLS only)

## Stakeholders

| Role | Description |
|------|-------------|
| Service owner | dnd-gcp-migration-infra team — maintains the pipeline, deploybot image, and monthly refresh cadence |
| Certificate requestors | Any Groupon GCP team that submits a JSON request file to `requests/` via Pull Request |
| Deployment approvers | Team members with Conveyor Cloud namespace access who authorize DeployBot deployments in ARQ |
| Certificate consumers | GCP service accounts and workloads that read `tls--{org}-{service}` secrets from GCP Secret Manager |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Shell (POSIX sh) | POSIX sh | `has-cert-requests.sh`, `get-cert-requests.sh` |
| Pipeline DSL | Groovy (Jenkins Declarative Pipeline) | Groovy 2.x | `Jenkinsfile` |
| Pipeline library | conveyor-ci-util | latest | `@Library("conveyor-ci-util@latest")` in `Jenkinsfile` |
| Deployment orchestrator | DeployBot | image `1.8-test-legacy` | `.deploy_bot.yml` |
| Container image | gcp_tls_certificate_manager_deploybot | 1.8-test-legacy | `.deploy_bot.yml` |
| Cert provisioner | cert-manager (Kubernetes) | v1 | `owners_manual.md` reference to `cert-manager.io/v1` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| conveyor-ci-util | latest | scheduling | Shared Jenkins pipeline utilities for Conveyor CI (deploybotValidate, deploybotDeploy) |
| cert-manager | v1 (Kubernetes CRD) | scheduling | Issues and renews Kubernetes Certificate resources in Conveyor Cloud namespaces |
| kubectl | cluster-version | scheduling | Applies Certificate and Secret Kubernetes resources in environment-specific namespaces |
| gcloud CLI | cluster-version | auth | Authenticates GCP service accounts and manages GCP Secret Manager entries |
| DeployBot | 1.8-test-legacy | scheduling | Orchestrates environment-promoted deployments via `.deploy_bot.yml` configuration |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
