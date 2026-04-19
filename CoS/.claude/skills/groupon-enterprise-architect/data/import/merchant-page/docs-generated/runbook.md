---
service: "merchant-page"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `/status.json` (port 8000) | http | Configured in `.service.yml` (disabled: true) | Not configured |
| Kubernetes liveness / readiness probes | http | Managed by Conveyor Cloud / cmf-itier Helm chart | Managed by Helm chart |
| Pingdom synthetic check (`www.groupon.com`) | http (external) | Pingdom-configured | Pingdom-configured |

> Note: The `.service.yml` declares `status_endpoint.disabled: true`. Health is assessed via Kubernetes probes and external Pingdom monitoring.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| Server-side latency P50 | histogram | Median page render time | Baseline: ~300 ms |
| Server-side latency P90 | histogram | 90th percentile page render time | Baseline: ~750 ms |
| Server-side latency P99 | histogram | 99th percentile page render time | Alert if >1200 ms |
| Memory utilisation | gauge | Pod memory usage vs. 3072 Mi limit | Critical if sustained high (risk of OOM) |
| HTTP error rate | counter | 5xx response rate | Alert on sustained elevation |

Metrics are emitted via `itier-instrumentation` ^9.10.4 to Wavefront (via Telegraf/InfluxDB) in conformance with the Standard Measurement Architecture.

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| SNc1/SAc1 merchant page dashboard | Wavefront | `https://groupon.wavefront.com/dashboard/sac1_snc1-i-tier-merchant-place-pages` |
| SNc1 itier dashboard | Wavefront | `https://groupon.wavefront.com/dashboard/snc1-itier_merchant_page-snc1` |
| SAc1 itier dashboard | Wavefront | `https://groupon.wavefront.com/dashboard/sac1-itier_merchant_page-sac1` |
| Dub1 merchant page dashboard | Wavefront | `https://groupon.wavefront.com/dashboard/dub1-i-tier-merchant-place-pages-dub1` |
| Dub1 itier dashboard | Wavefront | `https://groupon.wavefront.com/dashboard/dub1-itier_merchant_page-dub1` |
| Unified merchant page dashboard | Wavefront | `https://groupon.wavefront.com/dashboard/merchant-page` |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Server Side Latency | Increased server-side latency above SLA thresholds | P1 | Check dependency graphs; identify slow upstream API; contact responsible team |
| Memory Utilisation | Memory utilisation critical (risk of OOM and server lockup) | P3 | Check processes; assess memory leak; restart app after removing from load balancer; escalate to PagerDuty |
| DOWN alert: merchant-page (www.groupon.com) is DOWN | Pingdom cannot reach `www.groupon.com/biz/` | P1 | Check internal reachability; contact SRE/SOC if external-only; check load balancer; hit individual pods |

- **PagerDuty**: `https://groupon.pagerduty.com/service-directory/PEZNVMT`
- **Alert email**: `seo_alerts@groupon.com`
- **GChat space**: `AAAANlivtII`

## Common Operations

### Restart Service

Restarting is handled via Napistrano or Deploybot rollback (which re-deploys the last known good artifact). To restart individual pods without re-deploying, use `krane` or `kubectl` directly on the Kubernetes cluster.

```bash
# Via Napistrano rollback (redeploys previous artifact)
npx nap --cloud rollback staging us-central1

# Via Deploybot UI
# 1. Open https://deploybot.groupondev.com/seo/merchant-page
# 2. Click the current deployment's version
# 3. Click "ROLLBACK"
```

For emergency load-balancer removal before restart: remove or rename the heartbeat file at `/var/groupon/nginx/heartbeat.txt` on the affected host.

### Scale Up / Down

Replica counts are defined in `.deploy-configs/*.yml`. To scale horizontally:

1. Update `minReplicas` / `maxReplicas` in the appropriate deploy config file.
2. Re-deploy via Napistrano / Deploybot.

