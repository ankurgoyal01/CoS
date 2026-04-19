---
service: "api-proxy-config"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `/grpn/ready` (port 9000) | HTTP readiness probe | Kubernetes default | Kubernetes default |
| `/var/groupon/api-proxy/shared/heartbeat.txt` | File-based heartbeat | Kubernetes default | Kubernetes default |
| Jolokia JMX at port 8778 | HTTP (Telegraf scrape) | Telegraf scrape interval | — |

## Monitoring

### Metrics

Metrics are collected via the Telegraf sidecar scraping Jolokia on port 8778. Log shipping is performed by Filebeat with source type `api_proxy`, shipping to Kafka endpoints (`kafka-elk-broker.snc1` for production NA, `kafka-elk-broker.dub1` for production EMEA, `kafka-elk-broker-staging.snc1` for staging).

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| JVM heap usage | gauge | JVM heap utilization scraped via Jolokia port 8778 | Operational procedures to be defined by service owner |
| Pod CPU utilization | gauge | Kubernetes HPA driver metric; target 90% of request | HPA triggers scale-out at 90% |
| Pod memory usage | gauge | Container memory utilization | Limit: 4Gi (production) |
| Readiness probe failures | counter | `/grpn/ready:9000` probe failure count | Pod restart / deployment rollback |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| API Proxy monitoring | Grafana / Datadog | Operational procedures to be defined by service owner |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Pod readiness failure | `/grpn/ready:9000` returns non-200 | critical | Check `CONFIG` env var; verify config artifact is mounted and valid JSON; check JVM startup logs in `/app/log/application.log` |
| HPA max replicas reached | `replicas == maxReplicas` in production | warning | Review traffic spike; check upstream destination health; consider scaling Kubernetes node pool |
| Deployment timeout | `krane` exceeds `--global-timeout` (300–4000s) | critical | Check pod events (`kubectl describe pod`); look for config artifact mount failures or JVM OOM |

## Common Operations

### Restart Service

To safely restart the API Proxy pods after a configuration change:
1. Confirm the new configuration artifact has been packaged and pushed to the container registry
2. Trigger a DeployBot deployment for the target environment tag
3. DeployBot uses rolling update with `maxUnavailable: 0` — old pods drain for up to 30–90s (per environment `drainTimeout`) before termination
4. Monitor readiness probe at `/grpn/ready:9000` for each new pod
5. Verify the HPA shows `READY` replicas matching `minReplicas` before declaring success

### Scale Up / Down

Horizontal scaling is managed by the Kubernetes HPA targeting 90% CPU utilization. To manually adjust bounds:
1. Update `minReplicas` / `maxReplicas` in the relevant environment YAML under `.meta/deployment/cloud/components/app/<env>-<region>.yml`
2. Commit and create a new deployment tag
3. Verify HPA reflects new bounds with `kubectl get hpa -n api-proxy-<env>`

### Routing Configuration Operations

To add a new route:
```bash
node config_tools/addNewRouteRequest.js  # programmatic JSON request object
```

To remove routes:
```bash
node config_tools/removeRoutesCli.js --env=<env> --region=<na|emea> --isCloud=true
```

To promote a route from a previous environment to the target:
```bash
node config_tools/promoteRouteRequest.js  # programmatic JSON request object
```

To clean fully-rolled-out experiments:
```bash
node config_tools/cleanExperimentsCli.js --env=production --region=na --exp=All --isCloud=true
```

After any mutation, commit the modified `routingConf.json` files, open a PR for review by `groupon-api/api-platform-internal`, and deploy via DeployBot.

### Database Operations

> Not applicable. This service owns no databases. Configuration state is managed in Git.

## Troubleshooting

### API Proxy Fails to Start After Config Deployment
- **Symptoms**: New pods fail readiness probe; `kubectl logs` shows JSON parse errors or missing file errors at startup
- **Cause**: `CONFIG` env var points to a non-existent or malformed `mainConf.json`; config artifact was not properly packaged
- **Resolution**: Verify the `CONFIG` env var value in the deployment; validate JSON of target config file; check Maven assembly packaging output; rollback via DeployBot by redeploying previous tag

### Route Not Found After Adding via config_tools
- **Symptoms**: `apiProxy` returns 404 or routes traffic to wrong destination after a route was added
- **Cause**: Config tool mutation was not committed and deployed; or the wrong region/environment file was mutated
- **Resolution**: Run `getRoutesCli.js` to verify the route is present in the target `routingConf.json`; verify the correct cloud region files were modified; ensure the deployment was triggered after the commit

### Experiment Not Cleaning Up
- **Symptoms**: Old A/B experiment still active in routing config after rollout to 100%
- **Cause**: `cleanExperiments` not run; or experiment `startBucket`/`endBucket` not spanning 0–999 with `type: "rollout"`
- **Resolution**: Run `getExperimentsCli.js --env=<env> --region=<region>` to list active experiments; run `cleanExperimentsCli.js --exp=<id>` or `--exp=All` for fully-rolled-out ones

### HPA Failing to Scale
- **Symptoms**: Pod count stuck at `minReplicas` while CPU is above target; or stuck at `maxReplicas` under sustained load
- **Cause**: Kubernetes node pool exhausted; HPA target utilization set incorrectly; resource limits too low
- **Resolution**: Check node capacity with `kubectl describe nodes`; review HPA status with `kubectl get hpa -n api-proxy-production`; consider adjusting `maxReplicas` in environment YAML and deploying

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down — all API Proxy pods unready; all API traffic failing | Immediate | `groupon-api/api-platform-internal` |
| P2 | Degraded — partial pod failures or routing errors for subset of traffic | 30 min | `groupon-api/api-platform-internal` |
| P3 | Minor impact — stale experiments, single-zone issues, config tool errors | Next business day | `groupon-api/api-platform-internal` |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `apiProxy` runtime | `/grpn/ready:9000` per pod | Rolling deployment ensures old pods remain until new pods are ready (`maxUnavailable: 0`) |
| Kubernetes API (krane) | `krane` deploy success/timeout | Rollback by redeploying previous tagged version via DeployBot |
| Artifactory Helm registry | Helm chart `--repo http://artifactory.groupondev.com/artifactory/helm-generic/` reachable | Operational procedures to be defined by service owner |
| Git submodule secrets | `api-proxy-secrets` repo accessible | Operational procedures to be defined by service owner |
