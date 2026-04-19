---
service: "expy-service"
title: Architecture Context
generated: "2026-03-03T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuum"
  containers: ["continuumExpyService", "continuumExpyMySql"]
---

# Architecture Context

## System Context

Expy Service (`continuumExpyService`) is a container within the **Continuum** platform. It sits between internal Groupon services (which call it for bucketing decisions and feature-flag evaluation) and the external Optimizely ecosystem (CDN, REST API, Data Listener, S3). It owns its own MySQL database (`continuumExpyMySql`) for persisting projects, SDK keys, datafile metadata, feature and experiment configurations, and Quartz job state. Scheduled Quartz jobs refresh datafiles from Optimizely and copy them to a Groupon-owned S3 bucket.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Expy Service | `continuumExpyService` | Service | Java / Dropwizard (JTier) | JTier 5.14.0 | JTier service acting as a centralized interface between Optimizely and Groupon |
| Expy MySQL | `continuumExpyMySql` | Database | MySQL | — | Primary relational database for Expy service data — projects, SDK keys, datafiles, features, experiments, Quartz |

## Components by Container

### Expy Service (`continuumExpyService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| REST Resources (`expyService_apiResources`) | JAX-RS resources that handle all inbound API requests and route them to the service layer | JAX-RS (Dropwizard) |
| Service Layer (`serviceLayer_Exp`) | Business logic and orchestration — bucketing decisions, CRUD operations, error handling | Java |
| Data Access (`expyService_dataAccessLayer`) | JDBI DAOs and entity mappers for all MySQL reads and writes | JDBI |
| External Clients (`expyService_externalClients`) | HTTP clients targeting Optimizely REST API, CDN, and Data Listener | Retrofit / OkHttp |
| Quartz Jobs (`quartzJobs`) | Scheduled jobs — datafile refresh from Optimizely and daily S3 backup copy | Quartz |
| Cache Layer (`expyService_cacheLayer`) | In-memory caches for projects, datafiles, and Birdcage data to reduce external calls | In-memory |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumExpyService` | `continuumExpyMySql` | Reads/writes project, experiment, feature, datafile, and job data | JDBC / JDBI |
| `continuumExpyService` | `optimizelyApiSystem_6c1a` | Calls Optimizely REST API for project and experiment management | REST/HTTPS |
| `continuumExpyService` | `optimizelyCdnSystem_9d42` | Fetches current datafiles from Optimizely CDN | HTTPS |
| `continuumExpyService` | `optimizelyDataListenerSystem_5b7f` | Fetches event datafiles from Optimizely Data Listener | REST/HTTPS |
| `continuumExpyService` | `optimizelyS3Bucket_84a1` | Reads/writes datafiles in Optimizely-owned S3 bucket | AWS S3 SDK |
| `continuumExpyService` | `grouponS3Bucket_7c3d` | Writes datafile copies to Groupon-owned S3 bucket (daily backup) | AWS S3 SDK |
| `continuumExpyService` | `canaryApiSystem_2e31` | Calls Canary API for traffic management integration | REST/HTTPS |
| `expyService_apiResources` | `serviceLayer_Exp` | Routes inbound requests to business logic | Direct (in-process) |
| `serviceLayer_Exp` | `expyService_dataAccessLayer` | Reads/writes persistence layer | Direct (in-process) |
| `serviceLayer_Exp` | `expyService_externalClients` | Calls external Optimizely APIs | Direct (in-process) |
| `serviceLayer_Exp` | `expyService_cacheLayer` | Uses in-memory cache for lookups | Direct (in-process) |
| `quartzJobs` | `serviceLayer_Exp` | Triggers scheduled business logic | Direct (in-process) |
| `quartzJobs` | `expyService_externalClients` | Fetches datafiles from CDN and Data Listener | Direct (in-process) |
| `quartzJobs` | `expyService_dataAccessLayer` | Updates datafile and job state in MySQL | Direct (in-process) |

## Architecture Diagram References

- Container: `containers-continuum`
- Component: `components-continuumExpyService` (view key: `ExpyServiceComponents`)

> No dynamic views are defined in the current architecture model for this service.