For immediate temporary scaling, consult the [I-Tier Adding Capacity documentation](https://itier.groupon.com).

### Database Operations

> Not applicable — this service owns no database. No migrations or backfills apply.

## Troubleshooting

### Increased Server-Side Latency

- **Symptoms**: P50 > 300 ms, P90 > 750 ms, or P99 > 1200 ms sustained; Wavefront alerts fire
- **Cause**: Slow or degraded upstream dependency (`continuumUniversalMerchantApi`, `continuumRelevanceApi`, `continuumUgcService`, or `gims`)
- **Resolution**: Check the dependency latency graphs in Wavefront. Identify the slow API. Contact the responsible team. If a non-critical dependency is slow, consider disabling the related feature flag (see [Disabling Features](#disabling-features)).

### Memory Utilisation Critical

- **Symptoms**: Pod memory approaches 3072 Mi limit; risk of OOM kill and pod restart loop
- **Cause**: Memory leak in application code or a dependency; elevated traffic volume; large page payloads
- **Resolution**: Check Wavefront memory graphs for scope (single pod vs. fleet). Temporarily remove affected host from load balancer by renaming `/var/groupon/nginx/heartbeat.txt`. Restart the app. Escalate to PagerDuty (`https://groupon.pagerduty.com/services/P9LHU5Y`) for investigation.

### Pingdom DOWN Alert

- **Symptoms**: Pingdom reports `www.groupon.com` merchant pages are unreachable
- **Cause**: Routing Service misconfiguration; Hybrid Boundary issue; pod crash; networking failure
- **Resolution**: Verify internal reachability at `http://merchant-page.production.service.us-central1.gcp.groupondev.com/biz/*`. If internal is healthy, contact SRE/SOC for external routing investigation. If internal is also down, check pod status via Kube Web View and consider rollback.

### Disabling Features

Non-core features can be disabled via GConfig feature flags (`https://gconfig.groupondev.com/apps/merchant-page#feature_flags`) without a code deploy:

- **`megamind_widgets`**: Disables megamind GAPI call and hides widgets/deals
- **`nearby_deals_map`**: Disables the nearby deals map API call
- **`merchant_specials`**: Disables merchant specials API call
- **`coupons`**: Disables coupons API call

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down / Pingdom DOWN alert | Immediate | SEO team on-call; SRE/SOC if routing-layer issue |
| P2 | Degraded latency / elevated error rate | 30 min | SEO team; dependency team if upstream-caused |
| P3 | Memory warnings / non-critical feature failures | Next business day | SEO team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `continuumUniversalMerchantApi` | Check latency via Wavefront dependency graphs | Page returns `500` on failure |
| `continuumRelevanceApi` | Check latency via Wavefront dependency graphs | Deal carousel is hidden; page still renders |
| `continuumUgcService` | Check latency via Wavefront dependency graphs | Reviews section is empty; page still renders |
| `gims` | Check latency via Wavefront dependency graphs | Map image is omitted; page still renders |
| `continuumApiLazloService` | Check latency via Wavefront dependency graphs | Deal proxy fails; full merchant page renders instead |

## Log Access

| Environment | Location |
|-------------|----------|
| Production US logs | ELK: `https://logging-us.groupondev.com` (index: `us-*:filebeat-merchant-page_itier--*`) |
| Production EU logs | ELK: `https://logging-eu.groupondev.com` (index: `eu-*:filebeat-merchant-page_itier--*`) |
| Staging logs | ELK: `https://logging-stable-unified01.grpn-logging-stable.us-west-2.aws.groupondev.com` |
| Production US pods | Kube Web View: `https://kube-web-view.prod.us-central1.gcp.groupondev.com/clusters/local/namespaces/merchant-page-production/deployments/merchant-page--itier--default/logs` |
| Production EU pods | Kube Web View: `https://kube-web-view.prod.eu-west-1.aws.groupondev.com/clusters/local/namespaces/merchant-page-production/deployments/merchant-page--itier--default/logs` |
| Command line | `npx nap --cloud logs --follow <env> <region>` |
