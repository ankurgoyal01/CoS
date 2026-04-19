---
service: "gcp-tls-certificate-manager"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 6
internal_count: 1
---

# Integrations

## Overview

This service integrates with six external systems. GitHub Enterprise provides the source of truth for certificate request files; Jenkins and DeployBot provide CI/CD orchestration; Conveyor Cloud Kubernetes and cert-manager handle the actual certificate issuance; GCP Secret Manager and GCP IAM hold the output; and AWS ACM receives legacy mTLS certificates for services that require it. The one internal Groupon dependency is GitHub Enterprise (self-hosted). All integrations are invoked during pipeline execution only — there are no runtime integration calls from a long-running process.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| GitHub Enterprise | git | Source repository for request files and pipeline code | yes | `githubEnterprise` |
| Jenkins | CI trigger | Runs the pipeline on push events and monthly cron schedule | yes | `jenkins_a2feef` |
| DeployBot | webhook/API | Orchestrates environment-promoted deployments; applies resources to Conveyor Cloud | yes | `deployBot_2e6910` |
| Conveyor Cloud Kubernetes | kubectl | Hosts cert-manager namespaces (`gcp-tls-certificate-manager-{env}`) where Certificate resources are created | yes | `conveyorCloudKubernetes_449f0f` |
| cert-manager (Kubernetes CRD) | Kubernetes API | Issues TLS certificates from the Groupon internal CA in response to Certificate resources | yes | `certManager_8a8826` |
| GCP Secret Manager | GCP API (gcloud CLI) | Stores versioned TLS material as `tls--{org}-{service}` secrets in per-project secret stores | yes | `gcpSecretManager_cc4b72` |
| GCP IAM Service Accounts | GCP IAM | Provides authentication credentials (service account JSON key) for GCP API calls during deployment | yes | `gcpIamServiceAccounts_18e576` |
| AWS ACM | AWS API | Receives legacy mTLS certificates for services with `cntype: legacy` | no | `awsAcm_2ba5f4` |
| Hybrid Boundary | TLS (mTLS) | Enforces access policy; TLS CN values follow `{environment}/{service}` naming convention required by Hybrid Boundary policy | yes | `hybridBoundary_8b6034` |

### GitHub Enterprise Detail

- **Protocol**: git (SSH)
- **Base URL / SDK**: `git@github.groupondev.com:dnd-gcp-migration-infra/gcp-tls-certificate-manager.git`
- **Auth**: SSH deploy key (configured in Jenkins/DeployBot)
- **Purpose**: Source of truth for all certificate request files (`requests/**/*.json`) and the `Jenkinsfile` pipeline definition; change detection is performed against git commit history
- **Failure mode**: Pipeline cannot detect changes or clone repository; deployment is blocked
- **Circuit breaker**: No — git is a prerequisite; failures fail the pipeline

### DeployBot Detail

- **Protocol**: DeployBot internal API (invoked via `deploybotDeploy()` Conveyor CI utility)
- **Base URL / SDK**: `https://deploybot.groupondev.com/dnd-gcp-migration-infra/gcp-tls-certificate-manager`
- **Auth**: Conveyor CI service credentials
- **Purpose**: Receives deployment requests from the Jenkins pipeline; fetches the repo at the target SHA; executes the deploybot image (`gcp_tls_certificate_manager_deploybot:1.8-test-legacy`) against the target environment namespace
- **Failure mode**: Certificates are not provisioned; manual retry required via DeployBot UI
- **Circuit breaker**: No

### Conveyor Cloud Kubernetes Detail

- **Protocol**: kubectl (HTTPS to Kubernetes API server)
- **Base URL / SDK**: `https://conveyor-cloud--conveyor-stable83--us-west-2.production.service` (staging); `gcp-stable-us-central1` / `gcp-production-us-central1` clusters
- **Auth**: GCP service account credentials activated via `gcloud auth activate-service-account`; Conveyor Cloud kubeconfig context set to `gcp-tls-certificate-manager-{env}`
- **Purpose**: Hosts the cert-manager Certificate resources and retrieves the resulting Kubernetes TLS secrets for export to GCP Secret Manager
- **Failure mode**: Certificate issuance fails; deployment errors with `ServiceUnavailable`; retry is the only action
- **Circuit breaker**: No

### GCP Secret Manager Detail

- **Protocol**: GCP API via `gcloud` CLI
- **Base URL / SDK**: GCP project-specific Secret Manager endpoint
- **Auth**: GCP service account (e.g., `grpn-sa-deploybot-mtls@prj-grp-central-sa-stable-66eb.iam.gserviceaccount.com`)
- **Purpose**: Creates secrets named `tls--{org}-{service}` and pushes versioned JSON payloads containing the certificate, key, and certificate chain
- **Failure mode**: TLS material is not available to consuming GCP services; must check `project_id` in request file and deploybot logs
- **Circuit breaker**: No

### AWS ACM Detail

- **Protocol**: AWS API
- **Base URL / SDK**: AWS ACM service endpoint
- **Auth**: AWS credentials provided in Conveyor Cloud environment
- **Purpose**: Publishes legacy mTLS certificates (CN: `{service}.{environment}.service`) for services using the `cntype: legacy` field in their request file (e.g., `dnd-ingestion/janus-yati`)
- **Failure mode**: Legacy certificate is not published to AWS ACM; non-legacy certificate provisioning is unaffected
- **Circuit breaker**: No

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| GitHub Enterprise (Groupon self-hosted) | git | Hosts the certificate request repository | `githubEnterprise` |

## Consumed By

Downstream consumers are GCP-hosted Groupon services that read `tls--{org}-{service}` secrets from GCP Secret Manager. These are not tracked in this repository but are registered as `accessors` in each request file. Known consumer organizations include:

| Consumer Organization | Example Service | Secret Pattern |
|----------------------|----------------|----------------|
| cls | consumer-location-service | `tls--cls-consumer-location-service` |
| seo | seo-deal-redirect | `tls--seo-seo-deal-redirect` |
| subscription | gss-cerebro-job-cloud | `tls--subscription-gss-cerebro-job-cloud` |
| dnd-ingestion | janus-yati | `tls--dnd-ingestion-janus-yati` |
| marketing | cas-data-pipelines | `tls--push-cas-data-pipelines` |
| marketing | cm-performance-spark | `tls--marketing-cm-performance-spark` |
| crm | audience-data-flows | `tls--crm-audience-data-flows` |
| emerging-channels | regla-stream | `tls--emerging-channels-regla-stream` |
| relevance | ranking-offline | `tls--relevance-ranking-offline` |

> Full upstream consumer list is tracked via the `accessors` field in each request file under `requests/`.

## Dependency Health

No automated health checks, retry logic, or circuit breaker patterns are implemented in the pipeline. All dependencies are synchronous during pipeline execution:

- **Kubernetes `ServiceUnavailable`**: Retry the deployment via DeployBot UI.
- **Missing `tls-certificate-cicd-sa-key` Kubernetes secret**: Recreate using `kubectl create secret generic tls-certificate-cicd-sa-key --from-file=./tls-manager-cicd`.
- **GCP secret not created**: Verify `project_id` in the request file; check DeployBot logs for the action line.
