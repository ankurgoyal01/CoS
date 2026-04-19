---
service: "ingestion-service"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `GET /grpn/healthcheck` (port 8080) | HTTP readiness probe | 15 seconds (period), 30 seconds initial delay | Not specified |
| `GET /grpn/healthcheck` (port 8080) | HTTP liveness probe | 30 seconds (period), 60 seconds initial delay | Not specified |
| `GET /grpn/status` (port 8080) | Version/status check | On-demand | Not specified |

Liveness and readiness probe paths are defined in `.meta/deployment/cloud/components/app/common.yml`. A missing `heartbeat.txt` file at `/var/groupon/jtier/heartbeat.txt` is a known cause of liveness probe failure — recreate with `touch /var/groupon/jtier/heartbeat.txt`.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| HTTP in status > 200 | counter | Kibana KQL: `name: http.in AND groupon.fabric: conveyor-cloud AND data.status > 200` | Investigate errors |
| Pod CPU utilization | gauge | HPA target 100% — triggers scale-out at this threshold | 100% |
| DB connection count | gauge | MySQL DaaS connections — max pool exhaustion triggers errors | Investigate when max reached |
| JVM memory | gauge | Container memory limit 6144 MiB production; OOM kills pod | At limit |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Ingestion Service (US/EU combined) | Grafana | `https://prod-grafana.us-central1.logging.prod.gcp.groupondev.com/d/be8ghbfpszthcb/ingestion-service?orgId=1` |
| Ingestion Service Alerts Panel | Grafana | `https://prod-grafana.us-central1.logging.prod.gcp.groupondev.com/d/dea1yvz4xa9kwd/ingestion-service-alerts-panels?orgId=1` |
| Conveyor Cloud Customer Metrics | Grafana | `https://prod-grafana.us-central1.logging.prod.gcp.groupondev.com/d/fe7dii805648wc/conveyor-cloud-customer-metrics` (filter: namespace `ingestion-service-production`) |
| Wavefront Dashboard | Wavefront | `https://groupon.wavefront.com/dashboards/Ingestion-Service-Dashboard` |

### Logs

| Log Target | Link |
|------------|------|
| Kibana Production NA | `https://prod-kibana-unified.us-central1.logging.prod.gcp.groupondev.com/app/r/s/W8iez` |
| Kibana Production EMEA | `https://logging-eu.groupondev.com/goto/c12bf700-bba4-11f0-bf99-397535031e1c` |
| Kibana Staging | `https://stable-kibana-unified.us-central1.logging.stable.gcp.groupondev.com/app/r/s/NbzeP` |

Log source type: `ingestion_service` (Filebeat). Index pattern: `us-*:filebeat-ingestion-service*`.

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| PagerDuty notification | Service health degradation | critical | `ticket-ingestion-service@groupon.pagerduty.com`; PagerDuty service `P7YMF8A` |
| Pod CrashLoopBackoff | Pod repeatedly failing to start | critical | Check pod logs, verify heartbeat.txt, check DB migrations, check config values |
| Max DB connections | MySQL DaaS connection pool exhausted | warning | Delete and recreate affected pods; escalate to `#gds-daas` gchat space |
| HTTP 5xx errors | Salesforce API errors causing 500 responses | warning | Check Kibana logs, verify Salesforce connectivity, check job queue table |

## Common Operations

### Restart Service

1. Redeploy the same SHA via Deploybot UI (`https://deploybot.groupondev.com/CustomerSupport/ingestion-service`)
2. Alternatively, delete specific pods via kubectl:
   ```sh
   kubectx ingestion-service-production-us-central1
   kubectl delete pods ingestion-service--app--default-<POD-ID>
   ```
   Kubernetes will automatically recreate the pod.

### Scale Up / Down

1. Modify `minReplicas` and `maxReplicas` in the appropriate `.meta/deployment/cloud/components/app/*.yml` file
2. Redeploy via Deploybot or via raptor-cli:
   ```sh
   raptor cloud:logs
   ```
3. Contact `#cloud-support` gchat space for immediate scaling assistance without a deploy

### Check Pod Logs

```sh
# Authenticate
kubectl cloud-elevator auth

# Select context
kubectx ingestion-service-production-us-central1

# List pods
kubectl get pods

# Tail pod logs
kubectl logs -f ingestion-service--app--default-<POD-ID> -c main-log-tail

# Describe pod (state + events)
kubectl describe pods ingestion-service--app--default-<POD-ID>
```

