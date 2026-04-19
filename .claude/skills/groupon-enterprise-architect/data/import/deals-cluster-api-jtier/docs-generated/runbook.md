---
service: "deals-cluster-api-jtier"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `GET /grpn/status` (port 8080) | http | JTier default | JTier default |
| Admin port 8081 | http | Kubernetes liveness/readiness probe | — |

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| HTTP response codes | counter | Tracks error rates (4xx, 5xx) per endpoint | Wavefront alert threshold (see Wavefront alerts) |
| JVM heap / GC | gauge/histogram | JVM memory usage and GC pause times | Wavefront alert threshold |
| Request latency (TP99) | histogram | End-to-end request latency | 1000ms TP99 (SLA) |
| Throughput | counter | Requests per minute | 500 rpm (SLA target) |
| Message bus consumer lag | gauge | JMS queue depth for tagging/untagging workers | Wavefront alert threshold |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Deals Cluster V2 Dashboard | Wavefront | https://groupon.wavefront.com/dashboards/Deals-Cluster-V2-Dashboard |
| Deals Cluster V2 Cloud | Wavefront | https://groupon.wavefront.com/dashboards/Deals-Cluster-V2--Cloud |
| Marketing Tagging Service | Wavefront | https://groupon.wavefront.com/u/VB8gJdDs04?t=groupon |
| Deals Cluster (legacy) | Wavefront | https://groupon.wavefront.com/u/3BDwr2sYGj?t=groupon |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Staging alerts | See Wavefront: https://groupon.wavefront.com/u/XQjTBCFvMp | warning | Investigate logs, check pod status |
| Production alerts | See Wavefront: https://groupon.wavefront.com/u/WbyHDYj7kC | critical | Follow incident response; notify #production TDO and SOC |
| Alert emails | Threshold breach on key metrics | warning/critical | Sent to feed-service-alerts@groupon.com and deals-cluster-alerts@groupon.com |

## Common Operations

### Restart Service

- The service uses Kubernetes / Runit for process management.
- To restart in Kubernetes: scale the deployment to 0 and back to the configured minimum replicas via kubectl, or trigger a new DeployBot deployment.
- Staging: `https://deploybot.groupondev.com/MARS/deals-cluster-api-jtier` — trigger the current staging job.
- Production: Promote from staging following the standard deployment process (see [Deployment](deployment.md)).

### Scale Up / Down

- Adjust `minReplicas` / `maxReplicas` in the appropriate `.meta/deployment/cloud/components/app/<env>.yml` file and redeploy.
- HPA automatically scales within the configured min/max bounds based on CPU utilization target (100%).
- For immediate manual scaling, contact the #cloud-migration channel or CMF team.

### Database Operations

- Migrations are managed by `jtier-migrations` and run automatically on service startup.
- Quartz scheduler schema is managed by `jtier-quartz-postgres-migrations`.
- Auth tables are managed by `jtier-auth-postgres`.
- Database is DaaS PostgreSQL with primary/secondary replication and automated backups.
- For DaaS operations, contact the DaaS team through standard Groupon channels.

## Troubleshooting

### Service is overloaded / high error rate
- **Symptoms**: Elevated 5xx rates or latency TP99 > 1000ms on Wavefront dashboards
- **Cause**: Traffic spike, database connection exhaustion, or JVM heap pressure
- **Resolution**: Check Wavefront dashboards for the specific metric. See [Troubleshooting Guide](https://confluence.groupondev.com/display/EE/Troubleshooting+Guide#TroubleshootingGuide-Applicationleveldebugging). If not resolvable, reach out to CMF in #cloud-migration to tune pod replicas.

### Pod in CrashLoopBackOff
- **Symptoms**: Kubernetes pod repeatedly crashes and restarts
- **Cause**: Application startup failure (DB connection failure, config error, migration failure)
- **Resolution**: Check pod logs (`kubectl logs <pod> -n deals-cluster-<env>`). See [Troubleshooting Guide — CrashLoopBackOff](https://confluence.groupondev.com/display/EE/Troubleshooting+Guide#MyPodsareinCrashloopbackoff).

### HTTP 4xx / 5xx errors
- **Symptoms**: Elevated error codes on Wavefront
- **Cause**: Misconfigured request parameters, downstream dependency failure, or DB issue
- **Resolution**: See [Troubleshooting Guide — HTTP errors](https://confluence.groupondev.com/display/EE/Troubleshooting+Guide#TroubleshootingGuide-DebuggingHTTPerrorcodes).

### Tagging workflow not executing
- **Symptoms**: Tagging audit records not being created; deals not being tagged in Marketing Deal Service
- **Cause**: JMS worker is down, message bus connectivity issue, or DM API unreachable
- **Resolution**: Check worker pod logs; verify JMS queue health; verify `continuumMarketingDealService` is accessible.

### Top clusters endpoint returning stale data
- **Symptoms**: `/topclusters` returns outdated cluster rankings
- **Cause**: In-memory Guava cache preloaded at startup; if cluster data changed, cache reflects old data until next restart
- **Resolution**: Restart the application pod to force cache reload, or use `debug=true` query parameter to bypass cache.

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down, clusters unavailable | Immediate | Marketing Services team (mis-engineering@groupon.com), TDO, SOC |
| P2 | Degraded performance or partial feature failure | 30 min | Marketing Services team (mis-engineering@groupon.com) |
| P3 | Minor impact, non-critical feature affected | Next business day | Service owner: asdwivedi |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `continuumDealsClusterDatabase` | DaaS health monitoring; check DaaS dashboard | Service will fail to start or return errors if DB unreachable |
| `continuumMarketingDealService` | Check DM API health endpoint | Tagging/untagging operations will fail; messages remain in JMS queue for retry |
| `continuumDealCatalogService` | Check Deal Catalog Service health | Deal catalog enrichment will fail; cluster queries may return incomplete data |
| JMS Message Bus | Check mbus infrastructure health | Tagging messages will not be published; use case execution will fail |
