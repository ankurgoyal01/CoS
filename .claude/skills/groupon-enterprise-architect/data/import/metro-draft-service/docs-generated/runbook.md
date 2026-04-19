---
service: "metro-draft-service"
title: Runbook
generated: "2026-03-02T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `/healthcheck` (Dropwizard default) | http | Kubernetes liveness probe interval | Kubernetes probe timeout |
| `/ping` (Dropwizard default) | http | Kubernetes readiness probe interval | Kubernetes probe timeout |

> Exact probe intervals and timeouts are managed in the Kubernetes deployment manifest. Confirm with the Metro Team.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| JVM heap usage | gauge | JVM memory utilization | >85% for sustained period |
| HTTP request rate | counter | Incoming requests per second across all API endpoints | Baseline deviation |
| HTTP error rate (5xx) | counter | Server-side errors on REST API | >1% error rate |
| Database connection pool utilization | gauge | Pool saturation for all three PostgreSQL databases | >80% utilization |
| MBus publish lag | gauge | Latency between event production and MBus delivery | Baseline deviation |
| Quartz job execution time | histogram | Duration of scheduled batch jobs | Job-specific thresholds |

Metrics are emitted to `metricsStack` via the Metrics integration.

### Dashboards

> Operational dashboards are managed externally. Contact the Metro Team (metro-dev-blr@groupon.com) for links to Grafana or equivalent dashboards.

| Dashboard | Tool | Link |
|-----------|------|------|
| Metro Draft Service — Overview | Grafana / internal tooling | Managed externally |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| High 5xx rate | HTTP 5xx rate > 1% over 5 minutes | critical | Check logs in `loggingStack`; investigate recent deployments |
| Database connection exhaustion | Pool utilization > 90% | critical | Investigate slow queries; scale up connection pool; restart if needed |
| Stuck deal queue buildup | Stuck Deal Retry Job failing repeatedly | warning | Check DMAPI and MDS availability; inspect deal IDs in stuck state |
| Salesforce sync failures | Deal Score to Salesforce Job errors | warning | Verify Salesforce credentials and endpoint availability |
| MBus publish failures | Editor Action Publisher or Signed Deal Producer errors | critical | Check MBus broker health; investigate `continuumMetroDraftMessageBus` |

## Common Operations

### Restart Service

1. Identify the Kubernetes deployment: `kubectl get deployment -n <namespace> | grep metro-draft`
2. Perform a rolling restart: `kubectl rollout restart deployment/<metro-draft-deployment> -n <namespace>`
3. Monitor rollout: `kubectl rollout status deployment/<metro-draft-deployment> -n <namespace>`
4. Validate health check: `curl http://<service-endpoint>/healthcheck`

### Scale Up / Down

1. Update Kubernetes HPA or replica count: `kubectl scale deployment/<metro-draft-deployment> --replicas=<N> -n <namespace>`
2. Alternatively update HPA min/max in the deployment manifest and apply
3. Monitor pod readiness: `kubectl get pods -n <namespace> | grep metro-draft`

### Database Operations

- **Run migrations**: JTier migrations execute automatically on application startup; to run manually use the jtier-migrations CLI against the target database
- **Check migration state**: Query the `flyway_schema_history` table (or JTier equivalent) on each database
- **Backfills**: Coordinate with the Metro Team for any data backfill procedures; use read replicas where available to avoid production write contention

## Troubleshooting

### Deal stuck in publishing workflow

- **Symptoms**: Deal status does not advance after publish request; Stuck Deal Retry Job logs repeated retry attempts
- **Cause**: DMAPI, MDS, or Deal Catalog downstream call failing; inventory reservation failure
- **Resolution**: Check `loggingStack` for HTTP 5xx errors from downstream services; verify DMAPI and MDS health; manually trigger retry via admin endpoint or Quartz job console

### Salesforce sync not updating scores

- **Symptoms**: Deal Score to Salesforce Job completes but Salesforce records show stale scores
- **Cause**: Salesforce API credential rotation; Salesforce API rate limits; Deal Score Calculator Job not completing
- **Resolution**: Verify Salesforce credentials are current; check Deal Score Calculator Job logs; confirm scores are being persisted to `continuumMetroDraftDb` before the sync job runs

### MBus events not being consumed

- **Symptoms**: Signed Deal Listener not triggering downstream workflows after deal signing
- **Cause**: MBus broker connectivity issue; listener consumer group lag; application restart cleared in-flight messages
- **Resolution**: Check MBus broker health for `continuumMetroDraftMessageBus`; inspect consumer group lag; restart the service if the listener is not reconnecting

### Permission errors (403) on valid requests

- **Symptoms**: API requests returning 403 despite correct credentials
- **Cause**: RBAC Service (`continuumRbacService`) returning unexpected permissions; stale Redis cache
- **Resolution**: Flush relevant Redis keys in `continuumMetroDraftRedis`; verify RBAC Service is healthy; check Permission Filter logs

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down — no deal drafting or publishing | Immediate | Metro Team on-call (metro-dev-blr@groupon.com) |
| P2 | Degraded — publishing blocked or significant error rate | 30 min | Metro Team (metro-dev-blr@groupon.com) |
| P3 | Minor — background jobs failing, notifications not sending | Next business day | Metro Team (metro-dev-blr@groupon.com) |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `continuumMetroDraftDb` | Database connection pool metrics; query latency | No fallback — service cannot persist deals without primary DB |
| `continuumDealManagementService` | HTTP health endpoint; 5xx rate from Retrofit client | Deal publishing blocked; deals remain in draft state |
| `continuumRbacService` | HTTP health endpoint; Redis cache serves stale permissions | Stale permissions served from `continuumMetroDraftRedis` until TTL expiry |
| `continuumMetroDraftMessageBus` | MBus broker connectivity; consumer group lag | Events queue in broker; signed deal workflows delayed |
| `salesForce` | Salesforce API response codes in sync job logs | Deal Score to Salesforce Job retries; scores remain un-synced |
| `elasticSearch` | HTTP response codes from Search & Analytics Client | Search indexing queued or dropped; deal searchability degraded |
