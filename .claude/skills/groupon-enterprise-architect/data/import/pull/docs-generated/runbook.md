---
service: "pull"
title: Runbook
generated: "2026-03-02T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| Platform liveness probe (I-Tier standard) | http | Platform-managed | Platform-managed |
| Platform readiness probe (I-Tier standard) | http | Platform-managed | Platform-managed |

> Specific health check endpoint paths are managed by the `itier-server` framework and I-Tier platform conventions. Consult the I-Tier platform runbook for standard health endpoint details.

## Monitoring

### Metrics

Pull emits request metrics, distributed tracing, and application telemetry via `pullTelemetryPublisher` using `itier-instrumentation 9.13.4`.

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| Request latency (per route) | histogram | End-to-end render time for `/`, `/browse`, `/search`, `/local`, `/goods`, `/gifting` | Platform-defined SLA |
| Request error rate | counter | HTTP 5xx responses per route | Platform-defined threshold |
| Upstream dependency errors | counter | Failures calling Relevance API, API Proxy, Birdcage, Layout Service, GeoPlaces, LPAPI, UGC, Wishlist | Dependency-specific |
| Node.js process memory | gauge | Heap and RSS memory usage | Platform-managed |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Pull I-Tier Service Dashboard | Platform observability tooling | Consult Team Ion for dashboard links |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| High 5xx error rate | Error rate exceeds threshold on any discovery route | critical | Check upstream dependencies; review logs for root cause service |
| Elevated latency | P99 render time exceeds SLA on browse/search | warning | Check Relevance API and API Proxy response times |
| Relevance API unavailable | All calls to `continuumRelevanceApi` failing | critical | Escalate to Relevance API team; browse/search pages non-functional |
| Birdcage unavailable | All calls to `continuumBirdcageService` failing | warning | Feature flags fail-open to defaults; service continues degraded |

## Common Operations

### Restart Service

Operational procedures to be defined by service owner (Team Ion). Follow the standard I-Tier platform restart procedure — rolling restart via the platform orchestration tooling to avoid traffic loss.

### Scale Up / Down

Operational procedures to be defined by service owner (Team Ion). Scaling is managed by the I-Tier platform. Contact the platform team or use the I-Tier deployment tooling to adjust replica counts.

### Database Operations

> Not applicable. Pull is stateless and owns no data stores.

## Troubleshooting

### Browse/Search Pages Returning Errors or Empty Content

- **Symptoms**: HTTP 5xx responses on `/browse` or `/search`; pages render with no deal cards
- **Cause**: `continuumRelevanceApi` is unavailable or returning errors; `pullSearchBrowseOrchestrator` cannot assemble deal card data
- **Resolution**: Verify `continuumRelevanceApi` health; check API Proxy (`apiProxy`) availability; review `pullApiClientFacade` error logs

### Homepage Rendering Failure

- **Symptoms**: HTTP 5xx or blank page on `GET /`
- **Cause**: `pullHomepageOrchestrator` failure; likely upstream issue with API Proxy or Layout Service
- **Resolution**: Check `continuumLayoutService` and `apiProxy` availability; review homepage orchestrator error traces

### Incorrect Geographic Listings

- **Symptoms**: Users see deals for wrong city or division
- **Cause**: `continuumGeoPlacesService` returning incorrect location data; `pullGeoResolver` using fallback division
- **Resolution**: Verify GeoPlaces service health and input request headers (`X-Forwarded-For`)

### Feature Flags Not Applying

- **Symptoms**: Experiment variants not rendering; all users seeing baseline experience
- **Cause**: `continuumBirdcageService` unavailable; `pullFeatureFlagClient` failing open to defaults
- **Resolution**: Verify Birdcage service health; check `itier-feature-flags` client logs

### Wishlist Indicators Missing for Signed-In Users

- **Symptoms**: Wishlist heart icons absent or stale on listing pages for authenticated users
- **Cause**: `continuumWishlistService` unavailable or slow
- **Resolution**: Verify Wishlist service health; wishlist is non-critical — pages otherwise render normally

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down — all discovery pages returning 5xx | Immediate | Team Ion (ion@groupon.com); I-Tier platform on-call |
| P2 | Degraded — one or more routes degraded (e.g., search broken, homepage slow) | 30 min | Team Ion (ion@groupon.com) |
| P3 | Minor impact — non-critical feature degraded (e.g., wishlist, UGC missing) | Next business day | Team Ion (ion@groupon.com) |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `apiProxy` | Check API Proxy service health endpoint | Pages render with degraded supplemental content |
| `continuumBirdcageService` | Check Birdcage service health | Feature flags fail-open; baseline rendering continues |
| `continuumGeoPlacesService` | Check GeoPlaces service health | Falls back to default division; geolocation may be incorrect |
| `continuumLayoutService` | Check Layout Service health | Pages may fall back to static default layout |
| `continuumRelevanceApi` | Check Relevance API health | Browse/search pages cannot render deal cards — critical path |
| `continuumLpapiService` | Check LPAPI health | Browse/local pages may use generic layout |
| `continuumUgcService` | Check UGC service health | Ratings and reviews omitted from page |
| `continuumWishlistService` | Check Wishlist service health | Wishlist indicators omitted; page otherwise renders normally |
