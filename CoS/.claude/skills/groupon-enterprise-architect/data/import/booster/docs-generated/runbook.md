---
service: "booster"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `boosterSvc_integrationHealth` (integration monitor) | integration health | Continuous | N/A |
| Status endpoint | http | Disabled (`status_endpoint: disabled: true` in `.service.yml`) | N/A |

The `boosterSvc_integrationHealth` component within `continuumBoosterService` monitors Booster API availability, latency, and error rates. Health signals are emitted by `boosterSvc_apiContract` and consumed by `boosterSvc_supportRunbook` to guide incident response.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| Booster API availability | gauge | Whether the Booster external API is reachable | Vendor SLA threshold |
| Booster API latency | histogram | Response time for relevance ranking calls | No evidence found in codebase |
| Booster API error rate | counter | Rate of failed calls to the Booster API | No evidence found in codebase |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Booster Integration Dashboard | Wavefront | https://groupon.wavefront.com/u/lVgXTqptGN?t=groupon |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Booster API Unavailable | Booster API returns errors or is unreachable | critical | Page on-call via PagerDuty PPPC7X8; escalate to Data Breakers vendor support |
| Booster API High Latency | Response times exceed acceptable threshold | warning | Check Wavefront dashboard; notify Data Breakers if persistent |

- **PagerDuty**: https://groupon.pagerduty.com/service-directory/PPPC7X8
- **Slack**: channel C04779SKR8T
- **GChat**: space AAAA6Qw3NOM

## Common Operations

### Restart Service

> Not applicable. Booster is an external SaaS operated by Data Breakers. Groupon cannot restart the Booster service directly. For Booster-side issues, contact Data Breakers vendor support.

### Scale Up / Down

> Not applicable. Scaling is managed by the vendor (Data Breakers) according to the vendor agreement.

### Database Operations

> Not applicable. Booster is an external SaaS with no Groupon-owned database.

## Troubleshooting

### Booster API Unavailable or Returning Errors
- **Symptoms**: Consumer deal discovery returns degraded or empty rankings; `continuumRelevanceApi` logs errors when calling Booster endpoints; Wavefront dashboard shows elevated error rates
- **Cause**: Booster SaaS outage, network issue, or vendor-side deployment problem
- **Resolution**: Check the Wavefront dashboard at https://groupon.wavefront.com/u/lVgXTqptGN?t=groupon; page the on-call engineer via PagerDuty PPPC7X8; contact Data Breakers vendor support; refer to the vendor support Confluence page at https://groupondev.atlassian.net/wiki/spaces/RAPI/pages/80466641012/Data+Breakers+-+Booster#Support

### High Latency from Booster API
- **Symptoms**: Elevated response times for consumer deal listing; `continuumRelevanceApi` call duration metrics increase; consumer-facing latency degrades
- **Cause**: Booster SaaS performance degradation or overload condition on the vendor side
- **Resolution**: Check Wavefront dashboard; notify Data Breakers if latency is consistently above SLA thresholds

### Booster API Authentication Failure
- **Symptoms**: Booster API returns 401 or 403 errors; zero ranked results returned to consumers
- **Cause**: Expired or misconfigured API credentials in the calling service (`continuumRelevanceApi`)
- **Resolution**: Verify API credentials are current; rotate credentials if expired; contact Data Breakers if vendor-side credential management is required

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Booster API fully down — consumer deal discovery non-functional | Immediate | relevance-engineering@groupon.com; PagerDuty PPPC7X8; Data Breakers vendor support |
| P2 | Booster API degraded — elevated errors or high latency | 30 min | relevance-engineering@groupon.com; Slack channel C04779SKR8T |
| P3 | Minor Booster integration anomaly | Next business day | relevance-engineering@groupon.com |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| Booster external API | `boosterSvc_integrationHealth` component; Wavefront dashboard | No evidence found in codebase — fallback behavior not documented in architecture model |

> Full operational runbook: https://groupondev.atlassian.net/wiki/spaces/RAPI/pages/80466641012/Data+Breakers+-+Booster#Support
