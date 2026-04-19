---
service: "consumer-authority"
title: "Daily Attribute Pipeline"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "daily-attribute-pipeline"
flow_type: scheduled
trigger: "Airflow daily schedule triggers Cerebro Job Submitter, which submits the Spark job to the YARN cluster"
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

# Daily Attribute Pipeline

## Summary

The daily attribute pipeline is the core scheduled workflow of Consumer Authority. It runs once per day per region (NA, INTL, GBL), computing consumer attributes for Groupon users. Starting from an Airflow schedule trigger, the Job Orchestrator launches the pipeline, the Attribute Pipeline Engine discovers scripts and resolves dependencies, Spark executes SQL transformations against Hive/HDFS, and the resulting attribute partitions are written to the Consumer Authority Warehouse. After Spark completes, the Attribute Publication flow publishes derived signals to the Message Bus and pushes attribute metadata to the Audience Management Service. Operational alerts are sent on completion or failure.

## Trigger

- **Type**: schedule
- **Source**: Airflow DAG configured for daily execution; Cerebro Job Submitter submits the Spark application to the YARN cluster
- **Frequency**: Daily (once per run date per region)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Job Orchestrator | Bootstraps job configuration, parses CLI arguments, and launches pipeline execution | `cdeJobOrchestrator` |
| Attribute Pipeline Engine | Discovers attribute scripts and resolves the dependency execution graph | `cdeAttributePipelineEngine` |
| Metadata Adapter | Resolves table locations and partition metadata from Hive Metastore | `cdeMetadataAdapter` |
| Spark Execution Engine | Executes SQL transformations and writes partitioned output | `cdeSparkExecutionEngine` |
| Consumer Authority Warehouse | Receives and stores computed attribute output partitions | `continuumConsumerAuthorityWarehouse` |
| External Publisher | Publishes derived attribute signals to the Message Bus and AMS | `cdeExternalPublisher` |
| Message Bus | Receives and forwards consumer-attribute events to downstream consumers | `messageBus` |
| Audience Management Service | Receives attribute metadata updates via HTTP | `continuumAudienceManagementService` |
| Alerting Notifier | Sends success or failure notifications via SMTP | `cdeAlertingNotifier` |
| SMTP Relay | Delivers operational alert emails and pages | `smtpRelay` |

## Steps

1. **Trigger scheduled run**: Airflow DAG fires on the daily cron schedule and submits the Spark job through Cerebro Job Submitter.
   - From: Airflow (Cerebro Job Submitter)
   - To: `cdeJobOrchestrator`
   - Protocol: YARN `spark-submit`

2. **Bootstrap job configuration**: Job Orchestrator parses CLI arguments (run date, region, job mode), initializes Spark session settings, and starts the execution lifecycle.
   - From: `cdeJobOrchestrator`
   - To: `cdeAttributePipelineEngine`
   - Protocol: direct (in-process Scala)

3. **Build execution graph**: Attribute Pipeline Engine discovers all attribute scripts for the target region, resolves inter-attribute dependencies, and produces an ordered execution graph.
   - From: `cdeAttributePipelineEngine`
   - To: `cdeMetadataAdapter`
   - Protocol: direct (in-process Scala)

4. **Resolve table metadata**: Metadata Adapter queries the Hive Metastore to retrieve table locations, schema definitions, and available partition layouts for all source and intermediate tables.
   - From: `cdeMetadataAdapter`
   - To: `hiveWarehouse`
   - Protocol: Hive Metastore (Thrift)

5. **Execute transformations**: Spark Execution Engine builds Spark sessions, submits the ordered SQL and DataFrame transformations against HDFS-backed Hive tables, and collects computed attribute datasets.
   - From: `cdeAttributePipelineEngine`
   - To: `cdeSparkExecutionEngine`
   - Protocol: direct (in-process Scala / Apache Spark)

6. **Persist output partitions**: Spark Execution Engine writes computed attribute data as partitioned Hive tables to the Consumer Authority Warehouse (`user_attrs`, `user_attrs_intl`, or `user_attrs_gbl` depending on region).
   - From: `cdeSparkExecutionEngine`
   - To: `continuumConsumerAuthorityWarehouse`
   - Protocol: Hive/HDFS (Spark write)

7. **Publish derived signals**: External Publisher selects attributes designated for downstream propagation and publishes consumer-attribute events to the Message Bus via the Holmes publisher.
   - From: `cdeExternalPublisher`
   - To: `messageBus`
   - Protocol: Kafka (Holmes publisher)

8. **Push attribute metadata updates**: External Publisher calls the Audience Management Service HTTP API to update the attribute metadata catalog, signalling which attributes are now available for the completed run date.
   - From: `cdeExternalPublisher`
   - To: `continuumAudienceManagementService`
   - Protocol: HTTP (REST)

9. **Send run alerts**: Alerting Notifier dispatches an operational email or pager notification reporting the run outcome (success, failure, or anomaly) to configured recipients.
   - From: `cdeAlertingNotifier`
   - To: `smtpRelay`
   - Protocol: SMTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Hive Metastore unreachable | Job fails at metadata resolution step (step 4) | Airflow task marked failed; `cdeAlertingNotifier` sends failure alert; no output written for the run date |
| Spark executor OOM or task failure | YARN retries executor up to configured attempt limit | If retries exhausted, job fails; Airflow marks task failed; partial output may exist and should be dropped before re-running |
| Source partition missing for run date | Attribute Pipeline Engine cannot resolve dependency; job fails | Airflow task marked failed; alert sent; re-run after upstream source data is available |
| Message Bus publish failure | Holmes publisher delivery failure; no retry at job level | Warehouse output is intact; downstream event consumers do not receive signals for that run |
| AMS HTTP push failure | HTTP call returns non-2xx | Alert sent; warehouse and message bus outputs are not affected; AMS metadata catalog may lag one run |
| SMTP alert delivery failure | SMTP relay unreachable | Alert not delivered; job outcome still written to logs and Airflow DAG history |

## Sequence Diagram

```
Airflow (Cerebro)          -> cdeJobOrchestrator          : Trigger scheduled run (spark-submit)
cdeJobOrchestrator         -> cdeAttributePipelineEngine  : Build execution graph
cdeAttributePipelineEngine -> cdeMetadataAdapter          : Resolve table metadata and dependencies
cdeMetadataAdapter         -> hiveWarehouse               : Query table schema and partitions
hiveWarehouse              --> cdeMetadataAdapter         : Return metadata
cdeAttributePipelineEngine -> cdeSparkExecutionEngine     : Submit SQL/transformation work
cdeSparkExecutionEngine    -> hdfsStorage                 : Read source data files
hdfsStorage                --> cdeSparkExecutionEngine    : Return data
cdeSparkExecutionEngine    -> continuumConsumerAuthorityWarehouse : Write output partitions
cdeSparkExecutionEngine    -> cdeExternalPublisher        : Provide computed datasets for publication
cdeExternalPublisher       -> messageBus                  : Publish derived signals (Kafka)
cdeExternalPublisher       -> continuumAudienceManagementService : Push metadata updates (HTTP)
cdeJobOrchestrator         -> cdeAlertingNotifier         : Trigger run completion notification
cdeAlertingNotifier        -> smtpRelay                   : Send operational alert
```

## Related

- Architecture dynamic view: `dynamic-daily-attribute-pipeline`
- Related flows: [Backfill Pipeline](backfill-pipeline.md), [Attribute Publication](attribute-publication.md)
