---
service: "ckod-ui"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| Kubernetes pod readiness | HTTP | Kubernetes default | Kubernetes default |
| `kubectl get pods -n ckod-ui-{env}` | exec | Manual | — |

> No custom `/health` or `/healthz` endpoint is defined in the codebase. Health is assessed via Kubernetes pod status and Grafana metrics.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| Pod count | gauge | Number of running pods in namespace | Below minReplicas (2 in production) |
| Deployment count | counter | Number of deployments executed | — |
| Memory usage | gauge | Container memory consumption | Near 4194 MiB limit |
| CPU usage | gauge | Container CPU consumption | Near HPA target (50%) |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| ckod-ui metrics | Grafana | `https://prod-grafana.us-central1.logging.prod.gcp.groupondev.com/d/be9idygfdh8u8b/ckod-ui?orgId=1` |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Pod OOMKilled | Container memory exceeds 4194 MiB limit | critical | Check for memory leaks; reduce `MALLOC_ARENA_MAX` if needed (currently set to 4) |
| Pod CrashLoopBackOff | Container fails to start repeatedly | critical | Check logs via `kubectl logs`; verify DB connection strings and env vars |
| HPA at max replicas | Replica count at 15 continuously | warning | Investigate traffic spike or slow queries; consider increasing resource limits |

## Common Operations

### Restart Service

Perform a zero-downtime rolling restart:

```bash
# Set up kubectl context first
kubectl cloud-elevator auth
kubectl config use-context gcp-production-us-central1
kubectl config set-context --current --namespace ckod-ui-production

# Rolling restart
kubectl rollout restart deployment ckod-ui--app--default

# Monitor rollout
kubectl rollout status deployment ckod-ui--app--default
```

### Scale Up / Down

Scaling is managed via Kubernetes HPA. To manually override temporarily:

```bash
kubectl scale deployment ckod-ui--app--default --replicas=5
```

### Database Operations

- Schema migrations are managed via Prisma and Flyway (evidenced by `schema_version` table).
- Run `npm run generate` after any `prisma/schema.prisma` changes to regenerate the Prisma client.
- For emergency read-only diagnostics, connect using `CKOD_DB_RO` credentials.
- For write operations (SLO management, deployment record corrections), use `CKOD_DB_RW` with caution.

### Viewing Logs

Application logs are written to `/app/logs/ckod-ui.log` in JSON format and shipped via Filebeat. To view logs directly on a pod:

```bash
kubectl exec -it <pod-name> -- tail -f /app/logs/ckod-ui.log
```

## Troubleshooting

### Build information shows "not-set"
- **Symptoms**: Settings menu shows blank or "not-set" for build version/branch/commit
- **Cause**: Docker build args (`BUILD_REF`, `BUILD_DATE`, `BUILD_VERSION`, `BUILD_BRANCH`) were not passed during the Docker build
- **Resolution**: Check Jenkins pipeline logs for build arg values; verify `Jenkinsfile` `buildArgsMap` is populated; ensure Docker build command includes `--build-arg`

### SLO dashboard shows no data
- **Symptoms**: SLO job detail tables are empty or show errors
- **Cause**: MySQL read-only connection failure, or no records match the selected ETL date filter
- **Resolution**: Verify `CKOD_DB_RO` environment variable is correctly set; check pod logs for Prisma connection errors; confirm data is present in MySQL for the selected date

### Deployment creation fails
- **Symptoms**: "Create Deployment" action returns an error; JIRA ticket not created
- **Cause**: JIRA API credentials expired or invalid; Keboola project token expired; network policy blocking egress
- **Resolution**: Verify JIRA and Keboola API credentials in k8s secrets; check pod logs for specific error from `jira-client.ts` or `keboola-client.ts`

### Vertex AI agent chat unavailable
- **Symptoms**: `/vertex-ai-agent` page shows no agents or session creation fails
- **Cause**: `CKOD_AGENTS_JSON` not configured or credentials env key invalid; Vertex AI service account permissions expired
- **Resolution**: Verify `CKOD_AGENTS_JSON` in k8s secrets; check that each agent's `credentialsEnvKey` resolves to a valid service account JSON; review Vertex AI project permissions

### Hand It Over access denied
- **Symptoms**: User receives "Access Denied" on `/hand-it-over`; `handitover/check-access` returns `allowed: false`
- **Cause**: User's email is not a member of the PRE team in `CKOD_TEAMS`/`CKOD_TEAM_MEMBERS`
- **Resolution**: Add the user's `@groupon.com` email to the PRE team via the `prismaRW` client or the `/api-test` admin route (PRE team only)

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service completely down (no pages load) | Immediate | PRE team on-call (via JSM) |
| P2 | Key feature degraded (SLO dashboards unavailable, deployments failing) | 30 min | PRE team on-call |
| P3 | Minor impact (AI feature down, one SLO platform showing errors) | Next business day | PRE team Slack |

Full incident runbook: `https://docs.google.com/document/d/1NTfVdv5XEEm7H-FdaaPnaCcpGCSEU7KfiuojrfFbFjc/edit`

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `continuumCkodPrimaryMysql` | Prisma connection test on startup | Application fails to start; pod enters CrashLoopBackOff |
| `continuumCkodAirflowMysql` | Prisma connection test on startup | Application fails to start |
| JIRA Cloud | Manual — attempt a test API call | Deployment creation blocked; incident management unavailable |
| Keboola Storage API | Manual — attempt project listing | Branch deployment details unavailable |
| Vertex AI | Session creation response | AI agent feature unavailable; rest of app unaffected |
| LiteLLM Proxy | Note generation response | Handover note generation unavailable; manual notes only |
| Google Chat | Webhook POST response | Notifications silently fail; core features unaffected |
