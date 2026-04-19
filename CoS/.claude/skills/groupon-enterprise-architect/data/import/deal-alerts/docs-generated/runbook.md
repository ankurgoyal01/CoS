---
service: "deal-alerts"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `/rpc/health.check` | http | On demand | 5s (connection timeout) |
| `/rpc/health.live` | http | On demand | Immediate |

The health check endpoint verifies database connectivity by executing `SELECT 1` against PostgreSQL. It returns a JSON response with `status` (healthy/unhealthy), `timestamp`, and `database` (connected/disconnected) fields.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| Database connectivity | gauge | PostgreSQL connection pool status | Any disconnection |
| Action error count | counter | Failed actions across all types | Visible via Logs API (source: action) |
| SMS delivery failures | counter | Notifications with Failed/Undelivered status | Visible via SMS Stats API |
| Summary email errors | counter | Failed summary email sends | Visible via Logs API (source: summary_email) |
| Notification reply errors | counter | Reply processing failures | Visible via Logs API (source: notification_replies) |

### Dashboards

> Dashboard configuration is managed externally. The web app itself serves as an operational dashboard with built-in views for alerts, SMS analytics, error logs, and configuration.

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Database unreachable | `/rpc/health.check` returns unhealthy | critical | Check PostgreSQL connectivity, verify DATABASE_URL, check connection pool exhaustion |
| High action failure rate | Elevated error counts in Logs API (source: action) | warning | Review action error messages, check Salesforce connectivity, verify credentials in n8n |
| SMS delivery failures | Elevated Failed/Undelivered notifications | warning | Check Twilio account status, review error codes (21610 = unsubscribed), verify phone numbers |
| Ingestion stalled | No new ingestion_runs records | warning | Check n8n Deal Snapshots Ingestor workflow, verify MDS API availability |

## Common Operations

### Restart Service
1. The web app runs as a standalone Next.js server in a Docker container (`node apps/web/server.js`)
2. Restart via Kubernetes pod deletion or deployment rollout restart
3. The connection pool will be re-established automatically on startup (max 10 connections, 5s timeout)
4. No warm-up required; the app is stateless beyond the database connection pool

### Scale Up / Down
1. Scale the Kubernetes deployment replicas as needed
2. Each replica maintains its own connection pool (max 10 connections per replica)
3. Monitor total database connections to avoid exceeding PostgreSQL max_connections

### Database Operations

**Run migrations:**
```bash
cd packages/db
pnpm migrate:up
```

**Check migration status:**
```bash
cd packages/db
pnpm migrate:status
```

**Roll back last migration:**
```bash
cd packages/db
pnpm migrate:down
```

**Create new migration:**
```bash
cd packages/db
npx dbmate new create_new_table_name
```

**Ensure delta partitions exist ahead:**
```sql
SELECT ensure_partitions_ahead(6);  -- Creates partitions for 6 months ahead
```

**Refresh search index:**
```sql
SELECT * FROM refresh_search_index();
```

**Regenerate database types:**
```bash
cd apps/web
pnpm db:codegen
```

## Troubleshooting

### Alerts not being generated after ingestion
- **Symptoms**: New snapshots appear but no alerts are created for sold-out or ending deals
- **Cause**: Missing monitored_fields configuration, or PL/pgSQL alert functions not matching current data shape
- **Resolution**: Verify monitored_fields via admin API. Check that `generate_alerts_from_snapshot` function receives correct old/new body pairs. Review `resolve_soldout`, `resolve_deal_ended`, `resolve_deal_ending` function logic.

### SMS notifications stuck in Created/Sent status
- **Symptoms**: Notifications remain in Created or Sent status without progressing to Delivered
- **Cause**: n8n SMS Sender workflow not running, Twilio API issues, or webhook callbacks not being received
- **Resolution**: Check n8n SMS Notifications Sender workflow execution history. Verify Twilio account status and balance. Confirm webhook callback URL is accessible.

### High unsubscribed count in SMS stats
- **Symptoms**: Elevated count of Twilio error code 21610 (message blocked by carrier or recipient)
- **Cause**: Recipients sending STOP commands or carriers blocking messages
- **Resolution**: This is expected behavior. Unsubscribed recipients are automatically excluded from future sends. Monitor the subscription stats via the SMS Analytics API.

### Action severity not being resolved correctly
- **Symptoms**: Actions are created with unexpected severity levels or not matching expected thresholds
- **Cause**: Severity matrix entries misconfigured or missing for the alert type
- **Resolution**: Review severity matrix configuration via the admin API. Verify GP30 thresholds are set for all active alert types. Use the `copyTo` endpoint to replicate a working configuration.

### Database connection pool exhaustion
- **Symptoms**: Queries timing out, health check returning unhealthy
- **Cause**: Too many concurrent requests or long-running queries holding connections
- **Resolution**: Check active connections with `SELECT count(*) FROM pg_stat_activity WHERE datname = 'deal_alerts'`. Consider scaling replicas to distribute load. Review slow queries in pg_stat_statements.

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down (web app or database unreachable) | Immediate | Deal Alerts Engineering |
| P2 | Degraded (n8n workflows stalled, integration failures) | 30 min | Deal Alerts Engineering |
| P3 | Minor impact (individual notification failures, non-critical alerts) | Next business day | Deal Alerts Engineering |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| PostgreSQL | `/rpc/health.check` endpoint | None -- database is required |
| Salesforce | Action error tracking in `actions` table | Actions queued with error state for retry |
| Twilio | SMS delivery status in `notification_status_history` | Notifications remain in pending state |
| BigQuery | Ingestion error tracking | Internal alerts continue independently |
| MDS API | Ingestion run audit in `ingestion_runs` | Existing snapshots preserved; no new data |

> Operational procedures beyond what is documented here should be defined by the service owner.
