---
service: "channel-manager-integrator-synxis"
title: Runbook
generated: "2026-03-03T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `/healthcheck` (Dropwizard standard) | http | > No evidence found | > No evidence found |
| `/soap/CMService` — `ping` operation | SOAP | On-demand (called by SynXis CRS) | > No evidence found |

> Dropwizard exposes `/healthcheck` and `/ping` admin endpoints by default. Confirm ports and paths with the service owner.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| ARI events published to Kafka | counter | Number of ARI events successfully published per operation type | > Operational procedures to be defined |
| MBus RESERVE/CANCEL messages consumed | counter | Number of inbound reservation/cancellation messages processed | > Operational procedures to be defined |
| MBus reservation responses published | counter | Number of success/failure responses sent to Inventory Service Worker | > Operational procedures to be defined |
| SynXis SOAP call latency | histogram | Round-trip time for outbound calls to SynXis CRS | > Operational procedures to be defined |
| SynXis SOAP call failures | counter | Number of failed outbound SOAP calls to SynXis CRS | > Operational procedures to be defined |

### Dashboards

> Operational procedures to be defined by service owner.

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| SynXis SOAP call failure rate elevated | High rate of failures on `synxisClient` outbound calls | critical | Check SynXis CRS availability; verify credentials and endpoint URL; review SOAP fault messages in request/response log table |
| Kafka publish failures | ARI events failing to publish to `continuumKafkaBroker` | critical | Check Kafka broker health; verify Kafka bootstrap server config; check for schema or serialization errors |
| MBus consumer lag | `mbusInboundProcessor` not keeping up with RESERVE/CANCEL message backlog | warning | Check MBus broker health; check service pod status; scale if needed |
| Database connectivity failure | `mappingPersistence` unable to connect to MySQL | critical | Check `continuumChannelManagerIntegratorSynxisDatabase` MySQL health; verify DB credentials; check network connectivity |

## Common Operations

### Restart Service

> Operational procedures to be defined by service owner. Standard JTier/Kubernetes approach: rolling restart via `kubectl rollout restart deployment/<cmi-synxis-deployment>`.

### Scale Up / Down

> Operational procedures to be defined by service owner. Adjust Kubernetes replica count for `continuumChannelManagerIntegratorSynxisApp` deployment.

### Database Operations

> Operational procedures to be defined by service owner. Database migrations are managed via the service's migration tooling (refer to service repository). For backfills of mapping records, use the `PUT /mapping` REST endpoint where possible to ensure request/response audit logging.

## Troubleshooting

### ARI events not reaching Kafka

- **Symptoms**: SynXis CRS receives SOAP fault or timeout on `pushAvailability`/`pushInventory`/`pushRate`; downstream ARI consumers report stale data
- **Cause**: Kafka broker unreachable; ARI payload validation failure (mapping not found, hierarchy fetch failed); `inventoryHierarchyClient` unable to reach `continuumTravelInventoryService`
- **Resolution**: Check Kafka broker health and connectivity; check `continuumTravelInventoryService` availability; inspect request/response log table in MySQL for the failed operation; verify mapping records exist for the hotel/room identifiers in the payload

### Reservations not confirmed in SynXis

- **Symptoms**: `inventoryServiceWorker` receives failure response on MBus; hotel reservations not appearing in SynXis CRS
- **Cause**: SynXis SOAP call failed (network, credentials, SynXis error); mapping record missing or incorrect; MySQL write failure
- **Resolution**: Check SynXis CRS availability and credentials; inspect the request/response log table in MySQL for the failing SOAP operation; verify mapping records for the hotel; check `mbusOutboundPublisher` logs for response payload details

### MBus messages not being processed

- **Symptoms**: RESERVE/CANCEL requests accumulating without responses; `inventoryServiceWorker` timing out
- **Cause**: `mbusInboundProcessor` not consuming; service pod down or restarting; MBus broker connectivity issue
- **Resolution**: Check service pod status in Kubernetes; check MBus broker health; verify MBus connection configuration; restart service pod if necessary

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down — no ARI processing, no reservation handling | Immediate | Travel Engineering |
| P2 | Degraded — elevated error rates on SynXis calls or Kafka publishing | 30 min | Travel Engineering |
| P3 | Minor impact — mapping API errors, non-critical operation failures | Next business day | Travel Engineering |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `synxisCrs` | Invoke `ping` SOAP operation against SynXis CRS endpoint | No fallback — reservation creation and ARI push responses to SynXis will fail |
| `continuumKafkaBroker` | Check Kafka broker connectivity via admin client or platform monitoring | ARI events cannot be published; SOAP response to SynXis will indicate failure |
| `messageBus` | Check MBus broker connectivity via platform monitoring | RESERVE/CANCEL messages cannot be consumed or responses published |
| `continuumTravelInventoryService` | Invoke known REST health endpoint; check platform monitoring | ARI validation cannot be completed; `pushAvailability`/`pushInventory`/`pushRate` calls will fail |
| `continuumChannelManagerIntegratorSynxisDatabase` | Dropwizard `/healthcheck` database health indicator | All stateful operations fail — no mapping resolution, no reservation persistence |
