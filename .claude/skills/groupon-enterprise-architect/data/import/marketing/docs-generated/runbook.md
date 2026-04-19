---
service: "marketing"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| > No evidence found in codebase. | | | |

> Health check endpoints are not discoverable from the architecture model. Operational procedures to be defined by service owner.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| Campaign delivery rate (inferred) | gauge | Rate of successful campaign message deliveries | > Not defined |
| Inbox message volume (inferred) | counter | Count of inbox messages delivered to consumers | > Not defined |
| Kafka event publish rate (inferred) | counter | Rate of events published via Kafka Logging component | > Not defined |

> Metric details are inferred from component responsibilities. Actual metric names and thresholds are not discoverable from the architecture model.

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| > No evidence found in codebase. | | |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| > No evidence found in codebase. | | | |

## Common Operations

### Restart Service

> Operational procedures to be defined by service owner. The service runs as two Kubernetes deployments (`mailman` and `rocketman`) on Conveyor Cloud (GCP). Standard Kubernetes restart procedures apply (e.g., `kubectl rollout restart deployment`).

### Scale Up / Down

> Operational procedures to be defined by service owner. Scaling is managed via Kubernetes on Conveyor Cloud.

### Database Operations

> Operational procedures to be defined by service owner. The Marketing Platform Database (`continuumMarketingPlatformDb`) is a MySQL (DaaS) instance. Standard DaaS migration and backup procedures apply.

## Troubleshooting

### Campaign delivery failures

- **Symptoms**: Campaigns not reaching consumers, delivery metrics dropping
- **Cause**: > No evidence found in codebase. Possible Message Bus connectivity issues or Kafka broker unavailability.
- **Resolution**: > Operational procedures to be defined by service owner. Check Message Bus and Kafka connectivity, verify campaign status in database.

### Message Bus publishing errors

- **Symptoms**: Campaign events not appearing in downstream systems, Kafka Logging errors
- **Cause**: > No evidence found in codebase. Possible Kafka broker issues or authentication failures.
- **Resolution**: > Operational procedures to be defined by service owner. Verify Kafka broker health, check credentials, review Kafka Logging component logs.

### Inbox message delays

- **Symptoms**: Consumer inbox not updating, messages delayed
- **Cause**: > No evidence found in codebase. Possible database contention or inbox management component issues.
- **Resolution**: > Operational procedures to be defined by service owner. Check database performance, review Inbox Management component logs.

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down -- campaign delivery halted | Immediate | Marketing Platform team |
| P2 | Degraded -- delayed deliveries or partial failures | 30 min | Marketing Platform team |
| P3 | Minor impact -- single campaign or subscription issue | Next business day | Marketing Platform team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| Marketing Platform Database (`continuumMarketingPlatformDb`) | Database connectivity check | > No evidence found in codebase. |
| Message Bus (`messageBus`) | Broker connectivity check | > No evidence found in codebase. |
| Orders Service (`continuumOrdersService`) | Inbound -- service calls Marketing Platform | Notification delivery may be delayed |

> Operational procedures to be defined by service owner.
