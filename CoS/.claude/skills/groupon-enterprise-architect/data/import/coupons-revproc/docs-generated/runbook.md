---
service: "coupons-revproc"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `GET /grpn/healthcheck` | http (port 8080) | Kubernetes default | — |
| `/var/groupon/jtier/heartbeat.txt` | file (exec probe on cron jobs) | 5s | 5s |

Health check URLs:
- Production US: `https://coupons-revproc.production.service.us-central1.gcp.groupondev.com/grpn/healthcheck`
- Production EU (AWS): `https://ccoupons-revproc.production.service.eu-west-1.aws.groupondev.com/grpn/healthcheck`

## Monitoring

### Metrics

The service emits metrics via the JTier metrics infrastructure (Steno-structured logs shipped to Wavefront). Key metric tags use the constants in `MetricsTagsConstants`.

| Metric Tag | Type | Description | Alert Threshold |
|------------|------|-------------|----------------|
| `transaction` / `process` | counter | Transactions submitted to the processor | Significant drop indicates AffJet ingestion failure |
| `transaction` / `finalize` | counter | Transactions successfully finalized and persisted | Drop relative to process count indicates enrichment failures |
| `transaction` / `failed` | counter | Transactions that failed processing | Any sustained increase warrants investigation |
| `transaction` / `duplicate_revenue_found` | counter | Transactions skipped due to duplicate revenue detection | Expected to be low |
| `transaction` / `page_ingest` | counter | AffJet pages ingested (one count per non-empty page) | Sudden drop indicates AffJet connectivity issue |
| `transaction` / `merchant_slug_capi` | counter | Merchant slug resolved via CAPI path | Monitoring legacy slug resolution |
| `transaction` / `merchant_slug_vcapi` | counter | Merchant slug resolved via VoucherCloud API path | Monitoring preferred slug resolution |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Primary Revproc Dashboard | Wavefront | `https://groupon.wavefront.com/u/VP9FP5vQ69?t=groupon` |
| Secondary Dashboard | Wavefront | `https://groupon.wavefront.com/u/SmM3kNHl4L?t=groupon` |
| SRE Dashboard 1 | Wavefront | `https://groupon.wavefront.com/u/vgJXF8Z3HC?t=groupon` |
| SRE Dashboard 2 | Wavefront | `https://groupon.wavefront.com/u/qsYxqxVD5N?t=groupon` |

### Logs

All logs are shipped via Filebeat to ELK in Steno JSON format. Index: `filebeat-coupon-revproc_app--*`

| Environment | Kibana Link |
|-------------|------------|
| Staging / Pre-production | `https://stable-kibana-unified.us-central1.logging.stable.gcp.groupondev.com/` |
| Production US | `https://prod-kibana-unified.us-central1.logging.prod.gcp.groupondev.com/` |
| Production EU | `https://prod-kibana-unified-eu.logging.prod.gcp.groupondev.com/` |

Useful Kibana filters: `data.args.message`, `name`, `data.args.request.response.url`, `data.status`

Cron job log source types:
- Feed generator: `coupons-feed-generator_worker`
- Redirect sanitizer: `coupons-redirect-sanitizer_worker`
- Redirect cache prefill: `coupons-redirect-cache-prefill_worker`

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Service down / unresponsive | POST success rate below threshold or pods restarting | Sev 2 | Restart pods; check deploy logs on Deploybot and Kibana |
| Low Traffic | Significant drop in ingestion metrics | Sev 4 | Check Kibana logs — likely an AffJet affiliate network failure |
| API Timeouts | VoucherCloud or AffJet response times elevated | Sev 4 | Check external dependency health; review timeout config |

OpsGenie service: `https://groupondev.app.opsgenie.com/service/9a5a27d1-5977-411b-a040-262d2cd46ca4`

Target SLA: **99.5%** uptime. Dev team is paged if POST success rate drops below 99% or if 500-class errors / pod restarts occur.

## Common Operations

### Restart Service

```bash
# Authenticate
kubectl cloud-elevator auth

# Switch to correct context (production US example)
kubectx coupons-revproc-production-us-central-1

# Rolling restart (preferred — no downtime)
kubectl rollout restart deployment coupons-revproc--app--default

# Hard restart (scale to 0 then back to 1)
kubectl scale --replicas 0 deployments/coupons-revproc--app--default
kubectl scale --replicas 1 deployments/coupons-revproc--app--default
```

### Scale Up / Down

