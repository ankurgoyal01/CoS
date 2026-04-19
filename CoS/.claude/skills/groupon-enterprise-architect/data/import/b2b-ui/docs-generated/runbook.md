---
service: "b2b-ui"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| HTTP on port 8080 | http | Kubernetes liveness/readiness default | 300s (krane global timeout) |
| Admin port 8081 | http | Kubernetes probe | — |

> Detailed liveness/readiness probe configuration is managed in the secrets submodule (`b2b-ui-secrets`) and the `cmf-generic-api` Helm chart values.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| Client telemetry | — | Browser/client logs ingested via `POST /api/metrics/log` and written as structured JSON via Winston | — |
| Server logs | — | JSON-formatted logs written to `/var/groupon/logs/steno.log`, shipped via Filebeat with source type `mx-rbac-ui-service` | — |

> Operational metrics (error rates, latency, request counts) are expected to be derived from the shipped log stream. Specific Grafana or Datadog dashboard links are not available in this repository.

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| RBAC UI service logs | Elasticsearch / log platform | Filtered by `sourceType: mx-rbac-ui-service` |

### Alerts

> Operational alert definitions are not discoverable from this repository. Alert configuration is managed externally.

## Common Operations

### Restart Service

1. Identify the deployment in the appropriate Kubernetes cluster (`rbac-ui-staging-sox` or `rbac-ui-production-sox`).
2. Roll the deployment: `kubectl rollout restart deployment/rbac-ui -n rbac-ui-<env>-sox`
3. Monitor rollout: `kubectl rollout status deployment/rbac-ui -n rbac-ui-<env>-sox`

### Scale Up / Down

1. Edit the `minReplicas` / `maxReplicas` values in the appropriate `.meta/deployment/cloud/components/app/<env>.yml` file.
2. Re-run the deploy script: `bash ./.meta/deployment/cloud/scripts/deploy.sh <target> <env> rbac-ui-<env>-sox`
3. Alternatively, trigger a new DeployBot deployment from the CI pipeline.

Current limits: staging 1-2 replicas, production 1-4 replicas (HPA target CPU 50%).

### Database Operations

> Not applicable — this service owns no databases.

## Troubleshooting

### RBAC screens fail to load / BFF API errors
- **Symptoms**: Users see error pages or blank RBAC administration screens; browser console shows 5xx errors from `/api/rbac`
- **Cause**: `continuumRbacService` is unreachable, returning errors, or the RBAC client ID (`NEXT_PUBLIC_RBAC_CLIENT_ID`) is misconfigured
- **Resolution**: Check pod logs (`kubectl logs -n rbac-ui-<env>-sox`); verify `continuumRbacService` health; confirm `NEXT_PUBLIC_RBAC_CLIENT_ID` env var matches the expected client ID for the environment

### User provisioning failures
- **Symptoms**: `/api/rbac/users/create` returns errors; user accounts not created in one or both regions
- **Cause**: `continuumUsersService` is unavailable, permission checks fail, or the auth token lacks required scopes
- **Resolution**: Check User Provisioning Flow logs in the shipped log stream (`mx-rbac-ui-service`); verify `continuumUsersService` health; confirm identity headers are being injected by Session Middleware

### Login / session failures
- **Symptoms**: Users are redirected to login repeatedly; session middleware rejects valid cookies
- **Cause**: JWT validation failure in Session Middleware — expired token, wrong secret, or UMAPI client misconfiguration
- **Resolution**: Check pod logs for JWT validation errors; verify UMAPI client ID and secrets in the Kubernetes secrets; confirm `JTIER_RUN_CONFIG` path points to the correct secrets file

### Bot traffic redirect not working
- **Symptoms**: Bot requests reach application routes instead of `/botland`
- **Cause**: `grpn-request-middleware` `akamai-bot-detection` handler misconfigured or Akamai headers not forwarded
- **Resolution**: Verify `vpcs.config.json` middleware handler configuration; check Akamai edge config for header passthrough

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service completely down — RBAC admins cannot access the tool | Immediate | RBAC team (MerchantCenter-BLR@groupon.com), owner: c_jsima |
| P2 | Degraded — some screens or operations failing | 30 min | RBAC team (MerchantCenter-BLR@groupon.com) |
| P3 | Minor impact — cosmetic issues, single feature degraded | Next business day | RBAC team |

External runbook reference: [Owners Manual](https://github.groupondev.com/itier-next/technophrenia/blob/showcase/OWNERS_MANUAL.md)

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `continuumRbacService` | HTTP call to RBAC v2 endpoint from BFF; 5xx response indicates service is down | None — RBAC screens become non-functional |
| `continuumUsersService` | HTTP call from BFF during user resolution; error response propagated to client | None — user display and provisioning unavailable |
| UMAPI | Identity context absence causes authentication failure | Users cannot log in |
