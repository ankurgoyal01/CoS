---
service: "img-service-primer"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `GET /grpn/healthcheck` (port 8080) | http | 30 seconds | Default JTier timeout |
| Liveness probe: `GET /grpn/healthcheck` | http | 30 seconds (delay: 180s) | Default |
| Readiness probe: `GET /grpn/healthcheck` | http | 30 seconds (delay: 180s) | Default |
| Video-transformer cron readiness | exec (`/bin/true`) | 5 seconds (delay: 1s, timeout: 5s) | 5 seconds |

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| Outgoing HTTP request rate by service | counter | Requests/minute to deal-catalog, GIMS, Akamai | High-water-mark alert: `primer_high-water-mark` |
| Outgoing HTTP error rate | counter | Non-200 responses from downstream dependencies | `primer_execution_stats` — triggers if too many failed HTTP calls |
| Priming execution completion | counter | Successful daily cron runs per datacenter | `primer_execution_stats` — triggers if no execution in past 24 hours |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| gims-primer application metrics | Wavefront | https://groupon.wavefront.com/dashboard/gims-primer |
| gims-primer SMA metrics | Wavefront | https://groupon.wavefront.com/dashboards/gims-primer--sma |
| gims-primer Conveyor cloud application metrics | Wavefront | https://groupon.wavefront.com/dashboards/Conveyor-Cloud-Application-Metrics |
| gims-primer system metrics | Wavefront | https://groupon.wavefront.com/dashboards/Conveyor-Cloud-Customer-Metrics |
| gims-primer STAGING US-CENTRAL1 logs | Kibana | https://stable-kibana-unified.us-central1.logging.stable.gcp.groupondev.com/app/r/s/4LIWQ |
| gims-primer PROD US-CENTRAL1 logs | Kibana | https://prod-kibana-unified.us-central1.logging.prod.gcp.groupondev.com/app/r/s/G5wbG |
| gims-primer PROD EU-WEST-1 logs | Kibana | https://logging-prod-eu-unified1.grpn-logging-prod.eu-west-1.aws.groupondev.com/goto/217574d99a4786bee92b6d765f4830ea |

**Splunk log source**: `index=misc sourcetype=image_service_primer`

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| `primer_high-water-mark` | Too many requests/minute to upstream services | Severity 4 | Stop and restart the service via `kubectl rollout restart deployment`; check Splunk for request volume and duration |
| `primer_execution_stats` | Failed to execute at least once in past 24 hours, or too many failed HTTP calls | Severity 5 | Check Splunk and dashboards; review recent deployments |
| Akamai 5XX errors count | Outgoing calls to `img.grouponcdn.com` return 500 | — | Invoke a few requests manually; if persistent, report to info-sec team |
| Deal catalog 5XX errors count | Outgoing calls to deal-catalog `searchDeals` or `getDeal` fail with 500 | — | Check ELK; report to deal-catalog team |
| `deal-catalog searchDeals` endpoint latency | p99 latency of deal-catalog calls increased | — | Report to deal-catalog team |
| `getDeal` p99 latency alert | p99 latency of getDeal calls increased | — | Report to deal-catalog team |
| `akamai getImage` p99 alert | p99 latency of Akamai image fetch increased | — | Report to info-sec team |
| cron not ran for eu-west-1/us-west-1 | No cron execution detected in ELK | — | Invoke cron manually: `POST /v1/preload/cron/immediately` |

## Common Operations

### Restart Service (Kubernetes)

```sh
kubectl cloud-elevator auth
kubectl config use-context gims-primer-production-us-central1
kubectl rollout restart deployment <deployment-name>
```

Verify status:
```sh
kubectl get pods
kubectl logs <pod-name> main
```

### Manually Trigger Daily Priming

```sh
curl -X POST http://gims-primer-vip.snc1/v1/preload/cron/immediately
```

### Prime a Specific Deal

```sh
curl -X POST http://gims-primer-vip.snc1/v1/preload/deal/{dealUuid}
```

### Prime Deals for a Country

```sh
curl -X POST http://gims-primer-vip.snc1/v1/preload/country/{cc}
```

