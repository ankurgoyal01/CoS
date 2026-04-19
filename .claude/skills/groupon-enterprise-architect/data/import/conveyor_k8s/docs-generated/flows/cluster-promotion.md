---
service: "conveyor_k8s"
title: "Cluster Promotion"
generated: "2026-03-03"
type: flow
flow_name: "cluster-promotion"
flow_type: batch
trigger: "Jenkins `promote-cluster` job triggered manually by an operator with source and destination cluster names"
participants:
  - "conveyorK8sPipelines"
  - "conveyorK8sPipelineUtils"
  - "kubernetesClusters"
  - "aws"
architecture_ref: "dynamic-conveyorK8s"
---

# Cluster Promotion

## Summary

Cluster promotion replaces an existing active cluster (source) with a newly created cluster (destination). The pipeline coordinates data migration, readiness verification, and traffic cutover while tracking promotion state in a Kubernetes ConfigMap. A Wavefront event is opened at the start and closed at the end to mark the maintenance window in metrics dashboards. If any stage fails, the promotion status is set to `FAILED` and a Google Chat alert is sent.

## Trigger

- **Type**: manual
- **Source**: Jenkins `conveyor-cloud/promote-cluster` job; operator supplies `SOURCE_CLUSTER_NAME`, `DESTINATION_CLUSTER_NAME`, `CLUSTER_TYPE`, and promotion stage parameters
- **Frequency**: On-demand — triggered when a new cluster is ready to replace an existing one

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Conveyor K8s Pipelines | Orchestrates promotion stages in order | `conveyorK8sPipelines` |
| Pipeline Utils (`promotion`) | Reads/writes promotion metadata (status, eligible time, Wavefront ID) to Kubernetes ConfigMaps | `conveyorK8sPipelineUtils` |
| Pipeline Utils (`services_readiness`) | Polls destination cluster LoadBalancer services and compares against source | `conveyorK8sPipelineUtils` |
| Pipeline Utils (`wavefront`) | Opens and closes Wavefront events for the promotion window | `conveyorK8sPipelineUtils` |
| Pipeline Utils (`find_clusters`) | Resolves cluster names to S3 bucket metadata | `conveyorK8sPipelineUtils` |
| Source Kubernetes Cluster | Reference cluster; readiness baseline for LoadBalancer service comparison | `kubernetesClusters` (external stub) |
| Destination Kubernetes Cluster | New cluster being promoted; receives traffic | `kubernetesClusters` (external stub) |
| AWS S3 | Stores cluster state buckets used for cluster discovery | `aws` (external stub) |

## Steps

1. **Checkout and validate inputs**: Pipeline checks out the repository and validates that source and destination cluster names, environment, and region are provided and consistent.
   - From: `conveyorK8sPipelines`
   - To: Jenkins SCM
   - Protocol: Git

2. **Open Wavefront event**: The `wavefront create-event` binary sends `POST /api/v2/event` to mark the start of the promotion window.
   - From: `conveyorK8sPipelineUtils` (wavefront)
   - To: Wavefront API
   - Protocol: REST HTTP (Bearer token auth)

3. **Set promotion metadata to IN_PROGRESS**: The `promotion set metadata` binary writes a ConfigMap to the destination cluster with `SourceCluster`, `DestinationCluster`, `Status=IN_PROGRESS`, and the Wavefront event ID.
   - From: `conveyorK8sPipelineUtils` (promotion)
   - To: `kubernetesClusters` (destination) Kubernetes API
   - Protocol: k8s client-go

4. **Run data migration**: The `run-data-migration` Jenkins sub-pipeline migrates persistent data from the source cluster to the destination cluster.
   - From: `conveyorK8sPipelines`
   - To: `kubernetesClusters`
   - Protocol: Jenkins job invocation