Edit the appropriate environment deployment config file under `.meta/deployment/cloud/components/coupons-revproc/` to adjust `minReplicas`, `maxReplicas`, or CPU/memory limits, then redeploy via Deploybot.

```bash
# Emergency manual scale (does not persist across deploys)
kubectl scale --replicas <N> deployments/coupons-revproc--app--default
```

### Stop Service

```bash
kubectl scale --replicas 0 deployments/coupons-revproc--app--default
```

### Database Operations

Schema migrations are managed by Flyway via `jtier-migrations`. Automatic Flyway migration on staging and production is **disabled**. Schema changes must be run manually or by GDS.

```bash
# Local: baseline schema (one-time only, then update version from 1 to 0 in schema_version)
mvn clean compile flyway:baseline

# Local: apply migrations
mvn clean compile flyway:migrate

# Local: out-of-order Quartz migrations
mvn flyway:migrate -Dflyway.outOfOrder=true
```

### Manual AffJet Ingestion

Trigger a standard ingestion for a country (requires valid `client_id`):
```bash
curl -X POST "https://coupons-revproc.production.service.us-central1.gcp.groupondev.com/unprocessed_transactions/trigger_affjet_ingestion?countryCode=US&client_id=<client_id>"
```

Trigger a targeted ingestion with date range:
```bash
curl -X POST "https://.../unprocessed_transactions/trigger_targeted_affjet_ingestion?countryCode=GB&dateFrom=20260101000000&dateTo=20260201000000&client_id=<client_id>"
```

### Add a New client_id for API Access

```sql
-- Add client_id
INSERT INTO `client_ids` (`name`) VALUES ('<client_id>');
-- Assign role
INSERT INTO `client_id_roles` (`client_id`, `role`) VALUES (<client_id_primary_key>, 'all');
```

## Troubleshooting

### Service Down / Unresponsive

- **Symptoms**: Health check fails; pods in `CrashLoopBackOff` or `Error` state; 5xx error rate elevated
- **Cause**: Application startup failure (bad config, missing secret, DB connectivity); OOM kill; bad deployment
- **Resolution**: Check Deploybot console logs; check Kibana for startup errors; restart pods (`kubectl rollout restart`); roll back if a recent deploy is suspected

### Low Traffic / No Ingestion

- **Symptoms**: `transaction/page_ingest` metric drops to zero; no new processed transactions appearing
- **Cause**: AffJet API connectivity issue for one or more country networks; `affjet.enabled` config set to false; Quartz scheduler not running
- **Resolution**: Check Kibana for `AffJetAdapter.process.failed` log events; verify AffJet API reachability; trigger a manual ingestion via `trigger_affjet_ingestion` endpoint to isolate the failing country

### Mbus Message Send Failures

- **Symptoms**: `ProcessedTransactionFinalizer.sendMessages.error` log events in Kibana; processed transactions persisted to MySQL but not appearing downstream
- **Cause**: Mbus connectivity issue; malformed payload
- **Resolution**: Check Mbus health; verify `messagebus` config block in JTIER_RUN_CONFIG; reprocess affected transactions if needed

### VoucherCloud Click Enrichment Failures

- **Symptoms**: `VoucherCloudException` log events; transactions processed without click/deal enrichment
- **Cause**: VoucherCloud API degraded or credentials expired
- **Resolution**: Check VoucherCloud API status; verify `voucherCloudApi` config; transactions without click data are still persisted but will not generate Mbus messages

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 (Sev 2) | Service completely down | Immediate | Coupons team — coupons-eng@groupon.com; OpsGenie |
| P2 | Transaction ingestion stopped; backlog growing | 30 min | Coupons team |
| P3 (Sev 4) | Low traffic alert; single affiliate failing | Next business day | Coupons team — review Kibana |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| AffJet API | Trigger manual ingestion via API; check Kibana for `AffJetAdapter` events | Quartz retries on next scheduled run; no data loss if AffJet recovers within the 30-day lookback window |
| VoucherCloud API | Check `VoucherCloudException` in Kibana | Transactions processed without click enrichment; Mbus messages not sent for non-enriched records |
| MySQL | Check pod logs for JDBC errors | Service will fail to start if DB is unreachable |
| Redis | Check pod logs for Jedis errors | Redirect cache will be empty until next prefill run |
| Mbus | Check `MessageException` events in Kibana | Transactions are persisted to MySQL; messages must be replayed manually |
| Salesforce | Check `SalesforceException` in Kibana | Bonus payment records are not sent; must be retried manually |
