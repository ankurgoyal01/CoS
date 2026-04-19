---
service: "raas"
title: "Kubernetes Config Sync"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "kubernetes-config-sync"
flow_type: scheduled
trigger: "Continuous polling loop in the K8s Config Updater"
participants:
  - "continuumRaasConfigUpdaterService"
  - "continuumRaasElastiCacheApi"
  - "continuumRaasTerraformDefsUrl"
  - "continuumRaasKubernetesApi"
architecture_ref: "components-continuumRaasConfigUpdaterService"
---

# Kubernetes Config Sync

## Summary

The Kubernetes Config Sync flow keeps telegraf deployment config maps in Kubernetes up to date with the current set of Redis and Memcached endpoints discovered from AWS ElastiCache. The Config Updater runs a continuous reconciliation loop: it discovers live endpoints via the ElastiCache API, fetches resque namespace metadata from Terraform definitions, detects changes, and applies updated config maps and deployment resources to Kubernetes.

## Trigger

- **Type**: schedule
- **Source**: Continuous polling loop within `continuumRaasConfigUpdaterService_raasConfigUpdaterLoop`
- **Frequency**: Continuous (loop-based reconciliation; polling interval not specified in architecture model)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Config Updater Loop | Main reconciliation loop; orchestrates discovery and application | `continuumRaasConfigUpdaterService` |
| AWS Discovery Client | Queries ElastiCache and normalizes discovered endpoints | `continuumRaasConfigUpdaterService` |
| Terraform Repo Parser | Fetches and parses Terraform definitions for resque namespace mappings | `continuumRaasConfigUpdaterService` |
| Kubernetes Deploy Client | Builds and applies telegraf config maps and deployment updates | `continuumRaasConfigUpdaterService` |
| AWS ElastiCache API | Provides live cache cluster and endpoint data | `continuumRaasElastiCacheApi` |
| Terraform Redis Definitions URL | Provides resque namespace-to-cluster mapping metadata | `continuumRaasTerraformDefsUrl` |
| Kubernetes API | Receives config map and deployment update requests | `continuumRaasKubernetesApi` |

## Steps

1. **Initiate reconciliation loop iteration**: The Config Updater Loop starts a new reconciliation cycle.
   - From: `continuumRaasConfigUpdaterService_raasConfigUpdaterLoop`
   - To: (internal)
   - Protocol: In-process

2. **Discover live ElastiCache endpoints**: The AWS Discovery Client queries the ElastiCache API for all cache clusters and normalizes the discovered Redis and Memcached endpoints.
   - From: `continuumRaasConfigUpdaterService_raasConfigUpdaterLoop`
   - To: `continuumRaasConfigUpdaterService_raasAwsDiscoveryClient` → `continuumRaasElastiCacheApi`
   - Protocol: AWS SDK

3. **Load resque namespace mappings**: The Terraform Repo Parser fetches the Terraform-hosted Redis definitions file and parses it to produce a resque namespace-to-cluster map.
   - From: `continuumRaasConfigUpdaterService_raasConfigUpdaterLoop`
   - To: `continuumRaasConfigUpdaterService_raasTerraformRepoParser` → `continuumRaasTerraformDefsUrl`
   - Protocol: HTTPS

4. **Detect server-set changes**: The Config Updater Loop compares the discovered endpoint set against the currently applied Kubernetes config map state.
   - From: `continuumRaasConfigUpdaterService_raasConfigUpdaterLoop`
   - To: (in-process comparison)
   - Protocol: In-process

5. **Build updated config maps**: If changes are detected, the Kubernetes Deploy Client constructs updated telegraf config maps incorporating the new endpoint set and namespace mappings.
   - From: `continuumRaasConfigUpdaterService_raasConfigUpdaterLoop`
   - To: `continuumRaasConfigUpdaterService_raasKubeDeployClient`
   - Protocol: In-process

6. **Apply config maps and deployment updates to Kubernetes**: The Kubernetes Deploy Client creates or updates telegraf config map and deployment resources via the Kubernetes API.
   - From: `continuumRaasConfigUpdaterService_raasKubeDeployClient`
   - To: `continuumRaasKubernetesApi`
   - Protocol: Kubernetes API (client-go)

7. **Publish update metrics**: The Config Updater publishes config-update event metrics to the metrics stack.
   - From: `continuumRaasConfigUpdaterService`
   - To: `metricsStack`
   - Protocol: Metrics push

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| ElastiCache API unreachable | Discovery step fails; reconciliation loop retries on next iteration | Kubernetes config maps remain at last-applied state |
| Terraform definitions URL unavailable | Namespace mapping step fails; loop retries on next iteration | Config maps may be applied without updated namespace mappings |
| Kubernetes API write failure | Deploy Client logs error; config map update not applied | Telegraf deployment retains previous config; loop retries next iteration |
| No server-set changes detected | Reconciliation loop exits without applying updates | No change; Kubernetes config maps remain current |

## Sequence Diagram

```
continuumRaasConfigUpdaterService -> continuumRaasElastiCacheApi    : Discover ElastiCache endpoints
continuumRaasElastiCacheApi       --> continuumRaasConfigUpdaterService : Return endpoint list
continuumRaasConfigUpdaterService -> continuumRaasTerraformDefsUrl   : Fetch resque namespace definitions
continuumRaasTerraformDefsUrl     --> continuumRaasConfigUpdaterService : Return Terraform definitions
continuumRaasConfigUpdaterService -> continuumRaasConfigUpdaterService : Detect server-set changes
continuumRaasConfigUpdaterService -> continuumRaasKubernetesApi      : Apply telegraf config maps and deployment
continuumRaasKubernetesApi        --> continuumRaasConfigUpdaterService : Confirm update applied
continuumRaasConfigUpdaterService -> metricsStack                    : Publish config-update metrics
```

## Related

- Architecture dynamic view: `components-continuumRaasConfigUpdaterService`
- Related flows: [Terraform Deployment Post-Hook](terraform-deployment-post-hook.md)
