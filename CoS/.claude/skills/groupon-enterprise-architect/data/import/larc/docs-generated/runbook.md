---
service: "larc"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `GET /grpn/status` | HTTP (Dropwizard admin) | Kubernetes liveness/readiness probe | Per cluster default |
| `GET :8081/healthcheck` | HTTP (Dropwizard admin) | Kubernetes liveness/readiness probe | Per cluster default |
| `LarcHealthCheck` (math check) | Dropwizard HealthCheck | Registered at startup | — |

> Note: `.service.yml` marks `status_endpoint.disabled: true` as the v4 environment poller is not supported for this service.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| Ingestion job counts | counter | Number of QL2 ingestion jobs created, succeeded, failed per cycle | Operational procedures to be defined by service owner |
| LAR update latency | histogram | Time taken per `RoomTypeLarCalculator.process()` call (logged via StopWatch) | Operational procedures to be defined by service owner |
| `UPDATE_LAR_TIMED_OUT` events | counter | Count of LAR updates aborted due to Inventory Service timeout | Operational procedures to be defined by service owner |
| `UPDATE_LAR_FAILURE` events | counter | Count of LAR update failures for a given room type | Operational procedures to be defined by service owner |
| JVM metrics | gauge | Heap usage, GC, thread count (via JTier metrics stack) | Operational procedures to be defined by service owner |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| LARC Dashboard | Wavefront | https://groupon.wavefront.com/dashboards/larc |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Service down (PagerDuty PNJO670) | App pod not healthy / no successful health checks | critical | Page on-call via PagerDuty; check pod logs and Kubernetes events |
| `getaways-larc-alerts@groupon.com` | SRE notification triggers | warning/critical | Review Wavefront dashboard; check QL2 FTP connectivity and Inventory Service health |

## Common Operations

### Restart Service

1. Identify the failing component (`app`, `worker`, or `worker-bulk`)
2. Trigger a rolling restart via DeployBot or `kubectl rollout restart deployment/larc-<component> -n larc-production`
3. Verify new pods reach `Running` state and health checks pass
4. Confirm Wavefront metrics resume normal levels

### Scale Up / Down

The `app` component scales horizontally (HPA, min 2 / max 15). To adjust:
1. Update `.meta/deployment/cloud/components/app/production-us-central1.yml` `minReplicas` / `maxReplicas`
2. Trigger deployment via DeployBot

`worker` and `worker-bulk` run as single-replica deployments and must not be scaled horizontally — they coordinate state through the MySQL database.

### Database Operations

- **Schema migrations**: Managed by `MySQLMigrationBundle` (Flyway-compatible) — migrations run automatically on app startup
- **Manual DB access**: Use Groupon DaaS tooling to obtain a read/write connection to the `larc` MySQL instance
- **Archive operations**: NightlyLar archiving is controlled by feature flags (`nightlyLarArchiveOldQl2Timestamps`, `nightlyLarArchivePastNights`, `nightlyLarArchiveUnusedRecords`); enable via configuration change and deploy

## Troubleshooting

### QL2 Feed Files Not Being Ingested
- **Symptoms**: No new ingestion jobs created; NightlyLar table not being updated; LAR values stale
- **Cause**: QL2 FTP server unreachable, credential expiry, or file naming change (MD5 mismatch detection failing)
- **Resolution**: Check FTP credentials in k8s-secrets; verify FTP connectivity from worker pod (`kubectl exec`); review `getaways-larc-worker` log source in logging platform for FTPMonitorWorker errors

### LAR Updates Not Reaching Inventory Service
- **Symptoms**: `UPDATE_LAR_TIMED_OUT` or `UPDATE_LAR_FAILURE` events appearing in Wavefront; Getaways deal pricing not updating
- **Cause**: Inventory Service unavailable, network timeout, or auth token expired
- **Resolution**: Verify `continuumTravelInventoryService` health; check `olympiaAuthToken` validity; review `inventoryServiceConfig.client` timeout settings in the YAML config; trigger on-demand LAR send via API (`PUT /v2/getaways/larc/hotels/{hotel_uuid}/room_types/{room_type_uuid}/rate_plans/{rate_plan_uuid}/rates`) after dependency is restored

### Unmapped Rate Descriptions Causing Data Gaps
- **Symptoms**: Some nights have no LAR value computed; unmapped rate description email notifications sent
- **Cause**: QL2 introduced a new rate description name not yet mapped to a Groupon room type in the LARC database
- **Resolution**: Use the extranet app or eTorch to update rate description mappings via `PUT /v2/getaways/larc/hotels/{hotel_uuid}/rate_descriptions`; re-trigger LAR computation after mapping

### Worker OOM / Container Killed
- **Symptoms**: Worker pod restarted; OOM events in Kubernetes; memory limit exceeded
- **Cause**: `MALLOC_ARENA_MAX` not constraining glibc arena growth; large QL2 file parsed in memory
- **Resolution**: Verify `MALLOC_ARENA_MAX: 4` is set in deployment; consider increasing memory limit in `common.yml`; review CSV parsing batch size

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down — no rate updates reaching Inventory | Immediate | Getaways Engineering on-call via PagerDuty PNJO670 |
| P2 | Degraded — some feeds failing or LAR updates delayed | 30 min | getaways-larc-alerts@groupon.com |
| P3 | Minor impact — individual hotel unmapped, non-critical alert | Next business day | getaways-eng@groupon.com |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `continuumTravelInventoryService` | HTTP call to Inventory Service base URL health endpoint | LAR updates are retried on next worker cycle; existing rates remain in Inventory until overwritten |
| `continuumDealCatalogService` | HTTP call to Content Service health endpoint | Ingestion job fails gracefully; retried on next worker cycle |
| QL2 FTP | FTPMonitorWorker polls on `ftpMonitorIntervalInSec` interval | No new files downloaded; existing NightlyLar data used for LARs until next successful poll |
| `continuumTravelLarcDatabase` (MySQL) | JTier DaaS connection pool health | Service fails to start; all operations fail; DaaS failover handles replica promotion |
