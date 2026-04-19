---
service: "larc"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: [continuumTravelLarcService, continuumTravelLarcDatabase]
---

# Architecture Context

## System Context

LARC lives within the **Continuum** system — Groupon's travel commerce platform. It acts as a pricing bridge between the third-party market data provider (QL2) and Groupon's Travel Inventory Service. The service ingests raw hotel pricing feeds delivered by QL2 over SFTP, computes the lowest available nightly rate for each deal option, and writes those rates back to the inventory layer. Internal Groupon tools (eTorch, extranet app) call the LARC API to manage hotel-to-QL2 mappings and trigger on-demand rate recalculations.

## Containers

| Container | ID | Type | Technology | Description |
|-----------|----|------|-----------|-------------|
| Lowest Available Rate Calculator (LARC) | `continuumTravelLarcService` | Service | Java 11, Dropwizard | Travel service that ingests QL2 files, computes lowest available rates, and publishes rate updates |
| LARC Database | `continuumTravelLarcDatabase` | Database | MySQL | Primary MySQL datastore for ingestion jobs, hotel mappings, and calculated nightly rates |

## Components by Container

### Lowest Available Rate Calculator (`continuumTravelLarcService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| API Resources (`larcApiResources`) | Exposes Dropwizard REST resources for jobs, hotels, rates, and approved discount percentages | JAX-RS Resources |
| Worker Schedulers (`larcWorkerSchedulers`) | Runs background schedulers for FTP monitoring, CSV file download, live pricing alerting, and nightly LAR archiving | Scheduled workers / threads |
| Rate Computation Services (`larcRateComputation`) | Parses QL2 feed data, maps rate descriptions to room types, calculates LAR values, orchestrates rate updates to inventory | Service layer |
| Persistence Layer (`larcDataAccess`) | JDBI connectors and row mappers for ingestion jobs, nightly LARs, hotels, rate descriptions, and archive tables | JDBI + MySQL |
| External Service Clients (`larcExternalClients`) | HTTP clients (Retrofit/OkHttp) for Inventory Service and Content Service; FTP/SFTP clients for QL2 feed downloads | Retrofit + FTP/SFTP (JSch, Apache Commons Net) |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumTravelLarcService` | `continuumTravelLarcDatabase` | Reads and writes ingestion jobs, rate mappings, and archived rate records | JDBC/MySQL |
| `continuumTravelLarcService` | `continuumTravelInventoryService` | Reads inventory metadata and writes QL2/GRPN rate updates | HTTP/JSON |
| `continuumTravelLarcService` | `continuumDealCatalogService` | Fetches product set and rate-plan metadata for ingestion | HTTP/JSON |
| `continuumTravelLarcService` | `thirdPartyInventory` | Downloads partner QL2 feed files for price ingestion | SFTP/CSV |
| `continuumTravelLarcService` | `metricsStack` | Emits service metrics and operational telemetry | Metrics/HTTP |

## Architecture Diagram References

- Component diagram: `components-larc-service`
- Dynamic rate update flow: `dynamic-larc-rate-update-flow`
