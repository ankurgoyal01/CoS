---
service: "mds-feed-api"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: [continuumMdsFeedApi, continuumMdsFeedApiPostgres]
---

# Architecture Context

## System Context

The Marketing Feed Service (`continuumMdsFeedApi`) is a backend microservice within the Continuum Platform (`continuumSystem`). It sits at the intersection of Groupon's commerce data pipeline and external marketing partner integrations. Operations teams and the companion Spark job interact with it via REST. The service reads deal data artifacts from GCS/BigQuery (produced by upstream data pipelines), manages all feed metadata in its own PostgreSQL store, and pushes generated feed files to external marketing partners via S3, SFTP/FTP, or GCP upload destinations.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| MDS Feed API | `continuumMdsFeedApi` | Backend service | Java, Dropwizard (JTier) | 11 / 5.14.1 | REST service that manages feed definitions, schedules feed generation, tracks batch status, and orchestrates feed uploads |
| MDS Feed API Postgres | `continuumMdsFeedApiPostgres` | Database | PostgreSQL | - | Transactional datastore for feed definitions, schedules, batches, upload profiles, and metrics |

## Components by Container

### MDS Feed API (`continuumMdsFeedApi`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Feed API Resource Layer | HTTP resource endpoints for feeds, groups, schedules, uploads, metrics, and dispatch operations | JAX-RS Resources |
| Feed Orchestration Service | Domain workflows for feed configuration lifecycle, schedule management, and feed generation coordination | Service Layer |
| Upload Orchestration Service | Upload/download orchestration across S3, SFTP/FTP, and GCP storage profiles | Service Layer |
| Persistence Gateway | DAO and mapper layer for transactional persistence and retrieval operations | JDBI DAOs |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumMdsFeedApi` | `continuumMdsFeedApiPostgres` | Reads and writes feed metadata, schedules, batches, and metrics | JDBI/PostgreSQL |
| `continuumMdsFeedApi` | `messageBus` | Publishes feed generation and status events | JMS/Mbus (`mds-feed-publishing` destination) |
| `continuumMdsFeedApi` | `bigQuery` | Coordinates feed artifact generation and retrieval in shared analytics storage | GCS/BigQuery APIs |
| `mdsFeedApi_resourceLayer` | `mdsFeedApi_orchestration` | Invokes feed/schedule orchestration workflows | Direct (in-process) |
| `mdsFeedApi_resourceLayer` | `mdsFeedApi_uploadOrchestration` | Invokes upload and dispatch workflows | Direct (in-process) |
| `mdsFeedApi_orchestration` | `mdsFeedApi_persistence` | Reads/writes feed, batch, and schedule records | Direct (in-process) |
| `mdsFeedApi_uploadOrchestration` | `mdsFeedApi_persistence` | Reads upload profiles and records upload batch outcomes | Direct (in-process) |

## Architecture Diagram References

- System context: `contexts-continuumMdsFeedApi`
- Container: `containers-continuumMdsFeedApi`
- Component: `components-continuum-mds-feed-api-components`
