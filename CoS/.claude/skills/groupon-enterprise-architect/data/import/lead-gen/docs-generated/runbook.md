---
service: "lead-gen"
title: Runbook
generated: "2026-03-03T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `GET /api/health` | http | 30s | 5s |
| `GET /api/pipeline/status` | http | 60s | 10s |
| n8n workflow engine health | http | 30s | 5s |
| PostgreSQL connection check | tcp | 30s | 5s |

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| `leadgen_scrape_queue_depth` | gauge | Number of leads pending in the scrape queue | > 10,000 |
| `leadgen_scrape_jobs_total` | counter | Total Apify scraping jobs executed | N/A |
| `leadgen_scrape_failures_total` | counter | Failed Apify scraping jobs | > 5 in 1h |
| `leadgen_enrichment_latency_ms` | histogram | Latency of enrichment calls (PDS + quality) | p99 > 5000ms |
| `leadgen_enrichment_backlog` | gauge | Leads awaiting enrichment | > 5,000 |
| `leadgen_outreach_sent_total` | counter | Total outreach emails sent | N/A |
| `leadgen_outreach_success_rate` | gauge | Percentage of successfully delivered outreach emails | < 90% |
| `leadgen_outreach_bounce_rate` | gauge | Percentage of bounced outreach emails | > 10% |
| `leadgen_crm_sync_pending` | gauge | Leads pending Salesforce sync | > 1,000 |
| `leadgen_crm_sync_failures_total` | counter | Failed Salesforce sync attempts | > 10 in 1h |
| `leadgen_db_connections_active` | gauge | Active database connections | > 80% of pool max |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| LeadGen Pipeline Overview | Grafana | (configured in monitoring stack) |
| LeadGen Outreach Delivery | Grafana | (configured in monitoring stack) |
| n8n Workflow Execution | n8n UI | (n8n admin dashboard) |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Scrape queue overflow | `leadgen_scrape_queue_depth > 10000` for 15m | warning | Check Apify job throughput; scale n8n workers |
| Scrape job failures spike | `leadgen_scrape_failures_total > 5` in 1h | critical | Check Apify run logs; verify API token; retry with smaller batches |
| Enrichment latency high | `leadgen_enrichment_latency_ms p99 > 5000ms` for 10m | warning | Check inferPDS and merchantQuality health; reduce enrichment concurrency |
| Outreach delivery degraded | `leadgen_outreach_success_rate < 90%` for 30m | critical | Check Mailgun dashboard for rate limits or blocks; consider pausing outreach |
| Outreach bounce spike | `leadgen_outreach_bounce_rate > 10%` for 1h | critical | Pause campaign; review lead email quality; check sender reputation |
| CRM sync backlog | `leadgen_crm_sync_pending > 1000` for 1h | warning | Check Salesforce API limits; verify OAuth credentials; increase sync batch size |
| CRM sync failures spike | `leadgen_crm_sync_failures_total > 10` in 1h | critical | Inspect Salesforce API errors; check quota; pause syncs and backfill when limits reset |
| Database connection exhaustion | `leadgen_db_connections_active > 80%` | warning | Check for connection leaks; scale pods or increase pool size |

## Common Operations

### Restart Service

1. Verify current pod status: `kubectl get pods -l app=leadgen-service`
2. Perform rolling restart: `kubectl rollout restart deployment/leadgen-service`
3. Monitor rollout: `kubectl rollout status deployment/leadgen-service`
4. Verify health endpoint returns 200: `curl http://<service-url>/api/health`

### Scale Up / Down

1. For leadGenService: `kubectl scale deployment/leadgen-service --replicas=<N>`
2. For leadGenWorkflows (n8n): `kubectl scale deployment/leadgen-workflows --replicas=<N>`
3. Verify pods are running: `kubectl get pods -l app=leadgen-service` or `app=leadgen-workflows`

### Database Operations

1. Check connection health via `/api/health` endpoint
2. Run pending migrations: execute migration job via CI/CD pipeline or manual `flyway migrate`
3. Monitor query performance: check PostgreSQL slow query log and connection pool metrics
4. Backfill operations: use dedicated batch jobs triggered via n8n or manual API call

## Troubleshooting

### Apify scrape jobs fail or return empty results

- **Symptoms**: No new leads appearing in pipeline; scrape failure counter incrementing; n8n workflow marked as failed
- **Cause**: Apify actor configuration invalid, API token expired, Google Places inputs changed, or Apify rate limit hit
- **Resolution**: Check Apify run logs in Apify console; verify API token validity; retry with smaller batch sizes; confirm actor parameters match expected input schema

### AIDG enrichment unavailable (inferPDS / merchantQuality)

- **Symptoms**: Leads stuck in "pending enrichment" status; enrichment latency metrics spiking or timing out
- **Cause**: AIDG service endpoints down or overloaded; network connectivity issue; service authentication failure
- **Resolution**: Check inferPDS and merchantQuality service health; verify service auth credentials; if prolonged outage, disable enrichment via feature flags and proceed with partial lead data

### Outreach email delivery failures (Mailgun)

- **Symptoms**: Outreach success rate dropping below threshold; bounce rate spiking; Mailgun delivery metrics degraded
- **Cause**: Mailgun rate limits or blocks; sender domain reputation degraded; recipient email addresses invalid
- **Resolution**: Check Mailgun dashboard for rate limits or IP blocks; pause campaign if bounce rate exceeds 10%; review lead email quality from scraping; if Mailgun is blocked, switch `OUTREACH_PROVIDER` to alternate provider

### Salesforce CRM sync errors

- **Symptoms**: Leads accumulating in "pending sync" status; CRM sync failure counter incrementing
- **Cause**: Salesforce daily API limit exhausted; OAuth token expired or revoked; duplicate Account/Contact conflicts
- **Resolution**: Check Salesforce API usage dashboard; verify OAuth credentials; pause syncs and backfill when daily limits reset (midnight UTC); resolve duplicate record conflicts manually in Salesforce

### n8n workflow backlog or stuck executions

- **Symptoms**: Workflow runs accumulating in running/queued state; new jobs not starting; pipeline throughput dropping
- **Cause**: n8n worker resource exhaustion; database connectivity lost; stuck execution blocking queue
- **Resolution**: Restart stuck executions via n8n admin UI; scale n8n worker pods; verify leadGenDb connectivity; clear dead executions from n8n database

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Pipeline completely down (no scraping, enrichment, or outreach) | Immediate | Sales Engineering on-call |
| P2 | Partial pipeline degradation (one integration down, reduced throughput) | 30 min | Sales Engineering |
| P3 | Minor impact (slow enrichment, non-critical metric drift) | Next business day | Sales Engineering |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| Apify | Monitor scrape job success rate and run logs | Retry with smaller batches; pause scraping until Apify recovers |
| InferPDS | Monitor enrichment latency and error rate | Disable PDS enrichment via feature flag; proceed with quality score only |
| Merchant Quality | Monitor enrichment latency and error rate | Disable quality enrichment via feature flag; proceed with PDS data only |
| Mailgun | Monitor delivery success rate and bounce rate | Switch to alternate outreach provider; pause campaign if all providers degraded |
| Salesforce | Monitor sync success rate and API limit usage | Pause CRM sync; queue leads for backfill when limits reset |
| leadGenDb | Monitor connection pool utilization and query latency | No fallback -- database is critical path; escalate immediately |
| n8n | Monitor workflow execution queue depth and error rate | Restart stuck workers; scale pods; manual trigger via API if automation fails |
