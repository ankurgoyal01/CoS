---
service: "gpn-data-api"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `GET /grpn/healthcheck` | HTTP (Dropwizard health check) | Kubernetes liveness/readiness probe interval | Kubernetes default |
| `GET /grpn/status` | HTTP (JTier status endpoint — disabled in `.service.yml`) | N/A | N/A |
| Hybrid Boundary health check | HTTPS via edge proxy | Continuous | Standard HB timeout |

> The `GpnDataApiHealthCheck` is a placeholder that always returns healthy (arithmetic check `2 + 2 == 4`). Real dependency health is not reflected in the health check endpoint.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| Incoming HTTP request rate (RPM) | counter | Total requests received per minute | Alert: 0 RPM for 15 minutes |
| HTTP error rate | counter | Proportion of 4xx/5xx responses | Alert threshold configured in Wavefront |
| JVM heap usage | gauge | JVM memory utilisation | Wavefront JVM dashboard |
| Envoy upstream latency | histogram | End-to-end request latency via Hybrid Boundary | Wavefront SMA dashboard |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| SMA (Service Mesh Analytics) | Wavefront | https://groupon.wavefront.com/dashboards/gpn-data-api--sma |
| Service Health | Wavefront | https://groupon.wavefront.com/u/ChWfVwkDkx?t=groupon |
| Service Resources | Wavefront | https://groupon.wavefront.com/u/mHtDh16VdN?t=groupon |
| Hybrid Boundary | Wavefront | https://groupon.wavefront.com/u/1LCj7jjfpd?t=groupon |
| Custom (full overview) | Wavefront | https://groupon.wavefront.com/u/nWm3hhWnzc?t=groupon |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| No Incoming Traffic Alert | No incoming requests for 15 consecutive minutes | 4 (Warning) | Check Wavefront, Kibana, Hybrid Boundary, and pod logs — see [No Incoming Traffic](#no-incoming-traffic) |

PagerDuty service: https://groupon.pagerduty.com/services/PP9FGY1

Alert email: gpn-alerts@groupon.com

## Common Operations

### Restart Service

```bash
# Authenticate in the Kubernetes cluster
kubectl cloud-elevator auth

# Switch to the target context (choose production or staging)
kubectx gpn-data-api-production-us-central-1
# or
kubectx gpn-data-api-staging-us-central-1

# Stop all pods
kubectl scale --replicas=0 deployment/gpn-data-api--api--default

# Restart pods (use the desired replica count)
kubectl scale --replicas=2 deployment/gpn-data-api--api--default
```

### Scale Up / Down

Adjust `minReplicas` / `maxReplicas` in `.meta/deployment/cloud/components/api/production-us-central1.yml` and redeploy via deployBot. For immediate scaling without a deployment:

```bash
kubectl scale --replicas=<N> deployment/gpn-data-api--api--default
```

Production HPA bounds: min 2, max 5. Staging HPA bounds: min 1, max 2.

### Database Operations

- **Query limit adjustment**: Update the `property_value` for `property_name = 'attribution_teradata'` in the `attribution_properties` MySQL table.
- **Reset daily query count**: Manually delete or zero out the row in `attribution_query_count` for today's date if the limit was incorrectly set.
- **Schema migrations**: Managed by `com.groupon.jtier:jtier-migrations`. Migrations run automatically at application startup.

## Troubleshooting

### No Incoming Traffic

- **Symptoms**: Wavefront "No Incoming Traffic Alert" fires; `sem-ui` reports attribution data unavailable
- **Cause**: Pod crash, failed deployment, Hybrid Boundary misconfiguration, or upstream caller issue
- **Resolution**:
  1. Check the Wavefront dashboard for recent error spikes
  2. Verify service health via the Service Health dashboard, filtering by `serviceId = gpn-data-api`
  3. Check Hybrid Boundary health: `curl -k -L -vvv https://edge-proxy--staging--default.us-central1.conveyor.stable.gcp.groupondev.com/grpn/healthcheck --header "Host: gpn-data-api.staging.service"`
  4. Review Kibana logs (index: `filebeat-gpn-data-api_api--*`) for exceptions
  5. If Kibana is inconclusive, check pod logs directly (see pod log commands below)

### Pod Log Inspection

```bash
kubectl cloud-elevator auth
kubectx gpn-data-api-production-us-central-1
kubectl get pods
kubectl logs -f pod/<pod-name> app
```

### HTTP 429 Too Many Requests

- **Symptoms**: All attribution requests return `429` with message `"Maximum Query Limit reached for the user"`
- **Cause**: Daily query count in `attribution_query_count` exceeded the limit stored in `attribution_properties`
- **Resolution**: Increase the limit by updating `attribution_properties` in MySQL, or wait for the calendar day to roll over (the count resets daily)

### BigQuery Query Failures

- **Symptoms**: HTTP 500 responses; `BigQueryService.executeQuery.BigQueryException` events in Kibana logs
- **Cause**: BigQuery service unavailability, query timeout, invalid credentials, or dataset permission issues
- **Resolution**: Check GCP console for BigQuery job status in project `prj-grp-dataview-prod-1ff9`; verify the service-account key has not expired

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service completely down | Immediate | gpn-alerts@groupon.com (triggers PagerDuty PP9FGY1) |
| P2 | Attribution data degraded or slow | 30 min | gpn-alerts@groupon.com |
| P3 | Minor impact (e.g., elevated latency, single-region) | Next business day | gpn-dev@groupon.com |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| Google BigQuery | Execute a test query against `prj-grp-dataview-prod-1ff9`; check GCP console | No fallback — requests fail with HTTP 500 |
| MySQL (`continuumGpnDataApiMySql`) | JTier connection pool health; check Kibana for JDBC errors | No fallback — all requests fail if MySQL is unreachable (limit check is mandatory) |

### Kibana Log Indices

| Environment | Kibana URL | Index Pattern |
|-------------|-----------|---------------|
| Staging | https://stable-kibana-unified.us-central1.logging.stable.gcp.groupondev.com/ | `filebeat-gpn-data-api_api--*` |
| Production US | https://prod-kibana-unified.us-central1.logging.prod.gcp.groupondev.com/ | `filebeat-gpn-data-api_api--*` |
| Production INT/EU | https://prod-kibana-unified-eu.logging.prod.gcp.groupondev.com/ | `filebeat-gpn-data-api_api--*` |
