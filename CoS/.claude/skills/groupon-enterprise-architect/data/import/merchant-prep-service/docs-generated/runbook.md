---
service: "merchant-prep-service"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `GET /merchant-self-prep/health?invoker=service-portal` on port 8080 | http | Kubernetes liveness/readiness default | Kubernetes default |
| `GET /admin` on port 8081 | http (Dropwizard admin) | — | — |

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| Outgoing request 5xx error rate (US) | gauge | Error rate for outbound downstream calls in the US region | > 2% |
| Outgoing request 5xx error rate (EU) | gauge | Error rate for outbound downstream calls in the EU region | > 2% |
| Incoming request 5xx error rate (US) | gauge | Error rate for inbound API requests in the US region | > 2% |
| Incoming request 5xx error rate (EU) | gauge | Error rate for inbound API requests in the EU region | > 2% |
| Incoming request latency (US) | histogram | p99 latency for incoming requests in the US region | > 30 ms |
| Incoming request latency (EU) | histogram | p99 latency for incoming requests in the EU region | > 30 ms |
| Pod restart count (US) | counter | Number of pod restarts in US production | > 5 |
| Pod restart count (EU) | counter | Number of pod restarts in EU production | > 5 |
| Pod not running count (US) | gauge | Number of production pods not in Running state (US) | > 2 |
| Pod not running count (EU) | gauge | Number of production pods not in Running state (EU) | > 2 |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Merchant Preparation SMA (US) | Wavefront | https://groupon.wavefront.com/dashboards/mx-merchant-preparation--sma |
| Merchant Preparation US (sac1/snc1) | Wavefront | https://groupon.wavefront.com/dashboard/sac1_snc1-merchantpreparation-usa |
| Merchant Preparation EMEA (dub1) | Wavefront | https://groupon.wavefront.com/dashboard/dub1-merchantpreparation-emea |
| Merchant Preparation US (snc1) | Wavefront | https://groupon.wavefront.com/dashboard/snc1-merchantpreparation-usa |
| ELK Logs | ELK (Kibana) | https://logging-prod-us-unified1.grpn-logging-prod.us-west-2.aws.groupondev.com/goto/bcfe20039a1a07ab8b160e507f725f98 |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| MX Merchant Preparation Outgoing 5xx US | Outgoing error rate > 2% in US region | warning | Check which downstream SF endpoint is failing; contact owning team |
| MX Merchant Preparation Outgoing 5xx EU | Outgoing error rate > 2% in EU region | warning | Check which downstream SF endpoint is failing; contact owning team |
| MX Merchant Preparation Incoming 5xx US | Incoming error rate > 2% in US region | warning | Check ELK logs for exception details; contact dev team |
| MX Merchant Preparation Incoming 5xx EU | Incoming error rate > 2% in EU region | warning | Check ELK logs for exception details; contact dev team |
| MX Merchant Preparation Latency US | Incoming p99 latency > 30 ms in US | warning | Check downstream DaaS latency; escalate if DB-related |
| MX Merchant Preparation Latency EU | Incoming p99 latency > 30 ms in EU | warning | Check downstream DaaS latency; escalate if DB-related |
| MX Merchant Preparation Pod Restart US | Pod restarts > 5 in US | critical | Check Wavefront for restart cause; contact dev/cloud team |
| MX Merchant Preparation Pod Restart EU | Pod restarts > 5 in EU | critical | Check Wavefront for restart cause; contact dev/cloud team |
| MX Merchant Preparation Pod Not Running US | Pods not running > 2 in US | critical | Check Wavefront; contact dev/cloud team |
| MX Merchant Preparation Pod Not Running EU | Pods not running > 2 in EU | critical | Check Wavefront; contact dev/cloud team |

- **PagerDuty**: https://groupon.pagerduty.com/services/PV2ZOZL
- **Alert email**: bmx-alert@groupon.com
- **Slack channel**: `global-merchant-exper`

## Common Operations

### Restart Service

