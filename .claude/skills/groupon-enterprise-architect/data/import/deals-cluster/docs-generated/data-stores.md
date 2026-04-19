---
service: "deals-cluster"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "dealsClusterPostgres_4d6e"
    type: "postgresql"
    purpose: "Primary output store for cluster and top-cluster data served by the Deals Cluster API"
  - id: "dealsClusterHdfs_7a11"
    type: "hdfs"
    purpose: "Partitioned HDFS output store for cluster data consumed by TopClustersJob and analytics"
  - id: "mdsHdfs_3b2a"
    type: "hdfs"
    purpose: "Input — MDS deal flat files read by DealsClusterJob"
  - id: "edwProdDatabase_9c1f"
    type: "hive"
    purpose: "Input — EDW aggregated traffic and finance data enriching deal clusters"
---

# Data Stores

## Overview

Deals Cluster reads from two upstream data stores (MDS HDFS flat files and the EDW Hive table) and writes to two output stores (PostgreSQL DaaS and HDFS with Hive metadata). The PostgreSQL store is the primary serving store consumed by the Deals Cluster API. The HDFS store is used as input to the `TopClustersJob` and for analytics queries.

## Stores

### Deals Cluster PostgreSQL (`dealsClusterPostgres_4d6e`)

| Property | Value |
|----------|-------|
| Type | postgresql |
| Architecture ref | `dealsClusterPostgres_4d6e` |
| Purpose | Stores generated deals clusters and top clusters for API serving |
| Ownership | owned (DaaS — Database-as-a-Service) |
| Migrations path | No migration scripts found in repo; schema managed via DDL in `ddl/` |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `deals_cluster` (configured via `db.table`) | Stores all deals cluster records produced by `DealsClusterJob` | `clusterUuid`, `clusterName`, `dealsCount`, `dealDataFrom`, `country`, `rule`, `deals` (array), `data` (JSON) |
| `top_clusters` (configured via `db.top_clusters_table`) | Stores top-performing cluster records produced by `TopClustersJob` | cluster identity fields, `country`, `rule`, ranking metrics |

#### Access Patterns

- **Read**: Read exclusively by the Deals Cluster API (separate service); not read-back by this job.
- **Write**: `DealsClusterWriter` and `TopClustersWriter` write via Spark JDBC in `SaveMode.Append`, batched in configurable batch sizes (`db.write_size`). Partitioned writes use `numPartitions` for parallelism.
- **Indexes**: Not visible from this repository.

---

### Deals Cluster HDFS (`dealsClusterHdfs_7a11`)

| Property | Value |
|----------|-------|
| Type | hdfs (Hive external table) |
| Architecture ref | `dealsClusterHdfs_7a11` |
| Purpose | Partitioned JSON output store for clusters; input to TopClustersJob and analytics |
| Ownership | owned |
| Migrations path | `ddl/hive_deals_cluster_production.hql`, `ddl/hive_deals_cluster_staging.hql` |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `grp_gdoop_mars_mds_db.deals_cluster_production` | External Hive table over HDFS output; partitioned by `dt`, `country`, `brand`, `rule` | `clusterUuid`, `clusterName`, `dealsCount`, `dealDataFrom`, `updatedAt`, `clusterDefinition`, `deals` (array), `data` |
| `grp_gdoop_mars_mds_db.deals_cluster_staging` | Staging equivalent of the production Hive table | Same schema |

#### Access Patterns

- **Read**: `TopClustersJob` reads from HDFS path `${hdfs_path}/dt=<YYYYMM01>/country=<COUNTRY>/brand=groupon/rule=<RULE>` via Spark.
- **Write**: `DealsClusterWriter.writeToHDFS()` writes JSON files with lz4 compression using `coalesce(1)`, then executes `ALTER TABLE ... ADD IF NOT EXISTS PARTITION` to register new partitions in the Hive metastore.
- **Indexes**: Partitioned by `dt` (monthly), `country`, `brand`, `rule`.

---

### MDS HDFS Input (`mdsHdfs_3b2a`)

| Property | Value |
|----------|-------|
| Type | hdfs (Hive flat files — JSON) |
| Architecture ref | `mdsHdfs_3b2a` |
| Purpose | Input deal catalog flat files produced by the MDS pipeline |
| Ownership | external (produced by MDS pipeline) |
| Migrations path | Not applicable |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| MDS flat file per country | Deal catalog data including deal attributes, options, pricing, UUIDs | `uuid`, `options`, `country`, deal metadata fields |

#### Access Patterns

- **Read**: `DealsReader` loads JSON flat files from `hdfs://cerebro-namenode-vip.snc1/user/grp_gdoop_mars_mds/mds_flat_production/country_partition=<COUNTRY>/brand_partition=groupon/<COUNTRY>` into a Spark DataFrame, registered as the `deals` temp view.
- **Write**: Not applicable — this is a read-only input store for this service.

---

### EDW Production Database (`edwProdDatabase_9c1f`)

| Property | Value |
|----------|-------|
| Type | hive (Cerebro Hive metastore — `edwprod` database) |
| Architecture ref | `edwProdDatabase_9c1f` |
| Purpose | Provides 30-day rolling aggregated traffic and finance metrics per deal per country |
| Ownership | external (produced by EDW team) |
| Migrations path | Not applicable |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `edwprod.agg_gbl_traffic_fin_deal` | Aggregated deal-level traffic and financial metrics by traffic source | `deal_id`, `country_code`, `ds` (date), `gross_revenue_usd`, `gross_bookings_usd`, `nob_usd`, `nor_usd`, `activations`, `reactivations`, `transactions_qty`, `transactions`, `deal_views`, `refunds_qty`, `traffic_source` |

#### Access Patterns

- **Read**: `EDWReader.loadData()` queries the EDW table via Spark SQL for a 30-day rolling window ending on the job's run date, grouped by `deal_id` and `country_code`. Results are cached in Spark memory and exposed as the `edw_deals` temp view.
- **Write**: Not applicable — this is a read-only input store for this service.

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| Spark in-memory cache (`MEMORY_ONLY_SER_2`) | in-memory | EDW-decorated deals DataFrame cached across multiple rule iterations for the same country | Job lifetime (cleared between countries) |
| Spark in-memory+disk (`MEMORY_AND_DISK`) | in-memory + disk | EDW raw dataset and top-clusters output persisted across group-by iterations | Job lifetime |

## Data Flows

1. **MDS HDFS** (external) -> `DealsReader` reads deal catalog JSON into Spark.
2. **EDW Hive** (external) -> `EDWReader` reads 30-day aggregated metrics into Spark, joined with deals.
3. **Decorators** enrich the joined dataset (city, GP, sold gifts, gift PDS, deal scores, ILS campaign, promo price).
4. **ClustersGenerator** executes rule SQL queries, groups, filters, and aggregates the decorated dataset.
5. **DealsClusterWriter** writes cluster output to **PostgreSQL** and **HDFS** in parallel.
6. **TopClustersJob** reads cluster output from **HDFS**, applies top-cluster rules, and writes ranked output to **PostgreSQL**.