5. **Check service readiness**: The `services_readiness` binary polls the destination cluster's LoadBalancer services and compares them against the source cluster. Retries with exponential backoff (default: 5 attempts, 1–5 minute intervals, factor 1.5, jitter). A service is ready when at least `percAvailableReplicas` (default 50%) of replicas are running and ready.
   - From: `conveyorK8sPipelineUtils` (services_readiness)
   - To: `kubernetesClusters` (source + destination)
   - Protocol: k8s client-go (Kubernetes API)

6. **Run traffic migration**: The `run-traffic-migration` Jenkins sub-pipeline migrates traffic from the source cluster to the destination cluster (DNS or load balancer cutover).
   - From: `conveyorK8sPipelines`
   - To: `kubernetesClusters` / cloud load balancer
   - Protocol: Jenkins job invocation / cloud API

7. **Set promotion metadata to SUCCEEDED**: The `promotion set metadata` binary updates the ConfigMap with `Status=SUCCEEDED` and the `NextPromotionEligibleTime`.
   - From: `conveyorK8sPipelineUtils` (promotion)
   - To: `kubernetesClusters` (destination) Kubernetes API
   - Protocol: k8s client-go

8. **Close Wavefront event**: The `wavefront close-event` binary sends `POST /api/v2/event/{id}/close` to mark the end of the promotion window.
   - From: `conveyorK8sPipelineUtils` (wavefront)
   - To: Wavefront API
   - Protocol: REST HTTP (Bearer token auth)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Service readiness check times out | `services_readiness` exits non-zero after max attempts | Pipeline fails; promotion metadata set to `FAILED`; GChat alert sent |
| Data migration fails | Jenkins sub-pipeline fails; parent pipeline fails | Promotion halted; manual recovery required; source cluster remains active |
| Traffic migration fails | Jenkins sub-pipeline fails; parent pipeline fails | Promotion metadata set to `FAILED`; source cluster may still be active |
| Wavefront event creation fails | Non-fatal; promotion continues | Promotion window not marked in dashboards; no blocking effect |
| Wavefront event close fails | Non-fatal; promotion continues | Event may remain open in Wavefront; manual close required |

## Sequence Diagram

```
Operator -> Jenkins: Trigger promote-cluster (SOURCE, DESTINATION, ENV, REGION)
Jenkins -> wavefront: create-event (POST /api/v2/event)
wavefront --> Jenkins: Wavefront event ID

Jenkins -> promotion: set metadata (IN_PROGRESS, wavefrontEventId)
promotion -> DestinationCluster: Write ConfigMap
DestinationCluster --> promotion: OK

Jenkins -> DataMigration: run-data-migration sub-pipeline
DataMigration -> SourceCluster: Read persistent data
DataMigration -> DestinationCluster: Write persistent data
DataMigration --> Jenkins: Migration complete

Jenkins -> services_readiness: --source-cluster SOURCE --destination-cluster DEST
services_readiness -> SourceCluster: GetReadyLoadBalancerServices
services_readiness -> DestinationCluster: GetReadyLoadBalancerServices
DestinationCluster --> services_readiness: Services ready (>= 50% replicas)
services_readiness --> Jenkins: Readiness check passed

Jenkins -> TrafficMigration: run-traffic-migration sub-pipeline
TrafficMigration -> LoadBalancer: Cutover traffic to destination cluster
LoadBalancer --> TrafficMigration: Traffic migrated
TrafficMigration --> Jenkins: Migration complete

Jenkins -> promotion: set metadata (SUCCEEDED, nextEligibleTime)
promotion -> DestinationCluster: Update ConfigMap
DestinationCluster --> promotion: OK

Jenkins -> wavefront: close-event (POST /api/v2/event/{id}/close)
wavefront --> Jenkins: Event closed
Jenkins --> Operator: Promotion succeeded
```

## Related

- Architecture dynamic view: `dynamic-conveyorK8s`
- Related flows: [Cluster Creation (GKE)](cluster-creation-gke.md) — creates the destination cluster before promotion; [Cluster Discovery](cluster-discovery.md) — used to resolve cluster names during promotion setup
