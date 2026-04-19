---
service: "janus-yati"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "gcs-pde-bucket"
    type: "gcs"
    purpose: "Primary Delta Lake storage for Juno/Jupiter tables and canonical event files"
  - id: "gcs-raw-bucket"
    type: "gcs"
    purpose: "Raw Kafka event archive used for replay"
  - id: "gcs-canonicals-bucket"
    type: "gcs"
    purpose: "Canonical muncher-format event files for downstream consumption"
  - id: "gcs-cdp-bucket"
    type: "gcs"
    purpose: "Bloomreach CDP export GCS storage"
  - id: "gcs-operational-bucket"
    type: "gcs"
    purpose: "Spark checkpoints, JAR artifacts, init scripts, temp folders"
  - id: "bigQuery"
    type: "bigquery"
    purpose: "Native Janus event tables (Jovi) and analytics views"
  - id: "hiveWarehouse"
    type: "hive"
    purpose: "Hive Metastore schema registration for Jupiter Delta tables"
  - id: "mysql-reporting"
    type: "mysql"
    purpose: "Business metrics aggregates written by the Business Metrics Exporter"
---

# Data Stores

## Overview

Janus Yati does not own a transactional database. Its storage strategy is built around GCS-backed Delta Lake tables (the authoritative long-term store), BigQuery native tables for SQL analytics, a Hive Metastore for query-engine schema registration, and a MySQL database for business metrics aggregates. GCS is partitioned by event date and region. All writes are append-only or merge-on-read (Delta Lake). The operational GCS bucket holds Spark checkpoints, enabling crash-recovery by resuming from the last committed offset.

## Stores

### GCS PDE Bucket — Delta Lake Primary Store (`gcs-pde-bucket`)

| Property | Value |
|----------|-------|
| Type | gcs (Delta Lake) |
| Architecture ref | `cloudPlatform` |
| Purpose | Stores partitioned Delta Lake tables for Juno (hourly) and Jupiter (append) event datasets; also holds canonical and raw-source event files |
| Ownership | owned |
| Migrations path | Not applicable — schema evolves via `janus_schema_update` DAG |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `gs://grpn-dnd-prod-pipelines-pde/user/grp_gdoop_platform-data-eng/juno/` | Juno hourly Delta Lake table — deduplicated Janus events partitioned by event date | eventDate, eventType, platform, region |
| `gs://grpn-dnd-prod-pipelines-pde/user/grp_gdoop_platform-data-eng/jupiter/` | Jupiter append Delta Lake table — raw Janus events including AB experiments | eventDate, eventType |
| `gs://grpn-dnd-prod-pipelines-pde/kafka/region=na/source=janus-all/` | Canonical muncher-format files (NA region) | region, source, partition date |
| `gs://grpn-dnd-prod-pipelines-pde/kafka/region=na/yati_raw_sources/` | Raw source event files from raw topic ingestion | region, source |

#### Access Patterns

- **Read**: `DeltaLakeCompaction`, `DeltaLakeVacuuming`, and `JunoDeltaLakeDeduplicator` Spark jobs read partitioned Delta tables for maintenance; `HiveSchemaUpdate` reads schema via JDBC
- **Write**: Spark Structured Streaming jobs (`KafkaToFileJobMain`) append micro-batches using Delta merge-on-read; checkpoints written to `gs://prod-us-janus-operational-bucket/yati_checkpoint/` and `yati_juno_checkpoint/`
- **Indexes**: Delta Lake transaction log provides partition pruning by `eventDate`

---

### GCS Raw Bucket (`gcs-raw-bucket`)

| Property | Value |
|----------|-------|
| Type | gcs |
| Architecture ref | `cloudPlatform` |
| Purpose | Archives raw Kafka events verbatim from all source topics; serves as the source for the `janus_replay_raw` recovery flow |
| Ownership | owned |
| Migrations path | Not applicable |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `gs://grpn-dnd-prod-pipelines-yati-raw/kafka/region=na/` | NA raw event archive | region, topic, date |
| `gs://grpn-dnd-prod-pipelines-yati-raw/kafka/region=intl/` | EMEA raw event archive | region, topic, date |

#### Access Patterns

- **Read**: `ReplayMain` Spark job reads raw files by date range for replay operations
- **Write**: `KafkaToFileJobMain` with `outputFormat=muncher-format-for-raw-sources` appends raw topic data

---

### GCS Canonicals Bucket (`gcs-canonicals-bucket`)

| Property | Value |
|----------|-------|
| Type | gcs |
| Architecture ref | `cloudPlatform` |
| Purpose | Stores canonical muncher-format event files for downstream ETL consumers |
| Ownership | owned |
| Migrations path | Not applicable |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `gs://grpn-dnd-prod-pipelines-yati-canonicals/kafka/region=na/source=janus-all/` | Canonical NA events | region, source |
| `gs://grpn-dnd-prod-pipelines-yati-canonicals/kafka/region=intl/source=gcs-janus-replay/` | Canonical EMEA replay events | region, source |

---

### GCS CDP Export Bucket (`gcs-cdp-bucket`)

| Property | Value |
|----------|-------|
| Type | gcs |
| Architecture ref | `cloudPlatform` |
| Purpose | Bloomreach CDP segmented export files partitioned by region, campaign, and event type |
| Ownership | owned |
| Migrations path | Not applicable |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `gs://grpn-dnd-prod-pipelines-cdp-nonsox/bloomreach-export/region=na/campaign=mobile-notification/` | NA push notification exports | region, campaign |
| `gs://grpn-dnd-prod-pipelines-cdp-nonsox/bloomreach-export/region=intl/event=ab-experiment/` | EMEA AB experiment exports | region, event |

