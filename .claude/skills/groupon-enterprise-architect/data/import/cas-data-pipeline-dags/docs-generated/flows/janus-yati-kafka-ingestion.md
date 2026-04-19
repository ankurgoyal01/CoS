---
service: "cas-data-pipeline-dags"
title: "Janus-YATI Kafka Ingestion"
generated: "2026-03-03"
type: flow
flow_name: "janus-yati-kafka-ingestion"
flow_type: event-driven
trigger: "Manual trigger via Cloud Composer; schedule_interval=None; supports dag_run.conf JAR override"
participants:
  - "continuumCasDataPipelineDags"
  - "continuumCasSparkBatchJobs"
  - "gcpDataprocCluster"
  - "gcpGcsBucket"
architecture_ref: "dynamic-continuum-cas-data-pipeline-dags"
---

# Janus-YATI Kafka Ingestion

## Summary

The Janus-YATI DAG (`orchestrator/arbitration_janus_yati.py`, config `arbitration_janus_yati.json`, DAG ID `arbitration_janus_yati`) runs a Spark Structured Streaming job (`com.groupon.janus.yati.job.file.KafkaToFileJobMain`) on an ephemeral Dataproc cluster. The job subscribes to the `arbitration_log` Kafka topic (bootstrap servers `kafka-grpn-consumer.grpn-dse-stable.us-west-2.aws.groupondev.com:9094`) via consumer group `cas_stable_arbitration_log_2`, processes up to 1,000,000 offsets per 60-second micro-batch, and writes Muncher-format output to `gs://grpn-dnd-stable-analytics-grp-push-platform/user/janus-yati`. This flow is unique in that it supports a `dag_run.conf` JAR override via a custom `update_spark_job_config` macro.

## Trigger

- **Type**: manual
- **Source**: Cloud Composer Airflow scheduler (DAG ID `arbitration_janus_yati`); `schedule_interval=None`; triggered manually with optional `dag_run.conf` containing `jars` key to override the assembly JAR URI
- **Frequency**: On-demand; this is a streaming micro-batch job that runs until the Dataproc cluster is deleted

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Cloud Composer (Airflow) | Triggers DAG run; provides `dag_run.conf` for optional JAR override | `gcpCloudComposer` |
| CAS Data Pipeline DAGs | Orchestrates cluster lifecycle; injects JAR config override via Airflow macro | `continuumCasDataPipelineDags` |
| GCP Dataproc cluster `arbitration-janus-yati` | Runs Spark Structured Streaming job | `gcpDataprocCluster` |
| Kafka topic `arbitration_log` | Source of arbitration log events | external |
| Janus-YATI Spark job (`KafkaToFileJobMain`) | Consumes Kafka, writes GCS | `continuumCasSparkBatchJobs` |
| GCS bucket `grpn-dnd-stable-analytics-grp-push-platform` | Streaming output and checkpoint store | `gcpGcsBucket` |

## Steps

1. **Start**: Dummy operator marks DAG start.
   - From: `continuumCasDataPipelineDags` / To: `start` dummy task / Protocol: Airflow task dependency

2. **Create Dataproc cluster**: `DataprocCreateClusterOperator` creates cluster `arbitration-janus-yati`; n1-standard-8 master + N workers, image `1.5-debian10`; optional components: ANACONDA, JUPYTER, PRESTO; `init_secret_script` init action fetches TLS keystore (`cas-keystore.jks`) from GCP Secret Manager (secret `tls--push-cas-data-pipelines`); `http_port_access` enabled; Stackdriver logging enabled; `dataproc:dataproc.conscrypt.provider.enable: "false"`.
   - From: `continuumCasDataPipelineDags` / To: `gcpDataprocCluster` / Protocol: GCP Dataproc REST API

