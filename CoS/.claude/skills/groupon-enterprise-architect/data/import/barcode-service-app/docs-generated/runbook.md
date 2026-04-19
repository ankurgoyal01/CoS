---
service: "barcode-service-app"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `/grpn/status` (port 8080) | HTTP | Kubernetes default | Kubernetes default |
| Dropwizard healthcheck (`BarcodeServiceHealthCheck`) | HTTP (admin port 8081) | On demand | — |

The `.service.yml` `status_endpoint` is explicitly disabled (`disabled: true`) for the environment poller — operational health is monitored via Wavefront dashboards and Kibana logs.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| HTTP request rate | counter | Requests per second to all barcode endpoints | Monitor via Wavefront SMA dashboard |
| HTTP error rate | gauge | 4xx and 5xx response rate | Alert if > 0.1% (per README SLA) |
| HTTP latency TP99 | histogram | 99th percentile response time | SLA: 130ms TP99 |
| JVM heap usage | gauge | JVM heap consumption | Monitor for memory leaks / OOM |
| Pod restart count | counter | Kubernetes pod restart count | Investigate on any unexpected restarts |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Barcode Service SMA | Wavefront | `https://groupon.wavefront.com/dashboards/barcode-service--sma` |
| Citydeals Barcode App | Wavefront | `https://groupon.wavefront.com/dashboards/Citydeals-barcode-app-dashboard` |
| Custom dashboard | Wavefront | `https://groupon.wavefront.com/u/pB2YXm7P7J?t=groupon` |
| Staging logs (24h) | Kibana | `https://logging-stable-unified01.grpn-logging-stable.us-west-2.aws.groupondev.com/goto/6a75cbdbc51cd34c510a14c375492beb` |
| Production US logs (24h) | Kibana | `https://logging-us.groupondev.com/goto/6a75cbdbc51cd34c510a14c375492beb` |
| Production US 4xx errors | Kibana | `https://logging-us.groupondev.com/goto/432ea3b00e262cdaf90d2ef447bba6b2` |
| Production US 5xx errors | Kibana | `https://logging-us.groupondev.com/goto/c0e815b186974b279dfa49f12e52d6de` |
| Production EU 4xx errors | Kibana | `https://logging-eu.groupondev.com/goto/a661f69922e5e2cbdf85255018b0e478` |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| High error rate | HTTP error rate > 0.1% | P2 | Check Kibana for 4xx/5xx logs; inspect request parameters |
| High latency | TP99 > 200ms | P2 | Check pod count and HPA; check JVM GC pressure |
| Pod crash loop | Repeated pod restarts | P1 | Run `kubectl logs <pod> -c main`; check OOM events |
| Service unavailable | All pods unready | P1 | Check Kubernetes events; verify image pull and config mount |

PagerDuty service: `https://groupon.pagerduty.com/services/PA0PFWK`

## Common Operations

### Restart Service

```bash
# Get current pods
kubectl get pods -n barcode-service-production  # or barcode-service-staging

# Roll restart (zero-downtime)
kubectl rollout restart deployment/barcode-service--app--default -n barcode-service-production

# Check rollout status
kubectl rollout status deployment/barcode-service--app--default -n barcode-service-production
```

Kubernetes contexts:
- Production EMEA: `barcode-service-production-eu-west-1`
- Production US: `barcode-service-production-us-west-1`
- Staging US: `barcode-service-staging-us-west-1`
- Staging EMEA: `barcode-service-staging-us-west-2`

### Scale Up / Down

Change `minReplicas` / `maxReplicas` in the appropriate environment YAML file under `.meta/deployment/cloud/components/app/` and redeploy. For immediate scaling:

```bash
kubectl scale deployment/barcode-service--app--default --replicas=<N> -n barcode-service-production
```

Production configuration allows up to 15 replicas (`maxReplicas: 15`). Expected max capacity is 1000 RPS.

### Check Logs for a Specific Pod

```bash
# Get pod name
kubectl get pods -n barcode-service-production

# Stream logs from the main container
kubectl logs <pod_name> -c main -n barcode-service-production

# Get inside a pod for debugging
kubectl exec -it <pod_name> -c main -- bash -n barcode-service-production

# Check memory usage
kubectl top pod <pod_name> --containers -n barcode-service-production
```

### Database Operations

> Not applicable — Barcode Service has no database.

## Troubleshooting

### Increased 4xx Error Rate

- **Symptoms**: Wavefront SMA dashboard shows elevated 4xx response counts; Kibana shows error log entries
- **Cause**: Invalid barcode parameters passed by the caller — unsupported `codeType`, malformed `payload` for the given `payloadType`, or out-of-bounds dimensions
- **Resolution**: In Kibana, filter by `data.status` field and inspect input parameters for the affected request IDs. Verify the caller is passing valid `codeType` values (see [API Surface](api-surface.md)) and correctly encoding the payload.

### Increased 5xx Error Rate

- **Symptoms**: Wavefront SMA dashboard shows 5xx responses; pod restart count increasing in Kubernetes
- **Cause**: Service-level failure — OOM kill, JVM crash, or pod startup failure
- **Resolution**: Check pod health with `kubectl get pods`; check pod restart count. If OOM: verify `MALLOC_ARENA_MAX` is set to 4 and memory limits are correct in deployment YAML. Review `kubectl logs <pod> -c main` for exception stack traces.

### Service Appears Unresponsive

- **Symptoms**: No 200 responses observed in Wavefront live traffic view; timeout errors from callers
- **Cause**: All pods unready, image pull failure, or config mount error
- **Resolution**: Check `kubectl get pods` for pod status. Use `kubectl describe pod <pod_name>` for events. Check that the Docker image `docker-conveyor.groupondev.com/redemption/barcode-service` is accessible and the `JTIER_RUN_CONFIG` env var points to a valid mounted config file.

### Pod Memory OOM

- **Symptoms**: Pods repeatedly terminated with OOM reason; Wavefront shows pod restarts
- **Cause**: JVM heap or off-heap memory exceeding the 500Mi container limit
- **Resolution**: Confirm `MALLOC_ARENA_MAX: 4` is applied (prevents glibc arena explosion). Consider reducing `maxReplicas` to spread load, or temporarily increase memory limit in common.yml and redeploy.

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down — barcodes not generating for any request | Immediate | Redemption team on-call via barcode-service@groupon.pagerduty.com |
| P2 | Degraded — elevated error rate or high latency | 30 min | Redemption team (shawshank@groupon.com) |
| P3 | Minor impact — isolated errors for specific code types | Next business day | Redemption team Slack: #post-purchase-notification |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `tsd_aggregator` | Not applicable — metrics are fire-and-forget | Metric loss only; barcode generation continues unaffected |
| Kubernetes cluster | `kubectl get nodes` | No fallback — service requires cluster to be healthy |
