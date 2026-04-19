---
service: "sub_center"
title: Runbook
generated: "2026-03-03T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `/health` or `/_health` | http | Inferred from I-Tier standards | Inferred from I-Tier standards |

> Specific health check endpoint path and intervals are not defined in the architecture module. Verify in the service source repository and Kubernetes liveness/readiness probe configuration.

## Monitoring

### Metrics

> No evidence found in codebase. Metrics collection follows standard Continuum I-Tier patterns (inferred: request rate, error rate, response latency). Operational procedures to be defined by service owner.

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| HTTP request rate | counter | Requests per second to subscription center endpoints | To be defined |
| HTTP error rate (5xx) | counter | Server-side errors on subscription endpoints | To be defined |
| HTTP response latency | histogram | P99 latency for page rendering | To be defined |
| Memcached cache hit rate | gauge | Cache effectiveness for division/channel metadata | To be defined |
| Downstream error rate | counter | Errors from calls to Groupon V2 API, GSS, etc. | To be defined |

### Dashboards

> No evidence found in codebase. Operational procedures to be defined by service owner.

| Dashboard | Tool | Link |
|-----------|------|------|
| sub_center Service Dashboard | Datadog / Grafana (inferred) | To be defined by service owner |

### Alerts

> No evidence found in codebase. Operational procedures to be defined by service owner.

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| High 5xx Error Rate | >1% error rate over 5 min | critical | Check downstream service health; review logs |
| Unsubscribe Flow Failures | POST /unsubscribe returning errors | critical | Check Groupon V2 API and Subscriptions Service health |
| SMS Delivery Failures | Twilio SDK errors | warning | Check Twilio account status and credentials |
| Memcached Connectivity | Cache access failures | warning | Verify Memcached host configuration and connectivity |

## Common Operations

### Restart Service

Operational procedures to be defined by service owner. For Kubernetes-managed deployments:
1. Identify the deployment: `kubectl get deployment sub-center -n <namespace>`
2. Perform a rolling restart: `kubectl rollout restart deployment/sub-center -n <namespace>`
3. Monitor rollout: `kubectl rollout status deployment/sub-center -n <namespace>`

### Scale Up / Down

Operational procedures to be defined by service owner. For Kubernetes HPA-managed scaling:
1. Check current scale: `kubectl get hpa sub-center -n <namespace>`
2. Manually scale if needed: `kubectl scale deployment/sub-center --replicas=<N> -n <namespace>`

### Database Operations

> Not applicable. sub_center does not own a database. Subscription state is managed by downstream services. For cache issues, flush or restart the Memcached instance via the infrastructure team.

## Troubleshooting

### Unsubscribe Flow Not Processing

- **Symptoms**: Users report clicking unsubscribe links but remaining subscribed; POST to `/subscription-center/unsubscribe` returns errors
- **Cause**: Downstream Groupon V2 API or Subscriptions Service unavailable or returning errors
- **Resolution**: Check health of `grouponV2Api_ext_7c1d` and `subscriptionsService_ext_9a41`; review service logs for HTTP error codes from downstream calls

### Subscription Center Page Not Loading

- **Symptoms**: Users see errors or blank pages when navigating to the subscription center
- **Cause**: Remote Layout Service unavailable, or GeoDetails / Subscriptions Service failing on page load
- **Resolution**: Check health of `remoteLayoutService_ext_1f8c`, `geoDetailsService_ext_4d22`, and `subscriptionsService_ext_9a41`; check Memcached connectivity

### SMS Unsubscribe Not Sending

- **Symptoms**: Users complete the SMS unsubscribe flow but do not receive confirmation SMS
- **Cause**: Twilio SDK error — invalid credentials, account suspension, or network connectivity issue
- **Resolution**: Verify Twilio credentials in Vault; check Twilio account status in the Twilio Console

### High Latency on Subscription Pages

- **Symptoms**: Subscription center pages loading slowly
- **Cause**: Cache miss rate spike causing extra downstream calls; Remote Layout Service or GeoDetails Service slow
- **Resolution**: Check Memcached hit rate; review response times for Remote Layout Service and GeoDetails Service

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Unsubscribe flows completely broken (compliance risk) | Immediate | Continuum Platform Team |
| P2 | Subscription center pages degraded or slow | 30 min | Continuum Platform Team |
| P3 | Minor feature degradation (e.g., feature flag not evaluating) | Next business day | Continuum Platform Team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| Groupon V2 API (`grouponV2Api_ext_7c1d`) | Check service health endpoint | Return error to user; do not silently fail unsubscribes |
| GSS Service (`gssService_ext_5b3e`) | Check service health endpoint | Degraded subscription metadata display |
| Subscriptions Service (`subscriptionsService_ext_9a41`) | Check service health endpoint | Return error page |
| Remote Layout Service (`remoteLayoutService_ext_1f8c`) | Check service health endpoint | Render page without layout chrome |
| Twilio SMS (`twilioSms_ext_3a95`) | Check Twilio status page | Log failure; notify user that SMS confirmation may be delayed |
| Memcached (`memcached_ext_0c5e`) | TCP connectivity to host:port | Fetch data directly from upstream services (cache bypass) |