### Scale Up / Down

```sh
kubectl scale --replicas=<n> deployment <deployment-name>
```

### Database Operations

The `continuumImageServicePrimerDb` MySQL database holds video transformation state. Schema migrations are managed by `jtier-quartz-mysql-migrations` (version 0.1.4). No manual migration steps documented; migrations run at application startup via the JTier lifecycle.

### Reduce Load on Downstream Services

Edit the JTier config file at `/var/groupon/jtier/current/config/${DATACENTER}/production.yml` and set:

```yaml
defaultConfiguration:
  hitAkamai: false
  hitProcessedImages: false
rxConfig:
  schedulers:
    imageService:
      threadCount: 1
    dealCatalog:
      threadCount: 1
```

Then restart: `kubectl rollout restart deployment <deployment-name>`

### Updating Transformation Codes

Run the following Splunk query over a 7-day window to identify the current top transformation codes:

```
(index=main OR index=misc) sourcetype=image_service_app processingTime>0
  | rex field=url "/v1/(?<code>.*?(.(?<format>jpg|png|bmp|gif|tiff|pdf))?)([?].*)?$"
  | stats count by code
  | sort - count
```

Take the top N (100 recommended) and update the `imageTransforms` configuration property, then release a new version.

## Troubleshooting

### Downstream Services Overloaded
- **Symptoms**: High latency or 5XX errors in outgoing requests to deal-catalog or GIMS; `primer_high-water-mark` alert fires
- **Cause**: Primer is issuing too many concurrent requests to upstream services
- **Resolution**: Set `defaultConfiguration.hitAkamai=false` / `defaultConfiguration.hitProcessedImages=false` and reduce scheduler thread counts to 1; restart the application

### No Deals Match or No Images Fetched
- **Symptoms**: Priming cron runs but reports zero deals processed
- **Cause**: No deals are scheduled within the current 24-hour distribution window — this is expected behavior
- **Resolution**: Verify via Splunk: `index=misc sourcetype=image_service_primer name=trace data.name=log-done data.args.triggeredVia=CRON` — check that `data.args.deal.success > 0` and all `data.args.*.failure == 0`

### Application OOM
- **Symptoms**: Container killed with OOM; pod restarts
- **Cause**: More than ~10k deals with images in a single run; known capacity ceiling
- **Resolution**: Restart the application; occurrence during non-holiday periods is unexpected. Ensure `MALLOC_ARENA_MAX=4` is set.

### Connectivity Issues
- **Symptoms**: Steno log shows connectivity errors to deal-catalog or GIMS
- **Cause**: Network issue or downstream service outage
- **Resolution**: Check with production operations; verify connections manually from the pod; restart the application if connections succeed

### Cron Did Not Run
- **Symptoms**: No `log-done` entries in Splunk for a datacenter within the past 24 hours
- **Cause**: Application crash, deployment failure, or resource exhaustion
- **Resolution**: Manually invoke via `POST /v1/preload/cron/immediately`; check Kibana logs for errors; check pod health in Kubernetes

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down — no daily priming occurring | Immediate | Global Image Service team (PagerDuty PWFOW4O) |
| P2 | Degraded — priming running but with high failure rate | 30 min | Global Image Service team |
| P3 | Minor impact — individual deal or country not primed | Next business day | Global Image Service team |

**PagerDuty**: https://groupon.pagerduty.com/service-directory/PWFOW4O
**Slack**: #CFJ5NRS68 (image-service-ist)
**Email**: imageservice@groupon.com

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `deal-catalog` | Check ELK for 5XX on searchDeals / getDeal; check service portal | Reduce `dealCatalog.threadCount=1` or skip priming run |
| `gims` | Check ELK for 5XX on image preload requests; check GIMS service portal | Set `hitLocalCaches=false`; reduce `imageService.threadCount=1` |
| `akamai` | Check ELK for 5XX on `img.grouponcdn.com` | Set `hitAkamai=false` in config |
| MySQL (`continuumImageServicePrimerDb`) | Check pod logs for JDBI connection errors | No fallback — video transformation pipeline is unavailable |
