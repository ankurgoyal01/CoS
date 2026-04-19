---
service: "deals-cluster"
title: "Deals Cluster Job Execution"
generated: "2026-03-03"
type: flow
flow_name: "deals-cluster-job-execution"
flow_type: batch
trigger: "Daily crontab on Cerebro job submitter host"
participants:
  - "continuumDealsClusterSparkJob"
  - "dealsClusterRulesApi_b1c2"
  - "mdsHdfs_3b2a"
  - "edwProdDatabase_9c1f"
  - "dealsClusterPostgres_4d6e"
  - "dealsClusterHdfs_7a11"
architecture_ref: "dynamic-dealsClusterJob"
---

# Deals Cluster Job Execution

## Summary

The `DealsClusterJob` is the primary daily batch job that transforms raw deal catalog data and EDW performance metrics into structured deal collections ("clusters"). For each target country and each active clustering rule, it applies a pipeline of data enrichment (decorators) and SQL-based grouping to produce cluster records, then persists the results to both PostgreSQL (for API serving) and HDFS (for downstream analytics and the `TopClustersJob`).

## Trigger

- **Type**: schedule
- **Source**: crontab on Cerebro job submitter host (`svc_mars_mds@cerebro-job-submitter2.snc1` for production)
- **Frequency**: Daily (once per day; specific time defined in `src/main/resources/run/production/crontab`)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| DealsClusterJob (entry point) | Orchestrates the full pipeline | `continuumDealsClusterSparkJob` |
| ClustersGenerator | Executes clustering logic per country and rule | `continuumDealsClusterSparkJob` |
| Rules API Reader | Fetches active rule definitions at startup | `continuumDealsClusterSparkJob` |
| Deals Cluster Rules API | Supplies clustering rule configurations | `dealsClusterRulesApi_b1c2` |
| MDS HDFS (deal flat files) | Provides the deal catalog input | `mdsHdfs_3b2a` |
| EDW Hive (`edwprod.agg_gbl_traffic_fin_deal`) | Provides 30-day aggregated performance metrics | `edwProdDatabase_9c1f` |
| Cluster Decorators | Enrich the joined deal+EDW dataset | `continuumDealsClusterSparkJob` |
| DealsClusterWriter | Persists cluster output | `continuumDealsClusterSparkJob` |
| PostgreSQL DaaS | Stores cluster records for API serving | `dealsClusterPostgres_4d6e` |
| Deals Cluster HDFS | Stores cluster JSON files for analytics and TopClustersJob | `dealsClusterHdfs_7a11` |

## Steps

1. **Initialize Spark session**: `DealsClusterJob.main()` calls `SparkUtils.initialiseSparkSession()` to create a Spark session against the Cerebro YARN cluster.
   - From: `continuumDealsClusterSparkJob` (job submitter)
   - To: `cerebroSparkCluster_e5f6`
   - Protocol: YARN

2. **Fetch clustering rules**: `DealsClustersRulesReader.getRules()` calls the Deals Cluster Rules API over HTTPS, deserializes the JSON response into a list of `Rule` objects, and optionally filters by name.
   - From: `continuumDealsClusterSparkJob`
   - To: `dealsClusterRulesApi_b1c2`
   - Protocol: HTTPS/REST

3. **Load MDS deal flat file per country**: For each country in the country list, `DealsReader.loadData()` reads the MDS JSON flat file from HDFS into a Spark DataFrame and registers it as the `deals` temp view.
   - From: `continuumDealsClusterSparkJob`
   - To: `mdsHdfs_3b2a`
   - Protocol: HDFS

4. **Load and cache EDW data per country**: `EDWReader.loadData()` executes a 30-day aggregated Spark SQL query against `edwprod.agg_gbl_traffic_fin_deal` for the country, persists the result in Spark memory (`MEMORY_AND_DISK`), and registers it as the `edw_deals` temp view.
   - From: `continuumDealsClusterSparkJob`
   - To: `edwProdDatabase_9c1f`
   - Protocol: Hive/Spark SQL

5. **Decorate deals with EDW data**: `EDWDecorator.decorate()` LEFT JOINs the `deals` temp view with `edw_deals` on `country == country_code AND uuid == deal_id`, caches the result as `edwDeals` temp view.
   - From: `continuumDealsClusterSparkJob` (in-memory Spark operation)
   - To: `continuumDealsClusterSparkJob`
   - Protocol: Spark SQL (in-process)

