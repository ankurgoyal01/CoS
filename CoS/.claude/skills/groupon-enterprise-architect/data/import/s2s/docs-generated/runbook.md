---
service: "s2s"
title: Runbook
generated: "2026-03-03T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `/healthcheck` | http (Dropwizard standard) | > No evidence found | > No evidence found |
| Kafka consumer lag | metric | Continuous | — |

> Operational procedures to be defined by service owner. Dropwizard exposes a standard `/healthcheck` endpoint that reports database connectivity, Kafka consumer status, and internal health indicators.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| Kafka consumer lag (janus-tier2) | gauge | Number of unconsumed messages in Janus Tier2 topic | > No evidence found |
| Kafka consumer lag (janus-tier3) | gauge | Number of unconsumed messages in Janus Tier3 topic | > No evidence found |
| Partner API error rate (Facebook CAPI) | counter | Count of failed Facebook CAPI submissions | > No evidence found |
| Partner API error rate (Google Ads) | counter | Count of failed Google Ads conversion submissions | > No evidence found |
| Partner API error rate (TikTok) | counter | Count of failed TikTok Ads API submissions | > No evidence found |
| Partner API error rate (Reddit) | counter | Count of failed Reddit Ads API submissions | > No evidence found |
| Delayed events queue depth | gauge | Number of events pending replay in `continuumS2sPostgres` | > No evidence found |
| DataBreaker submission failures | counter | Count of failed DataBreaker datapoint/items submissions | > No evidence found |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| S2S Service | > No evidence found | > No evidence found |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| High Kafka consumer lag | Janus Tier lag exceeds threshold | critical | Check service health, scale consumers, investigate processing errors |
| Partner API failure spike | Partner API error rate exceeds threshold | critical | Check partner API status, review delayed events queue, notify SEM/Display team |
| Delayed events queue growing | Queue depth increasing without drain | warning | Trigger `/jobs/edw/aesRetry` if appropriate; investigate root cause |
| EDW job failure | Scheduled Teradata job fails | warning | Review job logs, retry via `/jobs/edw/customerInfo` or `/jobs/edw/aesRetry` |

## Common Operations

### Restart Service

> Operational procedures to be defined by service owner. Standard JTier restart process applies — use JTier deployment tooling to perform a rolling restart of `continuumS2sService` instances.

### Scale Up / Down

> Operational procedures to be defined by service owner. Use JTier deployment tooling to adjust replica count for `continuumS2sService`. Monitor Kafka consumer lag metrics to determine appropriate scale.

### Database Operations

- **Delayed events replay**: Trigger `/jobs/edw/aesRetry` endpoint to initiate replay of events stored in `continuumS2sPostgres` delayed events table.
- **Customer info backfill**: Trigger `/jobs/edw/customerInfo` endpoint to run a Teradata EDW customer info backfill job.
- **Display financial run**: Trigger `/jobs/bau/display-run` endpoint to execute the BAU display financial data pipeline.
- **Manual deal update**: POST to `/update` to trigger a manual booster deal update through the DataBreaker MBus Mapper.
- **Log level adjustment**: POST to `/logs` to adjust runtime log levels without restarting the service.

## Troubleshooting

### Partner API Submissions Failing

- **Symptoms**: Elevated partner API error counters; delayed events queue depth growing
- **Cause**: Partner API outage, credential expiry, or payload schema rejection
- **Resolution**: Check partner API status pages; verify credentials (Facebook token, Google OAuth, TikTok/Reddit tokens); inspect delayed events in `continuumS2sPostgres`; replay via `/jobs/edw/aesRetry` once root cause is resolved

### Kafka Consumer Lag Growing

- **Symptoms**: Janus Tier2/Tier3 consumer lag metric increasing; events not being processed in near-real-time
- **Cause**: Service restart, processing bottleneck, external dependency slowness (Consent Service, Orders Service)
- **Resolution**: Check service health via `/healthcheck`; review logs for slow dependency calls; scale `continuumS2sService` replicas if throughput is insufficient

### EDW Jobs Not Running

- **Symptoms**: Customer info not refreshed; AES retry records not processed
- **Cause**: Teradata EDW connectivity issue; Quartz scheduler misconfiguration; service restart reset job state
- **Resolution**: Verify Teradata connectivity (`TERADATA_JDBC_URL`, credentials); manually trigger via `/jobs/edw/customerInfo` or `/jobs/edw/aesRetry`; check Quartz scheduler logs

### MBus Booster Updates Not Reaching DataBreaker

- **Symptoms**: Booster campaigns not updated; MDS retry queue growing
- **Cause**: MBus connectivity issue; DataBreaker API unavailable; MDS errors persisted in retry table
- **Resolution**: Check MBus connectivity; verify DataBreaker API availability; inspect MDS retry records in `continuumS2sPostgres`; use `/update` endpoint to manually push a deal update

### Google Ads Automation Not Running

- **Symptoms**: No new Sheets reports; no automation email notifications
- **Cause**: BigQuery access failure; Google OAuth token expiry; SMTP misconfiguration
- **Resolution**: Verify BigQuery credentials and table access; refresh Google OAuth tokens; check SMTP configuration

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down — no partner events forwarded | Immediate | SEM/Display Engineering on-call |
| P2 | Degraded — partner submissions failing for one or more partners | 30 min | SEM/Display Engineering on-call |
| P3 | Minor impact — EDW job failures or booster update delays | Next business day | SEM/Display Engineering team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `continuumConsentService` | HTTP GET health endpoint; Cache2k consent cache serves stale decisions on outage | Consent cache (Cache2k) provides short-term fallback; events without valid consent dropped |
| `continuumS2sPostgres` | Dropwizard DB health check | Service unable to persist delayed events or consent cache; events may be lost |
| `continuumS2sTeradata` | JDBC connectivity check during job execution | Scheduled jobs fail gracefully; retry via manual job trigger |
| `continuumS2sKafka` | Kafka consumer connectivity | Service unable to consume Janus events; consumer lag grows until connectivity restored |
| `continuumFacebookCapi` | HTTP response from Facebook CAPI | Failed events persisted to delayed events queue in `continuumS2sPostgres` for replay |
| `continuumGoogleAdsApi` | HTTP response from Google Ads API | Events dropped or retried per Failsafe policy |
| `continuumTiktokApi` | HTTP response from TikTok Ads API | Events queued by `continuumS2sService_tiktokClientService` |
| `continuumRedditApi` | HTTP response from Reddit Ads API | Failed events persisted to delayed events queue for replay |
| `continuumDataBreakerApi` | HTTP response from DataBreaker API | DataBreaker submissions fail; MDS retry records queued for re-attempt |
