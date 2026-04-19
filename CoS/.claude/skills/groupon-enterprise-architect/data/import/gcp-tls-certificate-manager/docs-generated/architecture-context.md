---
service: "gcp-tls-certificate-manager"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: ["gcpTlsCertificateManagerPipeline"]
---

# Architecture Context

## System Context

GCP TLS Certificate Manager is a pipeline-only service within the `continuumSystem` (Continuum Platform). It sits at the boundary between Groupon's legacy Conveyor Cloud (AWS-hosted Kubernetes) and GCP-hosted workloads. When a GCP-based service needs to call a non-GCP internal Groupon service across the Hybrid Boundary, it requires a mutually authenticated TLS certificate. This service acts as the centralized provisioning authority for those certificates: it reads declarative request files from its GitHub repository, detects changes via git history, triggers a DeployBot deployment that creates cert-manager Certificate resources in Conveyor Cloud, retrieves the resulting TLS material, and publishes it to GCP Secret Manager under a standardized secret naming convention. It has no long-running process; all work is performed during pipeline execution triggered by git push events or a monthly cron schedule.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| GCP TLS Certificate Manager Pipeline | `gcpTlsCertificateManagerPipeline` | Pipeline | Jenkins Pipeline / Shell | latest | Jenkins pipeline and shell scripts that detect certificate request changes in the `requests/` directory and trigger DeployBot deployments or scheduled refreshes |

## Components by Container

### GCP TLS Certificate Manager Pipeline (`gcpTlsCertificateManagerPipeline`)

> No sub-components are defined in the architecture model for this container. The pipeline logic is implemented as a single `Jenkinsfile` with supporting shell scripts.

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `Jenkinsfile` | Detects push events and timer triggers; runs change detection; invokes deploybotDeploy for new/updated requests and for monthly refresh | Groovy (Jenkins Declarative Pipeline) |
| `has-cert-requests.sh` | Checks git HEAD diff for any file changes under `requests/`; exits 0 if changes detected | POSIX sh |
| `get-cert-requests.sh` | Lists git HEAD diff changes under `requests/` with action codes (A/M/D) | POSIX sh |
| Request files (`requests/**/*.json`) | Declarative certificate specifications — one JSON file per service/org pair | JSON |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `gcpTlsCertificateManagerPipeline` | `githubEnterprise` | Reads repository content and certificate request files | git |
| Jenkins (external) | `gcpTlsCertificateManagerPipeline` | Runs pipeline on push events and monthly refresh schedule (cron `H 12 1-7 * 1`) | Jenkins trigger |
| DeployBot (external) | `githubEnterprise` | Clones repository at a specific commit SHA during deployment | git |
| DeployBot (external) | Conveyor Cloud Kubernetes | Applies cert-manager Certificate and Secret resources in environment namespaces | kubectl |
| DeployBot (external) | cert-manager | Creates and updates Certificate resources | Kubernetes API |
| DeployBot (external) | `gcpSecretManager_cc4b72` | Creates and updates TLS material secrets and versions | GCP API |
| DeployBot (external) | `gcpIamServiceAccounts_18e576` | Authenticates using service account key JSON for GCP access | GCP IAM |
| DeployBot (external) | `awsAcm_2ba5f4` | Publishes legacy mTLS certificates when `cntype: legacy` is set | AWS API |

## Architecture Diagram References

- System context: `contexts-gcpTlsCertificateManager`
- Container: `containers-gcpTlsCertificateManager`
- Component: No component views defined for this service
