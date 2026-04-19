---
service: "deals-cluster"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuum"
  containers: ["continuumDealsClusterSparkJob"]
---

# Architecture Context

## System Context

Deals Cluster is a batch processing service within the **Continuum** platform. It operates as a scheduled Spark job on the Cerebro on-premises Hadoop/Spark cluster. The service sits between upstream data producers (MDS pipeline writing deal flat files to HDFS, and the EDW producing aggregated traffic/finance metrics) and downstream consumers (the Deals Cluster API, which serves cluster data to Groupon's front-end and recommendation systems). Clustering rules are configured externally via the Deals Cluster Rules API and Top Clusters Rules API.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Deals Cluster Spark Job | `continuumDealsClusterSparkJob` | Batch Job | Java/Spark | 2.4.8 | Daily Spark jobs that generate deals clusters and top clusters. |

## Components by Container

### Deals Cluster Spark Job (`continuumDealsClusterSparkJob`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `DealsClusterJob` | Entry point for the deals clustering pipeline; orchestrates all readers, decorators, generator, and writers per country and rule. | Java/Spark |
| `TopClustersJob` | Entry point for top cluster extraction; reads cluster output from HDFS and writes ranked top performers to PostgreSQL. | Java/Spark |
| `Rules API Reader` | Fetches clustering rules and top-cluster rules from the Deals Cluster Rules API over HTTPS at job startup. | Java |
| `Spark Readers` | Load MDS deal flat files and EDW aggregated data from HDFS/Hive into Spark DataFrames. | Java/Spark |
| `ClustersGenerator` | Applies rule definitions (filters, group-by, decorations, output fields) to the deal dataset to produce cluster DataFrames. | Java |
| `Cluster Decorators` | Enriches the deal dataset with city, EDW, GP, national, sold gifts, gift PDS, deal score, ILS campaign, and promo price data before clustering. | Java |
| `Writers` | Writes cluster output to PostgreSQL (via Spark JDBC) and HDFS (as JSON with lz4 compression), then registers HDFS partitions in the Hive metastore. | Java/Spark |
| `Metrics Provider` | Emits job execution counters and timers to InfluxDB using the SMA metrics library. | Java |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumDealsClusterSparkJob` | `cerebroSparkCluster_e5f6` | Runs Spark jobs on Cerebro YARN cluster | YARN/Spark |
| `continuumDealsClusterSparkJob` | `dealsClusterRulesApi_b1c2` | Reads deals clustering rules at startup | HTTPS/REST |
| `continuumDealsClusterSparkJob` | `topClustersRulesApi_c3d4` | Reads top-cluster rules at startup | HTTPS/REST |
| `continuumDealsClusterSparkJob` | `mdsHdfs_3b2a` | Reads MDS deal flat files | HDFS |
| `continuumDealsClusterSparkJob` | `edwProdDatabase_9c1f` | Reads aggregated traffic/finance data | Hive/JDBC |
| `continuumDealsClusterSparkJob` | `dealsClusterPostgres_4d6e` | Writes cluster and top-cluster data | JDBC/PostgreSQL |
| `continuumDealsClusterSparkJob` | `dealsClusterHdfs_7a11` | Writes cluster output files and registers Hive partitions | HDFS/Hive |

## Architecture Diagram References

- System context: `contexts-dealsCluster`
- Container: `containers-dealsCluster`
- Component: `components-dealsClusterSparkJob`
