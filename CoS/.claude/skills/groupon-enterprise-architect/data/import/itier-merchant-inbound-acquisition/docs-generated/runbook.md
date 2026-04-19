---
service: "itier-merchant-inbound-acquisition"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Details |
|---------------------|------|----------|---------|
| Pingdom external check | HTTP GET `/merchant/signup` | Configured in Pingdom | Monitors public-facing signup page availability; triggers PagerDuty escalation on failure |
| Kubernetes liveness/readiness | HTTP | Kubernetes default | Managed by Conveyor Cloud deployment manifests |

Note: `.service.yml` declares `status_endpoint.disabled: true`, so no `/status` endpoint is exposed.

## Monitoring

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Conveyor container monitoring | Wavefront | https://groupon.wavefront.com/u/cjqFXrXtMZ |
| Application monitoring | Wavefront | https://groupon.wavefront.com/u/CzySftZ2kg |
| Merchant Inbound Acquisition main | Wavefront | https://groupon.wavefront.com/dashboard/merchant-inbound-acquisition |
| BFM service metrics | BFM | https://bfm.groupondev.com/manage/services/565 |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Pingdom page unavailable | `/merchant/signup` returns non-2xx or times out | Critical | Check VIP health (see Troubleshooting); check Wavefront container dashboard; notify SOC |
| PagerDuty on-call | Triggered by Pingdom failure | Critical | Escalates to metro-ui@groupon.pagerduty.com (service PVDWNAE) |

### SLA Targets

- p50 page interactive (`t_done`): < 1 second
- p99 page interactive (`t_done`): < 2 seconds
- Criticality tier: Tier-2
- Security classification: PII — not SOX, not PCI

## Common Operations

### Restart Service

Napistrano does not support a `start` command for Conveyor-hosted apps. Use restart:

```bash
yarn nap restart <env>
```

For Conveyor Cloud:
```bash
npx nap --cloud logs -c log-steno staging
```

### Scale Up / Down

Scaling is manual via replica count changes in deploy config or via Conveyor Cloud Kubernetes console.

Production clusters:
- `staging-us-west-1`: https://kube-web-view.stable.us-west-1.aws.groupondev.com/clusters/local/namespaces/merchant-inbound-acquisition-staging/deployments/merchant-inbound-acquisition--itier--default
- `production-us-west-1`: https://kube-web-view.prod.us-west-1.aws.groupondev.com/clusters/local/namespaces/merchant-inbound-acquisition-production/deployments/merchant-inbound-acquisition--itier--default
- `production-eu-west-1`: https://kube-web-view.prod.eu-west-1.aws.groupondev.com/clusters/local/namespaces/merchant-inbound-acquisition-production/deployments/merchant-inbound-acquisition--itier--default

For capacity additions, follow: https://pages.github.groupondev.com/conveyor-ci/conveyor-ci-docs/owners_manual/adding-capacity.html

### Rollback

```bash
# Conveyor Cloud rollback (redeploys last-known-good artifact)
npx nap --cloud rollback staging us-west-1
npx nap --cloud rollback production us-west-1
npx nap --cloud rollback production eu-west-1
```

### Database Operations

> Not applicable — this service owns no database. No migrations or backfills are required.

### Viewing Logs

```bash
# Staging logs
npx nap --cloud logs -c log-steno staging

# Production logs
npx nap --cloud logs -c log-steno production
```

Log sourcetype: `merchant-inbound-acquisition_itier` — indexed in Splunk index `steno`.

## Troubleshooting

### Pingdom Alert — Page Not Responding

- **Symptoms**: Pingdom fires; `/merchant/signup` returns 5xx or times out
- **Cause**: Container crash loop, VIP routing failure, or upstream dependency (Metro / Salesforce) blocking page render
- **Resolution**:
  1. Check Wavefront container dashboard for error rate spikes or OOM events
  2. Check VIP status for US: https://vipstatus.groupondev.com/vips/search?q=conveyor-itier-merchant-inbound-acquisition-vip.snc1
  3. Check VIP status for INTL: https://vipstatus.groupondev.com/vips/search?q=conveyor-itier-merchant-inbound-acquisition-vip.dub1
  4. If VIP bound hosts are not green, notify SOC via "Product Operations" chat; request container restart
  5. If VIP is healthy but app is failing, check application Wavefront dashboard; consider rollback

### Lead Creation Failing

- **Symptoms**: Form submission returns error; GA events show `web2lead-submit-draft error` or `web2lead-submit-salesforce error`
- **Cause**: Metro draft service unavailable, or Salesforce authentication/connection failure
- **Resolution**:
  1. Check Metro draft service health
  2. Check Salesforce login endpoint availability (`https://groupon-dev.my.salesforce.com`)
  3. Check `itier-tracing` / steno logs for `createSFLead failed` or `metro.createDraftMerchant failed` messages
  4. If Salesforce-specific: verify credentials have not expired (Salesforce password + security token)

### Address Autocomplete Not Working

- **Symptoms**: City/address type-ahead returns no results or errors
- **Cause**: `continuumApiLazloService` (Groupon V2 address API) unavailable
- **Resolution**:
  1. Check steno logs for `addressAutocomplete.result API failed` messages
  2. Verify `itier-groupon-v2-client` base URL configuration is resolving correctly for the environment
  3. The form degrades gracefully — lead submission still works without autocomplete

### Service Overloaded / High Latency

- **Symptoms**: p99 `t_done` exceeds 2 seconds; Wavefront shows increased memory or CPU
- **Cause**: Traffic spike; insufficient replica count; memory leak
- **Resolution**:
  1. Add capacity by increasing replica count (see Conveyor Cloud console links above)
  2. Check `NODE_OPTIONS=--max-old-space-size=1024` is appropriate; consider increasing heap in staging first
  3. Review Wavefront application dashboard for request queue depth

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down — merchant signup unavailable | Immediate | metro-ui@groupon.pagerduty.com (PVDWNAE); Slack #metro-automation |
| P2 | Degraded — lead submission failing for subset of countries | 30 min | Metro Dev BLR team; metro-dev-blr@groupon.com |
| P3 | Minor — analytics or A/B features broken, page loads but form partially impaired | Next business day | Create Jira ticket in MIA project |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| Metro draft service | Check via Metro service dashboard; inspect steno logs for `metro.createDraftMerchant failed` | No automatic fallback; error returned to user |
| Salesforce CRM | Check Salesforce instance availability; inspect steno logs for `createSFLead failed` | No automatic fallback; error returned to user |
| Groupon V2 address API (`continuumApiLazloService`) | Inspect steno logs for `addressAutocomplete.result API failed` | Form degrades gracefully — autocomplete disappears but submission continues |
