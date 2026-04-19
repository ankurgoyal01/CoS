---
service: "mis-data-pipelines-dags"
title: "Janus Kafka Streaming"
generated: "2026-03-03"
type: flow
flow_name: "janus-kafka-streaming"
flow_type: event-driven
trigger: "Continuous — Kafka MSK tier-2 topic events containing deal IDs"
participants:
  - "misDags_dagOrchestrator"
  - "misDags_dataprocJobConfig"
  - "misDags_janusBootstrap"
  - "messageBus"
  - "cloudPlatform"
  - "loggingStack"
architecture_ref: "dynamic-mis-dags-core-flow"
---

# Janus Kafka Streaming

## Summary

The Janus Kafka Streaming flow provisions a persistent ephemeral GCP Dataproc cluster and submits the `mds-janus` Spark Streaming application, which continuously consumes deal ID events from a Kafka (MSK) tier-2 topic and enqueues them into a Redis queue for asynchronous processing by the MDS batch worker. TLS certificates for Kafka authentication are loaded at cluster startup from GCP Secret Manager via the Janus Bootstrap initialization script. Backpressure controls limit the Kafka ingestion rate to prevent overloading the batch worker. The cluster uses autoscaling and has an idle TTL of 3600 seconds to prevent runaway costs.

## Trigger

- **Type**: schedule (DAG is scheduled; the Spark Streaming job runs continuously once started)
- **Source**: Airflow Scheduler (Cloud Composer) provisions the cluster and submits the streaming job; Kafka MSK tier-2 topic feeds events continuously
- **Frequency**: Streaming — processes batches every 5 seconds (Spark Streaming batch interval); DAG manages cluster lifecycle

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| DAG Orchestrator | Provisions Janus Dataproc cluster, triggers TLS init action, submits Spark job | `misDags_dagOrchestrator` |
| Dataproc Job Config | Provides Janus cluster and Spark job parameters (`mds_janus_config.json`) | `misDags_dataprocJobConfig` |
| Janus Bootstrap Scripts | TLS certificate installation init script at cluster startup | `misDags_janusBootstrap` |
| Kafka / Message Bus (MSK) | Source of Janus tier-2 deal ID streaming events | `messageBus` |
| GCP Cloud Platform (Dataproc) | Hosts the Spark Streaming cluster; cluster name `dataproc-ephemeral-cluster-mds-janus` | `cloudPlatform` |
| Logging Stack (Stackdriver) | Receives Spark driver, executor, and YARN container logs | `loggingStack` |

## Steps

1. **Load Janus Job Config**: DAG Orchestrator reads `orchestrator/config/{env}/mds_janus_config.json` to determine cluster name (`dataproc-ephemeral-cluster-mds-janus`), machine types (1 master + 2 workers, `e2-standard-8`), autoscaling policy URI, Spark job parameters, and Kafka consumer group ID.
   - From: `misDags_dagOrchestrator`
   - To: `misDags_dataprocJobConfig`
   - Protocol: File I/O

2. **Create Janus Dataproc Cluster**: DAG Orchestrator creates the Dataproc cluster using Airflow `DataprocCreateClusterOperator`. Cluster uses image `1.5-debian10`, Anaconda/Jupyter/Presto optional components, Metastore `grpn-dpms-prod-analytics`, idle TTL 3600s.
   - From: `misDags_dagOrchestrator`
   - To: `cloudPlatform` (GCP Dataproc API)
   - Protocol: GCP REST API

3. **Install TLS Certificates**: Cluster initialization action `gs://grpn-dnd-prod-analytics-common/init/gcp-kafka/load-certificates-with-truststore.sh` runs `mds_janus_init_install_tls_certificate.sh`. Fetches `mis_certificate`, `mis_certificate_chain`, and `mis_private_key` from GCP Secret Manager. Generates JKS keystore (`mis-keystore.jks`) and truststore at `/var/groupon/`.
   - From: `misDags_janusBootstrap`
   - To: GCP Secret Manager (via `gcloud secrets versions access`)
   - Protocol: gcloud CLI / GCP Secret Manager API

