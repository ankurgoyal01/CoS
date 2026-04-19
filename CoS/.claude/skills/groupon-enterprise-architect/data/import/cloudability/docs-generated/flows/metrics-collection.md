---
service: "cloudability"
title: "Kubernetes Metrics Collection and Upload"
generated: "2026-03-03"
type: flow
flow_name: "metrics-collection"
flow_type: scheduled
trigger: "Continuous — Cloudability Metrics Agent runtime timer (approximately every 10 minutes)"
participants:
  - "continuumCloudabilityMetricsAgent"
  - "metricCollector"
  - "clusterMetadataCollector"
  - "metricsUploader"
  - "agentHealthChecks"
architecture_ref: "dynamic-cloudability-agent-provisioning-flow"
---

# Kubernetes Metrics Collection and Upload

## Summary

Once deployed to a Conveyor Kubernetes cluster, the Cloudability Metrics Agent runs a continuous scheduled loop. On each cycle it reads node, pod, namespace, and workload resource usage from the Kubernetes API Server, enriches samples with cluster identity metadata, packages them into a metric sample, and uploads the sample to Cloudability's ingestion endpoint via HTTPS. This data powers the container cost reporting visible in the Cloudability portal.

## Trigger

- **Type**: schedule (internal agent timer)
- **Source**: Cloudability Metrics Agent runtime (third-party container `docker.groupondev.com/cloudability/metrics-agent:2.4`)
- **Frequency**: Approximately every 10 minutes, as evidenced by log entries `Uploading Metrics` followed by `Exported metric sample ...`

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Cloudability Metrics Agent | Hosts and orchestrates the collection/upload cycle | `continuumCloudabilityMetricsAgent` |
| Metric Collector | Queries Kubernetes API for usage metrics | `metricCollector` |
| Cluster Metadata Collector | Provides cluster identity metadata to tag samples | `clusterMetadataCollector` |
| Metrics Uploader | Packages and uploads metric samples to Cloudability | `metricsUploader` |
| Agent Health and Probes | Monitors Metric Collector runtime health | `agentHealthChecks` |
| Kubernetes API Server (external) | Source of all cluster metrics data | `kubernetesApiServer_272a31` |
| Cloudability Ingestion API (external) | Destination for uploaded metric samples | `cloudabilityIngestionApi_c07c76` |

## Steps

1. **Agent Health Probe**: The Agent Health and Probes component verifies that the Metric Collector is alive and healthy before each collection cycle.
   - From: `agentHealthChecks`
   - To: `metricCollector`
   - Protocol: in-process health check

2. **Collect Node Metrics**: The Metric Collector queries the Kubernetes API Server for node-level resource usage, including CPU and memory requests, limits, and actual consumption.
   - From: `metricCollector`
   - To: Kubernetes API Server (`/api/v1/nodes`, `/api/v1/nodes/stats`, `/api/v1/nodes/metrics`)
   - Protocol: Kubernetes API (HTTPS)

3. **Collect Pod and Workload Metrics**: The Metric Collector queries for pod, namespace, deployment, replica set, daemon set, job, cron job, persistent volume, and persistent volume claim data.
   - From: `metricCollector`
   - To: Kubernetes API Server (`/api/v1/pods`, `/apis/apps/v1/deployments`, etc.)
   - Protocol: Kubernetes API (HTTPS)

4. **Collect Cluster Metadata**: The Cluster Metadata Collector reads cluster identity information (cluster name, region, environment) to tag the metric samples for cost attribution.
   - From: `metricCollector`
   - To: `clusterMetadataCollector`
   - Protocol: in-process

5. **Assemble Metric Sample**: The Metric Collector combines runtime metrics with cluster metadata into a named metric sample (e.g., `adfabfa8-728f-4693-a989-1329a1816b25_20220311185155`).
   - From: `metricCollector`
   - To: `metricsUploader`
   - Protocol: in-process

6. **Upload Metric Sample**: The Metrics Uploader sends the assembled sample to the Cloudability ingestion endpoint via HTTPS. On success, an `Exported metric sample <uuid>_<timestamp> to cloudability` entry is written to the agent log.
   - From: `metricsUploader`
   - To: Cloudability Ingestion API
   - Protocol: HTTPS

7. **Data Available in Portal**: Cloudability processes the ingested samples. Cost and usage data becomes visible in the Cloudability portal at `https://app.cloudability.com/#/containers` after a processing delay of up to 24 hours.
   - From: Cloudability Ingestion API
   - To: Cloudability portal (SaaS)
   - Protocol: Cloudability-internal

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Kubernetes API Server unreachable | Agent logs errors; Kubernetes liveness probe may fail, triggering restart | Pod restarts; SRE investigates ClusterRole/ClusterRoleBinding |
| Insufficient RBAC permissions | API requests return 403; agent logs permission errors | Pod restart loop; SRE must verify ClusterRole is applied correctly |
| Cloudability Ingestion API unreachable | Upload fails; agent retries on next cycle (governed by agent runtime) | Data gap for the missed cycle; portal shows stale data |
| Cloudability SaaS outage | No uploads succeed during outage window | Data gap in portal; no local fallback; check [status page](https://status.cloudability.com/) |

## Sequence Diagram

```
agentHealthChecks -> metricCollector: verify health
metricCollector -> Kubernetes API Server: GET /api/v1/nodes/stats (node metrics)
Kubernetes API Server --> metricCollector: node usage data
metricCollector -> Kubernetes API Server: GET /api/v1/pods (pod metrics)
Kubernetes API Server --> metricCollector: pod usage data
metricCollector -> clusterMetadataCollector: get cluster identity metadata
clusterMetadataCollector --> metricCollector: cluster name, region, environment
metricCollector -> metricsUploader: assembled metric sample
metricsUploader -> Cloudability Ingestion API: POST metric sample (HTTPS)
Cloudability Ingestion API --> metricsUploader: 200 OK
metricsUploader -> agent log: "Exported metric sample <uuid>_<timestamp> to cloudability"
```

## Related

- Architecture dynamic view: `dynamic-cloudability-agent-provisioning-flow`
- Related flows: [Agent Deployment](agent-deployment.md)
- Monitoring: see [Runbook](../runbook.md) for pod health checks and alert thresholds
