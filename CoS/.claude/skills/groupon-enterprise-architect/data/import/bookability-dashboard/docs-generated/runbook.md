---
service: "bookability-dashboard"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `https://www.groupon.com/bookability/dashboard/` | HTTP (curl) | On alert | — |
| `https://staging.groupon.com/bookability/dashboard/` | HTTP (curl) | On alert | — |
| GCS bucket contents check (`gcloud storage ls gs://bookability-dashboard-web-prod-us-central1/`) | CLI | On alert | — |

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| `backend_response_bytes` (GCP LB) | gauge | HTTP responses from GCS backend to the load balancer | Alert fires when no HTTP 200 responses detected (ConDash Load Balancer Backend Response Error) |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| ConDash | Grafana | `https://prod-grafana.us-central1.logging.prod.gcp.groupondev.com/d/af3w0spuhkxkwe/condash?orgId=1` |
| Partner Service Logs | Kibana | `https://prod-kibana-unified.us-central1.logging.prod.gcp.groupondev.com/app/r/s/pG0RQ` |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| ConDash Load Balancer Backend Response Error | No HTTP 200 responses from GCS backend detected | critical | Check bucket contents, recent deployments, CDN cache, LB configuration; see Troubleshooting below |

## Common Operations

### Restart Service

The Bookability Dashboard has no server processes to restart. To "restart" the service (force-serve fresh content):

1. Verify the GCS bucket has correct content (`gcloud storage ls gs://bookability-dashboard-web-prod-us-central1/`)
2. Invalidate CDN cache:
   ```bash
   gcloud compute url-maps invalidate-cdn-cache bookability-dashboard-web-prod-urlmap \
     --path "/*" --async --project=prj-grp-book-dash-prod-a776
   ```
3. Wait 2-5 minutes for CDN invalidation to propagate
4. Verify with `curl -I https://www.groupon.com/bookability/dashboard/` (expect `HTTP/2 200`)

### Scale Up / Down

> Not applicable — the service uses GCS static hosting. Scaling is handled automatically by Google Cloud CDN.

### Database Operations

> Not applicable — the service owns no database.

## Troubleshooting

### Dashboard returns 404 / 502 / 503

- **Symptoms**: Users cannot access `https://www.groupon.com/bookability/dashboard/`; Grafana alert fires
- **Cause**: GCS bucket is empty (failed deployment), CDN cache serving stale error response, or load balancer misconfiguration
- **Resolution**:
  1. Check bucket contents: `gcloud storage ls gs://bookability-dashboard-web-prod-us-central1/` — should contain `index.html` and `env-config.js`
  2. If empty, redeploy: trigger Jenkins pipeline or run manual deploy script with the latest known good `REVISION`
  3. Invalidate CDN cache and wait 2-5 minutes
  4. Check URL map config: `gcloud compute url-maps describe bookability-dashboard-web-prod-urlmap --project=prj-grp-book-dash-prod-a776`

### Dashboard loads but shows no data / spinner never resolves

- **Symptoms**: Dashboard loads but merchant/deal data never appears; browser console shows API errors
- **Cause**: `continuumPartnerService` is unavailable, or authentication (Doorman) is failing
- **Resolution**:
  1. Check Partner Service health in Kibana
  2. Verify `window._env_.API_URL` in `env-config.js` matches the expected proxy path
  3. Check browser network tab for HTTP status codes on API requests (401 = auth issue, 503 = Partner Service down)
  4. For 503: monitor Partner Service recovery; the dashboard will recover automatically on next data fetch

### Users cannot log in (stuck on login screen)

- **Symptoms**: Authentication loop; `LoginInternal` component repeatedly displayed
- **Cause**: `DOORMAN_URL` misconfigured in `env-config.js`, or Doorman service is unavailable
- **Resolution**:
  1. Verify `env-config.js` in the GCS bucket has the correct `DOORMAN_URL` value
  2. Check Doorman service availability: `https://doorman-na.groupondev.com` (production)
  3. If `env-config.js` is wrong, redeploy with the correct environment configuration file

### Data appears stale (not reflecting recent changes)

- **Symptoms**: Dashboard shows outdated merchant or deal data
- **Cause**: Browser in-memory cache has not expired (TTL: 5-10 minutes); or CDN is serving cached static assets after a deployment
- **Resolution**:
  1. Ask user to perform a hard refresh in the browser (Ctrl+Shift+R / Cmd+Shift+R) to clear in-memory state
  2. If stale assets after deployment: invalidate CDN cache (see Common Operations above)

### Health check logs take very long to load

- **Symptoms**: Deal detail view shows spinner for extended time when loading health-check history
- **Cause**: Large number of health-check log pages being fetched in parallel batches of 15; each page is 5,000 records; text extraction timeout is 180 s per page
- **Resolution**:
  1. Check Partner Service log volume in Kibana
  2. If logs are extremely large, Partner Service team may need to archive or paginate logs differently
  3. The dashboard has a 120 s Web Worker JSON parse timeout and 180 s text extraction timeout as safeguards

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Dashboard completely inaccessible to all users | Immediate | 3PIP-CBE engineering on-call |
| P2 | Dashboard loads but data is unavailable or stale | 30 min | 3PIP-CBE engineering |
| P3 | Partial feature degradation (e.g., one platform missing) | Next business day | 3PIP-CBE engineering |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `continuumPartnerService` | Kibana log dashboard; HTTP 200 on `/v1/partner_configurations` | Dashboard displays empty states; `isDown` banner shown on HTTP 503 |
| `continuumUniversalMerchantApi` | `/v2/merchant_oauth/internal/me` returns 200 | Login flow displayed; user cannot proceed until auth is restored |
| `apiProxy` | HTTP 200 on any dashboard API endpoint | All data fetching fails; browser console shows network errors |
| GCS buckets | `gcloud storage ls {bucket}` returns file list | CDN serves cached content until cache expires; then 404/502 |
| Google Cloud CDN | `curl -I https://www.groupon.com/bookability/dashboard/` | Direct GCS access (not exposed to users; transparent failover by GCP) |
