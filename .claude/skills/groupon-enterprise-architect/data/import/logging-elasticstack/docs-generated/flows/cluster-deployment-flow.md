---
service: "logging-elasticstack"
title: "Cluster Deployment Flow"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "cluster-deployment-flow"
flow_type: event-driven
trigger: "Jenkins branch push to release-gcp-us, release-gcp-staging, or release-eu; or manual Ansible run for on-prem"
participants:
  - "continuumLoggingLogstash"
  - "continuumLoggingElasticsearch"
  - "continuumLoggingKibana"
architecture_ref: "dynamic-logging-logstashPipeline-flow"
---

# Cluster Deployment Flow

## Summary

The Cluster Deployment Flow covers the full pipeline for building, testing, and deploying the Logging Elastic Stack to a target environment. For GKE-based environments, Jenkins detects a push to a release branch, builds Docker images, runs Logstash filter unit tests, and deploys the updated cluster components via Krane and Helm. For on-prem environments, the Logging Platform Team runs Ansible playbooks directly. The flow ensures that Logstash filter changes are tested before reaching any cluster.

## Trigger

- **Type**: event-driven (GKE) / manual (on-prem)
- **Source**: Git push to `release-gcp-us`, `release-gcp-staging`, or `release-eu` Jenkins pipeline branch; manual Ansible playbook execution for on-prem (snc1, sac1, dub1)
- **Frequency**: On-demand, per code or configuration change

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Jenkins | Detects branch push; orchestrates build, test, and deployment pipeline stages | — |
| Make / Docker | Builds Docker images for Logstash, Elasticsearch, and Ansible tooling | — |
| Logstash Filter Tests | Validates per-sourcetype filter configurations with unit tests before deployment | `continuumLoggingLogstash` |
| Krane | Applies Helm chart deployments to GKE clusters for Logstash, Elasticsearch (ECK), and Kibana | — |
| Helm | Packages and templates Kubernetes manifests for GKE deployments | — |
| Ansible | Provisions and configures on-prem ELK cluster nodes via ClusterShell parallel execution | — |
| Elasticsearch (ECK) | Receives updated container images; ECK operator manages rolling restart | `continuumLoggingElasticsearch` |
| Logstash (GKE) | Receives updated container image and filter configs; Kubernetes rolling deployment | `continuumLoggingLogstash` |
| Kibana (GKE) | Receives updated container image; Kubernetes rolling deployment | `continuumLoggingKibana` |

## Steps

### GKE Deployment Path

1. **Push to release branch**: A Logging Platform Team engineer merges changes to a release branch (`release-gcp-us`, `release-gcp-staging`, or `release-eu`).
   - From: `Engineer`
   - To: `Jenkins` (branch webhook trigger)
   - Protocol: Git push / Jenkins webhook

2. **Build Docker images**: Jenkins triggers Make to build updated Docker images for Logstash (Java 21 / Alpine 3.16 base), Elasticsearch, and any updated Ansible tooling images.
   - From: `Jenkins`
   - To: `Docker registry`
   - Protocol: `make build` → Docker build and push

3. **Run Logstash filter unit tests**: Jenkins executes the Logstash filter test suite against all per-sourcetype filter configurations. Tests validate grok patterns, field mutations, and date parsing using sample log lines.
   - From: `Jenkins`
   - To: `continuumLoggingLogstash` (test runner)
   - Protocol: `make test` → Logstash `--config.test_and_exit` or rspec filter tests

4. **Gate on test results**: If any filter unit test fails, the pipeline halts and notifies the team. No deployment proceeds.
   - From: `Jenkins`
   - To: `Logging Platform Team` (notification)
   - Protocol: Jenkins build failure notification

5. **Deploy via Krane**: On test success, Jenkins runs Krane to apply the updated Helm chart release to the target GKE cluster. Krane performs a structured rollout, validating each resource before proceeding.
   - From: `Jenkins`
   - To: `GKE cluster`
   - Protocol: Krane + Helm (`helm upgrade` → Kubernetes API)

