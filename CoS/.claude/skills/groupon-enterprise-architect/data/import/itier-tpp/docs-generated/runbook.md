---
service: "itier-tpp"
title: Runbook
generated: "2026-03-02T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `http://itier-tpp.staging.service/grpn/versions` | http | — | — |
| `http://itier-tpp.production.service/grpn/versions` | http | — | — |
| Nagios alert: `tpp_api_response_code errors increase` | external | continuous | — |
| Nagios alert: `tpp_response_code errors increase` | external | continuous | — |

Access via Hybrid Boundary tools: `https://github.groupondev.com/service-mesh/hb-tools#hb-tools`.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| `tpp_api_response_code` | counter | HTTP response code distribution for API endpoints | Abnormal error code increase |
| `tpp_api_response_time` | histogram | Response time for API endpoint calls | Abnormal latency increase |
| `tpp_response_time` | histogram | Response time for page loads | Abnormal latency increase (TP99 SLA: 2500 ms) |
| `tpp_response_code` | counter | HTTP response code distribution for page routes | Abnormal error code increase |
| `tpp_errors_and_boots` | counter | Process crash and restart count | Abnormal crash/boot increase |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| HTTP status codes (Splunk) | Splunk | `https://splunk-adhoc-snc1.groupondev.com` (search `sourcetype:itier-tpp_json`) |
| Performance graphs | Wavefront | `https://groupon.wavefront.com/u/FvlMGmmrFx` |
| Kubernetes workload | kube-web-view | `https://kube-web-view.stable.us-west-2.aws.groupondev.com/clusters/local/namespaces/itier-tpp-staging` |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| `tpp_api_response_code errors increase` | Abnormal error rate on API endpoints | P4 | Check Splunk and Wavefront; review recent deploy; rollback if needed; escalate to Partner Service team |
| `tpp_api_response_time increase` | API endpoint response time abnormally high | P4 | Check Splunk and Wavefront; review recent deploy; rollback if needed; page Partner Service team |
| `tpp_response_time increase` | Page load response time abnormally high | P4 | Check Splunk and Wavefront; review recent deploy; rollback if needed |
| `tpp_response_code errors increase` | Abnormal error rate on page routes | P4 | Check Splunk and Wavefront; review recent deploy; rollback if needed |
| `tpp_errors_and_boots increase` | Abnormal number of crashes and restarts | P4 | Check Splunk and Wavefront; review recent deploy; rollback if needed; escalate to I-Tier team |

PagerDuty escalation: `https://groupon.pagerduty.com/services/P8N7XHT`

## Common Operations

### Restart Service

Rolling restart via Kubernetes (no downtime):
```
nap --cloud deploy <current-artifact> <env> <region>
```
Or use `kubectl rollout restart deployment/itier-tpp-itier -n itier-tpp-production`.

### Scale Up / Down

Replica counts are defined in `.deploy-configs/*.yml`. Production is fixed at 3. To temporarily scale in staging:
```
kubectl scale deployment/itier-tpp-itier -n itier-tpp-staging --replicas=<N>
```
Permanent changes require updating `minReplicas`/`maxReplicas` in the Napistrano config and redeploying.

### Disable Feature Flags

Feature flags can be toggled at `https://gconfig.groupondev.com/apps/itier-tpp#feature_flags`. Obtain product team approval before disabling time-consuming page flags to shed load.

### Database Operations

> Not applicable. This service is stateless and does not own any data stores.

## Troubleshooting

### High Error Rate on API Endpoints
- **Symptoms**: Nagios alert `tpp_api_response_code errors increase`; elevated 5xx in Splunk
- **Cause**: Usually a downstream service outage (Partner Service is the identified primary bottleneck) or a bad deploy
- **Resolution**: (1) Check Splunk for error details; (2) Check Wavefront for correlated latency spikes; (3) Review recent deploys; (4) If a recent deploy is suspected, rollback with `nap --cloud rollback <env> <region>`; (5) If errors trace to Partner Service, escalate to that team

### High Page Load Latency
- **Symptoms**: Nagios alert `tpp_response_time increase`; TP99 exceeds 2500 ms SLA
- **Cause**: Slow downstream calls (Partner Service timeout 30 s); memory pressure; traffic spike
- **Resolution**: (1) Check Partner Service latency; (2) Check Node.js memory usage (`NODE_OPTIONS --max-old-space-size=1024`); (3) Disable expensive feature-flagged pages via gconfig; (4) Scale up staging replica count

### Crash / OOM Loop
- **Symptoms**: Nagios alert `tpp_errors_and_boots increase`; pods in `CrashLoopBackOff`
- **Cause**: Memory limit exceeded (4096 Mi); uncaught exception; dependency failure at startup
- **Resolution**: (1) Check pod logs via `kubectl logs`; (2) Check for OOM kill events; (3) Rollback if caused by a deploy; (4) Escalate to I-Tier platform team if systemic

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service completely down | Immediate | 3pip-booking@groupon.com, PagerDuty P8N7XHT |
| P2 | Degraded (major flows broken) | 30 min | 3pip-booking@groupon.com, Partner Service team |
| P3 | Minor impact (single feature broken) | Next business day | #3pip-custom-integrations-eng Slack |
| P4 | Alert / degraded performance | Best effort | #partner-ops-notifications Slack |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `continuumPartnerService` | Check Splunk for PAPI errors; verify `itier-tpp.production.service` → PAPI latency | Portal pages return errors; no built-in fallback |
| `bookerApi` | Verify Booker API credentials are valid; check `/partnerbooking` pages | Booker integration pages unavailable |
| `mindbodyApi` | Verify `MINDBODY_USERNAME`/`MINDBODY_PASSWORD` secrets; check `/partnerbooking` pages | Mindbody integration pages unavailable |
| `continuumApiLazloService` | Check deal-loading pages for errors | Deal data unavailable in affected portal views |
| `continuumDealCatalogService` | Check deal history views for errors | Deal history unavailable |
| `continuumGeoDetailsService` | Check onboarding forms for geo field errors | Division/location selection unavailable |
