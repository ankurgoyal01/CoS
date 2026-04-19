---
service: "akamai-cdn"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| Akamai Control Center (`https://control.akamai.com`) | http (manual check) | On-demand | N/A |
| Akamai status page (Akamai-provided) | http | On-demand | N/A |

> Note: The service has `status_endpoint: disabled: true` in `.service.yml`. No Groupon-owned health endpoint exists for this managed SaaS service.

## Monitoring

### Metrics

> No evidence found of Groupon-owned metric instrumentation. Akamai provides its own delivery metrics, cache hit ratios, and edge performance data through the Akamai Control Center portal and DataStream API.

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Akamai Control Center | Akamai (SaaS) | https://control.akamai.com |

### Alerts

> Operational procedures to be defined by service owner. The SRE cloud-routing team (cloud-routing@groupon.com) is the responsible party for configuring Akamai-native alerting and any Groupon-side integration with alerting systems.

## Common Operations

### Apply CDN Configuration Change

1. Log in to Akamai Control Center at `https://control.akamai.com`
2. Navigate to the relevant Groupon CDN property
3. Edit property rules (caching TTLs, routing logic, WAF rules) via Property Manager
4. Activate the updated configuration to the staging edge network first
5. Verify delivery behavior on staging
6. Activate the configuration to the production edge network
7. Monitor cache hit rates and error rates via Akamai reporting dashboards

### Purge CDN Cache

1. Log in to Akamai Control Center at `https://control.akamai.com`
2. Navigate to the Fast Purge section
3. Submit a purge request by URL, CP code, or tag as appropriate
4. Monitor purge completion status in the Control Center
5. Verify that content is refreshed by testing affected URLs

### Restart Service

> Not applicable — Akamai CDN is a managed SaaS platform with no Groupon-owned server processes to restart. To "restart" edge delivery for a Groupon property, activate a clean configuration version in Akamai Property Manager.

### Scale Up / Down

> Not applicable — scaling is managed entirely by Akamai's global edge network infrastructure.

### Database Operations

> Not applicable — this service owns no databases. See [Data Stores](data-stores.md).

## Troubleshooting

### Cache Serving Stale Content

- **Symptoms**: Users see outdated pages or assets after a Groupon deployment
- **Cause**: CDN cache TTLs have not expired and no purge was performed after the deployment
- **Resolution**: Initiate a Fast Purge via Akamai Control Center targeting the affected URLs, CP codes, or cache tags

### CDN Property Activation Failure

- **Symptoms**: A configuration change submitted to Akamai fails to activate; activation status shows "Error" in Control Center
- **Cause**: Invalid property rule syntax, conflicting rule conditions, or Akamai validation rejection
- **Resolution**: Review the activation error details in the Akamai Control Center activation log, correct the property rule, and resubmit activation

### Elevated Edge Error Rates

- **Symptoms**: Akamai reporting shows increased 5xx or 4xx error rates from edge nodes
- **Cause**: Origin connectivity issues, misconfigured routing rules, or WAF rule false positives blocking legitimate traffic
- **Resolution**: Check Akamai EdgeGrid reporting for error breakdown; verify origin health separately; temporarily disable overly aggressive WAF rules if false positives are confirmed; escalate to Akamai support if edge-side anomalies are detected

### Configuration Change Not Propagating to Edge

- **Symptoms**: Updated property rules are not taking effect on edge nodes after activation
- **Cause**: Activation propagation may take several minutes to complete across all edge servers; or a prior activation is still in progress
- **Resolution**: Check activation status in Akamai Control Center — wait for full propagation (typically 5-15 minutes); if status shows "Active" but behavior is unchanged, perform a targeted cache purge for the affected path

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | CDN completely down — all Groupon traffic affected | Immediate | cloud-routing@groupon.com |
| P2 | Degraded CDN performance or partial routing failure | 30 min | cloud-routing@groupon.com |
| P3 | Minor configuration issue, no user impact | Next business day | cloud-routing@groupon.com |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| Akamai Control Center | Browse `https://control.akamai.com`; check Akamai status page | Configuration changes must be deferred until Control Center is available; existing CDN delivery continues unaffected |
| Akamai Edge Network | Monitor Akamai delivery metrics and Akamai status page | No automated Groupon-side fallback; Akamai SLA governs edge availability |
