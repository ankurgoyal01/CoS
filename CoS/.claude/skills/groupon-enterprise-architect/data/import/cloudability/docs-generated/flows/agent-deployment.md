---
service: "cloudability"
title: "Agent Deployment"
generated: "2026-03-03"
type: flow
flow_name: "agent-deployment"
flow_type: batch
trigger: "Merge to main branch triggers deploybot; or manual kubectl apply by SRE operator"
participants:
  - "continuumCloudabilityProvisioningCli"
  - "deploymentExecutor"
  - "continuumCloudabilityMetricsAgent"
architecture_ref: "dynamic-cloudability-agent-provisioning-flow"
---

# Agent Deployment

## Summary

This flow describes how the patched Cloudability Metrics Agent manifest is deployed to one or more Conveyor Kubernetes clusters. Deployment is triggered automatically by deploybot when changes to the `secrets/` submodule are merged to `main`, following the configured cluster promotion chain. SRE operators may also apply manifests manually using `kubectl apply`. The end result is a running `cloudability-metrics-agent` Deployment in the appropriate namespace on each target cluster.

## Trigger

- **Type**: automatic (merge to `main`) or manual (`kubectl apply`)
- **Source**: Merge to `main` branch in the cloudability repo (deploybot monitors secrets submodule changes); or SRE operator manually runs `kubectl apply`
- **Frequency**: On every merge that updates the secrets submodule; or on-demand for manual deployments

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Deployment Executor | Applies manifests to target cluster | `deploymentExecutor` |
| Deploybot | Orchestrates sequential cluster promotion | `.deploy_bot.yml` |
| Conveyor Kubernetes Cluster | Receives and runs the deployed workload | Conveyor infrastructure |
| Cloudability Metrics Agent | Deployed workload; begins running after manifest applied | `continuumCloudabilityMetricsAgent` |

## Steps

1. **Merge to Main**: Cloud SRE merges a pull request updating the `secrets/` submodule with refreshed manifests.
   - From: SRE operator
   - To: `main` branch
   - Protocol: git / GitHub

2. **Deploybot Detects Change**: Deploybot at `https://deploybot.groupondev.com/CloudSRE/cloudability` detects the updated secrets submodule and initiates the deployment pipeline.
   - From: deploybot
   - To: `.deploy_bot.yml` configuration
   - Protocol: deploybot API

3. **Notify Start**: Deploybot posts a start notification to Slack channel `CNY6HCXBJ` (cloud-sre-testing).
   - From: deploybot
   - To: Slack
   - Protocol: Slack API

4. **Staging Cluster Rollout**: Deploybot runs `kubectl -n cloudability-staging apply -f secrets/conveyor-<staging-context>.yml` for each staging cluster in sequence, following the promotion chain: `staging-us-west-1` → `staging-us-west-2` → `staging-us-central1` (and independently `staging-europe-west1`).
   - From: `deploymentExecutor`
   - To: Staging Conveyor Kubernetes clusters
   - Protocol: kubectl apply

5. **Promote to Production**: After staging promotion completes, deploybot applies manifests to production clusters: `production-us-west-1` → `production-us-west-2` → `production-eu-west-1`; and separately `production-us-central1`, `production-europe-west1`.
   - From: `deploymentExecutor`
   - To: Production Conveyor Kubernetes clusters
   - Protocol: kubectl apply

6. **Agent Pod Starts**: Kubernetes creates or updates the `cloudability-metrics-agent` Deployment in the `cloudability-<env>` namespace. The pod starts with the pinned image `docker.groupondev.com/cloudability/metrics-agent:2.4`.
   - From: Kubernetes Deployment controller
   - To: `continuumCloudabilityMetricsAgent`
   - Protocol: Kubernetes

7. **Notify Complete**: Deploybot posts a completion notification to Slack channel `CNY6HCXBJ`.
   - From: deploybot
   - To: Slack
   - Protocol: Slack API

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| kubectl apply fails on a cluster | Deploybot halts promotion at the failed cluster | Downstream clusters are not updated; SRE investigates |
| Pod fails to start (ImagePullBackOff) | Kubernetes retries; pod stays in non-Running state | SRE checks image availability and registry access |
| Pod restarts repeatedly | Kubernetes liveness probe failure triggers restart loop | SRE checks ClusterRole/ClusterRoleBinding; see [Runbook](../runbook.md) |
| Dry run server-side fails | Kubernetes API rejects manifest; namespace may not exist | SRE verifies namespace pre-exists before apply |

## Sequence Diagram

```
SRE Operator -> GitHub: merge PR updating secrets submodule
GitHub -> deploybot: webhook (main branch updated)
deploybot -> Slack: notify start (channel CNY6HCXBJ)
deploybot -> staging-us-west-1: kubectl apply -f secrets/conveyor-stable-us-west-1.yml
deploybot -> staging-us-west-2: kubectl apply -f secrets/conveyor-stable-us-west-2.yml
deploybot -> staging-us-central1: kubectl apply -f secrets/conveyor-gcp-stable-us-central1.yml
deploybot -> production-us-west-1: kubectl apply -f secrets/conveyor-production-us-west-1.yml
deploybot -> production-us-west-2: kubectl apply -f secrets/conveyor-production-us-west-2.yml
Kubernetes --> deploybot: Deployment updated; pod running
deploybot -> Slack: notify complete (channel CNY6HCXBJ)
```

## Related

- Architecture dynamic view: `dynamic-cloudability-agent-provisioning-flow`
- Related flows: [Cluster Registration and Manifest Generation](cluster-registration.md), [Kubernetes Metrics Collection and Upload](metrics-collection.md)
