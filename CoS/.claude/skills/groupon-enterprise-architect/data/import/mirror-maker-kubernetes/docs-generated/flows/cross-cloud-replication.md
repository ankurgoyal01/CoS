---
service: "mirror-maker-kubernetes"
title: "Cross-Cloud Replication"
generated: "2026-03-03"
type: flow
flow_name: "cross-cloud-replication"
flow_type: event-driven
trigger: "Records available on source topics spanning GCP Kafka and AWS MSK cluster boundaries"
participants:
  - "continuumMirrorMakerService"
  - "continuumKafkaBroker"
architecture_ref: "dynamic-mirror-maker-replication-flow"
---

# Cross-Cloud Replication

## Summary

Cross-cloud replication covers the bidirectional topic mirroring flows that bridge GCP-hosted Kafka clusters and AWS MSK clusters. Separate MirrorMaker instances are deployed on GCP Kubernetes clusters (europe-west1, us-central1) to handle GCP→MSK and MSK→GCP directions. This enables services running on GCP infrastructure to consume events originally produced on AWS MSK (or K8s-native Kafka on AWS), and vice versa. The flow also includes specialized one-way forwarders for cross-region batch dispatch events (GCP NA → K8s EU) and CDP ingress (MSK EU → GCP US-Central1).

## Trigger

- **Type**: Event (records available on cross-cloud source topics)
- **Source**: Any service producing to a topic that must cross cloud boundaries (GCP Kafka → MSK, MSK → GCP Kafka)
- **Frequency**: Continuous; rate depends on topic volume

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| MirrorMaker Service (GCP cluster pod) | Runs on GCP Kubernetes; connects to MSK source or GCP source | `continuumMirrorMakerService` |
| GCP Kafka Cluster | GCP-native Kafka broker endpoint (e.g., `kafka-grpn.us-central1.kafka.prod.gcp.groupondev.com:9094`) | `continuumKafkaBroker` |
| AWS MSK Cluster | AWS MSK bootstrap endpoint (e.g., `kafka-grpn-consumer.grpn-dse-prod.eu-west-1.aws.groupondev.com:9094`) | `continuumKafkaBroker` |
| K8s-native Kafka Cluster | Kubernetes-native Kafka (e.g., `kafka-grpn-kafka-bootstrap.kafka-production.svc.cluster.local:9093`) | `continuumKafkaBroker` |

## Cross-Cloud Deployment Matrix

| Component | Cloud/Region | Source Cluster | Destination Cluster | Topics |
|-----------|-------------|----------------|--------------------|-|
| `gcp-msk-janus-mirrors` (europe-west1) | GCP EU | K8s-native (mTLS 9093) | MSK eu-west-1 (9094) | Janus whitelist with `gcp.` prefix |
| `msk-gcp-janus-mirrors` (europe-west1) | GCP EU | MSK eu-west-1 (9094) | K8s-native (mTLS 9093) | Janus whitelist with `msk.` prefix |
| `gcp-msk-janus-mirrors` (us-central1) | GCP NA | K8s-native (mTLS 9093) | MSK us-west-2 (9094) | Janus cloud topics with `gcp.` prefix |
| `gcp-k8s-eu-rapi-forwarder` (eu-west-1) | AWS EU | GCP NA (mTLS 9094) | K8s-native EU (mTLS 9093) | `batch_dispatch_rapi` |
| `batch-dispatch-email-usc-to-k8s-eu` (eu-west-1) | AWS EU | GCP NA (mTLS 9094) | K8s-native EU (mTLS 9093) | `batch_dispatch_email` |
| `batch-dispatch-push-usc-to-k8s-eu` (eu-west-1) | AWS EU | GCP NA (mTLS 9094) | K8s-native EU (mTLS 9093) | `batch_dispatch_push` |
| `cdp-ingress-eu-to-usc-topic` (us-central1) | GCP NA | MSK eu-west-1 (9094) | K8s-native GCP NA (mTLS 9093) | `cdp_ingress` |
| `gcp-msk-gaurun-mirrors` (europe-west1) | GCP EU | K8s-native | MSK eu-west-1 | Gaurun push notification topics |
| `gcp-msk-holmes-mirrors` (europe-west1) | GCP EU | K8s-native | MSK eu-west-1 | Holmes topics |

## Steps

