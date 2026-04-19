---
service: "itier-ttd-booking"
title: Runbook
generated: "2026-03-03T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| Standard ITier health endpoint (e.g., `/health` or `/_ah/health`) | http | Platform-managed | Platform-managed |

> Specific health check endpoint paths and intervals are defined in the Kubernetes deployment manifests in the service source repository.

## Monitoring

### Metrics

> Operational procedures to be defined by service owner.

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| HTTP request rate | counter | Inbound requests per second across all endpoints | — |
| HTTP error rate (5xx) | counter | Server-side errors on booking/reservation/ttd-pass routes | — |
| Reservation status poll latency | histogram | Latency of `/live/deals/{dealId}/reservation/status.json` polling calls | — |
| GLive Inventory Service call latency | histogram | Latency of downstream calls to `continuumGLiveInventoryService` | — |
| Deal Catalog Service call latency | histogram | Latency of downstream calls to `continuumDealCatalogService` | — |

### Dashboards

> Operational procedures to be defined by service owner.

| Dashboard | Tool | Link |
|-----------|------|------|
| TTD Booking ITier Service | Grafana / Datadog | Contact TTD.CX team (ttd-dev.cx@groupon.com) |

### Alerts

> Operational procedures to be defined by service owner.

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| High 5xx error rate | >1% of requests return 5xx over 5-minute window | critical | Check downstream service health; review application logs |
| GLive Inventory Service timeout | Reservation creation or status poll timeouts elevated | critical | Check `continuumGLiveInventoryService` health; route to error page if unrecoverable |
| Deal Catalog Service degraded | Deal metadata fetch failures elevated | warning | Check `continuumDealCatalogService` health; booking widget will fail to render |

## Common Operations

### Restart Service

> Operational procedures to be defined by service owner. Standard Kubernetes rolling restart applies.

1. Identify the Kubernetes deployment name for `itier-ttd-booking`
2. Run `kubectl rollout restart deployment/<deployment-name> -n <namespace>`
3. Monitor pod startup with `kubectl get pods -n <namespace> -w`
4. Verify health endpoint returns 200 before considering restart complete

### Scale Up / Down

> Operational procedures to be defined by service owner.

1. Edit the Kubernetes HPA or deployment replica count in the service manifests
2. Apply with `kubectl apply -f <manifest>` or via the CI/CD pipeline
3. Monitor pod scaling with `kubectl get pods -n <namespace>`

### Database Operations

> Not applicable — this service does not own a database. Session cache (Memcached) is managed by the platform team.

## Troubleshooting

### Booking Widget Fails to Render

- **Symptoms**: `/live/checkout/booking/{dealId}` returns 500 or empty page
- **Cause**: `continuumDealCatalogService` or `continuumUsersService` is unreachable or returning errors; deal data cannot be assembled
- **Resolution**: Check downstream service health via `apiProxy`; inspect application logs for adapter errors from `gapiWrapperAdapter` or `gliveInventoryAdapter`

### Reservation Spinner Stuck / Not Advancing

- **Symptoms**: `/live/deals/{dealId}/reservation` spinner never resolves; status polling returns non-terminal state indefinitely
- **Cause**: `continuumGLiveInventoryService` reservation creation failed or status polling is returning `pending` beyond expected TTL
- **Resolution**: Check `continuumGLiveInventoryService` health; verify reservation was created successfully; check for stuck reservation state in GLive Inventory Service; user should be directed to `/live/checkout/error`

### TTD Pass Page Shows No Cards

- **Symptoms**: `/ttd-pass-deals` renders empty or error state
- **Cause**: Alligator Cards Service unreachable or returning empty card set for the given deal
- **Resolution**: Check Alligator Cards Service health; verify deal has associated TTD pass assets configured; inspect `ttdPassAdapter` logs

### Experimentation Variants Not Applying

- **Symptoms**: Booking widget always shows control variant regardless of experiment assignment
- **Cause**: Expy/Optimizely SDK not evaluating correctly; missing or invalid `EXPY_API_KEY`
- **Resolution**: Verify `EXPY_API_KEY` environment variable is set; check Expy SDK initialization logs; confirm experiment is active in Optimizely dashboard

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down — booking widget and/or reservation flow unavailable | Immediate | TTD.CX team: ttd-dev.cx@groupon.com |
| P2 | Degraded — elevated error rate or reservation failures | 30 min | TTD.CX team: ttd-dev.cx@groupon.com |
| P3 | Minor impact — TTD pass page degraded or experiment variants not assigned | Next business day | TTD.CX team: ttd-dev.cx@groupon.com |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `continuumDealCatalogService` | Check service health via `apiProxy` routing | Booking widget renders error state |
| `continuumUsersService` | Check service health via `apiProxy` routing | Booking and reservation pages render error state |
| `continuumGLiveInventoryService` | Check service health via `apiProxy` routing | Reservation flow redirects to `/live/checkout/error` |
| Alligator Cards Service | Check service health endpoint directly | TTD pass page renders empty/error state |
| Memcached (session cache) | Platform monitoring | Session-related failures; ITier platform handles fallback |
