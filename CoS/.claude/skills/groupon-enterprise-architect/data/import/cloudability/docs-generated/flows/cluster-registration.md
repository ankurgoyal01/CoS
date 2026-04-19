---
service: "cloudability"
title: "Cluster Registration and Manifest Generation"
generated: "2026-03-03"
type: flow
flow_name: "cluster-registration"
flow_type: batch
trigger: "Manual — Cloud SRE operator runs get_agent_config.sh on the target kubectl context"
participants:
  - "continuumCloudabilityProvisioningCli"
  - "clusterRegistrationClient"
  - "configFetcher"
  - "manifestPatcher"
architecture_ref: "dynamic-cloudability-agent-provisioning-flow"
---

# Cluster Registration and Manifest Generation

## Summary

This flow covers the process of onboarding a new Conveyor Kubernetes cluster into Cloudability. A Cloud SRE operator runs `get_agent_config.sh` against the target kubectl context, which registers the cluster with the Cloudability Provisioning API, retrieves the auto-generated Kubernetes deployment manifest, and applies Groupon-specific hardening patches. The resulting patched manifest is saved to the `secrets/` submodule ready for deployment.

## Trigger

- **Type**: manual
- **Source**: Cloud SRE operator invokes `get_agent_config.sh` from a shell with an active `kubectl` context and a valid API key in `secrets/provisioning-api-key`
- **Frequency**: On-demand — once per new cluster, or when the manifest needs to be refreshed

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Cloudability Provisioning CLI | Orchestrates the registration and patch process | `continuumCloudabilityProvisioningCli` |
| Cluster Registration Client | Sends registration request to Cloudability API | `clusterRegistrationClient` |
| Config Fetcher | Retrieves generated agent manifest for the registered cluster | `configFetcher` |
| Manifest Patcher | Applies Groupon-specific hardening modifications | `manifestPatcher` |
| Cloudability Provisioning API (external) | Accepts cluster registration; returns generated manifests | `cloudabilityProvisioningApi_1be936` |

## Steps

1. **Read API Key**: Reads `secrets/provisioning-api-key` from the secrets submodule. Exits with an error if the key is missing or empty.
   - From: `continuumCloudabilityProvisioningCli`
   - To: `secrets/provisioning-api-key` (file)
   - Protocol: filesystem read

2. **Resolve kubectl Context**: Derives the cluster name by prepending `conveyor-` to the current `kubectl config current-context` value.
   - From: `continuumCloudabilityProvisioningCli`
   - To: `kubectl` (local CLI)
   - Protocol: direct

3. **Register Cluster**: POSTs to `https://api.cloudability.com/v3/containers/provisioning` with the cluster name and Kubernetes version `1.16`. If the cluster already exists, the API returns HTTP 400 (non-fatal; existing cluster key is preserved).
   - From: `clusterRegistrationClient`
   - To: Cloudability Provisioning API
   - Protocol: HTTPS/REST (HTTP Basic Auth)

4. **Resolve Cluster ID**: GETs the full cluster list from `https://api.cloudability.com/v3/containers/provisioning` and extracts the cluster ID for the current context using `jq`.
   - From: `clusterRegistrationClient`
   - To: Cloudability Provisioning API
   - Protocol: HTTPS/REST

5. **Fetch Agent Manifest**: GETs the generated Kubernetes deployment manifest from `https://api.cloudability.com/v3/containers/provisioning/{id}/config` and writes it to `secrets/<context>.yml`.
   - From: `configFetcher`
   - To: Cloudability Provisioning API
   - Protocol: HTTPS/REST

6. **Apply Groupon Patches**: Applies a `patch` diff to the raw manifest, making the following modifications:
   - Removes Namespace creation block (namespace is pre-provisioned by Conveyor)
   - Removes ClusterRole and ClusterRoleBinding blocks (managed by `aaa` playbook as `generic-metrics-agent-clusterrole`)
   - Replaces `cloudability` namespace with `cloudability-<suffix>` (staging / production / dev)
   - Pins container image from `cloudability/metrics-agent:latest` to `docker.groupondev.com/cloudability/metrics-agent:2.4`
   - Changes `imagePullPolicy` from `Always` to `IfNotPresent`
   - Reduces memory request/limit from `2Gi/4Gi` to `1024Mi/1024Mi`
   - Reduces CPU request/limit from `0.5/1` to `1000m/1000m`
   - Adds `com.groupon.conveyor.policies/skip-readiness-probe` annotation
   - From: `manifestPatcher`
   - To: `secrets/<context>.yml`
   - Protocol: GNU patch (filesystem)

7. **Commit to Secrets Submodule**: Operator commits the patched `secrets/conveyor-<context>.yml` to the `cloudability-secrets` submodule and updates the reference in the main repo.
   - From: Cloud SRE operator
   - To: `secrets/` (git submodule)
   - Protocol: git

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Missing API key | Script exits immediately with descriptive message | No registration attempt made |
| Unresolvable kubectl context | Script exits immediately | No API calls made |
| Cluster already registered (HTTP 400) | Treated as non-fatal; existing cluster key used | Flow continues to config fetch |
| Cluster ID not found after registration | Script exits and prints the manual curl command for provisioning | Operator must provision manually |
| Patch application fails | GNU patch returns non-zero exit code; script fails via `set -e` | Operator must inspect raw manifest and patch file |

## Sequence Diagram

```
SRE Operator -> get_agent_config.sh: run with active kubectl context
get_agent_config.sh -> secrets/provisioning-api-key: read API key
get_agent_config.sh -> kubectl: resolve current context
get_agent_config.sh -> Cloudability Provisioning API: POST /v3/containers/provisioning (register cluster)
Cloudability Provisioning API --> get_agent_config.sh: 200 OK or 400 Already Exists
get_agent_config.sh -> Cloudability Provisioning API: GET /v3/containers/provisioning (list clusters)
Cloudability Provisioning API --> get_agent_config.sh: cluster list JSON
get_agent_config.sh -> jq: extract cluster ID by name
get_agent_config.sh -> Cloudability Provisioning API: GET /v3/containers/provisioning/{id}/config
Cloudability Provisioning API --> get_agent_config.sh: raw Kubernetes manifest YAML
get_agent_config.sh -> manifestPatcher: patch raw manifest (namespace, RBAC, image, resources)
manifestPatcher --> get_agent_config.sh: patched manifest written to secrets/<context>.yml
SRE Operator -> git: commit secrets submodule update
```

## Related

- Architecture dynamic view: `dynamic-cloudability-agent-provisioning-flow`
- Related flows: [Agent Deployment](agent-deployment.md)
