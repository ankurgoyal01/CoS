---
service: "map_proxy"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `GET /heartbeat` | HTTP | 10s (readiness), 30s (liveness) | Default Kubernetes timeout |
| `GET /status` | HTTP (alias for /heartbeat) | On demand | — |

The heartbeat endpoints return HTTP 200 if the file at `MapProxy.heartbeatFile` (default: `/usr/local/mapproxy_service/heartbeat.txt`) exists on the container filesystem, and HTTP 404 otherwise.

**Staging health check command:**
```
curl -I https://edge-proxy--staging--public.stable.us-west-1.aws.groupondev.com/heartbeat \
  --header "Host: map-proxy--public.staging.service"
```
Expected: `HTTP/1.1 200 OK`

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| Request rate (RPM) | gauge | Requests per minute for all map endpoints | Min RPM alert at Wavefront |
| Static maps 5xx rate | counter | HTTP 5xx responses on static map endpoints | Wavefront alert ID 1626194096515 |
| Dynamic maps 5xx rate | counter | HTTP 5xx responses on dynamic map endpoints | Wavefront alert ID 1626193930315 |
| Static maps P99 latency | histogram | 99th percentile response time for static map requests | 50ms threshold; alert ID 1626186226832 |
| Dynamic maps P99 latency | histogram | 99th percentile response time for dynamic map requests | 50ms threshold; alert ID 1626186819853 |

Metrics are emitted via the Conveyor Cloud platform and visible in Wavefront.

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| MapProxy application metrics | Wavefront | https://groupon.wavefront.com/dashboards/mapproxy |
| Conveyor Cloud pod/container metrics | Wavefront | https://groupon.wavefront.com/dashboards/Conveyor-Cloud-Customer-Metrics |
| Pre-prod mapproxy logs | Kibana | https://logging-preprod.groupondev.com/goto/4bb8bd9187ba0aac175fdcf18f7159d7 |
| Prod NA mapproxy logs | Kibana | https://logging-us.groupondev.com/goto/145c599a9790ae904056d2e81b065d7c |
| Prod EU mapproxy logs | Kibana | https://logging-eu.groupondev.com/goto/cad20084321a94cb038b3500f346691c |

**Kibana log filter for application logs (cloud):**
- Source: `us-*:filebeat-mapproxy--*`
- Filters: `groupon.fabric:conveyor-cloud` AND `data.controller is one of StaticMapsServlet, DynamicMapsServlet`

**Kibana log filter for edge-proxy access logs:**
- Index: `edge-proxy-access-json`
- Filter: `authority:map-proxy.production.service`

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Min RPM Alert | Request rate drops below minimum threshold | warning | Send a few test curl requests to check if the service is serving. Investigate low-traffic root cause and triage with upstream consumers. |
| Max RPM Alert | Request rate exceeds maximum threshold | warning | Investigate reason for spike and triage with upstream consumers. |
| Static maps 5xx Error Rate | 5xx rate on `/maps/api/staticmap` or `/api/v2/static` exceeds threshold | critical | Send test curl request; if failing, redeploy the most recent deployment via DeployBot. |
| Dynamic maps 5xx Error Rate | 5xx rate on `/maps/api/js` or `/api/v2/dynamic` exceeds threshold | critical | Send test curl request; if failing, redeploy via DeployBot. |
| Static maps P99 Latency | P99 latency for static map requests exceeds 50ms | warning | Check all slow static map requests in Wavefront. Alert should auto-resolve; if not, redeploy via DeployBot. |
| Dynamic maps P99 Latency | P99 latency for dynamic map requests exceeds 50ms | warning | Check all slow dynamic map requests in Wavefront. Alert should auto-resolve; if not, redeploy via DeployBot. |

**PagerDuty**: https://groupon.pagerduty.com/service-directory/P7FZQE4
**Alert slack channel**: CF9BSHL1M

## Common Operations

### Restart Service

Kubernetes (cloud):
```
kubectl config use-context map-proxy-production-us-central1
kubectl rollout restart deployment/map-proxy--app--default -n map-proxy-production
```

Verify recovery:
```
kubectl get pods -n map-proxy-production
kubectl logs <pod-name> main -n map-proxy-production
```

