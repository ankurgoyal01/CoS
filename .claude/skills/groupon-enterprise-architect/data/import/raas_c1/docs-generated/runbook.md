---
service: "raas_c1"
title: Runbook
generated: "2026-03-03T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| Status endpoint | disabled | N/A | N/A |

> The `status_endpoint` is explicitly disabled in `.service.yml`. Health of C1 Redis nodes is monitored via the `raas_c1::mon` subservice (Monitoring Host) and the broader `raas` platform monitoring stack.

## Monitoring

### Metrics

> No evidence found — this Service Portal entry carries no runtime process and emits no metrics directly. Metrics for C1 Redis node health are produced by the `raas` platform containers.

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| RaaS C1 Node Overview | Internal | http://raas-info.snc1/dbs2.html |
| Redislabs Manual Dashboards | Confluence | https://confluence.groupondev.com/display/RED/redislabsManual-Dashboards |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| C1 Redis node unreachable | A C1 Redis node fails health checks via `raas_c1::mon` | critical | Page raas-pager@groupon.com via PagerDuty (https://groupon.pagerduty.com/services/PTK0O0E); review `raas_c1::mon` subservice logs |
| `raas_dns` resolution failure | DNS resolution for C1 endpoints fails | critical | Escalate to DNS infrastructure team; verify `raas_dns` dependency is healthy |

## Common Operations

### Restart Service

> Not applicable — this entry has no deployable process to restart. To address C1 Redis node issues, engage the `raas` platform operations procedures or contact raas-team@groupon.com.

### Scale Up / Down

> Not applicable — this is a Service Portal registration entry, not a deployable service.

### Database Operations

> Not applicable — this entry owns no data stores.

## Troubleshooting

### C1 Service Portal entry not resolving in OCT tooling

- **Symptoms**: OCT tooling cannot find BASTIC tickets associated with C1 Redis nodes; routing for C1 colos fails
- **Cause**: The `raas_c1` Service Portal entry may be misconfigured, or `raas_dns` resolution is failing
- **Resolution**: Verify `.service.yml` base URLs are correct for snc1, sac1, dub1 colos; confirm `raas_dns` dependency is healthy; contact raas-team@groupon.com for Service Portal revalidation

### C1 Redis node operational issues

- **Symptoms**: Redis nodes in snc1, sac1, or dub1 are unavailable or degraded
- **Cause**: This is beyond the scope of the `raas_c1` Service Portal entry; the issue lies in the Redis infrastructure managed by `redislabs_config` or the `raas` platform
- **Resolution**: Consult the [RaaS platform runbook](../../raas/docs-generated/runbook.md); open a ticket via https://dse-ops-request.groupondev.com

### Need to submit an operational request

- **Action**: Use the request portal at https://dse-ops-request.groupondev.com
- **Slack**: Join channel `CFA7KUDGV` (redis-memcached) for real-time coordination
- **Mailing list**: raas-announce@groupon.com for platform announcements

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | C1 Redis nodes completely unavailable; services depending on C1 Redis cannot connect | Immediate | raas-pager@groupon.com via PagerDuty |
| P2 | Degraded C1 Redis performance or partial node unavailability | 30 min | raas-pager@groupon.com |
| P3 | Minor C1 operational issue; tooling routing anomaly | Next business day | raas-team@groupon.com |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `raas_dns` | Verify DNS resolution of C1 Redis endpoint hostnames from within the colo network | No automated fallback; route through alternative DNS if available |
| `raas_c1::mon` (Monitoring Host) | Review monitoring dashboards at http://raas-info.snc1/dbs2.html | Escalate directly to raas-team for manual cluster health assessment |
| `raas_c1::redis` (Redis nodes) | Use Redislabs dashboard per the [Redislabs Manual](https://confluence.groupondev.com/display/RED/redislabsManual) | Failover per Redislabs cluster configuration |

> Detailed Redis cluster operational procedures are documented in the [RaaS FAQ](https://confluence.groupondev.com/display/RED/FAQ) and [Redislabs Manual](https://confluence.groupondev.com/display/RED/redislabs+Manual).