6. **Apply rule-specific decorators**: For each rule, `ClustersGenerator.createClustersForRule()` chains additional decorators as specified in the rule's `decorations` list: `city`, `national`, `gp_decoration`, `display_sold_gifts_decoration`, `giftPDSMapping`, `dealScores`, `instalilyDealScores`, `ilsCampaign`, `promoPriceDiscount`.
   - From: `continuumDealsClusterSparkJob` (in-memory Spark operations)
   - To: `continuumDealsClusterSparkJob` + additional Hive tables for decoration data
   - Protocol: Spark SQL (in-process)

7. **Execute clustering SQL query**: `ClustersGenerator` builds and executes a Spark SQL query using the rule's `selectStatement`, `whereClause`, `groupByColumns`, and `secondWhereClause` to produce the cluster DataFrame. For rules with both `national` and `city` decorations, the query includes a `UNION ALL`. Deduplication is applied based on decoration type.
   - From: `continuumDealsClusterSparkJob`
   - To: `continuumDealsClusterSparkJob` (Spark in-memory)
   - Protocol: Spark SQL (in-process)

8. **Write clusters to PostgreSQL**: `DealsClusterWriter.storeToDB()` maps each cluster row to a `DealsCluster` POJO and writes via Spark JDBC to the configured PostgreSQL table in `SaveMode.Append`.
   - From: `continuumDealsClusterSparkJob`
   - To: `dealsClusterPostgres_4d6e`
   - Protocol: JDBC/PostgreSQL

9. **Write clusters to HDFS and register Hive partition**: `DealsClusterWriter.writeToHDFS()` writes the cluster dataset as JSON (lz4 compressed, coalesced to 1 file) to the HDFS path `${hdfs_path}/dt=<YYYYMM01>/country=<COUNTRY>/brand=groupon/rule=<RULE>`, then executes `ALTER TABLE ... ADD IF NOT EXISTS PARTITION` to register the partition in the Hive metastore.
   - From: `continuumDealsClusterSparkJob`
   - To: `dealsClusterHdfs_7a11`
   - Protocol: HDFS / Hive DDL

10. **Emit completion metrics**: `MetricsProvider` emits `success` or `failed` counters (tagged by `country`, `rule-name`, `sub-service`) and the `time.total` / `success.total` timers to InfluxDB.
    - From: `continuumDealsClusterSparkJob`
    - To: InfluxDB metrics endpoint
    - Protocol: HTTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| EDW data load failure | `FailedDecoratingClusters` event logged; `failed` metric incremented; job continues to next country | That country skipped for all rules |
| Cluster creation failure | `FailedCreateClusters` event logged; `failed` metric incremented; loop continues to next rule | That rule/country combination skipped |
| HDFS write failure | `FailedWriteToHDFS` event logged; `IOException` thrown; that rule/country aborted | `TopClustersJob` will have missing input for that rule/country |
| PostgreSQL write failure | `FailedWriteToPostgres` event logged; exception caught; processing continues | Cluster data missing from API-serving PostgreSQL for that rule/country |
| Rules API unavailable | `IOException` thrown at job startup | Entire `DealsClusterJob` run fails; no clusters produced |

## Sequence Diagram

```
CronJob -> DealsClusterJob: Trigger daily execution
DealsClusterJob -> CerebroYARN: Initialize Spark session
DealsClusterJob -> DealsClusterRulesAPI: GET rules (HTTPS)
DealsClusterRulesAPI --> DealsClusterJob: List<Rule>
loop for each country
  DealsClusterJob -> MDS_HDFS: Read deal flat file
  MDS_HDFS --> ClustersGenerator: deals DataFrame (registered as "deals" temp view)
  ClustersGenerator -> EDW_Hive: SELECT aggregated metrics (30-day window)
  EDW_Hive --> ClustersGenerator: edw_deals DataFrame (cached)
  ClustersGenerator -> ClustersGenerator: EDWDecorator LEFT JOIN (-> "edwDeals" view)
  loop for each rule
    ClustersGenerator -> ClustersGenerator: Apply rule decorators (city, GP, scores, etc.)
    ClustersGenerator -> ClustersGenerator: Execute cluster SQL (GROUP BY, filters)
    ClustersGenerator -> PostgreSQL: JDBC write clusters (Append)
    ClustersGenerator -> HDFS: Write JSON clusters (lz4, coalesce 1)
    ClustersGenerator -> HiveMetastore: ALTER TABLE ADD PARTITION
    ClustersGenerator -> InfluxDB: Emit success/failed counter
  end loop
end loop
DealsClusterJob -> InfluxDB: Emit time.total, success.total
```

## Related

- Architecture dynamic view: `dynamic-dealsClusterJob`
- Related flows: [Top Clusters Job Execution](top-clusters-job-execution.md), [Cluster Decoration Pipeline](cluster-decoration-pipeline.md), [Rules Fetch at Job Startup](rules-fetch-at-startup.md)
