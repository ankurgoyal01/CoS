---
service: "librechat"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Component | Type | Interval | Timeout |
|---------------------|-----------|------|----------|---------|
| `GET /health` (port 3080) | LibreChat App | http | 10s | Default |
| `GET /health` (port 8000) | RAG API | http | 10s | Default |
| `GET /health` (port 7700) | Meilisearch | http | 10s | Default |
| `pg_isready -U myuser` | VectorDB | exec | 10s | 5s |
| `/bitnami/scripts/readiness-probe.sh` | MongoDB | exec | 10s | 5s |
| `/bitnami/scripts/ping-mongodb.sh` | MongoDB | exec (liveness) | 10s | 5s |

All health check failure thresholds are set to 6 consecutive failures before the pod is restarted (except App which inherits defaults).

## Monitoring

### Metrics

> No evidence found in codebase of custom metrics instrumentation or Prometheus scrape configuration. Metrics are likely collected by the Groupon platform-level observability stack via Kubernetes resource metrics.

### Dashboards

> Operational procedures to be defined by service owner. No dashboard links are present in the deployment configuration.

### Alerts

> Operational procedures to be defined by service owner. No alert definitions are present in the deployment configuration.

## Common Operations

### Restart Service

To restart the LibreChat App:
1. Identify the current Kubernetes context (e.g., `librechat-gcp-production-us-central1`)
2. Roll the deployment: `kubectl rollout restart deployment/librechat-app -n librechat-production`
3. Monitor rollout: `kubectl rollout status deployment/librechat-app -n librechat-production`

To restart a specific component (e.g., RAG API):
1. `kubectl rollout restart deployment/librechat-rag-api -n librechat-production`

### Scale Up / Down

Scaling is managed by Horizontal Pod Autoscaler based on CPU utilization (target 50%). To manually override:
1. Patch the HPA: `kubectl patch hpa librechat-app -n librechat-production -p '{"spec":{"minReplicas":5}}'`
2. Alternatively, update `minReplicas` / `maxReplicas` in the appropriate `<env>.yml` and redeploy via DeployBot.

App scaling bounds: min 2 / max 15 (production), min 1 / max 2 (staging).

### Database Operations

**MongoDB:**
- Connect: `mongosh mongodb://librechat--mongodb.<env>.service:27017/LibreChat`
- Check replica set status: `db.hello()`
- MongoDB is a single-replica StatefulSet (`rs0`); no horizontal scaling is supported.

**VectorDB (pgvector):**
- Connect: `psql -h librechat--vectordb.<env>.service -p 80 -U myuser`
- Readiness check: `kubectl exec -n librechat-production <pod> -- pg_isready -U myuser`

**Meilisearch:**
- Health: `curl http://librechat--meilisearch.<env>.service/health`
- Data is persisted in a StatefulSet volume at `/meili_data/` (100G).

### Deploy a New Version

1. Update `appVersion` in `.meta/deployment/cloud/scripts/deploy.sh`
2. Trigger a DeployBot deployment to the target environment (staging first, then promote to production)
3. Monitor with: `krane deploy librechat-<env> <ctx> --global-timeout=300s`

## Troubleshooting

### Chat prompts return errors or timeout

- **Symptoms**: Users see error messages when submitting prompts; API server logs show connection failures
- **Cause**: LiteLLM proxy unreachable, or `RAG_API_URL` service is down
- **Resolution**: Verify LiteLLM proxy service is healthy at `http://litellm.<env>.service`; check RAG API pod health at `GET /health` on port 8000; check app pod logs with `kubectl logs -n librechat-<env> -l app.kubernetes.io/name=librechat,app.kubernetes.io/component=app`

### Users cannot log in (SSO failure)

- **Symptoms**: OIDC callback fails; users are redirected to login page repeatedly
- **Cause**: Okta OIDC client secret misconfigured, or `OPENID_ISSUER` unreachable
- **Resolution**: Verify Okta connectivity from the app pod; check that `OPENID_ISSUER: https://groupon.okta.com/oauth2/default` is reachable; inspect OIDC-related env vars in the pod environment

### MongoDB connection failures

- **Symptoms**: App logs show MongoDB connection errors; conversations fail to load or save
- **Cause**: MongoDB StatefulSet pod not ready, or `MONGO_URI` misconfigured
- **Resolution**: Check MongoDB pod status; run readiness probe manually: `kubectl exec -n librechat-<env> <mongodb-pod> -- /bitnami/scripts/readiness-probe.sh`; verify `MONGO_URI` matches `mongodb://librechat--mongodb.<env>.service:80/LibreChat`

### Meilisearch returning no search results

- **Symptoms**: Search feature returns empty results for known content
- **Cause**: Meilisearch indexes not populated or Meilisearch pod not ready
- **Resolution**: Check Meilisearch health endpoint; verify the data volume at `/meili_data/` is mounted and not full; check `MEILI_HOST` env var on the app pod

### RAG API not returning context

- **Symptoms**: Chat responses do not include expected document context; RAG-augmented answers fall back to generic LLM responses
- **Cause**: RAG API pod not ready, or VectorDB unreachable
- **Resolution**: Check RAG API health at `GET /health` port 8000; verify VectorDB readiness with `pg_isready -U myuser` on the VectorDB pod; confirm `DB_HOST` and `DB_PORT` env vars on the RAG API pod are correct

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down (all users unable to access) | Immediate | Platform Engineering |
| P2 | Degraded (LLM responses failing or RAG unavailable) | 30 min | Platform Engineering |
| P3 | Minor impact (single component degraded, workarounds available) | Next business day | Platform Engineering |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| LiteLLM proxy | HTTP reachability from app pod | No fallback; chat is unavailable without LLM proxy |
| Okta OIDC | OIDC discovery endpoint reachability | No fallback; authentication is blocked |
| MongoDB | `readiness-probe.sh` exec probe | No fallback; conversation storage is unavailable |
| Meilisearch | HTTP GET `/health` port 7700 | Search feature unavailable; chat continues to function |
| RAG API | HTTP GET `/health` port 8000 | RAG context not injected; base LLM responses still served |
| VectorDB | `pg_isready` exec probe | RAG pipeline is blocked; RAG API cannot serve retrieval requests |
