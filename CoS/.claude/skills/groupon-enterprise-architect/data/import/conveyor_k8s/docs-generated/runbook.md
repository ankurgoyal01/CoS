---
service: "conveyor_k8s"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `services_readiness` binary — polls Kubernetes LoadBalancer services on destination cluster | exec | Configurable (default: 5 attempts, 1–5 min backoff) | Configurable via `--backoff-max` flag |
| `check_cluster.yml` Ansible playbook | exec | On-demand | N/A |
| `check_etcd_cluster_health.yml` Ansible playbook | exec | On-demand | N/A |

## Monitoring

### Metrics

> No evidence found in codebase. Conveyor K8s does not expose Prometheus metrics. Cluster-level metrics are collected by monitoring agents (e.g., Prometheus, Filebeat) deployed to clusters via the provisioning playbooks, but that monitoring is external to this repository.

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Cluster promotion events | Wavefront | Configured by Wavefront event `baseUrl` at pipeline runtime |

### Alerts

> Operational procedures to be defined by service owner. Pipeline failures generate build status notifications to Google Chat (`notifyToGchatSpace()` called in the main Jenkinsfile on Terraform apply failures).

## Common Operations

### Restart Service

> Not applicable. Conveyor K8s is not a running service. To re-run a pipeline, re-trigger the Jenkins job or GitHub Actions workflow.

### Scale Up / Down

> Not applicable. To scale a cluster managed by this repo, modify the Terraform worker configuration in `terra-eks/modules/eks-cluster/variables.tf` or the equivalent GKE module, commit, and allow the pipeline to apply changes.

### Manual Ansible Deployment (Rollback or Hot-fix)

1. Navigate to the GitHub Actions tab for the `conveyor_k8s` repository.
2. Select the **"apply ansible playbook - manual"** workflow.
3. Click **"Run workflow"** and supply:
   - `environment`: one of `dev`, `stable`, `production`
   - `region`: `US` or `EU`
   - `git_ref`: the git tag or commit hash to deploy (or roll back to)
   - `playbook`: the specific playbook file (e.g., `install_descheduler.yml`)
4. Monitor the run; a deployment summary is published to the job summary page.

### Promote a Cluster (Jenkins)

1. Trigger the `conveyor-cloud/promote-cluster` Jenkins job.
2. Supply `SOURCE_CLUSTER_NAME`, `DESTINATION_CLUSTER_NAME`, `CLUSTER_TYPE`, and promotion stage parameters.
3. The pipeline validates inputs, sets promotion metadata (`IN_PROGRESS`), runs data migration, checks service readiness, then runs traffic migration.
4. On success, sets promotion status to `SUCCEEDED`.
5. On failure, sets status to `FAILED` and sends a Google Chat notification.

### Create a New Cluster (Jenkins / GKE)

1. Trigger `conveyor-cloud/create-cluster-conveyor` Jenkins job.
2. Supply `ENVIRONMENT`, `AWS_REGION` (or GCP equivalent), `CLUSTER_TYPE`, `CLUSTER_NAME`.
3. Pipeline provisions infrastructure via Terraform (`terra-gke/`), then applies Ansible provisioning playbooks (`conveyor_provisioning_playbook/kube.yml`).
4. Optionally runs integration tests (`RUN_INTEGRATION_TESTS=true`).

### Database Operations

> Not applicable. No relational database. For Terraform state concerns, use `terraform state` CLI commands against the S3/GCS backend.

## Troubleshooting

### Promotion Stalled on Services Readiness Check

- **Symptoms**: `services_readiness` binary keeps retrying; promotion does not progress
- **Cause**: One or more LoadBalancer services in the destination cluster do not reach the readiness threshold (`--perc-available-replicas`, default 0.5) within the configured number of attempts
- **Resolution**: Check pod status on the destination cluster for the failing service namespaces. Increase `--attempts` or `--backoff-max` if transient. If a service should be excluded, add it to `--skip-services <namespace>.<service_name>`.

### Ansible Playbook Fails on Dev Cluster

- **Symptoms**: GitHub Actions job step "Run Playbooks" exits non-zero; summary shows a failed playbook
- **Cause**: Ansible task failure — could be a Kubernetes API error, OPA policy violation, or connectivity issue
- **Resolution**: Review the GitHub Actions job log for the failing Ansible task. The rollback step will automatically re-apply master playbooks to restore the dev cluster. Fix the playbook and push a new commit.

### Terraform Plan Shows Unexpected Differences

- **Symptoms**: Jenkins "Plan Terraform changes" stage shows unexpected resource replacements or deletions
- **Cause**: Drift between committed configuration and actual cloud state, or a code change that forces resource recreation (e.g., node pool AMI update)
- **Resolution**: Review the plan output in the Jenkins build log. If intentional, ensure the impacted clusters are not serving live traffic before apply. If unintentional, check for accidental changes in the override files (`terra-gke/cluster_manifests/override/env/`).

### AMI Not Found for Region

- **Symptoms**: `ami_lookup` binary exits with error; `FAILNOTFOUND=true` causes pipeline failure
- **Cause**: AMI baking pipeline (`ami.groovy`) did not complete successfully for that region, or the SHA does not match any baked AMI
- **Resolution**: Trigger the `conveyor-cloud/ami` Jenkins job for the target SHA and regions. Confirm the AMI exists in the source (sandbox) account before publishing.

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Production cluster unreachable or promotion broken | Immediate | Conveyor Cloud team on-call |
| P2 | Stable cluster degraded or Ansible deploy stuck | 30 min | Conveyor Cloud team |
| P3 | Dev cluster rollback failed or sandbox cleanup behind | Next business day | Conveyor Cloud team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| AWS EC2 / EKS | AWS service health dashboard | Delay operations; no automatic fallback |
| GCP GKE / GCS | GCP status page | Delay operations; no automatic fallback |
| Kubernetes API | `check_cluster.yml` playbook; `services_readiness` binary | Retry with backoff; pipeline fails if max retries exceeded |
| Wavefront | HTTP 5-second timeout | Non-fatal — promotion continues without Wavefront event |
| Jenkins | Jenkins UI availability | Use GitHub Actions manual dispatch as alternate for Ansible operations |
