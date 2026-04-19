---
service: "general-ledger-gateway"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| Dropwizard admin healthcheck (port 8081) | HTTP | JTier default | 3s (DB validation query timeout) |
| PostgreSQL validation query (`SELECT 1`) | SQL | On connection acquire | 3s |

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| Applied Credit Import Job error rate | counter/rate | Rate of 4xx and 5xx responses from `POST /v1/{ledger}/jobs/import-applied-invoices` | > 1% of all responses |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| General Ledger Gateway | Wavefront | https://groupon.wavefront.com/dashboards/General-Ledger-Gateway |
| Applied Credit Import Job Responses | Wavefront | https://groupon.wavefront.com/u/FBtKX83Pl2?t=groupon |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Applied Credit Import Job Error Rate | 4xx + 5xx rate > 1% of job endpoint responses | warning | Review request payload; connect to pod via `bin/` scripts and inspect JTier logs; check Applied Credit Import Job Responses Wavefront dashboard for response breakdown |

## Common Operations

### Restart Service

```shell
# Set context
./bin/staging-context   # or ./bin/production-context

# View current pods
./bin/pods

# Force pod restart by deleting pod (Kubernetes will reschedule)
kubectl delete pod <pod-name>

# Or use kubectl rollout restart
kubectl rollout restart deployment general-ledger-gateway--api--default
```

### Scale Up / Down

```shell
# Scale up staging (after on-hold period)
kubectl config use-context stable-us-west-1
kubens general-ledger-gateway-staging-sox
kubectl -n general-ledger-gateway-staging-sox scale deployment general-ledger-gateway--api--default --replicas=2

# Scale up production
kubectl config use-context production-us-west-1
kubens general-ledger-gateway-production-sox
kubectl -n general-ledger-gateway-production-sox scale deployment general-ledger-gateway--api--default --replicas=3

# Scale down (on-hold)
kubectl scale deployment general-ledger-gateway--api--default --replicas=0
```

### View Logs

```shell
# JTier structured application logs
./bin/jtier-log-tail

# Kubernetes pod logs (useful for failed deploys)
./bin/pod-logs

# Forward pod port for local inspection
./bin/port-forward   # forwards to localhost:9000
```

### Database Operations

```shell
# Connect to staging read-only database (parses YAML config automatically)
./bin/staging-psql

# Run Flyway migrations (development only)
mvn flyway:migrate
```

### Trigger Import Applied Invoices Job Manually

```shell
# Via port-forward to a live pod
./bin/port-forward &
curl -X POST http://localhost:9000/v1/NORTH_AMERICA_LOCAL_NETSUITE/jobs/import-applied-invoices
```

## Troubleshooting

### Applied Credit Import Job Returns 4xx / 5xx

- **Symptoms**: Wavefront alert fires; error rate > 1% on job endpoint
- **Cause**: Usually a bad request payload from QA or misconfigured ledger ID; may also be downstream NetSuite or Accounting Service failure
- **Resolution**:
  1. Check the Applied Credit Import Job Responses dashboard in Wavefront for response breakdown
  2. Connect to a pod shell (`./bin/bash`) and replay the request with the same payload
  3. Review JTier structured logs for the exception details (`./bin/jtier-log-tail`)
  4. If NetSuite is unreachable, verify OAuth credentials are current in k8s secrets

### NetSuite RESTlet Calls Failing

- **Symptoms**: Invoice send errors; job execution fails during applied invoice download
- **Cause**: Expired OAuth credentials; NetSuite API downtime; incorrect realm or script IDs
- **Resolution**:
  1. Verify environment variables `*_CONSUMER_KEY`, `*_TOKEN`, etc. are correctly set in k8s secrets
  2. Check NetSuite service status
  3. Confirm `searchScriptID` and `findAndInsertScriptID` values in config match NetSuite configuration

### Quartz Job Not Firing

- **Symptoms**: Applied invoices not being reconciled; no job execution logs
- **Cause**: Cron triggers are currently commented out in all config files; job must be triggered via the Job Resource endpoint
- **Resolution**:
  1. Trigger manually: `POST /v1/{ledger}/jobs/import-applied-invoices`
  2. Verify `features.jobResourceEnabled: true` in the active config file
  3. Check Quartz job store in PostgreSQL for misfire records (misfireThreshold: 5000ms)

### Pod Fails to Start

- **Symptoms**: Kubernetes pod in `CrashLoopBackOff` or `Error` state
- **Cause**: Missing or incorrect k8s secrets; database unreachable; Redis unreachable
- **Resolution**:
  1. Check pod logs: `./bin/pod-logs`
  2. Verify all required secrets are mounted
  3. Confirm database and Redis endpoints are accessible from the cluster

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down — no invoice operations possible | Immediate | FED team (fed@groupon.com), Service Owner (erevangelista@groupon.com) |
| P2 | Import job failing — reconciliation delayed | 30 min | FED team |
| P3 | Minor degradation (single ledger affected) | Next business day | FED team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| NetSuite ERP | Implicit — API call failure surfaced as error response | Retry (Resilience4j); currency results served from Redis cache if available |
| Accounting Service | Implicit — HTTP call failure surfaced as error response | Retry (Resilience4j); no fallback for apply-invoice failures |
| PostgreSQL (RW) | `SELECT 1` on connection acquire, 3s timeout | None — service will fail to process requests |
| PostgreSQL (RO) | `SELECT 1` on connection acquire, 3s timeout | None — read endpoints will fail |
| Redis | Connection health managed by Lettuce | NetSuite calls proceed without cache if Redis is unavailable |
