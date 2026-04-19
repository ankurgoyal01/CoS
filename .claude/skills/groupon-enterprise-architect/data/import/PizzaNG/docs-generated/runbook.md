---
service: "PizzaNG"
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

Instrumentation is provided by `itier-instrumentation` 9.10.4. The `continuumPizzaNgLoggerComponent` emits GSO/PizzaNG-specific telemetry logs. Specific metric names are not discoverable from this repository.

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| BFF request rate | counter | Inbound HTTP requests to `/api/bff/pizza` and `/api/bff/create-order` | No evidence found in codebase |
| BFF response latency | histogram | End-to-end response time for BFF API endpoints | No evidence found in codebase |
| Downstream error rate | counter | Failed calls to CAAP, Cyclops, CFS, Deal Catalog, API Proxy, Zendesk | No evidence found in codebase |
| ticketFields cache hit rate | gauge | Ratio of in-memory cache hits vs misses for ticket field metadata | No evidence found in codebase |

### Dashboards

> No evidence found in codebase. Operational procedures to be defined by service owner.

### Alerts

> No evidence found in codebase. Operational procedures to be defined by service owner.

## Common Operations

### Restart Service

> Operational procedures to be defined by service owner. Follow standard Continuum I-Tier Kubernetes pod restart procedures. Note: restarting clears the in-memory `ticketFields` cache; the cache repopulates from Zendesk on the next request.

### Scale Up / Down

> Operational procedures to be defined by service owner. Follow standard Kubernetes HPA or manual replica scaling procedures.

### Database Operations

Not applicable — PizzaNG owns no persistent data stores.

## Troubleshooting

### `/api/bff/pizza` returns incomplete or empty data
- **Symptoms**: CS agent sees missing customer, order, or snippet context on the PizzaNG UI
- **Cause**: CAAP (`unknownExternalCaap_4b37e1`) is unreachable or returning errors
- **Resolution**: Verify CAAP service health; check Doorman auth resolution for downstream call tokens

### Order creation workflow fails
- **Symptoms**: `/api/bff/create-order` returns error or agent cannot complete order creation
- **Cause**: CAAP or Cyclops (`cyclops`) is unreachable, or Doorman auth token resolution has failed
- **Resolution**: Check health of CAAP, Cyclops, and Doorman integrations

### Deal content not enriched
- **Symptoms**: Deal data shown without NLP/ECE scoring or deal catalog metadata
- **Cause**: CFS Service (`continuumCfsService`) or Deal Catalog (`continuumDealCatalogService`) is unreachable
- **Resolution**: Verify CFS and Deal Catalog service health; check API Proxy (`apiProxy`) for Lazlo-backed endpoints

### Ticket context unavailable
- **Symptoms**: Agent sees no Zendesk ticket data; `ticketFields` cache cannot be populated
- **Cause**: Zendesk integration (`zendesk`) is unreachable
- **Resolution**: Verify Zendesk API availability; if cache is stale, restart pod to force re-population after Zendesk recovers

### Snippet generation fails
- **Symptoms**: Agent cannot load or apply support snippets
- **Cause**: CAAP snippet APIs are unreachable
- **Resolution**: Verify CAAP snippet endpoint health

### Authentication failures
- **Symptoms**: Agents receive 401/403 or are redirected from all pages
- **Cause**: OGWall/session validation by `continuumPizzaNgAuthComponent` has failed, or Doorman is unreachable
- **Resolution**: Check I-Tier session configuration and Doorman service health

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down — CS agents cannot access PizzaNG during active ticket handling | Immediate | GSO / Customer Support Engineering |
| P2 | Degraded — one or more workflows non-functional (e.g., refunds, order creation) | 30 min | GSO / Customer Support Engineering |
| P3 | Minor impact — non-critical feature (e.g., merchant workflows) unavailable | Next business day | GSO / Customer Support Engineering |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| CAAP | Check CAAP base URL health endpoint | Customer/order/refund/snippet data unavailable |
| `cyclops` | Check Cyclops base URL health endpoint | Cyclops-specific workflows unavailable |
| `continuumCfsService` | Check CFS service health endpoint | ECE scoring unavailable; deal content shown unscored |
| `continuumDealCatalogService` | Check Deal Catalog health endpoint | Deal metadata unavailable |
| `apiProxy` | Check API Proxy health endpoint | Lazlo-backed deal content unavailable |
| `zendesk` | Check Zendesk API availability | Ticket context unavailable; ticketFields cache cannot refresh |
| Doorman | Check Doorman health endpoint | Downstream authenticated calls blocked |
| Ingestion Service | Check ingestion endpoint | Zendesk ticket creation via ingestion unavailable |
