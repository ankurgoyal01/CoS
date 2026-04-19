---
service: "consumer-authority"
title: "Backfill Pipeline"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "backfill-pipeline"
flow_type: batch
trigger: "Manual or Airflow-triggered backfill run with explicit historical run date and region supplied as CLI arguments"
participants:
  - "cdeJobOrchestrator"
  - "cdeAttributePipelineEngine"
  - "cdeMetadataAdapter"
  - "cdeSparkExecutionEngine"
  - "continuumConsumerAuthorityWarehouse"
  - "cdeExternalPublisher"
  - "messageBus"
  - "continuumAudienceManagementService"
  - "cdeAlertingNotifier"
  - "smtpRelay"
architecture_ref: "dynamic-daily-attribute-pipeline"
---

# Backfill Pipeline

## Summary

The backfill pipeline recomputes historical consumer attributes for one or more past run dates and regions. It follows the same execution path as the [Daily Attribute Pipeline](daily-attribute-pipeline.md) but is initiated manually (via Airflow backfill task or direct job submission) with an explicit historical run date and target region. The output partitions for the specified date are overwritten in the Consumer Authority Warehouse, and the corrected attribute data is re-published to the Message Bus and Audience Management Service.

## Trigger

- **Type**: manual
- **Source**: Airflow backfill command or manual re-trigger of a failed DAG task instance; operator supplies explicit `--run-date` and `--region` CLI arguments
- **Frequency**: On demand (invoked to repair failed, missing, or incorrect runs)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Job Orchestrator | Bootstraps job configuration with explicit historical run date and region | `cdeJobOrchestrator` |
| Attribute Pipeline Engine | Discovers and orders attribute scripts for the target region | `cdeAttributePipelineEngine` |
| Metadata Adapter | Resolves table locations and verifies source partition availability for the backfill date | `cdeMetadataAdapter` |
| Spark Execution Engine | Executes transformations and overwrites the target output partition | `cdeSparkExecutionEngine` |
| Consumer Authority Warehouse | Receives overwritten attribute output partition for the backfill date | `continuumConsumerAuthorityWarehouse` |
| External Publisher | Re-publishes corrected attribute events for the backfill date | `cdeExternalPublisher` |
| Message Bus | Receives corrected consumer-attribute events | `messageBus` |
| Audience Management Service | Receives refreshed attribute metadata for the backfill date | `continuumAudienceManagementService` |
| Alerting Notifier | Sends backfill completion or failure notification | `cdeAlertingNotifier` |
| SMTP Relay | Delivers alert email for backfill outcome | `smtpRelay` |

## Steps

1. **Initiate backfill**: Operator triggers an Airflow backfill for the target run date and region; Cerebro Job Submitter launches the Spark application with the explicit `--run-date` and `--region` arguments.
   - From: Airflow (manual or Cerebro Job Submitter)
   - To: `cdeJobOrchestrator`
   - Protocol: YARN `spark-submit`

2. **Bootstrap with historical date**: Job Orchestrator parses the explicit run date and region, initializes the Spark session, and enters the execution lifecycle in backfill mode (bypassing any daily-date defaulting logic).
   - From: `cdeJobOrchestrator`
   - To: `cdeAttributePipelineEngine`
   - Protocol: direct (in-process Scala)

3. **Build execution graph**: Attribute Pipeline Engine discovers attribute scripts for the specified region and resolves the dependency graph identically to the daily run.
   - From: `cdeAttributePipelineEngine`
   - To: `cdeMetadataAdapter`
   - Protocol: direct (in-process Scala)

4. **Verify source data availability**: Metadata Adapter confirms that source table partitions for the historical run date exist in the Hive Metastore before proceeding.
   - From: `cdeMetadataAdapter`
   - To: `hiveWarehouse`
   - Protocol: Hive Metastore (Thrift)

5. **Execute transformations for historical date**: Spark Execution Engine runs SQL and DataFrame transformations against source data partitioned by the backfill run date.
   - From: `cdeAttributePipelineEngine`
   - To: `cdeSparkExecutionEngine`
   - Protocol: direct (in-process Scala / Apache Spark)

6. **Overwrite output partition**: Spark Execution Engine writes the recomputed attribute data to the target partition in the Consumer Authority Warehouse, overwriting any previously written (incorrect or partial) output.
   - From: `cdeSparkExecutionEngine`
   - To: `continuumConsumerAuthorityWarehouse`
   - Protocol: Hive/HDFS (Spark write with partition overwrite)

7. **Re-publish corrected signals**: External Publisher emits updated consumer-attribute events for the backfill date to the Message Bus.
   - From: `cdeExternalPublisher`
   - To: `messageBus`
   - Protocol: Kafka (Holmes publisher)

8. **Refresh AMS metadata**: External Publisher pushes updated attribute metadata for the backfill date to the Audience Management Service.
   - From: `cdeExternalPublisher`
   - To: `continuumAudienceManagementService`
   - Protocol: HTTP (REST)

9. **Send backfill completion alert**: Alerting Notifier sends an email reporting the backfill outcome.
   - From: `cdeAlertingNotifier`
   - To: `smtpRelay`
   - Protocol: SMTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Source partition missing for backfill date | Job fails at metadata verification step | Alert sent; operator must confirm source data availability before retrying |
| Partial overwrite of output partition | Spark write fails mid-job; existing partition may be in partial state | Drop the target partition manually (`ALTER TABLE DROP PARTITION`) before re-running the backfill |
| Message Bus re-publish failure | Holmes publisher delivery failure | Warehouse partition is correct; downstream consumers may receive duplicate or out-of-order events if the daily run already published a version of this date |
| AMS push failure | HTTP non-2xx response | Warehouse and Message Bus are consistent; AMS metadata may reflect stale attribute state for the backfill date |

## Sequence Diagram

```
Airflow (manual backfill)  -> cdeJobOrchestrator          : Submit with --run-date=YYYY-MM-DD --region=NA|INTL|GBL
cdeJobOrchestrator         -> cdeAttributePipelineEngine  : Build execution graph (historical date)
cdeAttributePipelineEngine -> cdeMetadataAdapter          : Verify source partition availability
cdeMetadataAdapter         -> hiveWarehouse               : Check partition for run date
hiveWarehouse              --> cdeMetadataAdapter         : Return partition metadata
cdeAttributePipelineEngine -> cdeSparkExecutionEngine     : Execute transformations for historical date
cdeSparkExecutionEngine    -> continuumConsumerAuthorityWarehouse : Overwrite output partition
cdeSparkExecutionEngine    -> cdeExternalPublisher        : Provide recomputed datasets
cdeExternalPublisher       -> messageBus                  : Re-publish corrected signals
cdeExternalPublisher       -> continuumAudienceManagementService : Refresh metadata updates
cdeJobOrchestrator         -> cdeAlertingNotifier         : Trigger backfill completion notification
cdeAlertingNotifier        -> smtpRelay                   : Send operational alert
```

## Related

- Architecture dynamic view: `dynamic-daily-attribute-pipeline`
- Related flows: [Daily Attribute Pipeline](daily-attribute-pipeline.md), [Attribute Publication](attribute-publication.md)
