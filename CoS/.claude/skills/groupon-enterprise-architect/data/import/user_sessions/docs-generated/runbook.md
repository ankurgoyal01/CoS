---
service: "user_sessions"
title: Runbook
generated: "2026-03-03T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| No evidence found — expected Kubernetes liveness/readiness probe on itier-server default health path | http | No evidence found | No evidence found |

> Operational procedures to be defined by service owner. Health check endpoint path is not discoverable from the inventory; consult the Kubernetes deployment manifest.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| HTTP request rate | counter | Requests per second across all routes | No evidence found |
| HTTP error rate (5xx) | counter | Server-side errors on login/signup/reset endpoints | No evidence found |
| GAPI response latency | histogram | Latency of downstream GAPI GraphQL calls | No evidence found |
| Memcached operation errors | counter | Failed session cache reads/writes | No evidence found |

> Metrics are emitted via `itier-instrumentation` 9.13.4. Alert thresholds and dashboard links are managed externally.

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| No evidence found | No evidence found | No evidence found |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Login endpoint elevated 5xx | HTTP 5xx rate on `/login` or `/signup` above baseline | critical | Check GAPI connectivity; check Memcached health; inspect service logs |
| GAPI unreachable | GAPI calls failing consistently | critical | Verify `GRAPHQL_ENDPOINT` value; check GAPI service health |
| Memcached unavailable | Cache write/read failures on all hosts in `MEMCACHED_HOSTS` | warning | Verify Memcached cluster health; users will be unable to maintain sessions |

## Common Operations

### Restart Service

Operational procedures to be defined by service owner. For Kubernetes deployments, a rolling restart can be triggered with:
```
kubectl rollout restart deployment/user-sessions -n <namespace>
```
Allow the rollout to complete and verify pod readiness before considering the restart complete.

### Scale Up / Down

Operational procedures to be defined by service owner. For Kubernetes HPA-managed scaling, adjust the HPA min/max replica count in the deployment manifest or via:
```
kubectl scale deployment/user-sessions --replicas=<N> -n <namespace>
```

### Database Operations

This service does not own a relational database. No schema migrations apply. Memcached is schema-less — no migration procedures are required. If Memcached is flushed or restarted, all active sessions are lost and users must re-authenticate.

## Troubleshooting

### Users Cannot Log In
- **Symptoms**: Login form submission returns errors or loops; users report being unable to authenticate
- **Cause**: GAPI endpoint unreachable, returning errors, or `GRAPHQL_ENDPOINT` misconfigured
- **Resolution**: Verify `GRAPHQL_ENDPOINT` environment variable; check GAPI service health; inspect service logs for GraphQL error responses

### Sessions Lost / Users Logged Out Unexpectedly
- **Symptoms**: Authenticated users are redirected to login on subsequent requests
- **Cause**: Memcached cluster unavailable or flushed; `SESSION_SECRET` rotated without coordinated cookie invalidation
- **Resolution**: Check Memcached cluster health and connectivity via `MEMCACHED_HOSTS`; verify `SESSION_SECRET` consistency across all pod replicas

### Social Login Fails (Google / Facebook)
- **Symptoms**: OAuth redirect returns an error; "Sign in with Google/Facebook" flow does not complete
- **Cause**: OAuth client credentials misconfigured or expired; OAuth provider endpoint unreachable; `FEATURE_FLAGS` has social login disabled
- **Resolution**: Verify OAuth client credentials in secrets; check provider status pages; review `FEATURE_FLAGS` configuration

### Password Reset Link Does Not Work
- **Symptoms**: User clicks reset link and receives an error or is redirected to an error page
- **Cause**: Reset token expired or already used; GAPI token validation failing; URL path mismatch (legacy vs canonical path)
- **Resolution**: Verify GAPI is healthy and token endpoints respond; confirm token has not expired; check that all three reset paths (`/users/password_reset/:token`, `/passwordreset/:token`, `/users/reset_password/:userId/:token`) are routed correctly

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down — no users can log in or register | Immediate | Identity Platform on-call |
| P2 | Degraded — partial auth failures (e.g., social login only) | 30 min | Identity Platform on-call |
| P3 | Minor impact — intermittent errors, single-region degradation | Next business day | Identity Platform team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| GAPI (`gapiSystem_5c8b`) | Verify `GRAPHQL_ENDPOINT` responds to health probe; check GAPI service status | No fallback — login/signup/reset are unavailable without GAPI |
| Memcached (`memcachedCluster_6e2f`) | Check connectivity to each host in `MEMCACHED_HOSTS` | No fallback — session persistence is unavailable; users cannot maintain authenticated state |
| Google OAuth (`googleOAuth_1d2e`) | Check Google OAuth status page | Google social login unavailable; email/password login unaffected |
| Facebook OAuth (`facebookOAuth_9a7c`) | Check Facebook API status page | Facebook social login unavailable; email/password login unaffected |
