---
service: "transporter-jtier"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `GET /grpn/healthcheck` via Edge Proxy | http | Per deployment platform | Not documented |
| `GET /grpn/status` (disabled, port 8080) | http | n/a | n/a |
| Dropwizard admin port 8081 | http | Per platform | Not documented |

Health check command:
```sh
curl -I https://edge-proxy--production--default.prod.us-west-1.aws.groupondev.com/grpn/healthcheck \
  --header "Host: transporter-jtier.production.service"
```
Expected response: `HTTP/1.1 200 OK`

## Monitoring

### Metrics

Metrics are emitted via Telegraf (HTTP listener on port `8186`) and shipped to InfluxDB locally, and to Wavefront in production.

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| `custom.*` (service-level) | Various | Custom JTier service metrics (query InfluxDB: `select * from "custom.*" where service='transporter-jtier'`) | Not documented |
| JVM metrics | gauge | Heap, GC, thread counts via JTier JVM metrics | Not documented |
| HTTP in/out | counter/histogram | Inbound and outbound HTTP call rates, latencies | Not documented |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Transporter JTier SMA (Production) | Wavefront | https://groupon.wavefront.com/u/1725QQl8zk?t=groupon |
| Transporter JTier SMA (Staging) | Wavefront | https://groupon.wavefront.com/u/7wr5CTP4sh?t=groupon |
| Cloud Conveyor Customer Metrics | Grafana | https://prod-grafana.us-central1.logging.prod.gcp.groupondev.com/goto/CmF4HZivR |
| transporter-jtier Logs (Production) | Kibana | https://prod-kibana-unified.us-central1.logging.prod.gcp.groupondev.com/app/r/s/bvrqd |
| transporter-jtier Logs (Pre-prod) | Kibana | https://stable-kibana-unified.us-central1.logging.stable.gcp.groupondev.com/app/r/s/tC2uA |
| edge-proxy Logs (Production) | Kibana | https://prod-kibana-unified.us-central1.logging.prod.gcp.groupondev.com/app/r/s/rHxAl |
| edge-proxy Logs (Pre-prod) | Kibana | https://stable-kibana-unified.us-central1.logging.stable.gcp.groupondev.com/app/r/s/DbgDU |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Transporter Jtier Pods In Crash Loop | Pods enter CrashLoopBackOff state | critical | Investigate pod logs via `kubectl logs`; check recent deployments; rollback if needed |

PagerDuty service: https://groupon.pagerduty.com/services/PLUGT8Z
Jira Ops: https://groupondev.atlassian.net/jira/ops/teams/og-9ceb0ec2-446a-4ac3-bc4e-85f4e40ca5ca

## Common Operations

### Restart Service

```sh
# Authenticate
kubectl cloud-elevator auth
kubectl config use-context transporter-jtier-production-us-west-1

# Restart the api deployment
kubectl rollout restart deployment/transporter-jtier--app--default

# Restart the worker deployment
kubectl rollout restart deployment/transporter-jtier--sf-upload-worker--default
```

The service restarts automatically as part of deployments.

### Scale Up / Down

Scaling is managed by the HPA configured in Conveyor deployment manifests. To manually scale:
```sh
kubectl scale deployment/transporter-jtier--app--default --replicas=<N>
```
Production limits: min 2 / max 6 replicas per component.

### Database Operations

Schema migrations run automatically at service startup via the `jtier-migrations` Flyway bundle.

To run migrations manually during development:
```sh
mvn flyway:migrate
```

To connect to MySQL locally:
```sh
cd .local
docker-compose exec shell /bin/bash -lc 'mysql -h mysql -u transporter_user -p${MYSQL_PASSWORD}'
```

### View Logs

Application logs:
```sh
kubectl logs <pod-name> main
kubectl logs <pod-name> main-log-tail
```

Pod names follow the pattern: `transporter-jtier--app--default-<hash>`

## Troubleshooting

### Pods in Crash Loop

- **Symptoms**: Grafana alert fires; `kubectl get pods` shows `CrashLoopBackOff`
- **Cause**: JVM startup failure (OOM, misconfiguration, Salesforce connectivity, MySQL unreachable)
- **Resolution**: Check `kubectl logs <pod-name> main` for exception; verify `JTIER_RUN_CONFIG` points to valid config; check downstream MySQL and Redis connectivity; rollback via DeployBot if related to a recent deploy

### Upload Jobs Stuck

- **Symptoms**: Upload job records remain in a pending/in-progress state; no Salesforce records updated
- **Cause**: `sf-upload-worker` Quartz job failing; Salesforce API unavailable; S3 file not found; AWS IRSA token expired
- **Resolution**: Check worker pod logs; verify AWS IAM role assignment; check S3 bucket availability; inspect Salesforce API status

### Authentication Failures

- **Symptoms**: `POST /v0/auth` returns errors; users cannot authenticate
- **Cause**: Salesforce OAuth credentials invalid or expired; Salesforce connected app configuration changed; Okta issues
- **Resolution**: Verify Salesforce OAuth secrets in Conveyor secrets store; check Salesforce connected app settings; review Okta service status

### ELK Log Debugging

Application logs index filter: `us-*:filebeat-transporter-jtier--*`
Apply filter: `groupon.fabric:conveyor-cloud`

Edge proxy access logs index: `edge-proxy-access-json`
Filter: `authority:transporter-jtier.production.service`

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down — upload UI non-functional | Immediate | Salesforce Integration team via PagerDuty `PLUGT8Z`; `sfint-dev-alerts@groupon.com` |
| P2 | Degraded — uploads failing but service responding | 30 min | Salesforce Integration team; Slack `salesforce-integration` |
| P3 | Minor impact — individual job failures | Next business day | `sfint-dev@groupon.com` |

Criticality Tier: **Non-Core**

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| MySQL | Dropwizard health check on admin port 8081 | No fallback — service cannot persist state |
| Redis | Dropwizard health check on admin port 8081 | Token re-fetch from Salesforce on cache miss |
| Salesforce | Endpoint availability check | Upload jobs fail; queued in database |
| AWS S3 | SDK call failure | Worker job fails; no input files retrievable |
| GCS | SDK call failure | Result files not written; signed URLs unavailable |

## Access Requirements

Request access to the `transporter-jtier` LDAP groups and Kubernetes namespace:
1. Visit https://arq.groupondev.com/ra/ad_subservices/transporter-jtier
2. Select all 3 Conveyor Cloud Groups
3. Provide a reason for access and submit