---

### GCS Operational Bucket (`gcs-operational-bucket`)

| Property | Value |
|----------|-------|
| Type | gcs |
| Architecture ref | `cloudPlatform` |
| Purpose | Spark streaming checkpoints, JAR artifacts, Dataproc init scripts, temporary GCS folders for BigQuery indirect loads |
| Ownership | owned |
| Migrations path | Not applicable |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `gs://prod-us-janus-operational-bucket/yati_checkpoint/` | Kafka offset checkpoints for NA/EMEA streaming jobs | region, source |
| `gs://prod-us-janus-operational-bucket/yati_juno_checkpoint/` | Kafka offset checkpoints for Juno/Jupiter jobs | region, source |
| `gs://prod-us-janus-operational-bucket/jar/` | Versioned JAR artifacts deployed to Dataproc | artifact version |
| `gs://prod-us-janus-operational-bucket/initscript.sh` | Dataproc cluster initialisation script | — |
| `gs://prod-us-janus-operational-bucket/yati_jovi_temporary_gcs_folder/` | Temporary staging for BigQuery indirect loads | — |

---

### BigQuery — Janus Dataset (`bigQuery`)

| Property | Value |
|----------|-------|
| Type | bigquery |
| Architecture ref | `bigQuery` |
| Purpose | Native BigQuery tables for the Janus analytics dataset; schema auto-updated by `BigQuerySchemaUpdate`; views created by `BigQueryViewCreate` |
| Ownership | shared (project `prj-grp-datalake-prod-8a19`, dataset `janus`) |
| Migrations path | `src/main/resources/db/V1_create_jovi_bq_native_table_prod.sql` |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `janus.jovi` | Native BigQuery table receiving Janus events via indirect GCS load (Jovi sink) | eventType, eventDate |
| `janus.junoHourly` | BigLake external table over Juno hourly GCS Delta path, connection `prj-grp-datalake-prod-8a19.us-central1.janus_biglake` | eventDate, eventType, platform |
| `janus.jupiter` | BigLake external table over Jupiter GCS Delta path | eventDate, eventType |
| `janus.janusAll` | Aggregate view / table over full Janus event history | — |
| `janus.v_pageView`, `janus.v_click`, `janus.v_order`, `janus.v_deal`, etc. | Thematic BigQuery views (21+ views) created by `BigQueryViewCreate`; 7-day rolling window | events list, platforms, lastDays |

#### Access Patterns

- **Read**: Analytics consumers via BigQuery SQL; Hive gateway via JDBC at `analytics.data-comp.prod.gcp.groupondev.com:8443`
- **Write**: `janusBigQuerySink` indirect load (stage to GCS then load); `BigQuerySchemaUpdate` schema evolution; `BigQueryViewCreate` DDL

---

### Hive Metastore (`hiveWarehouse`)

| Property | Value |
|----------|-------|
| Type | hive |
| Architecture ref | `hiveWarehouse` |
| Purpose | Hive schema registration for Jupiter Delta table enabling analytics query engines to discover table structure |
| Ownership | shared |
| Migrations path | Managed by `HiveSchemaUpdate` Spark job |

#### Access Patterns

- **Read**: Analytics Hive gateway (`analytics.data-comp.prod.gcp.groupondev.com:8443`)
- **Write**: `HiveSchemaUpdate` Spark job updates schema via Hive JDBC (`jdbc:hive2://analytics.data-comp.prod.gcp.groupondev.com:8443/default;ssl=true`)

---

### MySQL Reporting Database (`mysql-reporting`)

| Property | Value |
|----------|-------|
| Type | mysql |
| Architecture ref | stub — not in central model |
| Purpose | Business metrics aggregates written by the Janus Business Metrics Exporter |
| Ownership | shared (janus-web-cloud RW instance) |
| Migrations path | Not applicable — schema owned by janus-web-cloud |

#### Access Patterns

- **Write**: `janusBusinessMetricsExporter` Spark job writes via JDBC to `jdbc:mysql://janus-web-cloud-rw-na-production-db.gds.prod.gcp.groupondev.com:3306/janus`

---

## Caches

> No evidence found in codebase.

Janus Yati does not use any caching layer.

## Data Flows

Events flow through several stages:

1. **Raw ingestion**: Kafka topics land in GCS raw bucket (`yati-raw`) as verbatim event archives
2. **Canonical processing**: `janus-all` and raw-source topics are processed into canonical muncher-format files in the PDE and canonicals buckets
3. **Delta Lake materialisation**: `janus-all` events are written into Juno (hourly, deduplicated) and Jupiter (append) Delta tables in the PDE bucket
4. **BigQuery load**: Jovi sink writes a subset of `janus-all` events into the `janus.jovi` native BigQuery table via GCS staging
5. **Schema sync**: The schema update job reads the Janus metadata API and synchronises BigQuery external table schemas and Hive Metastore schemas
6. **Analytics views**: BigQuery views are rebuilt twice daily from the current Juno/Jupiter table schemas
7. **Maintenance**: Compaction and vacuuming jobs periodically optimise the Delta tables; deduplication runs daily on the Juno table
8. **Replay recovery**: When events are missing or corrupted, `janus_replay_raw` reads the raw bucket and republishes to `janus-cloud-replay-raw` Kafka topic, which is re-consumed by canonical ingestion jobs
