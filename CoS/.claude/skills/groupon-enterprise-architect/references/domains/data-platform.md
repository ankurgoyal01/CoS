# Data Platform & Discovery

## Overview

The Data Platform domain is represented in the Structurizr architecture model as the domain view `containers-continuum-platform-data-analytics` with 31 elements. It encompasses data warehousing, ETL pipelines, real-time streaming, pipeline orchestration, and analytics tooling. The domain sits within the Continuum platform (ID:297) and serves as the data backbone for all Groupon platforms — Continuum, Encore, and MBNXT all consume its outputs.

The tribe is organized under the Data & Discovery (DD) Confluence space and operates 5 specialized squads covering infrastructure, ingestion, pipeline reliability, and tooling.

## Tribe Structure (5 Squads)

| Squad | Responsibility | Key Services / Technologies |
|-------|---------------|-----------------------------|
| **DnD Infrastructure** | GCP infrastructure provisioning and management for all data stores | Teradata, Keboola infrastructure, BigQuery, Bigtable, Data Lake, Dataproc, GCP Hadoop Infrastructure |
| **DnD Janus** | Foundational data ingestion pipeline — transforms raw events into canonical datasets | Janus Engine, Janus Yati, Janus Muncher, Watson Realtime, Watson API, Ask Janus AI |
| **DnD Ingestion** | Database source ingestion via CDC from operational databases | Megatron (CDC to Teradata/Hadoop from MySQL, PostgreSQL, RDS, CloudSQL), Magneto (Salesforce ingestion), GCP Datastream |
| **DnD PRE** | Platform Reliability Engineering — 24/7 pipeline operations and monitoring | Airflow (Cloud Composer), Zombie Runner, CKOD, PRE Observability dashboards |
| **DnD Tools** | Analytics and experimentation tooling for data consumers | Tableau, Data Catalog V2 (OpenMetadata), Optimus Prime ETL, Expy A/B testing service |

## Key Technologies

### Active Systems

| Technology | Role | Details |
|------------|------|---------|
| **BigQuery** | Cloud data warehouse (target) | GCP-native, replacing Teradata as primary warehouse. 2026 migration initiative. Cross-platform view available: `contexts-data-bigquery` |
| **Keboola** | Cloud ETL platform | Replacing legacy ETL pipelines. Used by AdsOnGroupon and other teams for data transformation workflows |
| **Kafka** | Real-time event streaming | Running on AWS via Strimzi/Conveyor. Migrating from Amazon MSK. Janus Tier1 Topic (ID:361) is the primary Kafka topic in the architecture model |
| **Apache Airflow** | Pipeline orchestration | Deployed as Cloud Composer (GCP managed). Multi-tenant — serves all squads. Operated by DnD PRE squad 24/7 |
| **OpenMetadata** | Data catalog v2 | Replaces legacy catalog. Provides data discovery, lineage, and governance metadata |
| **Bigtable** | Real-time audience store | Realtime Audience Bigtable (ID:360). Used for audience targeting and real-time lookups |
| **ElasticSearch** | Search and analytics | ElasticSearch Cluster (ID:346). Powers search indexing and log analytics |

### Migration: Teradata to BigQuery

The dominant infrastructure initiative for 2026 is the migration from Teradata EDW (ID:299, tagged `ToDecommission`) to BigQuery. Teradata currently serves as the primary data warehouse for financial systems (JLA sources daily from Teradata), reporting, and analytics. The migration impacts:

- Financial Data Engine (FDE) and Journal Ledger Accounting (JLA) pipelines
- AdsOnGroupon reporting (migrating ads-jobframework Scala/Spark jobs to Keboola)
- Megatron CDC pipelines (DnD Ingestion squad)
- All downstream Tableau dashboards and reports

## Infrastructure Containers

Key data infrastructure containers registered in the architecture model:

| Container | ID | Type | Notes |
|-----------|----|------|-------|
| Hive Warehouse | 357 | Data Store | Hadoop-based warehouse for batch analytics |
| HDFS | 358 | Data Store | Distributed filesystem backing Hive and Spark jobs |
| Cassandra Audience Cluster | 359 | Data Store | Audience segmentation and targeting data |
| Realtime Audience Bigtable | 360 | Data Store | GCP Bigtable for real-time audience lookups |
| ElasticSearch Cluster | 346 | Data Store | Search indexing and log analytics |
| Janus Tier1 Topic | 361 | Messaging | Primary Kafka topic for event ingestion |
| Message Bus | 300 | Messaging | ActiveMQ Artemis — used by commerce services, also consumed by data pipelines |

## Decommission Targets

| Element | ID | Type | Replacement |
|---------|----|------|-------------|
| EDW - Teradata | 299 | Container | BigQuery (2026 migration) |
| OptimusPrime Analytics | 91 | System | Being replaced — Expy and Keboola absorbing its functions |

OptimusPrime is listed under the DnD Tools squad as an active ETL tool but is tagged `ToDecommission` at the system level in the architecture model. Its ETL workloads are migrating to Keboola, while its experimentation features are being absorbed by the Expy service.

## Integration Points

The data platform integrates with other Continuum domains through:

- **Commerce/Inventory services** export data via EDW Exporter components (e.g., VIS EDW Exporter, ID:576, sends daily batch ETL to S3 then to Teradata/BigQuery)
- **ActiveMQ Message Bus** (ID:300) carries commerce events consumed by Janus for real-time ingestion
- **Kafka** (Janus Tier1 Topic, ID:361) provides the real-time event backbone
- **Encore Platform** accesses data via BigQuery Wrapper (ID:7663) for B2B reporting and analytics

## Source Links

| Document | Space | Link |
|----------|-------|------|
| DnD Tribe Structure | DD | [View](https://groupondev.atlassian.net/wiki/spaces/DD/pages/82524864515/DnD+-+Data+Platform+and+Discovery+Tribe+structure) |
| Data Platform Architecture | DD | [View](https://groupondev.atlassian.net/wiki/spaces/DD/pages/81905352726/Data+Platform+Architecture) |
| Data Platform Architecture KTs | DD | [View](https://groupondev.atlassian.net/wiki/spaces/DD/pages/81862656028/Data+Platform+Architecture+KTs) |
| Groupon Architecture Next (C4 Model) | ARCH | [View](https://groupondev.atlassian.net/wiki/spaces/ARCH/pages/82195873828/Groupon+Architecture+Next) |
| Continuum Containers | ARCH | [View](https://groupondev.atlassian.net/wiki/spaces/ARCH/pages/82198331428/Continuum) |