4. **Submit Janus Spark Streaming Job**: DAG Orchestrator submits the Spark job via `DataprocSubmitJobOperator`. Main class: `com.groupon.mds.jobs.MDSJanusStreamingApplication`. JAR from Artifactory: `mds-janus_2.12-1.1.52-assembly.jar`. Configured with 27 executor instances (5 cores, 2g memory each), batch interval 5s, shuffle partitions 240, backpressure enabled.
   - From: `misDags_dagOrchestrator`
   - To: `cloudPlatform` (Dataproc Spark job submission)
   - Protocol: GCP Dataproc Jobs API

5. **Consume Kafka Events (Continuous)**: Spark Streaming application polls Kafka MSK tier-2 topic using consumer group `mds_janus_msk_prod_3`. Applies backpressure (initial rate 30 msgs/partition, max 1000, min 100) to control throughput. Repartitions consumed data to 55 partitions before processing.
   - From: `cloudPlatform` (Janus Spark job)
   - To: `messageBus` (Kafka MSK tier-2 topic)
   - Protocol: Kafka (mTLS via JKS keystore)

6. **Enqueue Deal IDs to Redis**: Janus Spark job processes each batch of deal ID events and writes them to the Redis queue for the MDS batch worker. Redis queue ownership is external to this service.
   - From: `cloudPlatform` (Janus Spark job)
   - To: Redis (external batch worker queue)
   - Protocol: Redis protocol

7. **Emit Execution Logs**: Spark driver, executor, and YARN container logs forwarded to Stackdriver Logging (`loggingStack`) via Dataproc Stackdriver integration.
   - From: `cloudPlatform`
   - To: `loggingStack`
   - Protocol: Stackdriver Logging API

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| GCP Secret Manager cert retrieval fails | Init script exits with code 2 for unknown project; shell `set -e` causes cluster init failure | Cluster creation fails; DAG task marked failed |
| Spark Streaming job crashes | YARN application master restarts executor; `yarn.resourcemanager.am.max-attempts: 3` on MDS Feeds cluster (not set on Janus cluster) | Job may restart up to YARN retry limit; cluster idle TTL 3600s triggers deletion |
| Kafka partition lag exceeds backpressure | Backpressure PID controller reduces consumption rate to `minRate: 100` | Processing slows but does not crash; deal ID queue ingestion rate reduced |
| Cluster auto-deleted (idle TTL 3600s) | Airflow DAG manages cluster lifecycle; next scheduled run recreates cluster | Gap in streaming processing; catch-up on Kafka consumer lag at restart |

## Sequence Diagram

```
Airflow Scheduler -> misDags_dagOrchestrator: Trigger Janus DAG
misDags_dagOrchestrator -> misDags_dataprocJobConfig: Read mds_janus_config.json
misDags_dagOrchestrator -> cloudPlatform: Create Dataproc cluster (dataproc-ephemeral-cluster-mds-janus)
cloudPlatform -> GCP Secret Manager: Fetch mis_certificate, mis_certificate_chain, mis_private_key
GCP Secret Manager --> cloudPlatform: TLS certificate data
cloudPlatform -> cloudPlatform: Generate mis-keystore.jks and truststore.jks
misDags_dagOrchestrator -> cloudPlatform: Submit Spark job (mds-janus_2.12-1.1.52-assembly.jar)
cloudPlatform -> messageBus: Poll Kafka tier-2 topic (consumer group mds_janus_msk_prod_3, mTLS)
messageBus --> cloudPlatform: Deal ID events (batch interval 5s)
cloudPlatform -> Redis: Enqueue deal IDs for batch worker
cloudPlatform -> loggingStack: Forward Spark driver/executor/YARN logs
```

## Related

- Architecture dynamic view: `dynamic-mis-dags-core-flow`
- Related flows: [MDS Backfill Pipeline](mds-backfill-pipeline.md)
