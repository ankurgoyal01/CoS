---
service: "transporter-jtier"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers:
    - continuumTransporterJtierService
    - continuumTransporterMysqlDatabase
    - continuumTransporterRedisCache
---

# Architecture Context

## System Context

Transporter JTier is a container within the `continuumSystem` (Continuum Platform). It sits behind the Transporter ITier frontend, acting as the authoritative backend for Salesforce bulk upload workflows. Requests arrive from `transporter-itier` over HTTP/REST. The service communicates outbound to Salesforce via OAuth2/REST, to AWS S3 via the AWS SDK for reading input files, and to GCS via the Google Cloud Storage SDK for writing result files. All job state is persisted in an owned MySQL database; Salesforce OAuth tokens are cached in an owned Redis instance.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Transporter JTier Service | `continuumTransporterJtierService` | Backend API + Worker | Java 11, Dropwizard | jtier-service-pom 5.14.0 | Dropwizard service that handles user requests, manages Salesforce uploads, and coordinates storage and token workflows |
| Transporter MySQL | `continuumTransporterMysqlDatabase` | Database | MySQL | 5.7 | Stores upload jobs, user records, and Salesforce upload metadata |
| Transporter Redis | `continuumTransporterRedisCache` | Cache | Redis | latest | Caches Salesforce user tokens and session data |

## Components by Container

### Transporter JTier Service (`continuumTransporterJtierService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Transporter API Resource (`transporterJtier_apiResource`) | JAX-RS resource handling user token, upload, and Salesforce object endpoints | JAX-RS |
| Upload Orchestration (`uploadOrchestration`) | Validates user input, persists upload metadata, and coordinates Salesforce uploads | Service |
| User Token Service (`userTokenService`) | Manages Salesforce OAuth token validation and refresh | Service |
| Salesforce Access Client (`salesforceAccess`) | Handles OAuth2 and Salesforce API calls | HTTP Client (SalesforceHttpClient 1.15) |
| Cloud Storage Clients (`storageClients`) | Reads and writes user input and result files in object storage | AWS SDK v2 / GCS SDK |
| Upload Worker (`uploadWorker`) | Processes upload jobs, executes Salesforce operations, and persists results | Quartz Job |
| User Service (`userService_TraJti`) | Persists and retrieves user records for upload flows | JDBI Service |
| Upload Persistence (`persistence`) | JDBI persistence for upload and job metadata | JDBI |
| Health and Metrics (`metricsHealth`) | Health checks and service metrics | Dropwizard Health |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumTransporterJtierService` | `continuumTransporterMysqlDatabase` | Reads and writes upload and user data | JDBI/MySQL |
| `continuumTransporterJtierService` | `continuumTransporterRedisCache` | Caches Salesforce user tokens | Redis |
| `continuumTransporterJtierService` | `salesforceSystem` | Authenticates and performs Salesforce data operations | OAuth2/REST |
| `continuumTransporterJtierService` | `awsS3ObjectStorage` | Reads and writes user input files | S3 (AWS SDK v2) |
| `continuumTransporterJtierService` | `gcsObjectStorage` | Writes upload result files and generates signed URLs | GCS SDK |
| `transporterJtier_apiResource` | `uploadOrchestration` | Submits upload requests and queries status | direct |
| `transporterJtier_apiResource` | `userTokenService` | Validates Salesforce user tokens | direct |
| `transporterJtier_apiResource` | `userService_TraJti` | Reads user metadata for requests | direct |
| `uploadOrchestration` | `persistence` | Reads and writes upload records | JDBI |
| `uploadOrchestration` | `storageClients` | Stores user input and result files | AWS SDK / GCS SDK |
| `uploadOrchestration` | `salesforceAccess` | Calls Salesforce APIs for uploads | HTTP |
| `uploadWorker` | `persistence` | Reads and updates upload job state | JDBI |
| `uploadWorker` | `storageClients` | Fetches inputs and writes results | AWS SDK / GCS SDK |
| `uploadWorker` | `salesforceAccess` | Executes Salesforce operations | HTTP |
| `userTokenService` | `salesforceAccess` | Exchanges and refreshes OAuth tokens | HTTP |
| `userService_TraJti` | `persistence` | Uses JDBI to manage user records | JDBI |

## Architecture Diagram References

- System context: `contexts-continuumSystem`
- Container: `containers-continuumSystem`
- Component: `components-transporter_jtier_components`
