---
service: "taxonomyV2"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `GET /grpn/status` (admin port 8081) | HTTP | Kubernetes liveness/readiness probe | Per k8s probe config |
| Dropwizard health check — Postgres | In-process | At startup and via admin port | — |
| Dropwizard health check — Redis | In-process | At startup and via admin port | — |

> The `status_endpoint` is marked `disabled: true` in `.service.yml` pending v4 schema support.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| HTTP request rate | Counter | Requests per minute across all endpoints | Alert on drop below 70K rpm sustained |
| HTTP error rate | Counter | 4xx/5xx responses | Alert on elevated 5xx rate |
| JVM heap utilization | Gauge | JVM heap used vs. allocated (70% of container memory) | Alert on sustained > 90% |
| Redis cache hit rate | Gauge | Ratio of Redis cache hits to total category lookups | Alert on significant drop |
| Message bus consumer lag | Gauge | Processing delay on `jms.topic.taxonomyV2.cache.invalidate` | Alert on lag > threshold |
| Snapshot activation latency | Histogram | Time from `PUT /snapshots/activate` to cache rebuild completion | Alert on p99 > 10s |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Taxonomy App Metrics | Grafana | https://prod-grafana.us-central1.logging.prod.gcp.groupondev.com/d/ae7pzovd5kr9cc/coreapps-app-metrics?orgId=1&var-service=taxonomyv2 |
| JVM Metrics | Grafana | https://prod-grafana.us-central1.logging.prod.gcp.groupondev.com/d/fe7qcxu6ruvwgf/coreapps-jvm-metrics?orgId=1&var-service=taxonomyv2 |
| Conveyor Cloud Customer Metrics | Grafana | https://prod-grafana.us-central1.logging.prod.gcp.groupondev.com/d/fe7dii805648wc/conveyor-cloud-customer-metrics?orgId=1&var-namespace=taxonomyv2-production |
| Redis (us-central1, GCP) | Grafana | https://prod-grafana.us-central1.logging.prod.gcp.groupondev.com/d/bea2rbflxq4u8d/redis-nodes?orgId=1&var-project=prj-grp-caches-prod-8a6d&var-cluster_id=projects/prj-grp-caches-prod-8a6d/locations/us-central1/instances/taxonomyv2 |
| Redis (eu-west-1, AWS) | Grafana | https://prod-grafana.us-central1.logging.prod.gcp.groupondev.com/d/eeanjgkyfcfeob/redis-clusters-aws?orgId=1&var-server=taxonomyv2-prod |
| MessageBus — cache.invalidate | Grafana | https://prod-grafana.us-central1.logging.prod.gcp.groupondev.com/d/ee504tdtmpbeoa/messagebus-cloud-dashboard?orgId=1&var-address=jms.topic.taxonomyV2.cache.invalidate |
| MessageBus — content.update | Grafana | https://prod-grafana.us-central1.logging.prod.gcp.groupondev.com/d/ee504tdtmpbeoa/messagebus-cloud-dashboard?orgId=1&var-address=jms.topic.taxonomyV2.content.update |
| Wavefront — taxonomy SMA | Wavefront | https://groupon.wavefront.com/dashboards/taxonomyv2--sma |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| High error rate | Elevated 5xx responses on any endpoint | Critical | Check ELK logs; verify Postgres and Redis connectivity; check snapshot activation in flight |
| Redis unavailable | Redis health check failing | Critical | Page RaaS team (`raas-team@groupon.com`); service falls back to Postgres reads |
| Cache rebuild failure | Notification from `NotificationService` (Slack + email) | Warning | Check Slack #taxonomy channel; manually re-trigger snapshot activation if safe |
| Snapshot activation stuck | `PUT /snapshots/activate` p99 > 10s sustained | Warning | Check Redis cache build logs; check message bus consumer lag; restart service if deadlocked |
| OOM kill | Container killed with OOM | Critical | Review `MALLOC_ARENA_MAX` setting; check `MAX_RAM_PERCENTAGE`; scale replicas up |

Taxonomy alerts: https://prod-grafana.us-central1.logging.prod.gcp.groupondev.com/alerting/list?search=taxonomy

## Common Operations

### Restart Service

Restart is performed via Deploybot by re-deploying the current image version:
1. Navigate to https://deploybot.groupondev.com/hawk/taxonomyV2
2. Select the current deployment for the target environment
3. Use the "retry" or re-deploy action to restart pods
4. Monitor pod readiness via Kubernetes or Conveyor Cloud Metrics dashboard

Alternatively, scale the deployment to 0 and back to `minReplicas` via Kubernetes if direct cluster access is available.

