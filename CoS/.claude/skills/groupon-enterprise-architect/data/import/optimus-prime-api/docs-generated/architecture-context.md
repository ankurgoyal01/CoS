---
service: "optimus-prime-api"
title: Architecture Context
generated: "2026-03-03T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: [continuumOptimusPrimeApi, continuumOptimusPrimeApiDb, continuumOptimusPrimeGcsBucket, continuumOptimusPrimeS3Storage]
---

# Architecture Context

## System Context

Optimus Prime API sits within the `continuumSystem` as the orchestration hub for Groupon's ETL pipeline platform. Data engineers and analysts interact with it via REST to define jobs, manage connections, and monitor runs. The service delegates actual data workflow execution to Apache NiFi (`continuumOptimusPrimeNifi`) and persists all state — job definitions, run history, users, groups, and connections — in its dedicated PostgreSQL database (`continuumOptimusPrimeApiDb`). It integrates with Active Directory for identity and access, with cloud storage systems (GCS, S3) for file ingress/egress, with SFTP endpoints for file delivery, and with data warehouses (Hive, BigQuery) for data movement coordination.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Optimus Prime API | `continuumOptimusPrimeApi` | Service | Java 17, Dropwizard (JTier) | 5.14.0 | Dropwizard-based API managing ETL job definitions, scheduling, orchestration, and run status updates |
| Optimus Prime Postgres DB | `continuumOptimusPrimeApiDb` | Database | PostgreSQL | — | Operational relational datastore for users, groups, connections, jobs, and run history |
| Optimus Prime GCS Bucket | `continuumOptimusPrimeGcsBucket` | Storage | Google Cloud Storage | 2.26.1 | Cloud Storage bucket for Optimus Prime file ingress/egress |
| Optimus Prime S3 Storage | `continuumOptimusPrimeS3Storage` | Storage | Amazon S3 | AWS SDK 2.17.174 | S3 buckets used by Optimus Prime job steps |

## Components by Container

### Optimus Prime API (`continuumOptimusPrimeApi`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `apiEndpoints` | JAX-RS resources exposing v2 endpoints for jobs, runs, groups, users, storage, and metadata | Jersey Resources |
| `orchestrationEngine` | Application services coordinating validation, scheduling, migrations, and job-run lifecycle | Service Layer |
| `opApi_persistenceLayer` | JDBI DAOs and Flyway migrations for application state in PostgreSQL | JDBI/PostgreSQL |
| `nifiIntegration` | Clients and service logic for NiFi process group and processor lifecycle management | NiFi REST Client |
| `authDirectoryAdapter` | LDAP-backed user lookup and authentication support | LDAP Client |
| `notificationAdapter` | Email delivery integration for reports and alerts | SMTP Client |
| `storageAdapter` | Storage integrations for ETL workflows (GCS, S3, SFTP) | Storage Connectors |
| `metadataAdapter` | Google Sheets and analytics metadata retrieval services | Google Sheets Client |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumOptimusPrimeApi` | `continuumOptimusPrimeApiDb` | Reads and writes application state | JDBC/SQL |
| `continuumOptimusPrimeApi` | `continuumOptimusPrimeNifi` | Orchestrates job execution via NiFi | REST / HTTP |
| `continuumOptimusPrimeApi` | `activeDirectory` | Authenticates and resolves users | LDAP |
| `continuumOptimusPrimeApi` | `smtpRelay` | Sends reports and operational alerts | SMTP |
| `continuumOptimusPrimeApi` | `googleSheetsApi` | Reads spreadsheet metadata | REST / HTTPS |
| `continuumOptimusPrimeApi` | `continuumOptimusPrimeGcsBucket` | Manages file ingestion and exports | GCS SDK |
| `continuumOptimusPrimeApi` | `continuumOptimusPrimeS3Storage` | Manages file ingestion and exports | AWS SDK |
| `continuumOptimusPrimeApi` | `cloudPlatform` | Transfers files to configured SFTP endpoints | SFTP |
| `continuumOptimusPrimeApi` | `hiveWarehouse` | Coordinates Hive data movement steps | JDBC/Hive |
| `continuumOptimusPrimeApi` | `bigQueryWarehouse` | Coordinates BigQuery data movement steps | BigQuery API |

> All relationships except those to owned containers (`continuumOptimusPrimeApiDb`, `continuumOptimusPrimeGcsBucket`, `continuumOptimusPrimeS3Storage`) reference external systems defined as stubs in the federated model.

## Architecture Diagram References

- System context: `contexts-optimus-prime-api`
- Container: `containers-optimus-prime-api`
- Component: `components-continuumOptimusPrimeApi`
- Dynamic view: `dynamic-job-run-orchestration` (defined in `architecture/views/dynamics/job-run-orchestration.dsl`)
