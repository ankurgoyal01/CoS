---
service: "deploybot"
title: Runbook
generated: "2026-03-02T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| > No evidence found in codebase for a dedicated health check endpoint | — | — | — |

> Operational procedures to be defined by service owner for liveness and readiness probes.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| > No evidence found in codebase for exported metrics | — | — | — |

> Operational procedures to be defined by service owner.

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| > No evidence found in codebase | — | — |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Deployment stuck in validating state | Deployment remains in `validating` status beyond expected timeout | warning | Inspect validation gate blocking; check GitHub CI status, ProdCAT, Conveyor maintenance window; manually authorize or kill via `POST /deployments/{key}/authorize` or `POST /deployments/{key}/kill` |
| Jira ticket creation failure | SOX logbook ticket not created for a deployment | critical | Check Jira credentials in `/auth/creds/jira`; verify Jira API availability; manually create audit record |
| S3 log upload failure | Deployment log not archived to S3 | warning | Check AWS credentials and S3 bucket permissions; re-run `deploybotLogImporter` utility if needed |
| Kubernetes deploy failure | Deployment execution fails against Kubernetes API | critical | Check `deploybotInitExec` init container logs; verify service account permissions; inspect Kubernetes API server health |

## Common Operations

### Restart Service

1. Identify the running pod in the `deploybot` namespace: `kubectl get pods -n deploybot`
2. Delete the pod to trigger a rolling restart: `kubectl delete pod <pod-name> -n deploybot`
3. Kubernetes will schedule a replacement pod using the current deployment spec
4. Verify the new pod reaches `Running` state: `kubectl get pods -n deploybot -w`

### Scale Up / Down

> Operational procedures to be defined by service owner. Kubernetes HPA configuration and manual scaling commands are managed in deployment manifests not present in the service inventory.

### Database Operations

- **Inspect deployment state**: Query MySQL (`externalDeploybotDatabase_43aa`) `deploy_requests` table filtered by project, org, or status
- **Audit review**: Query `audit_logs` table by deployment key or time window for SOX review
- **Jira ticket reconciliation**: Cross-reference `jira_tickets` table with live Jira to identify any unclosed logbook entries
- **Migrations**: > No evidence found in codebase for a migration tool or migration path. Consult service owner for schema change procedures.

## Troubleshooting

### Deployment Stuck in Validating

- **Symptoms**: A deployment shows status `validating` and does not progress; Slack notification shows `deploy_queued` but no `deploy_started`
- **Cause**: One or more validation gates are blocking: GitHub CI checks have not passed, ProdCAT gate is failing, a manual authorization is required, or a Conveyor maintenance window is active
- **Resolution**: Check GitHub commit status for the relevant SHA; check ProdCAT for the service; check Conveyor for active maintenance windows; if manual approval is needed, use `POST /deployments/{key}/authorize`; if the deployment should be cancelled, use `POST /deployments/{key}/kill`

### Deployment Fails with Image Not Found

- **Symptoms**: Deployment execution fails; logs show image pull error or Artifactory validation failure
- **Cause**: The Docker image for the deployment target does not exist in Artifactory, or Artifactory credentials are invalid
- **Resolution**: Verify the image tag exists in Artifactory; check `/auth/creds/artifactory` credentials; confirm Artifactory is reachable

### Jira SOX Ticket Not Created

- **Symptoms**: Deployment completes but no Jira logbook ticket appears; `jira_tickets` MySQL table has no entry for the deployment key
- **Cause**: Jira API unreachable, or credentials in `/auth/creds/jira` are invalid or expired
- **Resolution**: Verify Jira API availability; rotate credentials in `/auth/creds/jira`; manually create logbook ticket for SOX compliance; notify compliance team

### Kubernetes Workload Not Starting

- **Symptoms**: Deployment execution completes in deploybot but the Kubernetes workload never becomes healthy; logs show exec errors
- **Cause**: Kubernetes API server unreachable, service account lacks permissions, or the deployment image is invalid
- **Resolution**: Check `deploybotInitExec` init container logs for auth setup errors; verify service account RBAC; check Kubernetes API server health; inspect pod events with `kubectl describe pod -n <namespace>`

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down — no deployments possible | Immediate | RAPT (Release & Platform Tools) team |
| P2 | Degraded — deployments failing or SOX audit gaps | 30 min | RAPT team |
| P3 | Minor impact — Slack notifications failing or log archival delayed | Next business day | RAPT team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| MySQL (`externalDeploybotDatabase_43aa`) | Query `deploy_requests` table for recent records | No fallback — service cannot operate without MySQL |
| AWS S3 (`externalS3Bucket_4b6c`) | Attempt a test object put/get against the bucket | Log archival skipped; deployment proceeds but logs are not archived |
| GitHub REST API | Call GitHub status endpoint | CI-gated deployments block; non-CI-gated deployments may proceed |
| Jira | Call Jira REST API health endpoint | SOX logbook entry is skipped; compliance team must be notified manually |
| Okta | OIDC discovery endpoint | All OAuth-protected actions (kill, authorize, promote) are unavailable |
| Kubernetes API | `kubectl cluster-info` or client-go health check | Kubernetes-targeted deployments fail; Docker-targeted deployments may continue |
| Slack | Slack API test call | Notifications are suppressed; deployment proceeds without Slack alerts |
| Artifactory | Query Artifactory API for known image | Image validation fails; deployment blocked until Artifactory is restored |
