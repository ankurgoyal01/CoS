---
service: "contract_service"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `GET /status` (Kubernetes readiness/liveness) | http | Readiness: 5s; Liveness: 15s | Initial delay: readiness 20s, liveness 30s |
| `GET /grpn/healthcheck` (Nginx layer) | http | 5s | — |
| `GET /status.json` (on-prem load balancer / Nagios) | http | Per Nagios config | — |
| `GET /heartbeat` (on-prem heartbeat file) | http | Per Nagios/VIP config | — |

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| Request rate (rpm) | counter | Requests per minute across all endpoints | Alert: `cicero_status` — high error response codes |
| Endpoint latency | histogram | Per-endpoint response time in milliseconds | P95 > 1.6s on `GET /v1/contracts/{id}` (SLA baseline: 635ms median, 1.6k P95) |
| Signing latency | histogram | Response time for `POST /v1/contracts/{id}/sign` | P95 > 29ms (SLA baseline: 27ms median, 29ms P95) |
| Error rate | counter | HTTP 4xx/5xx response rate | Alert: `cicero_endpoint_status` — high error count on specific endpoint |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Contract Service Overview | Wavefront | https://groupon.wavefront.com/dashboard/contract_service |
| Cicero SMA | Wavefront | https://groupon.wavefront.com/dashboard/cicero--sma |
| Cicero Detail | Wavefront | https://groupon.wavefront.com/dashboard/cicero |
| Cicero Contract Versioning | Splunk | https://splunk-adhoc-us.groupondev.com/en-US/app/search/cicero_contract_versioning_service |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| `contract-service-vip_http_80` | Load balancer health < 50% | 3 | Check VIP status; curl `/status.json` on downed host; SSH and touch `heartbeat.txt` if endpoint responds |
| `cicero_status` (Splunk) | High number of error response codes | 3 | Check ELK logs (`us-*:filebeat-steno_skeletor_rails--*`), inspect pod logs with `stern <pod_name>` |
| `cicero_latency` (Splunk) | High overall latency | 3 | Check DB connection pool exhaustion; consider restarting pods to release connections |
| `cicero_endpoint_status` (Splunk) | High error count for specific endpoint | 4 | Identify failing endpoint from Splunk; check for schema validation errors or DB issues |
| `cicero_endpoint_latency` (Splunk) | High latency for specific endpoint | 4 | Profile slow queries; check MySQL DaaS replication lag |

## Common Operations

### Restart Service

**Cloud (Kubernetes):**
```
kubectx cicero-production-sox   # or cicero-staging-sox
kubectl get pods
kubectl delete pod <pod_name>   # Kubernetes will recreate the pod
```
Or trigger a new deploy via Deploybot — this performs a rolling restart.

**On-prem (legacy):**
```
sudo /usr/local/etc/init.d/unicorn_contract_service restart
```

### Scale Up / Down

Scaling is handled automatically by the Kubernetes HPA based on CPU utilization. For manual override:
```
kubectx cicero-production-sox
kubectl scale deployment cicero--app--default --replicas=<N>
```
Contact `#cloud-migration` or `#cloud-sre-support` for guidance on fine-tuning replica counts.

### Database Operations

**Run migrations (Cloud):**
Migrations run automatically as a Kubernetes Job before each deployment (`.meta/deployment/cloud/components/app/template/migrations.yml.erb`).

**Run migrations manually (local/on-prem):**
```
rake db:migrate
rake db:migrate RAILS_ENV=staging
```

**Max DB connections reached:**
The production and staging MySQL instances have been tuned for connection limits. If exhaustion occurs, restart the application pods to release connections:
```
kubectl -n cicero-production-sox rollout restart deployment/cicero--app--default
```

## Troubleshooting

### Pods in CrashLoopBackoff

- **Symptoms**: Pods repeatedly crash and restart; `kubectl get pods` shows `CrashLoopBackoff` or high restart count
- **Cause**: Application startup failure — typically a missing secret, bad config, or DB connectivity issue
- **Resolution**: Run `kubectl describe pod/<pod_name> -n cicero-production-sox` to read the exit reason. Open a shell (`kubectl -n <namespace> exec -it <pod_name> -c main -- /bin/sh`) and check `/var/groupon/logs/steno.log`. For secrets issues, follow the [Raptor secrets troubleshooting guide](https://pages.github.groupondev.com/cloud-migration-factory/configuration-tools-docs/secrets/overview.html#verification--troubleshooting).

### High Error Rate on `/v1/contracts/{id}`

- **Symptoms**: Elevated 4xx/5xx in `cicero_status` Splunk alert; high P95 latency
- **Cause**: MySQL connection issues, schema validation failures, or attempted modification of signed contracts
- **Resolution**: Check ELK logs using index `us-*:filebeat-steno_skeletor_rails--*`. Look for `ActiveRecord::StatementInvalid` or validation error messages. If DB-related, check DaaS connection and replica lag.

### Secrets Submodule Out of Sync

- **Symptoms**: Deploy fails with secrets-related errors in Deploybot console
- **Cause**: The `contract_service-secrets` submodule SHA in the main repo does not match the current secrets SHA
- **Resolution**: Run `git submodule foreach git pull origin master` to pull the latest secrets SHA, then deploy with the secrets change as the only change in the commit. Follow the full procedure in RUNBOOK.md.

### Contract Cannot Be Modified or Deleted

- **Symptoms**: `PUT` or `DELETE` on a contract returns `422` with "cannot modify or delete a signed contract"
- **Cause**: The contract has been signed — a signature record is attached. Signed contracts are immutable by design.
- **Resolution**: This is expected behavior. If modification is genuinely required, escalate to the Deal Management Services team (dms-dev@groupon.com) for a manual data operation.

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service completely down; merchants cannot access or sign contracts | Immediate | Page via PagerDuty (PXM5GIL); escalate to IMOC in `#production` |
| P2 | Degraded — high latency or elevated error rate; partial functionality | 30 min | dms-dev@groupon.com; `#dms` Slack |
| P3 | Minor impact — specific endpoint slow or single-environment issue | Next business day | dms-dev@groupon.com |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| MySQL (DaaS) | `rake db:version` or a test query from within a pod | No fallback; service is fully dependent on DB availability |
| Metrics Stack (Telegraf/Wavefront) | Check Wavefront dashboards for data gaps | Metrics stop recording; service continues to serve requests |
| Hybrid Boundary (Envoy) | `wget -q -O - http://localhost:9901/server_info` (Envoy admin port) | mTLS fails; inter-service traffic blocked |

## Log Access

**Staging ELK:** https://logging-stable-unified01.grpn-logging-stable.us-west-2.aws.groupondev.com/

**Production ELK:** https://logging-prod-us-unified1.grpn-logging-prod.us-west-2.aws.groupondev.com/

Index pattern: `us-*:filebeat-steno_skeletor_rails--*`

**Live pod logs (Kubernetes):**
```
brew install stern
stern <pod_name> -n cicero-production-sox
```
