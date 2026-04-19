---
service: "cs-token"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `GET /heartbeat.txt` | HTTP | Conveyor Cloud default | Conveyor Cloud default |
| `GET /status` | HTTP | Manual / monitoring | — |

- **NA healthcheck URL**: `https://cs-token-service.production.service.us-central1.gcp.groupondev.com/heartbeat.txt`
- **EMEA healthcheck URL**: `https://cs-token-service.production.service.eu-west-1.aws.groupondev.com/heartbeat.txt`

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| `http.in` (response time) | histogram | Inbound HTTP request timing; TP95 < 100ms, TP99 < 200ms | TP99 > 200ms |
| `name: http.in, data.action: create` | counter | Token creation request volume and errors | Failure rate spike |
| `name: http.in, data.action: show` | counter | Token verification request volume and errors | Failure rate spike |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| CS Token Service Cloud | Wavefront | `https://groupon.wavefront.com/dashboards/cs-token-service-cloud` |
| Conveyor Cloud Customer Metrics (NA) | Wavefront | `https://groupon.wavefront.com/dashboards/Conveyor-Cloud-Customer-Metrics` (env: production-us-west-1) |
| Conveyor Cloud Customer Metrics (EMEA) | Wavefront | `https://groupon.wavefront.com/dashboards/Conveyor-Cloud-Customer-Metrics` (env: production-eu-west-1) |
| ELK / Kibana (NA Production) | Kibana | `https://prod-kibana-unified.us-central1.logging.prod.gcp.groupondev.com/app/kibana#/discover` |
| ELK / Kibana (EMEA Production) | Kibana | `https://logging-eu.groupondev.com/app/kibana#/discover` |
| ELK / Kibana (Dev/Staging) | Kibana | `https://stable-kibana-unified.us-central1.logging.stable.gcp.groupondev.com/app/discover#/` |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| `[SEVERE] CS Token Service NA token#verify_auth failures` | High rate of verify_auth failures (NA) | critical | See troubleshooting steps below |
| `[SEVERE] CS Token Service EMEA token#verify_auth failures` | High rate of verify_auth failures (EMEA) | critical | See troubleshooting steps below |
| `[SEVERE] CS Token Service NA token#create failures` | High rate of token creation failures (NA) | critical | See troubleshooting steps below |
| `[SEVERE] CS Token Service EMEA token#create failures` | High rate of token creation failures (EMEA) | critical | See troubleshooting steps below |

PagerDuty service: `https://groupon.pagerduty.com/services/PCK1GVL`
PagerDuty escalation: `customer-support-international@groupon.pagerduty.com`

## Common Operations

### Restart Service

1. Obtain access to the `grp_conveyor_production_cs-token-service` AD group and install `kubectl` and cloud elevator.
2. Authenticate: `kubectl cloud-elevator auth browser`
3. Select the target context: `kubectx cs-token-service-production-sox-us-central1`
4. Select the namespace: `kubens cs-token-service-production-sox`
5. List pods: `kubectl get pods`
6. Delete a pod to trigger restart: `kubectl delete pod <pod-name>`
7. Verify the new pod starts successfully: `kubectl get pods -w`

### Scale Up / Down

- Scaling is managed automatically by Kubernetes HPA based on CPU utilization.
- To manually adjust bounds, update `minReplicas`/`maxReplicas` in `.meta/deployment/cloud/components/app/<env>.yml` and redeploy.
- Contact `#cloud-support` Google Chat space for immediate manual scaling assistance.

### Database Operations

> Not applicable — CS Token Service has no relational database. The only data store is the Redis cache, which self-manages expiry via TTL.

To flush a specific token (e.g., to force re-authentication):
- Delete the Redis key corresponding to the encrypted token string in the relevant Redis instance.

## Troubleshooting

### Token Verify Auth Failures (High Rate)

