---
service: "giftcard_service"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `GET /grpn/healthcheck` | http | Per load-balancer config | Per load-balancer config |
| `GET /grpn/heartbeat` | http | Per load-balancer config | Per load-balancer config |
| `GET /heartbeat.txt` | http | Per load-balancer config | Per load-balancer config |
| `GET /status.json` | http | On-demand | — |

The `/grpn/healthcheck` path is blacklisted from the Sonoma access log middleware to prevent log noise.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| HTTP response codes (5xx) | counter | Server-side errors on any endpoint | Alert on sustained 5xx rate |
| HTTP response codes (4xx) | counter | Client errors — invalid gift card or request | Informational |
| First Data integration errors | counter | Failures from the Datawire XML API | Alert on elevated error rate |
| Orders bucks allocation failures | counter | Failures calling the Orders bucks API | Alert on elevated error rate |
| VIS redemption failures | counter | Failures from the Voucher Inventory Service | Alert on elevated error rate |

Metrics are emitted via the `Sonoma::Metrics::Middleware` (configured in `config/application.rb`).

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Primary SMA | Wavefront | https://groupon.wavefront.com/dashboards/giftcard-service--sma |
| Dashboard 1 | Wavefront | https://groupon.wavefront.com/u/8q25Hcd5s4?t=groupon |
| Dashboard 2 | Wavefront | https://groupon.wavefront.com/u/48wQTDWHzz?t=groupon |
| Dashboard 3 | Wavefront | https://groupon.wavefront.com/u/hvKWFr4Wgc?t=groupon |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Service down | Health check fails | P1 | Page via PagerDuty (https://groupon.pagerduty.com/services/P5AMT2O); notify giftcard-service-alerts@groupon.com |
| First Data unavailable | All First Data URL pings fail | P1 | Check First Data status; verify `first_data_urls` table has valid entries; contact First Data if needed |
| Orders bucks allocation failing | Sustained non-2xx from Orders API | P1 | Check Orders Service health; verify `ORDERS_API` env var points to correct host |
| Elevated 4xx on `/api/v1/redemptions` | High rate of invalid gift card errors | P2 | Investigate whether First Data mock mode is accidentally enabled in production (`config/first_data.yml`); check for upstream client changes |

Alert notifications go to `giftcard-service-alerts@groupon.com` and Google Chat space `AAAAXNgz0P4`.

## Common Operations

### Restart Service
Perform a rolling restart via Deploybot or Kubernetes:
```bash
kubectl rollout restart deployment/giftcard-service -n giftcard-service-{env}-sox
```
Or trigger a re-deploy through Deploybot with the current version.

### Scale Up / Down
Horizontal scaling is managed by HPA (min 2–3, max 15 replicas). To manually override:
```bash
kubectl scale deployment/giftcard-service --replicas={N} -n giftcard-service-{env}-sox
```
Note: HPA will reassert its settings; manual scaling is temporary.

### Database Operations
Migrations run automatically in test mode via the container entrypoint (`entrypoint.sh` runs `rake db:create db:migrate db:seed` when `RACK_ENV=test`). For production migrations, run via a one-off Kubernetes job or a deploy pipeline step. Use caution — the `legacy_credit_codes` table is operational data.

### First Data DID Provisioning
To provision a new First Data merchant account (DID):
1. Contact `securetransport.integration@firstdata.com` for `merchant_id`, `terminal_id`, and `srs_url`
2. Update `merchant_id` and `terminal_id` in `config/first_data.yml` under `svdot_constructor_settings`
3. Run the provisioning script: `SECRETS_DIR=$PWD/secrets construi rails runner ./script/get_datewire_id.rb -- --merchant_id=<id> --terminal_id=<id> --srs_url=<url>`
4. Capture the DID from output and update `datawire_id` in `config/first_data.yml` under `service_url_settings`

## Troubleshooting

### Gift card redemptions returning UNAUTHORIZED_GIFTCARD in production
- **Symptoms**: Valid external gift cards return `UNAUTHORIZED_GIFTCARD` or `UNAUTHORIZED_EXTERNAL_GIFTCARD`
- **Cause**: First Data `mock: true` accidentally active in production config, OR First Data Datawire endpoint is unreachable
- **Resolution**: Verify `RAILS_ENV` env var matches a production config block in `config/first_data.yml` where `mock: false`; check `first_data_urls` table for valid URLs; check First Data service status

### VIS code redemption failing with UNAUTHORIZED_INTERNAL_GIFTCARD
- **Symptoms**: Internal `vs-` prefixed gift cards rejected even for valid codes
- **Cause**: VIS API unreachable, unit not in `collected` + `isRedeemable` status, unit is refunded, or deal category validation failing
- **Resolution**: Check VIS service health; check Orders API health (`/v2/inventory_units/{unit_id}` endpoint); verify deal's `primaryDealServiceCategoryId` matches configured UUID in `config/deal_catalog_service.yml`; check EMEA `distribution_region_code_check` setting

### Orders bucks allocation stuck with CONCURRENT_BUCKS_ALLOCATION_REQUEST
- **Symptoms**: Redemption takes >60 seconds (6 attempts × 10-second interval) and returns `SERVER_ERROR`
- **Cause**: Orders Service is throttling concurrent bucks allocation requests for the same user
- **Resolution**: Check Orders Service health and throughput; if user-specific, the issue resolves automatically after the lock clears; check for concurrent redemption attempts by the same user

### ServiceDiscovery job not refreshing First Data URLs
- **Symptoms**: First Data requests using stale or failing endpoints
- **Cause**: `ServiceDiscovery` job (SuckerPunch, hourly) failing silently
- **Resolution**: Check application logs for First Data service discovery errors; verify Datawire discovery URL (`https://vxn.datawire.net/sd/{service_id}`) is reachable; check `first_data_urls` table last-write timestamps

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down — no gift cards can be redeemed | Immediate | Payments team (cap-payments@groupon.com); PagerDuty P5AMT2O; giftcard-service-alerts@groupon.com |
| P2 | Degraded — some regions or card types failing | 30 min | Payments team via Google Chat space AAAAXNgz0P4 |
| P3 | Minor impact — elevated error rate, service operational | Next business day | cap-payments@groupon.com |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| Orders Service | `GET http://{ORDERS_API}/` or check Orders service monitoring | No fallback — bucks cannot be allocated without Orders; redemption fails with `SERVER_ERROR` |
| Voucher Inventory Service (VIS) | VIS service health endpoint | No fallback — VIS code redemptions fail; external card redemptions are unaffected |
| Deal Catalog Service | Deal Catalog service health endpoint | No fallback — VIS redemptions requiring category validation fail |
| First Data / Datawire | `ServiceDiscovery` job pings all discovered URLs hourly; `first_data_urls` table holds results | In mock mode (non-production), `FirstData::GiftCardMock` is used; in production, no fallback |
| MySQL Database | Database connectivity (ActiveRecord connection pool) | No fallback — legacy credit code creation and First Data URL management fail |