### Scale Up / Down

1. Edit the relevant environment YAML in `.meta/deployment/cloud/components/app/<env>.yml` — increase or decrease `maxReplicas`
2. Merge to master to trigger a CI build, then promote via Deploybot to the target environment
3. HPA will automatically scale pods up to the new maximum under load

For emergency capacity increase, update `maxReplicas` directly and redeploy the same image tag.

### Database Operations

- Schema migrations are applied automatically on service startup via `jtier-migrations`
- Direct Postgres access requires DaaS credentials; contact the taxonomy team for production credentials
- Production read/write host (US): `taxonomyV2-rw-na-production-db.gds.prod.gcp.groupondev.com`
- Production read-only host (EMEA): `taxonomyv2-ro-emea-production-db.gds.prod.gcp.groupondev.com`
- Staging read/write host (US-Central1): `taxonomyv2-rw-na-staging-db.gds.stable.gcp.groupondev.com`

## Troubleshooting

### High Latency on Flat Hierarchy Endpoint

- **Symptoms**: `GET /taxonomies/{guid}/flat` without `If-Modified-Since` header taking > 10s (p99 expected is 10,000ms)
- **Cause**: This endpoint returns the full category tree and is intentionally slow without a conditional header; the `If-Modified-Since` header enables a fast cache-timestamp check (p99: 20ms)
- **Resolution**: Ensure consumers send the `If-Modified-Since` header; if latency is above even the expected 10s, check Redis cache health and Postgres read load

### Cache Not Updating After Snapshot Activation

- **Symptoms**: Old taxonomy data served after `PUT /snapshots/activate` returns 200; consumers see stale categories
- **Cause**: Redis cache rebuild may have failed or the JMS message bus message was not processed
- **Resolution**: Check Slack #taxonomy channel for failure notification; check message bus consumer lag on `jms.topic.taxonomyV2.cache.invalidate`; re-trigger snapshot activation if safe; verify Redis connectivity

### Redis Unavailable

- **Symptoms**: High error rates; health check failing for Redis; service falls back to Postgres (high DB load)
- **Cause**: RaaS Redis cluster outage or network issue
- **Resolution**: Check [Redis GCP dashboard](https://prod-grafana.us-central1.logging.prod.gcp.groupondev.com/d/bea2rbflxq4u8d/redis-nodes); contact RaaS team at `raas-team@groupon.com`; for emergency page SOC to escalate to RaaS on-call

### OOM Container Kills

- **Symptoms**: Pods being killed with OOM errors; eviction events in Kubernetes
- **Cause**: JVM heap or off-heap memory exceeding container limits; common during large cache rebuilds
- **Resolution**: Verify `MALLOC_ARENA_MAX: 4` is set; check if `MAX_RAM_PERCENTAGE: 70.0` is appropriate; consider increasing memory limits via `.meta/deployment/cloud/components/app/<env>.yml` and redeploying

### Varnish Cache Not Invalidated

- **Symptoms**: Downstream consumers served stale taxonomy data from Varnish despite Redis being updated
- **Cause**: Varnish BAN request failed during snapshot activation
- **Resolution**: Check `VarnishClient` logs for HTTP BAN failures; manually trigger Varnish invalidation if possible; check `VarnishValidationClient` logs for Jenkins validation job status

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down / 5xx on all endpoints | Immediate | taxonomy-dev@groupon.pagerduty.com (PD: PVUUEHR) |
| P2 | Degraded — cache rebuild failing / elevated latency | 30 min | taxonomy-dev@groupon.com + Slack #taxonomy |
| P3 | Minor impact — Varnish validation failure / notification failure | Next business day | taxonomy-dev@groupon.com |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| PostgreSQL DaaS | Dropwizard health check at admin port 8081; verify connectivity to `taxonomyV2-rw-na-production-db.gds.prod.gcp.groupondev.com` | No automatic fallback — Postgres is the authoritative store |
| Redis RaaS | Dropwizard health check at admin port 8081; check Grafana Redis dashboards | Service can serve some requests by falling back to Postgres; cache miss rate spikes |
| JMS Message Bus | Consumer lag metrics on Grafana MessageBus dashboard | Cache invalidation stalls; stale data served from Redis until manual re-activation |
| Varnish Edge Cache | Varnish Validation Service Jenkins jobs; check HTTP BAN response codes | Stale data served at edge; consumers still get correct data from Redis-backed API |
| SMTP / Slack | Non-critical; monitor notification delivery | Deployments continue; operators lose visibility into automated notifications |