```sh
# Restart the default deployment (replaces pods rolling)
kubectl rollout restart deploy mx-merchant-preparation--app--default

# Scale to 0 and back to restore pods completely
kubectl scale --replicas 0 deployment.apps/mx-merchant-preparation--app--default
kubectl scale --replicas 5 deployment.apps/mx-merchant-preparation--app--default
```

### Scale Up / Down

```sh
# View current pods
kubectl get pods

# Scale manually (HPA must be paused or target adjusted first)
kubectl scale --replicas <N> deployment.apps/mx-merchant-preparation--app--default
```

### Database Operations

- Schema migrations are run automatically at service startup via Flyway (`jtier-migrations` bundle).
- Local database initialization: `.init/init.sql` creates the `merchant_self_prep` schema and sets the default search path.
- To connect to the production database use DaaS tooling with the `daas_postgres` dependency credentials.

### Port-Forwarding for Debug

```sh
# Forward production pod for local API testing
kubectl port-forward <pod_name> 8080:8080

# Log into a pod shell
kubectl -n mx-merchant-preparation-production-sox exec -it pod/<pod_name> -c main -- /bin/sh
```

## Troubleshooting

### High 5xx Incoming Error Rate

- **Symptoms**: Alert fires; ELK logs show exception stack traces; Wavefront incoming request error counter elevated.
- **Cause**: Application bug, misconfiguration, or downstream dependency failure cascading to request handling.
- **Resolution**: Identify the failing endpoint from Wavefront; check ELK logs for root cause; if a single pod is affected, delete it (`kubectl delete pod <pod_name>`) and Kubernetes will recreate it; if all pods are affected, check downstream dependency status and escalate.

### High Latency Alert

- **Symptoms**: Latency alert fires; Wavefront shows elevated p99 on specific endpoints.
- **Cause**: Downstream DaaS PostgreSQL latency spike, or Salesforce API slowdown.
- **Resolution**: Check the Wavefront SMA dashboard for outgoing request latency by destination; if DB-related, contact the DaaS team; if Salesforce-related, contact the SF integration team.

### Pod Restart / OOM Kills

- **Symptoms**: Pod restart alert; `kubectl describe pod` shows OOM kill or crash loop backoff.
- **Cause**: Memory leak, heap exhaustion, or `MALLOC_ARENA_MAX` misconfiguration.
- **Resolution**: Inspect pod events with `kubectl describe pod <pod_name>`; check JVM heap usage in Wavefront; consider reducing `MAX_RAM_PERCENTAGE` or increasing memory limits; contact dev/cloud team.

### Salesforce Integration Errors

- **Symptoms**: Outgoing 5xx alert fires; ELK logs show Salesforce API errors; merchants cannot update prep data.
- **Cause**: Salesforce API downtime, OAuth token expiry, or field-level permission issues.
- **Resolution**: Verify Salesforce service status; check OAuth token rotation; contact the Salesforce integration team.

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down — merchants cannot complete prep | Immediate | Merchant Experience team (MerchantCenter-BLR@groupon.com); PagerDuty PV2ZOZL |
| P2 | Degraded — specific endpoints or regions failing | 30 min | Merchant Experience team; Slack `global-merchant-exper` |
| P3 | Minor impact — isolated errors, no widespread merchant impact | Next business day | Merchant Experience team via mailing list mx-api-announce@groupon.com |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| Salesforce | Monitor outgoing error rate in Wavefront; check SF status page | No automated fallback; write operations fail gracefully |
| DaaS PostgreSQL (primary DB) | Monitor latency and error rate in Wavefront | No fallback; read/write operations fail |
| NOTS Notification Service | Monitor outgoing error rate | Notification delivery failure; main prep flow unblocked |
| Accounting Service | Monitor outgoing error rate | Payment hold info unavailable; endpoint returns error |
| Contract Service | Monitor outgoing error rate | Contract rendering unavailable; other prep steps unaffected |
| Message Bus (MBUS) | Monitor via JTier MBUS client metrics | Event publication failure; state changes still persisted to DB |
