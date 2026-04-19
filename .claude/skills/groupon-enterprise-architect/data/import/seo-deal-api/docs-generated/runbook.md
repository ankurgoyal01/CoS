---
service: "seo-deal-api"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `GET /grpn/healthcheck` | http | Not specified | Not specified |

The `/grpn/healthcheck` endpoint is the standard Dropwizard health check path, evidenced in the Logstash test fixture (`seo_deal_api_test.rb`) where an example log entry shows a `GET /grpn/healthcheck` request returning HTTP 200.

## Monitoring

### Metrics

> No evidence found in codebase.

Specific metric names and alert thresholds are not discoverable from the available source archive. Dropwizard exposes JVM and HTTP metrics by default via its admin port (typically `:8081`).

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| SEO Admin UI dashboard | Wavefront | `https://groupon.wavefront.com/dashboard/seo-admin-ui` (evidenced in `seo-admin-ui/.service.yml`; seo-deal-api metrics may be included) |

### Alerts

> No evidence found in codebase.

Alert configuration is managed externally and not discoverable from the available source archive. PagerDuty alerts for related SEO services route to `seo-alerts@groupon.pagerduty.com` (evidenced in `seo-admin-ui/.service.yml`).

## Common Operations

### Restart Service

> Operational procedures to be defined by service owner.

The service follows the standard Groupon JTier/Kubernetes restart pattern. Contact the SEO team at `computational-seo@groupon.com` for current restart procedures.

### Scale Up / Down

> Operational procedures to be defined by service owner.

Scaling is managed via the Kubernetes orchestration layer. Contact the SEO team for current scaling configuration.

### Database Operations

> Operational procedures to be defined by service owner.

The `continuumSeoDealPostgres` PostgreSQL database is owned by this service. Migration paths are not specified in the available source evidence. Contact the SEO team for schema migration and backfill procedures.

### Manually Fix Incorrect Redirects

To update a deal redirect manually, send an HTTP `PUT` request to:

```
PUT https://seo-deal-api.production.service.us-central1.gcp.groupondev.com/seodeals/deals/{DEAL_UUID}/edits/attributes?source=manual
Content-Type: application/json

{ "redirectUrl": "https://groupon.com/deals/123example" }
```

To remove a `redirectUrl` from a deal, supply a null value:

```json
{ "redirectUrl": null }
```

Evidence: `seo-deal-redirect/WORKFLOW.md` — Manually Fixing Incorrect Redirects section.

## Troubleshooting

### Redirect pipeline bulk upload failure

- **Symptoms**: `seo-deal-redirect` Airflow DAG `api_upload` job reports HTTP non-200 responses or connection errors
- **Cause**: mTLS certificate expiry, rate limit exceeded, or seo-deal-api service unavailability
- **Resolution**: Check certificate expiry at GCP Secret Manager (`tls--seo-seo-gcp-pipelines`); verify service health at `/grpn/healthcheck`; review Airflow job logs for `failed api PUT in do_api_upload` entries; re-run the Airflow DAG after resolving the root cause

### SEO attributes not updated in admin console

- **Symptoms**: `seo-admin-ui` returns `ERROR getting deal through seo-deal-api` or stale attribute values
- **Cause**: seo-deal-api unavailable, database write failure, or incorrect `dealId` lookup
- **Resolution**: Confirm seo-deal-api health; check Elasticsearch logs for `seo_deal_api` sourcetype errors; verify the deal UUID is correct via Deal Catalog

### Noindex not applied during deal ingestion

- **Symptoms**: Deals remain indexed in search engines after ingestion
- **Cause**: `ingestion-jtier` `PUT /seodeals/deals/{dealId}/edits/noindex` call failed (non-critical — logged as warning and swallowed)
- **Resolution**: Check `ingestion-jtier` logs for `failed_to_disable_seo_indexing` warning; manually trigger a PUT to `/seodeals/deals/{dealId}/edits/noindex` with body `true` and `clientId=3pip_local_feed` query param

### IndexNow submission failure

- **Symptoms**: Search engine re-indexing not triggered after deal attribute updates
- **Cause**: IndexNow client error or external IndexNow service unavailability
- **Resolution**: Retry by calling `POST /index-now/request` with the affected URLs; check service logs for error context

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down — SEO admin console non-functional, redirect pipeline failing | Immediate | SEO team (`computational-seo@groupon.com`); GChat space `AAAANlivtII` |
| P2 | Degraded — Partial failures in attribute writes or redirect uploads | 30 min | SEO team (`computational-seo@groupon.com`) |
| P3 | Minor impact — IndexNow or Jira integration failures | Next business day | SEO team (`computational-seo@groupon.com`) |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `continuumSeoDealPostgres` | Query the DB directly or observe JDBI errors in service logs | No fallback — database is the primary store |
| `continuumDealCatalogService` | Check Deal Catalog service health endpoint | No fallback — deal enrichment degrades |
| `continuumTaxonomyService` | Check Taxonomy service health endpoint | No fallback — taxonomy enrichment degrades |
| `continuumInventoryService` | Check Inventory service health endpoint | No fallback — inventory enrichment degrades |
| `continuumM3PlacesService` | Check M3 Places service health endpoint | No fallback — place enrichment degrades |
| `indexNowService` | External dependency; check IndexNow status | Non-critical; submission can be retried |
| `continuumJiraService` | Check Jira API availability | Non-critical; Jira issue creation can be retried |
