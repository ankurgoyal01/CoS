---
service: "seo-admin-ui"
title: Runbook
generated: "2026-03-03T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `GET /status.json` | http | > No evidence found in codebase. | > No evidence found in codebase. |

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| HTTP request latency | histogram | End-to-end request duration via itier-instrumentation | > No evidence found in codebase. |
| HTTP error rate (5xx) | counter | Count of 5xx responses from the I-Tier server | > No evidence found in codebase. |
| Downstream API error rate | counter | Errors returned by LPAPI, SEO Deal API, and other dependencies | > No evidence found in codebase. |
| Neo4j query duration | histogram | Duration of Neo4j crosslinks graph queries | > No evidence found in codebase. |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| SEO Admin UI Service Health | > No evidence found in codebase. | > No evidence found in codebase. |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| High 5xx rate | Error rate exceeds baseline | critical | Check downstream dependency health; review logs for root cause |
| /status.json failing | Health check returns non-200 | critical | Restart the pod; escalate if restart does not resolve |
| Neo4j connectivity lost | Neo4j queries timing out | warning | Verify Neo4j host availability; crosslinks feature will be degraded |

## Common Operations

### Restart Service

Operational procedures to be defined by service owner. Standard Kubernetes restart:
1. Identify the running pod: `kubectl get pods -l app=seo-admin-ui -n <namespace>`
2. Delete the pod to trigger a rolling restart: `kubectl delete pod <pod-name> -n <namespace>`
3. Confirm new pod reaches Running state: `kubectl get pods -l app=seo-admin-ui -n <namespace>`
4. Verify health: `curl https://<host>/status.json`

### Scale Up / Down

Operational procedures to be defined by service owner. Adjust HPA min/max replicas or manually patch the deployment:
1. `kubectl scale deployment seo-admin-ui --replicas=<N> -n <namespace>`
2. Monitor pod startup and confirm all replicas reach Running state.

### Database Operations

seo-admin-ui reads from Neo4j but does not own schema migrations for it. Contact the Neo4j SEO data platform team for schema changes. Memcached cache can be flushed by restarting Memcached pods if stale data causes issues.

## Troubleshooting

### Landing page routes not loading
- **Symptoms**: Landing page management screen shows errors or empty results
- **Cause**: LPAPI is unavailable or returning errors
- **Resolution**: Verify LPAPI health; check `LPAPI_BASE_URL` config value; review I-Tier logs for HTTP error codes from LPAPI

### Crosslinks graph not rendering
- **Symptoms**: Crosslinks analysis page is blank or shows a connection error
- **Cause**: Neo4j SEO instance is unreachable or `NEO4J_URI` / credentials are misconfigured
- **Resolution**: Verify Neo4j connectivity from the pod; check `NEO4J_URI`, `NEO4J_USERNAME`, `NEO4J_PASSWORD` environment variables; confirm Neo4j cluster health

### SEO deals not populating
- **Symptoms**: SEO deals management screen shows empty deal data
- **Cause**: Deal Catalog (GAPI) GraphQL endpoint is unavailable or `GAPI_GRAPHQL_ENDPOINT` is incorrect
- **Resolution**: Check GAPI health; verify `GAPI_GRAPHQL_ENDPOINT` config value; review GraphQL error responses in logs

### Auto-index worker not triggering
- **Symptoms**: Pages are not being submitted for indexing; no worker activity in logs
- **Cause**: Google Search Console API credentials are invalid or expired, or the worker has crashed
- **Resolution**: Validate `GOOGLE_SEARCH_CONSOLE_CLIENT_ID` and `GOOGLE_SEARCH_CONSOLE_CLIENT_SECRET`; check OAuth token validity; review worker logs

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service completely down; SEO operators cannot access admin console | Immediate | SEO Engineering + Platform/SRE |
| P2 | Key feature degraded (e.g., landing page management unavailable) | 30 min | SEO Engineering |
| P3 | Minor feature degraded (e.g., crosslinks graph unavailable) | Next business day | SEO Engineering |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| LPAPI | Check LPAPI `/status` endpoint | Landing page management unavailable; other features continue |
| Deal Catalog (GAPI) | Check GAPI GraphQL health | SEO deal management unavailable; other features continue |
| Google Search Console API | Check OAuth token validity; call API health | Auto-index and auditing features unavailable |
| Neo4j (SEO) | Verify Bolt connection from pod | Crosslinks analysis unavailable; other features continue |
| Memcached | Check Memcached host connectivity | Cache misses cause increased downstream API latency; service continues |

> Operational procedures to be defined by service owner where marked above.