3. **Resolve JAR URI** (Airflow macro): The `update_spark_job_config` user-defined macro checks `dag_run.conf` for a `jars` key; if present, overrides the default Janus-YATI JAR URI from the config file with the value from the DAG run configuration. This allows hotswapping the JAR without redeploying the DAG.
   - From: `continuumCasDataPipelineDags` (template rendering)
   - To: `continuumDagOperatorFactory`
   - Protocol: Airflow Jinja template macro

4. **Janus-YATI Streaming job** (`cas_yanus_yati_streaming`): `DataprocSubmitJobOperator` submits `com.groupon.janus.yati.job.file.KafkaToFileJobMain` with args:
   - `--kafkaBootstrapServers=kafka-grpn-consumer.grpn-dse-stable.us-west-2.aws.groupondev.com:9094`
   - `--kafkaTopicName=arbitration_log`
   - `--kafkaConsumerGroup=cas_stable_arbitration_log_2`
   - `--kafkaSslKeystoreLocation=/var/groupon/cas-keystore.jks`
   - `--messageFormat=loggernaut-json`
   - `--outputRootPath=gs://grpn-dnd-stable-analytics-grp-push-platform/user/janus-yati`
   - `--outputFormat=muncher`
   - `--checkpointLocation=gs://grpn-dnd-stable-analytics-grp-push-platform/mezzanine_checkpoint/region=na/source=arbitration_log`
   - `--maxOffsetsPerTrigger=1000000`
   - `--batchIntervalMs=60000`
   - `--metricsEndpoint=http://telegraf.us-central1.conveyor.stable.gcp.groupondev.com`
   - From: `gcpDataprocCluster`
   - To: Kafka `arbitration_log` (read), `gcpGcsBucket` (write)
   - Protocol: Kafka 0.10 / SSL (read), GCS API (write)

5. **Delete Dataproc cluster**: `DataprocDeleteClusterOperator` tears down `arbitration-janus-yati` cluster when streaming job is terminated.
   - From: `continuumCasDataPipelineDags` / To: `gcpDataprocCluster` / Protocol: GCP Dataproc REST API

6. **End**: Dummy operator marks DAG completion.

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Kafka SSL keystore not found | Init action fails; cluster creation fails | DAG fails at create step; check `tls--push-cas-data-pipelines` secret and `init_secret_script` path |
| Kafka consumer lag spike | `maxOffsetsPerTrigger=1000000` caps each micro-batch; lagged batches catch up over subsequent triggers | No data loss (checkpoint-based); increased latency in output |
| Streaming job terminated (OOM) | `retries=0`; Airflow marks task `FAILED` | GCS checkpoint preserves offset; restart from checkpoint by re-triggering DAG |
| DAG triggered with bad JAR URI override | `update_spark_job_config` uses provided `jars` value; Dataproc submit fails if JAR is not accessible | DAG task fails; re-trigger without JAR override or with corrected URI |

## Sequence Diagram

```
CloudComposer -> CasDataPipelineDAGs: Trigger arbitration_janus_yati DAG (optionally with dag_run.conf.jars)
CasDataPipelineDAGs -> GCPDataproc: Create cluster arbitration-janus-yati (with TLS init action)
GCPDataproc -> GCPSecretManager: Fetch TLS keystore (tls--push-cas-data-pipelines)
CasDataPipelineDAGs -> CasDataPipelineDAGs: Resolve JAR URI (update_spark_job_config macro)
CasDataPipelineDAGs -> GCPDataproc: Submit KafkaToFileJobMain (cas_yanus_yati_streaming)
GCPDataproc -> Kafka(arbitration_log): Consume micro-batches (60s interval, max 1M offsets)
GCPDataproc -> GCSBucket: Write Muncher output (janus-yati/), update checkpoint
CasDataPipelineDAGs -> GCPDataproc: Delete cluster
```

## Related

- Architecture dynamic view: `dynamic-continuum-cas-data-pipeline-dags`
- Related flows: [NA Email Data Pipeline](na-email-data-pipeline.md)