6. **ECK operator manages Elasticsearch rolling restart**: For Elasticsearch changes, the ECK operator detects the updated spec and performs a safe rolling restart, ensuring cluster health is maintained throughout.
   - From: `ECK operator`
   - To: `continuumLoggingElasticsearch`
   - Protocol: Kubernetes controller loop

7. **Logstash rolling deployment**: Kubernetes performs a rolling deployment of the updated Logstash pods. New pods start consuming from Kafka consumer group offsets; old pods drain and terminate.
   - From: `Kubernetes`
   - To: `continuumLoggingLogstash`
   - Protocol: Kubernetes rolling update

8. **Kibana rolling deployment**: Kubernetes performs a rolling deployment of the updated Kibana pods.
   - From: `Kubernetes`
   - To: `continuumLoggingKibana`
   - Protocol: Kubernetes rolling update

9. **Post-deployment smoke test**: Jenkins or the engineer validates cluster health (`/_cluster/health`) and Kibana status (`/api/status`) to confirm successful deployment.
   - From: `Jenkins` / `Engineer`
   - To: `continuumLoggingElasticsearch`, `continuumLoggingKibana`
   - Protocol: REST HTTP

### On-Prem Deployment Path (Ansible)

1. **Engineer runs Ansible playbook**: The Logging Platform Team engineer manually triggers the appropriate Ansible playbook targeting the on-prem cluster (snc1, sac1, or dub1) for the desired role (logstash, elasticsearch, or kibana).
   - From: `Engineer`
   - To: `Ansible`
   - Protocol: manual command execution

2. **ClusterShell parallel execution**: Ansible uses ClusterShell to execute provisioning and configuration tasks in parallel across all cluster nodes.
   - From: `Ansible`
   - To: `On-prem ELK nodes`
   - Protocol: SSH (ClusterShell)

3. **Service restart and health validation**: Ansible restarts the relevant ELK service on each node and validates that it comes up healthy before proceeding to the next node (serial deployment).
   - From: `Ansible`
   - To: `continuumLoggingElasticsearch` / `continuumLoggingLogstash` / `continuumLoggingKibana`
   - Protocol: SSH + systemctl + REST health check

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Filter unit test failure | Jenkins pipeline halts; no deployment proceeds | Engineers fix filter config; re-push branch to retry |
| Krane deployment timeout | Krane reports failure; Helm revision rolled back automatically | Previous release restored; engineers investigate pod events and logs |
| ECK rolling restart health degraded | ECK operator pauses rolling restart when cluster health drops to red | Restart paused until cluster recovers; engineers investigate unassigned shards |
| Ansible node provisioning failure | Ansible reports task failure on affected node; stops or continues per `ignore_errors` setting | Node may be in partial state; manual remediation required for failed node |
| Logstash pod OOMKilled during deployment | Kubernetes restarts pod; consumer group offset maintained in Kafka | Kafka lag increases during restart; recovers automatically on pod restart |

## Sequence Diagram

```
Engineer -> Git: Push to release-gcp-us branch
Git -> Jenkins: Webhook triggers pipeline
Jenkins -> Docker: make build (Docker images for Logstash, ES, Ansible)
Docker --> Jenkins: Images built and pushed to registry
Jenkins -> Logstash: make test (filter unit tests)
Logstash --> Jenkins: All tests pass
Jenkins -> Krane: helm upgrade (apply Helm chart to GKE cluster)
Krane -> Kubernetes: Apply Logstash, Elasticsearch (ECK), Kibana manifests
ECK Operator -> Elasticsearch: Rolling restart (updated spec)
Kubernetes -> Logstash: Rolling pod deployment
Kubernetes -> Kibana: Rolling pod deployment
Jenkins -> Elasticsearch: GET /_cluster/health (smoke test)
Elasticsearch --> Jenkins: green/yellow (deployment successful)
Jenkins -> Kibana: GET /api/status (smoke test)
Kibana --> Jenkins: OK
Jenkins -> Engineer: Pipeline success notification
```

## Related

- Architecture dynamic view: `dynamic-logging-logstashPipeline-flow`
- Related flows: [Log Source Onboarding Flow](log-source-onboarding-flow.md), [Log Ingestion and Search Flow](logging-ingestion-search-flow.md)
