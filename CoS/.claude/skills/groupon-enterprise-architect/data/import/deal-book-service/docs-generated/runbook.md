---
service: "deal-book-service"
title: Runbook
generated: "2026-03-03T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `GET /health` | http | Platform default | Platform default |
| `GET /heartbeat` | http | Platform default | Platform default |

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| Request rate | counter | HTTP requests per second to the API | Not discoverable |
| Error rate | counter | HTTP 5xx responses from the API | Not discoverable |
| Response time | histogram | API endpoint latency | Not discoverable |
| Message consumer lag | gauge | Unprocessed messages on `jms.topic.taxonomyV2.content.update` | Not discoverable |
| Google Sheets sync success | counter | Successful vs failed scheduled sync runs | Not discoverable |
| Cache hit rate | gauge | Redis cache hit ratio for fine print clause responses | Not discoverable |

Metrics are emitted via `sonoma-metrics 0.8.0` to the Sonoma/Continuum metrics platform.

### Dashboards

> Operational procedures to be defined by service owner.

| Dashboard | Tool | Link |
|-----------|------|------|
| Deal Book Service API metrics | Sonoma metrics platform | Not discoverable |
| Message consumer metrics | Sonoma metrics platform | Not discoverable |

### Alerts

> Operational procedures to be defined by service owner.

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| High API error rate | HTTP 5xx rate exceeds threshold | critical | Check MySQL and Redis connectivity; review logs via sonoma-logger |
| Health check failure | `GET /health` returns non-200 | critical | Restart API service; check Rails process and database connectivity |
| Google Sheets sync failure | Rake task exits with error | warning | Check Google Drive credentials; verify sheet accessibility; re-run sync manually |
| Taxonomy consumer lag | Message backlog exceeds threshold | warning | Check `dealBookMessageWorker` process health; review message bus connectivity |
| Redis unavailable | Redis connection errors in logs | warning | Check Redis instance; API falls back to MySQL reads |

## Common Operations

### Restart Service

> Follow Continuum platform standard restart procedures.

1. Identify API, worker, and rake task pods/containers in the target environment
2. Drain active connections from API pod (if load-balanced)
3. Restart `dealBookServiceApp` via Kubernetes rolling restart or platform tooling
4. Restart `dealBookMessageWorker` separately
5. Verify `GET /health` returns 200 after restart

### Scale Up / Down

> Scaling follows Continuum platform Kubernetes HPA or manual replica count adjustment for `dealBookServiceApp`. `dealBookMessageWorker` typically runs as a single instance.

### Database Operations

- **Run migrations**: `bundle exec rake db:migrate RAILS_ENV=production`
- **Manual Google Sheets sync**: `bundle exec rake deal_book:sync_from_google_sheets RAILS_ENV=production`
- **Increment content version**: `bundle exec rake deal_book:increment_content_version RAILS_ENV=production`
- **Verify MySQL connectivity**: Check `DATABASE_URL` env var; test connection from a Rails console

## Troubleshooting

### Fine Print Clauses Return Empty or Stale Data
- **Symptoms**: `GET /v4/fine_print_clauses` returns empty list or outdated content
- **Cause**: Google Sheets sync has not run recently, or MySQL `fine_print_clauses` table is empty
- **Resolution**: Run the Google Sheets sync rake task manually; verify Google Drive credentials; check `content_versions` table for last update timestamp

### Compile Returns Unexpected Result
- **Symptoms**: `POST /v2/compile` produces incorrect or incomplete fine print document
- **Cause**: Clause IDs in the request do not match current database content; taxonomy mappings are stale
- **Resolution**: Verify clause IDs against current database; check if a taxonomy update event has been processed recently; re-run taxonomy sync if needed

### Taxonomy Update Event Not Processed
- **Symptoms**: Clause-category mappings are out of date after taxonomy changes; `dealBookMessageWorker` logs show no recent activity
- **Cause**: Message worker is down or message bus connectivity has failed
- **Resolution**: Check `dealBookMessageWorker` pod health; verify message bus credentials and connectivity; restart worker if stopped

### Persisted Fine Print CRUD Failures
- **Symptoms**: `POST/PUT/DELETE /v2/persisted_fine_prints` returns errors
- **Cause**: MySQL connectivity issue, validation failure, or missing deal record in Model API
- **Resolution**: Verify MySQL is reachable; check request payload for required fields; confirm deal ID exists via Model API

### Google Sheets Sync Fails
- **Symptoms**: Rake task `deal_book:sync_from_google_sheets` exits with error; content not updated
- **Cause**: Google Drive credentials expired or revoked; sheet access permissions changed; network error
- **Resolution**: Rotate and verify `GOOGLE_DRIVE_CLIENT_ID` and `GOOGLE_DRIVE_CLIENT_SECRET`; confirm service account has read access to the target Google Sheet

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | API completely down — Deal Wizard cannot create deals | Immediate | Deal Management Team |
| P2 | Degraded — compile or persist endpoints failing; taxonomy sync stopped | 30 min | Deal Management Team |
| P3 | Minor impact — stale content; Google Sheets sync delayed | Next business day | Deal Management Team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `continuumDealBookMysql` | MySQL ping from Rails connection pool | All API requests fail; no fallback |
| `continuumDealBookRedis` | Redis PING command | API falls back to direct MySQL reads |
| `continuumTaxonomyService` | HTTP health endpoint (platform standard) | Clause filtering by taxonomy category may fail |
| `continuumGoogleSheetsApi` | Verify with a test read in Google Drive SDK | Content sync fails; existing data served from MySQL |
| `continuumTaxonomyContentUpdateTopic` | Message bus connectivity check | Taxonomy mapping updates delayed |
| `salesForce` | External — not directly checkable | External UUID mapping unavailable |
