---
service: "pact-broker"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `GET /diagnostic/status/heartbeat` | HTTP | 15s (liveness), 5s (readiness) | 5s |

The heartbeat endpoint verifies the application is running and can reach the database. Returns HTTP 200 when healthy.

## Monitoring

### Metrics

> Operational procedures to be defined by service owner. No custom metric configuration is present in this repository. The pact-foundation/pact-broker application exposes basic Ruby/Rack metrics. Consult the [QA Tribe Confluence — Pact Broker Infrastructure](https://groupondev.atlassian.net/wiki/spaces/QAT/pages/82222252147/Pact+Broker+-+Infrastructure) for configured dashboards.

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Pact Broker Infrastructure | Confluence | [QA Tribe — Pact Broker Infrastructure](https://groupondev.atlassian.net/wiki/spaces/QAT/pages/82222252147/Pact+Broker+-+Infrastructure) |

### Alerts

> Operational procedures to be defined by service owner. No alert definitions are present in this repository.

## Common Operations

### Restart Service

1. Navigate to [Deploybot — Pact Broker](https://deploybot.groupondev.com/qa/pact-broker).
2. Trigger a redeploy of the target environment.
3. Alternatively, use `kubectl rollout restart deployment/pact-broker -n pact-broker-staging` on the `gcp-stable-us-central1` cluster with context `pact-broker-gcp-staging-us-central1`.
4. Verify recovery via `GET /diagnostic/status/heartbeat` returning HTTP 200.

### Scale Up / Down

The service currently runs at a fixed replica count of 2 (`minReplicas: 2`, `maxReplicas: 2`). To change the replica count:
1. Update `minReplicas` and `maxReplicas` in `.meta/deployment/cloud/components/app/staging-us-central1.yml`.
2. Commit and push the change.
3. Trigger a deployment via Deploybot.

### Database Operations

- **Schema migrations**: Applied automatically by the pact-foundation/pact-broker application on startup. No manual migration steps are required for version upgrades.
- **Database access**: Connect via the hostname in `PACT_BROKER_DATABASE_HOST` using credentials from the `pact-broker-secrets` submodule.
- **Database name (staging)**: `pact_broker_stg`
- **Database user (staging)**: `pact_broker_stg_dba`

### Update Secrets

1. Update the [pact-broker-secrets](https://github.groupondev.com/QA/pact-broker-secrets) repository with the new secret value.
2. In this repository, run: `git submodule update --remote .meta/deployment/cloud/secrets`
3. Verify the submodule update: `git diff .meta/deployment/cloud/secrets`
4. Stage and commit the submodule pointer: `git add .meta/deployment/cloud/secrets && git commit`
5. Approve the manual deployment at [Deploybot — Pact Broker](https://deploybot.groupondev.com/qa/pact-broker).
6. Update the 1Password "Pact Broker" item with the new secret value.

## Troubleshooting

### Heartbeat returns non-200 / Pod not ready
- **Symptoms**: Kubernetes readiness probe fails; pod enters `NotReady` state; traffic not routed to pod.
- **Cause**: Application cannot reach the PostgreSQL database, or the Ruby application failed to start.
- **Resolution**: Check pod logs (`kubectl logs -n pact-broker-staging <pod>`), verify `PACT_BROKER_DATABASE_HOST` is reachable, confirm secrets are correctly mounted.

### Webhook delivery fails
- **Symptoms**: Pact lifecycle events are not triggering CI builds; webhook status shows failure in Pact Broker UI (`/webhooks`).
- **Cause**: Target host not in `PACT_BROKER_WEBHOOK_HOST_WHITELIST`, network policy blocking outbound HTTPS, or incorrect webhook credentials.
- **Resolution**: Verify the webhook target hostname is listed in `PACT_BROKER_WEBHOOK_HOST_WHITELIST`. Check outbound network connectivity from the GCP cluster to `github.groupondev.com` and `github.com`. Review webhook execution logs in the Pact Broker UI.

### Pact publish returns 401 Unauthorized
- **Symptoms**: Consumer CI pipelines fail when publishing pacts with HTTP 401.
- **Cause**: `PACT_BROKER_BASIC_AUTH_USERNAME` or `PACT_BROKER_BASIC_AUTH_PASSWORD` mismatch.
- **Resolution**: Verify credentials in the `pact-broker-secrets` submodule match what the consumer CI pipeline is configured to use. Re-deploy after updating secrets if needed.

### Database connection error on startup
- **Symptoms**: Pod repeatedly crashes; logs show database connection refused or authentication failure.
- **Cause**: Incorrect `PACT_BROKER_DATABASE_HOST`, `PACT_BROKER_DATABASE_NAME`, `PACT_BROKER_DATABASE_USERNAME`, or `PACT_BROKER_DATABASE_PASSWORD`.
- **Resolution**: Confirm the database host is accessible from the `gcp-stable-us-central1` cluster. Verify the secret submodule is up-to-date and the secrets file was correctly merged by Helm.

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down — contract publishing/verification blocked for all teams | Immediate | QA Tribe |
| P2 | Degraded — webhook delivery failing, CI gates degraded | 30 min | QA Tribe |
| P3 | Minor impact — UI unresponsive, non-critical read path degraded | Next business day | QA Tribe |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `continuumPactBrokerPostgres` (PostgreSQL) | `GET /diagnostic/status/heartbeat` tests DB connectivity; Kubernetes probe restarts pod on failure | No fallback — database is required for all operations |
| `githubEnterprise` | Check webhook execution status in Pact Broker UI at `/webhooks` | Webhook failures are non-blocking for API callers; contracts remain stored |
| `githubDotCom` | Check webhook execution status in Pact Broker UI at `/webhooks` | Webhook failures are non-blocking for API callers; contracts remain stored |
