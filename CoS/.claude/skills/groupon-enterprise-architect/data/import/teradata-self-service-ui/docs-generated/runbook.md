---
service: "teradata-self-service-ui"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `GET /grpn/healthcheck` | HTTP (Nginx inline return 200) | Kubernetes default | Kubernetes default |

The health check endpoint is served directly by Nginx without forwarding to the backend. It returns HTTP 200 with body `ok\n`. This means the pod is considered healthy as long as the Nginx process is running, regardless of backend API availability.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| API call timing (all 7 operations) | gauge | Recorded to Google Analytics as `timing_complete` events via `gaTiming()` — includes `getUser`, `getConfiguration`, `getAccounts`, `getRequests`, `createAccount`, `processRequest`, `updatePassword` | No automated alert; monitored via GA dashboard |
| API error rate | counter | GA `exception` events for `NETWORK_ERROR`, `UNKNOWN_ERROR`, and backend error codes | No automated alert |
| Core Web Vitals (CLS, FID, LCP, FCP, TTFB) | gauge | Reported to GA via `web-vitals` library on page load | No automated alert |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Teradata Self Service UI | Wavefront | `https://groupon.wavefront.com/dashboards/Teradata-Self-Service-UI` |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| PagerDuty alert | Triggered by SRE on-call process | critical | Page `tss-tool@groupon.pagerduty.com` / service `PRFAUHJ` |
| Slack notification | Deploybot events (start, complete, override) | info | Monitor `#dnd-tools-ops` |

## Common Operations

### Restart Service

Rolling restart via Kubernetes:
1. Identify the current deployment: `kubectl get deploy -n teradata-self-service-ui-<env>`
2. Trigger a rolling restart: `kubectl rollout restart deploy/<deployment-name> -n teradata-self-service-ui-<env>`
3. Monitor rollout: `kubectl rollout status deploy/<deployment-name> -n teradata-self-service-ui-<env>`

### Scale Up / Down

Scaling is managed by Kubernetes HPA. To manually override:
1. `kubectl scale deploy/<deployment-name> --replicas=<N> -n teradata-self-service-ui-<env>`
2. Staging allows 1–5 replicas; production allows 2–10 replicas (configured in `.meta/deployment/cloud/`).

### Database Operations

> Not applicable. This service owns no database. All data operations are delegated to `teradata-self-service-api`.

## Troubleshooting

### Users Cannot Log In / Blank Screen on Load

- **Symptoms**: Application loads but no user data is shown; the splash screen does not dismiss
- **Cause**: The `tss-user` cookie is missing or expired. This is set by Nginx from the `X-GRPN-USERNAME` SSO header. If the upstream SSO proxy is not injecting headers (VPN disconnected, Okta session expired, SSO misconfiguration), cookies will be blank and the API `user-id` header will fall back to the default value (`ijohansson`).
- **Resolution**: Confirm the user has VPN access. Confirm Okta session is active. Check Nginx access logs for incoming `X-GRPN-USERNAME` header presence.

### Network Error on All API Calls

- **Symptoms**: All data views show errors; GA receives `NETWORK_ERROR` exception events
- **Cause**: `teradata-self-service-api` is unreachable. The Nginx `proxy_pass` to `teradata-self-service-api.${ENV}.service` is failing — either the backend pods are down or DNS resolution is failing.
- **Resolution**: Check health of `teradata-self-service-api` deployment in the same namespace/cluster. Verify service DNS resolves from within the pod: `kubectl exec -it <pod> -- nslookup teradata-self-service-api.<env>.service`.

### GMS Employees Cannot Create Accounts

- **Symptoms**: Clicking "New Account" shows a blocking dialog instead of the account creation form
- **Cause**: Expected behaviour. Employees with `companyId === 'GMS'` are blocked from creating personal Teradata accounts. This is enforced in `Account.vue` via the `gms-restriction` EventBus event.
- **Resolution**: No action needed. GMS employees should be directed to service account workflows.

### Teradata Account Shows LOCKED Status

- **Symptoms**: Account badge shows the red lock icon and `LOCKED` status
- **Cause**: The Teradata account has been locked (failed login attempts or manual lock). Lock duration is configurable via the backend's `lockDurationInHours` parameter (default 12 hours per mock configuration).
- **Resolution**: Contact `teradata-self-service-api` team to unlock the account via the backend, or use the "Unlock Account" action in the UI (which calls the API).

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service completely down — no users can access Teradata self-service | Immediate | DnD Tools on-call via PagerDuty (`PRFAUHJ`); Slack `#dnd-tools-ops` |
| P2 | Degraded — key workflows failing (e.g., cannot submit account requests) | 30 min | DnD Tools on-call; `dnd-tools@groupon.com` |
| P3 | Minor impact — cosmetic issues, non-critical analytics failures | Next business day | `dnd-tools@groupon.com` |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `teradata-self-service-api` | `GET /api/v1/healthcheck` (or check pod health in k8s cluster) | None — all data operations fail; users see error notifications |
| Google Analytics | No health check; fire-and-forget | Graceful degradation — analytics silently fail, application fully functional |
| Corporate SSO proxy | Check `X-GRPN-USERNAME` header presence in Nginx logs | Application falls back to cookie default (`ijohansson`); incorrect user context |
