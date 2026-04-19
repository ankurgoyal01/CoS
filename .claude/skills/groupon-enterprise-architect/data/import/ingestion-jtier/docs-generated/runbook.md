---
service: "ingestion-jtier"
title: Runbook
generated: "2026-03-02T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `/healthcheck` | http | Kubernetes liveness probe interval | Kubernetes probe timeout |
| `/ping` | http | Kubernetes readiness probe interval | Kubernetes probe timeout |

> Dropwizard exposes `/healthcheck` (admin port) and `/ping` by default. Exact probe intervals are defined in Kubernetes deployment manifests — see infrastructure Helm chart.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| `ingestion_run_duration_ms` | histogram | End-to-end duration of a feed extraction and ingestion run per partner | > Operational procedures to be defined by service owner |
| `ingestion_run_status` | counter | Count of ingestion runs by status (success/failed/partial) per partner | Consecutive failures > threshold |
| `offer_ingestion_total` | counter | Total offers processed (created/updated/skipped) per run | > Operational procedures to be defined by service owner |
| `availability_sync_duration_ms` | histogram | Duration of availability synchronization runs | > Operational procedures to be defined by service owner |
| `deal_management_api_errors` | counter | HTTP errors calling Deal Management API | Any 5xx spike |
| `external_partner_api_errors` | counter | HTTP errors calling external partner APIs | Any sustained error rate |
| `redis_lock_wait_ms` | histogram | Time spent waiting for distributed lock acquisition | > Operational procedures to be defined by service owner |
| `jvm_memory_used_bytes` | gauge | JVM heap usage | > 80% of configured heap |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| ingestion-jtier Service Overview | > Operational procedures to be defined by service owner | > Link not available in inventory |
| Partner Feed Ingestion Health | > Operational procedures to be defined by service owner | > Link not available in inventory |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| IngestionRunFailed | Partner feed run returns ERROR status | warning | Check IngestionOperationalEvent logs for ERROR events; verify external partner API availability |
| AllPartnersIngestionFailed | All scheduled partner runs fail in same window | critical | Investigate shared dependency (DB, Redis, Deal Management API); escalate to 3PIP Ingestion team |
| DealManagementApiDown | Sustained 5xx errors from Deal Management API | critical | Verify Deal Management API health; pause ingestion runs via `PUT /partner/v1/pause` if needed |
| RedisConnectionFailure | Cannot connect to `continuumIngestionJtierRedis` | critical | Distributed locks unavailable; concurrent job overlap possible; restart pod after Redis recovery |
| PostgresConnectionFailure | Cannot connect to `continuumIngestionJtierPostgres` | critical | Service cannot read or write ingestion state; page on-call |

## Common Operations

### Restart Service

1. Identify the Kubernetes namespace and deployment name for ingestion-jtier
2. Run: `kubectl rollout restart deployment/ingestion-jtier -n <namespace>`
3. Monitor pod startup: `kubectl rollout status deployment/ingestion-jtier -n <namespace>`
4. Verify health: `curl http://<pod-ip>:<admin-port>/healthcheck`
5. Check logs for successful Quartz scheduler startup: `kubectl logs -l app=ingestion-jtier -n <namespace>`

### Scale Up / Down

1. Edit replica count in Helm values or use: `kubectl scale deployment/ingestion-jtier --replicas=<N> -n <namespace>`
2. Note: Quartz jobs use Redis distributed locks to prevent duplicate execution across replicas — scaling is safe for the API surface; Quartz clustering behavior depends on jtier-quartz-bundle configuration
3. Monitor resource usage after scaling

### Pause a Partner

1. To prevent ingestion for a specific partner without stopping the service: `PUT /partner/v1/pause` with the partner ID in the request body
2. This sets the partner status to paused in `continuumIngestionJtierPostgres`, causing Quartz jobs to skip that partner
3. To resume: `PUT /deals/v1/unpause` (for deals) or re-enable via database update if no unpause endpoint exists for partners

### Trigger On-Demand Ingestion

1. For a full feed run: `POST /ingest/v1/start` with partner configuration in the body
2. For availability sync only: `POST /ingest/v1/availability/start`
3. Monitor progress via IngestionOperationalEvent messages on the Message Bus or PostgreSQL `ingestion_runs` table

### Database Operations

- **View recent ingestion runs**: `SELECT * FROM ingestion_runs ORDER BY started_at DESC LIMIT 50;`
- **Check deletion queue backlog**: `SELECT COUNT(*) FROM deal_deletions WHERE processed_at IS NULL;`
- **Check blacklisted offers**: `SELECT * FROM offers WHERE blacklisted = true;`
- **Database migrations**: Run via Maven Flyway plugin or jtier-daas-postgres migration tooling; always back up before migrating in production

## Troubleshooting

### Feed Extraction Producing No Records

- **Symptoms**: Ingestion run completes with recordCount=0; no new deals created
- **Cause**: External partner API returning empty response, authentication failure, or schema change in partner feed
- **Resolution**: Check external partner API credentials and connectivity; verify partner feed format has not changed; review IngestionOperationalEvent ERROR messages; test partner API call manually

### Deal Creation Failures After Successful Extraction

- **Symptoms**: Offers extracted and stored in PostgreSQL but no deals created; Deal Management API errors in logs
- **Cause**: Deal Management API unavailable, returning validation errors, or taxonomy mapping failure
- **Resolution**: Verify Deal Management API health; check Taxonomy Service availability; review offer payload for missing required fields; re-trigger via `POST /ingest/v1/start` after upstream fix

### Redis Lock Not Released (Job Stuck)

- **Symptoms**: Quartz job does not start for a partner; Redis lock key still present after expected job duration
- **Cause**: Previous job crashed without releasing distributed lock; lock TTL not yet expired
- **Resolution**: Manually delete the Redis lock key: `DEL lock:ingest:<partnerId>`; investigate root cause of previous crash in pod logs

### Availability Sync Falling Behind

- **Symptoms**: Deal availability dates stale; `POST /ingest/v1/availability/start` taking unusually long
- **Cause**: Large volume of availability records; slow partner API response; high database write contention
- **Resolution**: Use `POST /ingest/v1/availability/bulk/start` for bulk processing; check PostgreSQL slow query log; consider increasing pod resources temporarily

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service completely down — no ingestion running, deals going stale | Immediate | 3PIP Ingestion on-call (3pip-cbe-eng@groupon.com) |
| P2 | Degraded — one or more partners failing, partial ingestion | 30 min | 3PIP Ingestion team (3pip-cbe-eng@groupon.com) |
| P3 | Minor impact — single offer failures, non-critical partner delays | Next business day | vaarora / 3pip-cbe-eng@groupon.com |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `continuumIngestionJtierPostgres` | JDBC connection pool health via `/healthcheck` | No fallback — service cannot operate without primary store |
| `continuumIngestionJtierRedis` | Redis ping via Jedis connection test | Ingestion can run without locks but risks duplicate job execution |
| `continuumDealManagementApi` | HTTP GET health endpoint (not confirmed from inventory) | Offers extracted and stored; deal creation retried on next scheduled run |
| `mbusPlatform` | Message Bus connectivity check via jtier-messagebus-client | Events queued locally or dropped; monitoring impact |
| External partner APIs | HTTP connectivity to each partner endpoint | Per-partner failure; other partners continue; ERROR events published |
