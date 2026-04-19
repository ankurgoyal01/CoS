---
service: "deals-cluster"
title: "Top Clusters Job Execution"
generated: "2026-03-03"
type: flow
flow_name: "top-clusters-job-execution"
flow_type: batch
trigger: "Daily crontab on Cerebro job submitter host, after DealsClusterJob completes"
participants:
  - "continuumDealsClusterSparkJob"
  - "topClustersRulesApi_c3d4"
  - "dealsClusterHdfs_7a11"
  - "dealsClusterPostgres_4d6e"
architecture_ref: "dynamic-topClustersJob"
---

# Top Clusters Job Execution

## Summary

`TopClustersJob` is the second daily batch job in the Deals Cluster pipeline. It reads the cluster output written by `DealsClusterJob` from HDFS, applies top-cluster rules to rank and filter the most performant clusters per country and group-by dimension, deduplicates results, and writes the ranked top-performing clusters to PostgreSQL. For Canada, it also mirrors US-branded results to the `US` country code.

## Trigger

- **Type**: schedule
- **Source**: crontab on Cerebro job submitter host; runs after `DealsClusterJob` completes each day
- **Frequency**: Daily

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| TopClustersJob (entry point) | Orchestrates top-cluster extraction | `continuumDealsClusterSparkJob` |
| TopClustersExtractor | Applies top-cluster rules per country | `continuumDealsClusterSparkJob` |
| Top Clusters Rules API | Supplies top-cluster rule configurations | `topClustersRulesApi_c3d4` |
| Deals Cluster HDFS | Provides cluster input from DealsClusterJob | `dealsClusterHdfs_7a11` |
| DealsClusterReader | Reads and augments cluster DataFrames from HDFS | `continuumDealsClusterSparkJob` |
| TopClustersWriter | Persists ranked top-cluster output | `continuumDealsClusterSparkJob` |
| PostgreSQL DaaS | Stores top-cluster records for API serving | `dealsClusterPostgres_4d6e` |

## Steps

1. **Initialize Spark session**: `TopClustersJob.main()` calls `SparkUtils.initialiseSparkSession()` for the `TOP_CLUSTER` job type, creating a Spark session on Cerebro YARN.
   - From: `continuumDealsClusterSparkJob` (job submitter)
   - To: `cerebroSparkCluster_e5f6`
   - Protocol: YARN

2. **Fetch top-cluster rules**: `TopClustersRulesReader.getRules()` calls the Top Clusters Rules API over HTTPS and deserializes the response into a list of `TopClustersRule` objects.
   - From: `continuumDealsClusterSparkJob`
   - To: `topClustersRulesApi_c3d4`
   - Protocol: HTTPS/REST

3. **Read HDFS cluster data per country and rule**: For each country and each top-cluster rule, `DealsClusterReader.loadData()` reads the HDFS path `${hdfs_path}/dt=<YYYYMM01>/country=<COUNTRY>/brand=groupon/rule=<clusterName>` into a Spark DataFrame and registers it as the `deals_cluster` temp view.
   - From: `continuumDealsClusterSparkJob`
   - To: `dealsClusterHdfs_7a11`
   - Protocol: HDFS

4. **Skip empty datasets**: If the loaded cluster DataFrame is empty (`.limit(1).count() == 0`), the rule/country combination is skipped with a `NoDealsClusterData` info log event and a `success` counter increment.
   - From: `continuumDealsClusterSparkJob`
   - To: `continuumDealsClusterSparkJob` (short-circuit)

5. **Add computed columns**: `DealsClusterReader.createAdditionColoumns()` augments the loaded DataFrame with additional derived columns needed for top-cluster ranking.
   - From: `continuumDealsClusterSparkJob`
   - To: `continuumDealsClusterSparkJob` (in-memory Spark)
   - Protocol: Spark (in-process)

6. **Execute top-cluster query per group-by**: For each `groupBy` dimension in the top-cluster rule, `DealsClusterReader.executeQueryByRule()` applies the rule's filter, group-by, and order-by logic to rank and select the top clusters.
   - From: `continuumDealsClusterSparkJob`
   - To: `continuumDealsClusterSparkJob` (Spark SQL in-process)
   - Protocol: Spark SQL

7. **Handle Canada-to-US mirroring**: For country code `CA`, `TopClustersWriter` creates a second mapped dataset with `country = US` and unions it with the Canada dataset, so Canadian divisions are also queryable under the `US` country code.
   - From: `continuumDealsClusterSparkJob`
   - To: `continuumDealsClusterSparkJob` (in-memory Spark)
   - Protocol: Spark (in-process)

8. **Persist to memory/disk and write to PostgreSQL**: `TopClustersWriter.storeToDB()` persists the transformed top-clusters dataset to Spark memory+disk, then writes via JDBC to the PostgreSQL `top_clusters` table in `SaveMode.Append`.
   - From: `continuumDealsClusterSparkJob`
   - To: `dealsClusterPostgres_4d6e`
   - Protocol: JDBC/PostgreSQL

9. **Emit metrics**: `MetricsProvider` emits `success` or `failed` counters (tagged by `country`, `rule-name`, `sub-service=TOP_CLUSTER`) and `time.total` / `success.total` timers to InfluxDB.
   - From: `continuumDealsClusterSparkJob`
   - To: InfluxDB
   - Protocol: HTTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Top Clusters Rules API unavailable | `IOException` thrown at startup | Entire `TopClustersJob` run fails |
| HDFS input missing for a rule/country | Dataset is empty; `NoDealsClusterData` logged; `success` metric incremented | Skipped gracefully; no top clusters written for that combination |
| Query or write failure per group-by | `FailedTopClustersExtraction` event logged; `failed` metric incremented; loop continues | That group-by combination skipped; other group-bys still processed |

## Sequence Diagram

```
CronJob -> TopClustersJob: Trigger after DealsClusterJob completes
TopClustersJob -> CerebroYARN: Initialize Spark session
TopClustersJob -> TopClustersRulesAPI: GET topclustersrules (HTTPS)
TopClustersRulesAPI --> TopClustersJob: List<TopClustersRule>
loop for each country
  loop for each TopClustersRule
    TopClustersExtractor -> HDFS: Read cluster data (dt=YYYYMM01/country/brand/rule)
    HDFS --> TopClustersExtractor: deals_cluster DataFrame
    alt dataset is empty
      TopClustersExtractor -> InfluxDB: success counter (skipped)
    else dataset has data
      TopClustersExtractor -> TopClustersExtractor: createAdditionalColumns()
      loop for each groupBy dimension in rule
        TopClustersExtractor -> TopClustersExtractor: executeQueryByRule()
        TopClustersWriter -> TopClustersWriter: CA -> union with US dataset (if CA)
        TopClustersWriter -> PostgreSQL: JDBC write top clusters (Append)
        TopClustersWriter -> InfluxDB: success/failed counter
      end loop
    end alt
  end loop
end loop
TopClustersJob -> InfluxDB: Emit time.total, success.total
```

## Related

- Architecture dynamic view: `dynamic-topClustersJob`
- Related flows: [Deals Cluster Job Execution](deals-cluster-job-execution.md), [Rules Fetch at Job Startup](rules-fetch-at-startup.md)
