---
service: "ad-inventory"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumAdInventoryService"
  containers:
    - "continuumAdInventoryService"
    - "continuumAdInventoryMySQL"
    - "continuumAdInventoryRedis"
    - "continuumAdInventoryHive"
    - "continuumAdInventoryGcs"
---

# Architecture Context

## System Context

Ad Inventory sits within the **Continuum** platform as a Criticality Tier 2 advertising backend. It is the sole Groupon-internal service responsible for bridging ad placement requests from Groupon frontend pages with external ad networks (Google Ad Manager, LiveIntent, Rokt, CitrusAd) and for managing the data pipelines that bring ad performance reports into Hive for analytics. It depends on Groupon's Audience Management Service (AMS) to validate audience definitions, on DaaS::MySQL for primary persistence, and on GCS for file staging.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Ad Inventory Service | `continuumAdInventoryService` | Backend | Java 17, Dropwizard/JTier | 5.14.1 | Core application: handles ad placement serving, audience management, sponsored click tracking, and scheduled report orchestration |
| Ad Inventory MySQL | `continuumAdInventoryMySQL` | Database | MySQL (DaaS) | — | Primary relational store for audiences, placements, reports, metrics, and job metadata via JDBI DAOs |
| Ad Inventory Redis | `continuumAdInventoryRedis` | Cache | Redis (via Redisson 3.16.0) | — | Cache layer for audience membership and ad content lookups |
| Ad Inventory Hive Warehouse | `continuumAdInventoryHive` | Data Warehouse | Hive on Hadoop | — | Hive warehouse used to materialize and query downloaded ad performance reports |
| Ad Inventory GCS Bucket | `continuumAdInventoryGcs` | Object Storage | Google Cloud Storage | — | GCS bucket holding bloom filters and staged report CSVs for validation and Hive load |

## Components by Container

### Ad Inventory Service (`continuumAdInventoryService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `continuumAdInventoryService_aiAudienceResource` | JAX-RS endpoints to create, fetch, and delete audience definitions; validates against AMS and manages bloom filters | JAX-RS |
| `continuumAdInventoryService_adInventoryPlacementResource` | JAX-RS endpoints serving ad placements and capturing sponsored listing clicks, with audience eligibility checks and metrics emission | JAX-RS |
| `continuumAdInventoryService_adInventoryAdminResource` | Admin-only endpoints to refresh caches and reset configuration | JAX-RS |
| `continuumAdInventoryService_aiReportingResource` | JAX-RS endpoints to create, update, backfill, trigger, and delete scheduled reports | JAX-RS |
| `continuumAdInventoryService_schedulerApi` | Wrapper over Quartz scheduler enabling creation, triggering, pausing, resuming, and deleting report jobs | Quartz |
| `continuumAdInventoryService_audienceApi` | In-memory audience eligibility resolver backed by caches | Java |
| `continuumAdInventoryService_abstractAudienceService` | DAO-backed audience CRUD and targeting persistence, including bloom filter metadata | JDBI |
| `continuumAdInventoryService_reportsRepository` | DAO-backed report metadata, history, and job state management for scheduled and backfill runs | JDBI |
| `continuumAdInventoryService_sponsoredListingService` | Persists sponsored click events and forwards them to CitrusAd; emits SMA metrics | Service |
| `continuumAdInventoryService_dfpReportDownloaderTask` | Quartz task polling Google Ad Manager for report readiness and staging CSVs to GCS | Batch |
| `continuumAdInventoryService_reportValidationTask` | Validates downloaded report CSVs against schema, uploads validated files to GCS, and cleans staging artifacts | Batch |
| `continuumAdInventoryService_hiveReportTableCreatorTask` | Creates Hive tables and loads validated report CSVs into the warehouse | Batch |
| `continuumAdInventoryService_liveIntentReportTask` | Transforms LiveIntent report payloads into Hive tables/partitions for analytics | Batch |
| `continuumAdInventoryService_s3FileDownloaderTask` | Downloads Rokt CSVs from S3, normalizes them, and uploads to GCS for downstream processing | Batch |
| `continuumAdInventoryService_gcpClient` | Uploads, downloads, and deletes files in GCS for bloom filters and report staging | GCS SDK |
| `continuumAdInventoryService_amsClient` | Fetches authoritative audience details from the AMS service | HTTP Client |
| `continuumAdInventoryService_emailer` | Sends report lifecycle and alert notifications | SMTP |
| `continuumAdInventoryService_smaMetricsLogger` | Submits custom metrics to SMA for placements and click counts | Metrics SDK |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumAdInventoryService` | `continuumAdInventoryMySQL` | Persists audiences, targets, reports, and click events | JDBI/MySQL |
| `continuumAdInventoryService` | `continuumAdInventoryRedis` | Caches audiences and ad content for fast eligibility checks | Redis (Redisson) |
| `continuumAdInventoryService` | `continuumAdInventoryHive` | Loads and queries analytical report tables | Hive JDBC |
| `continuumAdInventoryService` | `continuumAdInventoryGcs` | Stages bloom filters and report CSV files | GCS SDK |
| `continuumAdInventoryService` | `continuumAudienceManagementService` | Retrieves audience details for validation | HTTP |
| `continuumAdInventoryService` | `googleAdManager` | Runs and downloads DFP inventory reports | HTTP/SOAP |
| `continuumAdInventoryService` | `liveIntent` | Consumes LiveIntent reporting feeds | HTTP |
| `continuumAdInventoryService` | `rokt` | Ingests Rokt report CSVs | S3 |
| `continuumAdInventoryService` | `continuumSmaMetrics` | Submits placement and click metrics | HTTP |
| `continuumAdInventoryService` | `continuumEmailService` | Sends report lifecycle notifications | SMTP |
| `continuumAdInventoryService_aiAudienceResource` | `continuumAdInventoryService_amsClient` | Fetch audience details for validation | HTTP |
| `continuumAdInventoryService_adInventoryPlacementResource` | `continuumAdInventoryService_audienceApi` | Resolve eligible audiences for placements | In-memory cache |
| `continuumAdInventoryService_schedulerApi` | `continuumAdInventoryService_dfpReportDownloaderTask` | Triggers DFP report download job | Quartz |
| `continuumAdInventoryService_dfpReportDownloaderTask` | `googleAdManager` | Poll and download DFP reports | HTTP |
| `continuumAdInventoryService_hiveReportTableCreatorTask` | `continuumAdInventoryHive` | Create and load Hive tables from validated CSVs | Hive SQL |
| `continuumAdInventoryService_s3FileDownloaderTask` | `rokt` | Download Rokt CSVs | S3 |

## Architecture Diagram References

- System context: `contexts-continuum-ad-inventory`
- Container: `containers-continuum-ad-inventory`
- Component: `components-continuum-ad-inventory-service-components`
- Dynamic view: `dynamic-ad-inventory-reporting-ingestion-flow`
