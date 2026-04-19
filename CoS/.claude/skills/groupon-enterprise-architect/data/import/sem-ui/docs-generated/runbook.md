---
service: "sem-ui"
title: Runbook
generated: "2026-03-03T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| I-Tier default health endpoint | http | No evidence found in codebase | No evidence found in codebase |

## Monitoring

### Metrics

Instrumentation is provided by `itier-instrumentation` 9.11.2. Specific metric names are not discoverable from this repository.

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| Request rate | counter | Inbound HTTP requests to I-Tier server | No evidence found in codebase |
| Response latency | histogram | End-to-end response time for proxy routes | No evidence found in codebase |
| Proxy error rate | counter | Failed upstream proxy calls (4xx/5xx from downstream) | No evidence found in codebase |

### Dashboards

> No evidence found in codebase. Operational procedures to be defined by service owner.

### Alerts

> No evidence found in codebase. Operational procedures to be defined by service owner.

## Common Operations

### Restart Service

> Operational procedures to be defined by service owner. Follow standard Continuum I-Tier Kubernetes pod restart procedures.

### Scale Up / Down

> Operational procedures to be defined by service owner. Follow standard Kubernetes HPA or manual replica scaling procedures.

### Database Operations

Not applicable — this service is stateless and owns no data stores.

## Troubleshooting

### Keyword Manager page not loading
- **Symptoms**: `/keyword-manager` page returns errors or shows no data
- **Cause**: SEM Keywords Service (`semKeywordsService`) is unreachable or returning errors via `/proxy/keyword/deals/{permalink}/keywords`
- **Resolution**: Verify SEM Keywords Service health and check proxy route configuration

### Denylist page not loading
- **Symptoms**: `/denylisting` page returns errors or shows no data
- **Cause**: SEM Blacklist Service (`continuumSemBlacklistService`) is unreachable or returning errors via `/proxy/denylist`
- **Resolution**: Verify SEM Blacklist Service health; check `continuumSemUiWebApp` -> `continuumSemBlacklistService` relationship

### Attribution Lens page not loading
- **Symptoms**: `/attribution-lens` page returns errors or shows no data
- **Cause**: GPN Data API (`gpnDataApi`) is unreachable or returning errors via `/proxy/attribution/orders`
- **Resolution**: Verify GPN Data API availability and proxy route configuration

### Authentication failures
- **Symptoms**: Users redirected away from all pages or receive 401/403 responses
- **Cause**: `itier-user-auth` middleware cannot validate session
- **Resolution**: Check I-Tier session configuration and upstream identity provider health

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down — SEM operators cannot access dashboard | Immediate | SEM / Search Engineering |
| P2 | Degraded — one or more pages non-functional | 30 min | SEM / Search Engineering |
| P3 | Minor impact — intermittent proxy errors | Next business day | SEM / Search Engineering |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `semKeywordsService` | Check `/proxy/keyword/deals/{permalink}/keywords` response code | Keyword Manager page unavailable; other pages unaffected |
| `continuumSemBlacklistService` | Check `/proxy/denylist` response code | Denylist page unavailable; other pages unaffected |
| `gpnDataApi` | Check `/proxy/attribution/orders` response code | Attribution Lens page unavailable; other pages unaffected |
