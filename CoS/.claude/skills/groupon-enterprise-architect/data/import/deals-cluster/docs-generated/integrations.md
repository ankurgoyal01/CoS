---
service: "deals-cluster"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 5
internal_count: 2
---

# Integrations

## Overview

Deals Cluster has five key external runtime dependencies: two REST APIs (for rule configuration), two HDFS/Hive data stores (MDS flat files and EDW), and one metrics sink (InfluxDB). It also depends on two internal Groupon data systems — the Cerebro Spark/YARN cluster for execution and the PostgreSQL DaaS for cluster output. The service has no inbound synchronous callers; it is triggered exclusively by a cron job on the Cerebro job submitter host.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Deals Cluster Rules API | HTTPS/REST | Fetches deals clustering rule definitions at `DealsClusterJob` startup | yes | `dealsClusterRulesApi_b1c2` |
| Top Clusters Rules API | HTTPS/REST | Fetches top-cluster rule definitions at `TopClustersJob` startup | yes | `topClustersRulesApi_c3d4` |
| MDS HDFS (deal flat files) | HDFS | Input deal catalog data per country | yes | `mdsHdfs_3b2a` |
| EDW Hive (`edwprod.agg_gbl_traffic_fin_deal`) | Hive/Spark SQL | 30-day aggregated traffic and finance metrics per deal | yes | `edwProdDatabase_9c1f` |
| InfluxDB (metrics endpoint) | HTTP | Receives job execution metrics (counters, timers) | no | — |

### Deals Cluster Rules API Detail

- **Protocol**: HTTPS with mutual TLS (client keystore: `/var/groupon/mis-data-pipelines-keystore.jks`)
- **Base URL**: Configured via `cluster_rule_source` property; VIP endpoints: `http://deals-cluster-vip.snc1/rules` (production), `http://deals-cluster-staging.snc1/rules` (staging)
- **Host header**: Set from `deals_cluster_rule_hb_url` property (used for SNI/routing)
- **Auth**: mTLS (JKS truststore + PKCS12 keystore)
- **Purpose**: Retrieves the list of `Rule` objects defining grouping, filters, decorations, and output fields for the `DealsClusterJob`. Optionally filtered by `name` query parameter when a specific rule is targeted.
- **Failure mode**: If the API is unreachable or returns an error, `DealsClustersRulesReader` throws an `IOException` and the entire `DealsClusterJob` run fails.
- **Circuit breaker**: No circuit breaker configured.

### Top Clusters Rules API Detail

- **Protocol**: HTTPS with mutual TLS
- **Base URL**: Configured via `top_clusters_rule_source` property; VIP endpoints: `http://deals-cluster-vip.snc1/topclustersrules` (production), `http://deals-cluster-staging.snc1/topclustersrules` (staging)
- **Host header**: Set from `deals_cluster_rule_hb_url` property
- **Auth**: mTLS
- **Purpose**: Retrieves `TopClustersRule` objects defining the cluster selection, group-by fields, and ranking logic for `TopClustersJob`.
- **Failure mode**: If unreachable, `TopClustersRulesReader` throws and the job fails.
- **Circuit breaker**: No circuit breaker configured.

### MDS HDFS Detail

- **Protocol**: HDFS (Hadoop Distributed File System) via Spark
- **Base URL / SDK**: Path pattern `hdfs://cerebro-namenode-vip.snc1/user/grp_gdoop_mars_mds/mds_flat_production/country_partition=<COUNTRY>/brand_partition=groupon/<COUNTRY>` — passed as CLI argument at job invocation.
- **Auth**: Hadoop Kerberos / service account (`svc_mars_mds`)
- **Purpose**: Provides the deal catalog (MDS flat) JSON files for each country processed by `DealsClusterJob`.
- **Failure mode**: If the file is missing or unreadable, `MissingHDFSFile` error event is logged and the job fails for that country. The MDS pipeline must produce the file before Deals Cluster runs.
- **Circuit breaker**: No circuit breaker configured.

### EDW Hive Detail

- **Protocol**: Spark SQL (via Cerebro Hive metastore connection, configured in `cerebro.*` properties)
- **Base URL / SDK**: Hive table `edwprod.agg_gbl_traffic_fin_deal`; queried via `spark.sql()` within `EDWReader.loadData()`
- **Auth**: Cerebro service account (`cerebro.users` / `cerebro.password` properties)
- **Purpose**: Provides 30-day rolling traffic, conversion, revenue, and refund metrics per deal per country, used to enrich deal clusters with performance data.
- **Failure mode**: `EDWLoadErr` event is logged; `FailedDecoratingClusters` event is emitted per country and a failure metric counter is incremented. The job continues to attempt other countries.
- **Circuit breaker**: No circuit breaker configured.

### InfluxDB Detail

- **Protocol**: HTTP
- **Base URL / SDK**: Configured via `metrics_endpoint` property; client is `influxdb-java` 2.9.
- **Auth**: None evidenced in code (open InfluxDB endpoint on internal network).
- **Purpose**: Receives job execution metrics: `success`, `failed` counters per rule/country/sub-service, and `time.total` / `success.total` timers per job.
- **Failure mode**: InfluxDB write errors are logged but do not halt job execution (async batch flush with exception handler).
- **Circuit breaker**: No circuit breaker; InfluxDB failures are non-blocking.

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Cerebro Spark/YARN Cluster | YARN/Spark | Provides distributed Spark execution environment for both jobs | `cerebroSparkCluster_e5f6` |
| PostgreSQL DaaS | JDBC | Stores DealsCluster and TopClusters output for downstream API consumption | `dealsClusterPostgres_4d6e` |

## Consumed By

> Upstream consumers are tracked in the central architecture model.

The primary downstream consumer of data written by Deals Cluster is the **Deals Cluster API** (`deals-cluster-api-jtier`), which reads from the PostgreSQL store and serves cluster data to Groupon's front-end and personalization services.

## Dependency Health

- **EDW availability**: Query the EDW Hive table at `http://cerebro-hue-server1.snc1:8000/beeswax/` or via SSH to the Cerebro job submitter. If access fails, contact the EDW team.
- **MDS file availability**: Check HDFS file browser at `http://cerebro-hue-server1.snc1:8000/filebrowser/#/user/grp_gdoop_mars_mds/deals_cluster_production` (production) or `deals_cluster_staging` (staging).
- **Rules API health**: Accessible at the VIP URLs listed above. If down, job startup will fail with a rules-loading error.
- **PostgreSQL health**: Monitored via CheckMK dashboard. Contact GDS team for PostgreSQL infrastructure issues.
- **No circuit breakers or retry logic** are implemented for any dependency; failures result in job-level error events and metric increments.
