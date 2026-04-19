---
service: "umapi"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

> No evidence found in codebase. As a Vert.x service, UMAPI likely exposes a health check endpoint (e.g., `/health` or `/status`), but this is not documented in the architecture model.

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `/health` (inferred) | http | -- | -- |

## Monitoring

### Metrics

> No evidence found in codebase.

### Dashboards

> No evidence found in codebase.

### Alerts

> No evidence found in codebase.

## Common Operations

### Restart Service

> Operational procedures to be defined by service owner.

### Scale Up / Down

> Operational procedures to be defined by service owner.

### Database Operations

> Operational procedures to be defined by service owner.

## Troubleshooting

### High Latency on Merchant Lookups (inferred)

- **Symptoms**: Increased response times on merchant profile or place retrieval endpoints; timeout errors from upstream consumers (Merchant Center, Merchant Page Service, etc.)
- **Cause**: Potential database query performance degradation, connection pool exhaustion, or upstream traffic spike
- **Resolution**: Check database query performance, review connection pool metrics, verify no abnormal traffic patterns from consumers. Scale horizontally if under load.

### Message Bus Connectivity Issues (inferred)

- **Symptoms**: Events not being published or consumed; downstream services report stale merchant data
- **Cause**: ActiveMQ Artemis broker connectivity failure or message backlog
- **Resolution**: Verify Message Bus health, check UMAPI broker connection configuration, review dead letter queues for failed messages.

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down -- merchant operations blocked across platform | Immediate | Merchant Platform team |
| P2 | Degraded -- partial merchant operations failing | 30 min | Merchant Platform team |
| P3 | Minor impact -- non-critical endpoint degradation | Next business day | Merchant Platform team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| Message Bus (ActiveMQ Artemis) | Check broker connectivity and queue depth | Service continues to handle synchronous requests; async event delivery delayed |

> Operational procedures to be defined by service owner.
