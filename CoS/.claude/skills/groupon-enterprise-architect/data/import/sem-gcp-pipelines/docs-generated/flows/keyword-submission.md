---
service: "sem-gcp-pipelines"
title: "Keyword Submission"
generated: "2026-03-03"
type: flow
flow_name: "keyword-submission"
flow_type: batch
trigger: "Scheduled Airflow DAG — cron-based; also triggerable manually"
participants:
  - "continuumSemGcpPipelinesComposer"
  - "gcpDataprocCluster_469e25"
  - "gcsDataBucket_a28d89"
  - "messageBus"
architecture_ref: "dynamic-semGcpPipelinesKeywordSubmission"
---

# Keyword Submission

## Summary

The Keyword Submission flow reads pre-computed keyword data from GCS (output of a prior keyword generation Spark job) and publishes one Message Bus message per deal-country combination to the internal Groupon Message Bus via STOMP. This flow feeds the downstream SEM keyword management system with deal-level keyword lists, enabling automatic keyword creation and management in Google Ads and other ad platforms. The PySpark job uses `foreachPartition` to open a STOMP connection per Spark partition (by country) and send messages in bulk.

## Trigger

- **Type**: schedule
- **Source**: Airflow DAG scheduler; cron interval defined per deployment configuration
- **Frequency**: Scheduled; also triggerable manually via Airflow UI

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Airflow Composer | Schedules and monitors the DAG | `continuumSemGcpPipelinesComposer` |
| GCP Dataproc | Runs the `submit_smart_keywords` PySpark job | `gcpDataprocCluster_469e25` |
| GCS Data Bucket | Source of final keyword Parquet files, partitioned by region/country/target_date | `gcsDataBucket_a28d89` |
| Message Bus | Receives keyword submission messages over STOMP | `messageBus` |

## Steps

1. **DAG Triggered**: Airflow schedules or operator triggers the keyword submission DAG.
   - From: `continuumSemGcpPipelinesComposer`
   - To: DAG run started

2. **Create Dataproc Cluster**: Airflow provisions an ephemeral Dataproc cluster.
   - From: `continuumSemGcpPipelinesComposer`
   - To: `gcpDataprocCluster_469e25`
   - Protocol: GCP Dataproc API
   - See [Dataproc Cluster Lifecycle](dataproc-cluster-lifecycle.md) for cluster details

3. **Check GCS Partition Exists**: `GSUtils.has_dir()` verifies the keyword Parquet partition exists before attempting to read.
   - From: PySpark job on `gcpDataprocCluster_469e25`
   - To: `gcsDataBucket_a28d89`
   - Protocol: `gsutil ls -L {directory}/`
   - If partition missing: job logs "Data partition is not available. No keyword is submitted." and exits cleanly

4. **Read Keyword Parquet Data**: PySpark reads the final keyword Parquet files from GCS.
   - From: `gcpDataprocCluster_469e25`
   - To: `gcsDataBucket_a28d89`
   - Protocol: GCS / Spark
   - Path: `{KWGEN_HDFS_PATH}/region={region}/country={country}/target_date={target_date}`
   - Schema: `deal`, `country`, `keyword`, `user`

5. **Group Keywords by Deal and Country**: PySpark `groupBy("deal", "country", "user").agg(collect_list("keyword"))` aggregates keywords per deal.
   - From: Spark executor on `gcpDataprocCluster_469e25`
   - To: local Spark DataFrame
   - Output: one row per deal-country combination with all keywords as a list

6. **Repartition by Country**: DataFrame is repartitioned by country to co-locate messages per country on the same partition.
   - From: Spark executor
   - To: Spark partition layout
   - Method: `repartition(kws_df.country)`

7. **Connect to Message Bus**: Per Spark partition, a `MessageBusClient` connects to the STOMP Message Bus.
   - From: `gcpDataprocCluster_469e25`
   - To: `messageBus`
   - Protocol: STOMP (via `stomp.py 8.1.0`)
   - Auth: Username/password from job params file (`MESSAGE_BUS.USERNAME`, `MESSAGE_BUS.PASSWORD`)
   - Heartbeats: 60,000 ms receive / 20,000 ms send

8. **Publish Keyword Messages**: For each deal-country row in the partition, publishes a STOMP message.
   - From: `gcpDataprocCluster_469e25`
   - To: `messageBus` queue (`MESSAGE_BUS.QUEUE_NAME`)
   - Protocol: STOMP
   - Payload: `{"deal_id": "<deal>", "keywords": ["<kw1>", ...], "user": "<user>", "country": "<country>"}`
   - Header: `persistent: true`

9. **Disconnect from Message Bus**: After all messages in the partition are sent, `MessageBusClient.disconnect()` cleanly closes the STOMP connection.

10. **Delete Dataproc Cluster**: Airflow tears down the cluster.
    - From: `continuumSemGcpPipelinesComposer`
    - To: `gcpDataprocCluster_469e25`
    - Protocol: GCP Dataproc API

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| GCS partition does not exist for target_date | Job logs "Data partition is not available" and returns cleanly | No messages published; DAG task succeeds (no retry needed) |
| STOMP connection failure | `ConnectionError` raised; PySpark partition fails | Spark job fails; Airflow task fails; PagerDuty alert triggered |
| Message send failure | Exception propagated from `stomp.py` | Spark job fails; Airflow task fails; PagerDuty alert |
| Dataproc cluster creation failure | Airflow task fails | No keywords submitted; PagerDuty alert |

## Sequence Diagram

```
Scheduler      -> Composer: Trigger keyword submission DAG
Composer       -> DataprocAPI: Create cluster (DataprocCreateClusterOperator)
DataprocAPI    -> Cluster: Provision + run init (download artifact ZIP)
Composer       -> Cluster: Submit submit_smart_keywords PySpark job
Cluster        -> GCS: gsutil ls (check partition exists)
GCS            --> Cluster: Partition exists / not found
Cluster        -> GCS: spark.read.parquet(keyword_path)
GCS            --> Cluster: Keyword Parquet data (deal, country, keyword, user)
Cluster        -> Cluster: groupBy(deal, country, user).agg(collect_list(keyword))
Cluster        -> Cluster: repartition(country)
Cluster        -> MessageBus: stomp.Connection.connect(USERNAME, PASSWORD, HOSTS, PORT)
MessageBus     --> Cluster: Connected
Cluster        -> MessageBus: send(QUEUE_NAME, {deal_id, keywords, user, country})  [N times]
Cluster        -> MessageBus: disconnect()
Composer       -> DataprocAPI: Delete cluster (DataprocDeleteClusterOperator)
```

## Related

- Architecture dynamic view: `dynamic-semGcpPipelinesKeywordSubmission`
- Related flows: [Dataproc Cluster Lifecycle](dataproc-cluster-lifecycle.md)