### Database Operations

- Schema migrations run automatically on service startup via `jtier-migrations`
- If migration fails, the service will not start — check pod logs for migration error details
- For DB instance issues, contact `#gds-daas` gchat space
- Quartz tables are managed separately via `jtier-quartz-mysql-migrations`

## Troubleshooting

### Application Not Starting (CrashLoopBackoff)

- **Symptoms**: Pod repeatedly entering CrashLoopBackoff state; service unavailable
- **Cause**: Missing heartbeat file; invalid/missing configuration; failed DB migration
- **Resolution**:
  1. Check which container is failing: `kubectl describe pods ingestion-service--app--default-<POD-ID>`
  2. Check logs: `kubectl logs -f ingestion-service--app--default-<POD-ID> -c main-log-tail`
  3. If heartbeat missing: `touch /var/groupon/jtier/heartbeat.txt` inside the container
  4. If config issue: verify YAML config values in environment-specific cloud config file
  5. If DB migration fails: check migration scripts and DB connectivity

### Max DB Connections Reached

- **Symptoms**: `Max DB connections reached` errors in logs; requests failing with 500
- **Cause**: DB connection pool exhausted — possible leak or DaaS instance issue
- **Resolution**:
  1. Contact `#gds-daas` gchat space to check DaaS instance health
  2. Delete one pod and verify the new pod does not exhibit the same issue:
     ```sh
     kubectx <env-namespace>; kubectl delete pods <pod-name>
     ```
  3. If resolved, continue deleting remaining affected pods one by one
  4. If unresolved, escalate to `#gso-engineering` gchat space

### Salesforce Ticket Creation Failures

- **Symptoms**: API returns 500 "Error creating a ticket! It has been queued for a retry."; failed ticket queue growing
- **Cause**: Salesforce API unavailable or returning errors
- **Resolution**:
  1. Check Salesforce API health
  2. Monitor Kibana logs for specific SF error codes
  3. The `SfCreateTicketFailuresJob` will automatically retry failed requests on schedule
  4. Manually trigger retry via `GET /odis/api/v1/salesforce/ticket/triggerJob?id={id}` for specific records

### High CPU / Overload

- **Symptoms**: High CPU utilization; slow response times; HPA scaling at max replicas
- **Cause**: Traffic spike or inefficient query to downstream dependencies
- **Resolution**:
  1. HPA will auto-scale up to 15 replicas — monitor scaling in Conveyor dashboard
  2. Contact `#cloud-support` gchat space to fine-tune replicas
  3. Notify `#production` TDO and SOC on-call if degradation persists

### HTTP Errors in Cloud

- **Diagnosis**:
  1. Go to Kibana: `https://prod-kibana-unified.us-central1.logging.prod.gcp.groupondev.com/app/discover#`
  2. Choose index `us-*:filebeat-ingestion-service*`
  3. Query: `name: http.in AND groupon.fabric: conveyor-cloud AND data.status > 200`
  4. Filter by request ID, response status, and timestamp

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service completely down | Immediate | SOC on-call + `#production` + GSO Engineering manager |
| P2 | Degraded (partial failures, elevated error rates) | 30 min | `#gso-engineering` gchat + PagerDuty `P7YMF8A` |
| P3 | Minor impact (single job failures, non-critical endpoint errors) | Next business day | GSO Engineering team via `gso-india-engineering@groupon.com` |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| Salesforce | Verify SF API status; check Kibana logs for SF error codes | Failed ticket requests queued in MySQL for Quartz retry |
| CAAP API | Kibana logs for CAAP HTTP errors | No automatic fallback — errors propagated to caller |
| MySQL DaaS | `#gds-daas` gchat; delete/recreate pods | No fallback — service cannot authenticate without DB |
| Lazlo API | Check Kibana logs for HTTP errors to Lazlo | No fallback — deal endpoint returns error to caller |
| Users Service | Check Kibana logs for HTTP errors | No fallback — user endpoint returns error to caller |

## Rollback

Rollback is performed by redeploying the last successful build SHA via the Deploybot UI:
1. Navigate to `https://deploybot.groupondev.com/CustomerSupport/ingestion-service`
2. Find the last known-good deploy
3. Click redeploy/rollback on that entry
4. Verify the `/grpn/status` endpoint returns the expected version after deploy completes