- **Symptoms**: Alert fires for `token#verify_auth failures`; callers receive HTTP 401 responses
- **Cause**: Redis unavailable, expired tokens, invalid method/consumer_id in requests, or callers passing wrong API keys
- **Resolution**:
  1. Open Kibana (NA or EMEA index) and filter: `name: http.in and data.controller: "api.v1.users.token" and data.action: show`
  2. Identify failing request IDs and extract all events for those IDs
  3. If Redis connection errors appear, contact `#redis-memcached` Google Chat space
  4. If `token_unverified` with reason `invalid_method_name` or `invalid_consumer_id`, check whether calling service is sending correct parameters
  5. If `token_expired`, confirm token TTL settings match caller expectations

### Token Create Failures (High Rate)

- **Symptoms**: Alert fires for `token#create failures`; callers receive HTTP 400 or 401 responses
- **Cause**: Missing required params, invalid `X-API-KEY`, Redis unavailable
- **Resolution**:
  1. Open Kibana and filter: `name: http.in and data.controller: "api.v1.users.token" and data.action: create`
  2. Check for `Invalid X-API-KEY` — verify the calling service's API key matches `supported_api_keys` in the environment config
  3. Check for `Invalid Params` — confirm calling service sends `consumer_id`, `agent_id`, `agent_email`, and `method`
  4. Check for Redis connection errors — contact `#redis-memcached`

### Redis Timeout Issues

- **Symptoms**: Increased latency or connection errors to Redis
- **Cause**: Redis cluster issues or network partition
- **Resolution**:
  1. Contact `#redis-memcached` Google Chat space immediately
  2. Delete one pod to force a fresh Redis connection: `kubectl delete pod <pod-name>`
  3. If the new pod connects successfully, cycle remaining pods one at a time
  4. If problem persists, escalate to dev team in `#gso-engineering`

### Pod in CrashLoopBackoff

- **Symptoms**: Pod repeatedly crashes and restarts; `kubectl get pods` shows `CrashLoopBackoff`
- **Cause**: Missing heartbeat file, bad config file, or missing environment variables
- **Resolution**:
  1. Check pod events: `kubectl describe pod <pod-name>`
  2. Check container logs: `kubectl logs <pod-name> -c main`
  3. If heartbeat file missing: `kubectl exec <pod-name> -c main -- touch /var/groupon/jtier/heartbeat.txt`
  4. If config error, review `CONFIG_FILE` env var and ensure the referenced YAML file exists

### Service Healthcheck Not Responding

- **Symptoms**: Load balancer removes instances from pool; `GET /heartbeat.txt` returns non-200
- **Cause**: Application crashed, `heartbeat.txt` file missing, or Unicorn workers exhausted
- **Resolution**:
  1. Verify healthcheck endpoint directly from Kubernetes pod
  2. Check Kibana logs for the failed instance
  3. Search for the `x-request-id` from the healthcheck request in Edge proxy logs if not found in service logs
  4. Contact HB (Hybrid Boundary) team if edge proxy issues are suspected

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down (no tokens creatable or verifiable) | Immediate | GSO Engineering on-call via PagerDuty `PCK1GVL` |
| P2 | Degraded (elevated error rate, partial region) | 30 min | GSO Engineering `gso-india-engineering@groupon.com` |
| P3 | Minor impact (elevated latency, isolated failures) | Next business day | `cs-internal@groupon.com` mailing list |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| Redis (`csTokenRedis`) | `Settings.tokenizer_redis.present?` check on every request; connection errors surfaced in logs | No fallback — token operations fail with HTTP 401/500 if Redis is unreachable |

## AD Group Access Required

- `grp_conveyor_production_cs-token-service` — standard production access
- `grp_conveyor_privileged_cs-token-service` — privileged production access

## Kibana Log Indexes

| Region | Index Pattern |
|--------|--------------|
| NA (production) | `us-*:filebeat-cs-token-service_app--*` |
| EMEA (production) | `eu-*:filebeat-cs-token-service_app--*` |
| All environments | `filebeat-cs-token-service--*` |

**Example KQL query**: `name: http.in and data.controller: "api.v1.users.token"`