1. **Resolve cross-cloud broker endpoints**: At startup, the Security Bootstrap reads mTLS certificates from `/var/groupon/certs` as needed. Since cross-cloud traffic often traverses public endpoints (MSK external bootstrap, GCP external endpoint), mTLS is typically required on the cross-cloud side (e.g., `SOURCE_USE_MTLS=true` when sourcing from K8s-native; `DESTINATION_USE_MTLS=true` when producing to K8s-native).
   - From: `mirrorMaker_securityBootstrap`
   - To: `mirrorMaker_runtimeLauncher`
   - Protocol: In-process (certificate material)

2. **Connect to source cross-cloud cluster**: The MirrorMaker consumer opens a Kafka connection to the source endpoint. For GCP→MSK flows, source is the K8s-native cluster on port 9093 with mTLS. For MSK→GCP flows, source is the MSK external bootstrap on port 9094 without mTLS.
   - From: `continuumMirrorMakerService`
   - To: `continuumKafkaBroker` (source)
   - Protocol: Kafka consumer protocol (TCP/mTLS or TCP plaintext)

3. **Poll records from cross-cloud topics**: MirrorMaker polls the cross-cloud source topics (per `WHITELIST`). For batch dispatch flows, topics such as `batch_dispatch_email`, `batch_dispatch_push`, and `batch_dispatch_rapi` are consumed. For CDP ingress, `cdp_ingress` is consumed.
   - From: `continuumMirrorMakerService`
   - To: `continuumKafkaBroker` (source)
   - Protocol: Kafka consumer fetch

4. **Apply topic prefix or use as-is**: Cross-cloud non-Janus flows (batch dispatch, CDP ingress, RAPI forwarder) do not apply topic prefix — records are produced to the same topic name on the destination cluster. Janus cross-cloud flows apply the `gcp.` or `msk.` prefix as described in [Janus Topic Forwarding](janus-topic-forwarding.md).
   - From: `mirrorMaker_runtimeLauncher` (in-process)
   - To: Producer buffer
   - Protocol: In-process

5. **Produce to destination cluster across cloud boundary**: Records are published to the destination Kafka cluster. For cross-cloud flows, producer settings `BATCH_SIZE=200000` and `LINGER_MS=1000` are used for efficiency over higher-latency inter-cloud links. `MAX_REQUEST_SIZE` is set to 4194304 bytes for batch dispatch email flows to accommodate large payloads.
   - From: `continuumMirrorMakerService`
   - To: `continuumKafkaBroker` (destination)
   - Protocol: Kafka producer protocol (TCP/mTLS)

6. **Commit source offsets**: Offsets committed to source broker after acknowledgement from destination.
   - From: `continuumMirrorMakerService`
   - To: `continuumKafkaBroker` (source)
   - Protocol: Kafka offset commit

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Cross-cloud network partition | Producer retries; consumer lag grows on source | Data is not lost from source; records replayed once connectivity restores |
| mTLS certificate expiry on cross-cloud connection | SSL handshake failure at Kafka client level | MirrorMaker cannot connect; pod stays running (pgrep java passes); requires certificate rotation and pod restart |
| Large message exceeding `MAX_REQUEST_SIZE` | Producer exception | Record dropped; `record-error-rate` metric increments; increase `MAX_REQUEST_SIZE` if needed |
| GCP Kafka endpoint unavailable | Consumer cannot poll | Replication halts for that direction; MSK→GCP reverse direction continues independently |

## Sequence Diagram

```
ServiceOnGCP -> GCPKafka: Produce to janus-cloud-all_snc1 (example)
MirrorMakerService(GCP pod) -> K8sNativeKafka: Poll janus-cloud-all_snc1 (SOURCE mTLS 9093)
K8sNativeKafka --> MirrorMakerService: Return record batch
MirrorMakerService -> MirrorMakerService: Apply gcp. prefix (IS_JANUS_FORWARDER=true)
MirrorMakerService -> MSKCluster: Produce gcp.janus-cloud-all_snc1 (DESTINATION 9094)
MSKCluster --> MirrorMakerService: ACKS=1
MirrorMakerService -> K8sNativeKafka: Commit source offsets
```

## Related

- Architecture dynamic view: `dynamic-mirror-maker-replication-flow`
- Related flows: [Topic Replication](topic-replication.md), [Janus Topic Forwarding](janus-topic-forwarding.md)