### Kubernetes Access

Request access via: `https://arq.groupondev.com/ra/ad_subservices/map_proxy` — select all 3 Conveyor Cloud groups.

```
# Authenticate
kubectl cloud-elevator auth

# Switch to production EU context
kubectl config use-context map-proxy-production-eu-west-1

# Verify namespace write access
kubectl auth can-i create deployments -n map-proxy-production

# View pods
kubectl get pods -n map-proxy-production

# Stream logs
kubectl logs <pod-name> main -n map-proxy-production

# Exec into a pod
kubectl exec -it <pod-name> --container main -- /bin/bash
```

### Scale Up / Down

Scaling is managed via DeployBot and Kubernetes HPA. To manually override replica count:
```
kubectl scale deployment/map-proxy--app--default --replicas=<n> -n map-proxy-production
```

Persistent scaling changes must be made in `.meta/deployment/cloud/components/app/*.yml` and deployed.

### Database Operations

> Not applicable. MapProxy is stateless with no database.

## Troubleshooting

### Static map requests returning 500

- **Symptoms**: Callers receive HTTP 500; Kibana shows `InvalidKeyException` or `URISyntaxException` log entries in `StaticMapsServlet`.
- **Cause**: The HMAC signing key configured in `MapProxy.google.signingKey` is invalid or the request URI could not be parsed.
- **Resolution**: Verify the signing key is correctly set in the Kubernetes secret / config file. Redeploy if a bad config was recently rolled out. Test signing with: `curl -I "https://edge-proxy--staging--public.stable.us-west-1.aws.groupondev.com/maps/api/staticmap?..."`.

### Dynamic map JS not loading

- **Symptoms**: Browser console shows network error for `/api/v2/dynamic`; Kibana shows `[DynamicV2] File not found:` log entries.
- **Cause**: The provider JavaScript template or library file is missing from the classpath (packaging issue).
- **Resolution**: Verify the JAR was built correctly (`mvn clean assembly:assembly`). Check that `/js-templates/{provider}.js` and `/js-libraries/{provider}.js` are present in the JAR. Redeploy.

### Heartbeat returning 404

- **Symptoms**: Kubernetes liveness/readiness probe fails; pods are being restarted by Kubernetes; `GET /heartbeat` returns HTTP 404.
- **Cause**: The heartbeat file at `MapProxy.heartbeatFile` does not exist on the container filesystem.
- **Resolution**: The heartbeat file should be created by the deployment process at the path configured in `MapProxy.heartbeatFile` (configured as `/usr/local/mapproxy_service/heartbeat.txt` in `common.yml`). Verify the `heartbeatPath` in `common.yml` matches the property in the config file. Re-deploy if misconfigured.

### Wrong provider being selected

- **Symptoms**: Users in a Yandex-supported country see Google maps (or vice versa).
- **Cause**: The `country` query parameter is absent or incorrect; the `X-Country` header is not being forwarded by the upstream proxy; the Referer TLD parsing is wrong; or the `MapProxy.yandex.countryList` config is incorrect.
- **Resolution**: Inspect request logs in Kibana for the `country=`, `provider=` fields in the log message. Verify `MapProxy.yandex.countryList` contains the expected ISO codes. Check that the upstream service or ITA is setting the `X-Country` header correctly.

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down — no maps served across all platforms | Immediate | Geo Services on-call (geo-alerts@groupon.com), PagerDuty P7FZQE4 |
| P2 | Degraded — partial map failures (one region or one endpoint type) | 30 min | Geo Services on-call |
| P3 | Minor — elevated latency or isolated errors | Next business day | Geo Services team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| Google Maps Static API | Test curl of `/maps/api/staticmap` and verify HTTP 302 redirect to `maps.googleapis.com` | No in-process fallback; caller receives provider error |
| Google Maps JavaScript API | Test curl of `/maps/api/js` and verify HTTP 302 redirect to Google JS loader | No in-process fallback |
| Yandex Static Maps API | Test curl of `/api/v2/static?country=RU&...` and verify HTTP 302 redirect to Yandex | No in-process fallback |
| Kubernetes heartbeat file | `GET /heartbeat` returns HTTP 200 | Pod is restarted by Kubernetes if liveness probe fails |
