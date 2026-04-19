---
service: "transporter-jtier"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 5
internal_count: 1
---

# Integrations

## Overview

Transporter JTier has five external dependencies: Salesforce (primary data destination), AWS S3 (input file staging), GCS (result file storage), Okta (identity), and RaaS (internal auth/role service referenced in `.service.yml`). Its single direct internal consumer is `transporter-itier`. DaaS MySQL is used via the JTier `jtier-daas-mysql` library for managed database connectivity.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Salesforce | OAuth2/REST | Authenticate users and perform bulk data operations | yes | `salesforceSystem` |
| AWS S3 | S3 (AWS SDK v2) | Read user-submitted CSV input files | yes | `awsS3ObjectStorage` |
| GCS | GCS SDK | Write upload result files and generate signed download URLs | yes | `gcsObjectStorage` |
| Okta | OAuth2 | Identity provider for user authentication | yes | Listed in `.service.yml` dependencies |
| RaaS | REST | Role and authorization service | no | Listed in `.service.yml` dependencies |

### Salesforce Detail

- **Protocol**: OAuth2 + Salesforce REST/Bulk API
- **Base URL / SDK**: `com.groupon.salesforce.httpclient:SalesforceHttpClient:1.15`
- **Auth**: OAuth2 authorization code flow; tokens cached in Redis (`continuumTransporterRedisCache`)
- **Purpose**: Authenticates Salesforce users, enumerates Salesforce objects for the UI, and executes bulk insert/update/delete data operations
- **Failure mode**: Upload jobs cannot execute; worker fails job record with error state; ITier users cannot authenticate
- **Circuit breaker**: No evidence found in codebase

### AWS S3 Detail

- **Protocol**: S3 SDK (`software.amazon.awssdk:s3:2.9.10`)
- **Base URL / SDK**: `software.amazon.awssdk:s3`; IRSA via `AWS_WEB_IDENTITY_TOKEN_FILE` projected into the `sf-upload-worker` pod
- **Auth**: AWS Web Identity Token (IRSA) — IAM role `tr-iam-role-upload-production` / `tr-iam-role-upload-staging`; token expires after 86400 seconds
- **Purpose**: Reads user-submitted CSV files staged for bulk upload; accessed exclusively by the `uploadWorker` and `storageClients` components
- **Failure mode**: Upload worker cannot fetch input files; jobs fail
- **Circuit breaker**: No evidence found in codebase

### GCS Detail

- **Protocol**: GCS SDK (`com.google.cloud:google-cloud-storage:1.111.2`)
- **Base URL / SDK**: `com.google.cloud:google-cloud-storage`; GCP service account `con-sa-transporter-jtier@prj-grp-central-sa-prod-0b25.iam.gserviceaccount.com` (production)
- **Auth**: GCP Workload Identity via Conveyor-managed GCP service account (IRSA-equivalent for GCP)
- **Purpose**: Writes upload result files after Salesforce bulk operations complete; generates signed URLs for result download
- **Failure mode**: Workers cannot persist results; signed download links unavailable
- **Circuit breaker**: No evidence found in codebase

### Okta Detail

- **Protocol**: OAuth2
- **Base URL / SDK**: Listed as dependency in `.service.yml`
- **Auth**: OAuth2
- **Purpose**: Identity provider for user authentication
- **Failure mode**: Users cannot authenticate to the service
- **Circuit breaker**: No evidence found in codebase

### RaaS Detail

- **Protocol**: REST
- **Base URL / SDK**: Listed as dependency in `.service.yml`
- **Auth**: Internal service auth
- **Purpose**: Role and access authorization service used during user validation
- **Failure mode**: Authorization checks may fail, blocking user access
- **Circuit breaker**: No evidence found in codebase

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| DaaS MySQL | JDBI/MySQL | Managed MySQL database connectivity via `jtier-daas-mysql` | `continuumTransporterMysqlDatabase` |

## Consumed By

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| transporter-itier | REST | Submits upload jobs, checks upload status, authenticates users, lists Salesforce objects |

> Upstream consumers are tracked in the central architecture model.

## Dependency Health

Health checks are exposed on admin port `8081` via Dropwizard's built-in health check framework (`metricsHealth` component). No evidence of explicit circuit breaker libraries or retry policies beyond Dropwizard defaults. APM is enabled (`apm: enabled: true` in deployment config) for tracing integration health across all environments.
