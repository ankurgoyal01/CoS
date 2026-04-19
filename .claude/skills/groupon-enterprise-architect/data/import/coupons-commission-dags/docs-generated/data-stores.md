---
service: "coupons-commission-dags"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "gcpDataprocMetastore"
    type: "dataproc-metastore"
    purpose: "Hive-compatible metadata service used by Spark jobs during execution"
---

# Data Stores

## Overview

coupons-commission-dags itself does not own any data stores. The DAGs provision ephemeral Dataproc clusters that connect to GCP Dataproc Metastore for Hive metadata during Spark job execution. The Spark jobs (running as submitted JAR artifacts) perform all data reads and writes; the DAGs only manage the compute cluster lifecycle and job submission. Data persistence and storage strategy are owned by the Spark job implementations, not by these DAGs.

## Stores

### GCP Dataproc Metastore (`gcpDataprocMetastore`)

| Property | Value |
|----------|-------|
| Type | dataproc-metastore (Hive-compatible managed service) |
| Architecture ref | `gcpDataprocMetastore` |
| Purpose | Hive metadata service used by Spark jobs running on ephemeral Dataproc clusters |
| Ownership | external — managed by GCP; shared across Dataproc workloads |
| Migrations path | Not applicable |

#### Key Entities

> No evidence found in codebase. Table and entity definitions are managed within the Spark job implementations, not within these DAGs.

#### Access Patterns

- **Read**: Dataproc clusters read Hive table metadata during Spark job planning
- **Write**: Spark jobs write processed commission data back through the Hive metastore layer
- **Indexes**: No evidence found in codebase

**Prod metastore**: `projects/prj-grp-datalake-prod-8a19/locations/us-central1/services/grpn-dpms-prod-analytics`
**Stable metastore**: `projects/prj-grp-datalake-stable-dcf6/locations/us-central1/services/grpn-dpms-stable-analytics`
**Dev metastore**: `projects/prj-grp-datalake-dev-8876/locations/us-central1/services/grpn-dpms-dev-analytics`

## Caches

> Not applicable. No caching layer is used by these DAGs.

## Data Flows

Each DAG stage operates on data in sequence:

1. **Sourcing** — The sourcing Spark job (`SourcingMainJob`) ingests raw commission data for the configured affiliate accounts covering the specified date range and writes it to a GCP-backed storage layer accessible via the Dataproc Metastore.
2. **Transformation** — The transformation Spark job (`DataTransformationJob`) reads sourced data, applies business logic transformations, and writes normalized commission records.
3. **Aggregation** — The aggregation Spark job (`DataAggregationJob`) reads transformed records and produces rolled-up commission summary outputs.

> The exact storage locations (GCS buckets, Hive tables) are defined within the Spark JAR implementations, not in these DAGs.
