---
service: "merchant-booking-tool"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| I-tier platform health endpoint | http | I-tier platform default | I-tier platform default |

> Specific health check endpoint paths are managed by the I-tier platform. Confirm with the Continuum Merchant Experience team.

## Monitoring

### Metrics

> Operational procedures to be defined by service owner. No metric definitions are visible in the architecture DSL.

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| HTTP 5xx error rate | counter | Rate of server errors returned to merchant browsers | To be defined by service owner |
| Merchant API call latency | histogram | Latency of calls from `mbtMerchantApiClient` to `continuumUniversalMerchantApi` | To be defined by service owner |
| Proxy endpoint error rate | counter | Error rate on `/reservations/mbt/proxy/*` passthrough calls | To be defined by service owner |

### Dashboards

> Operational procedures to be defined by service owner. Dashboard links are not available in the architecture DSL.

| Dashboard | Tool | Link |
|-----------|------|------|
| Merchant Booking Tool operational dashboard | Internal monitoring tool | To be defined by service owner |

### Alerts

> Operational procedures to be defined by service owner.

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| High HTTP 5xx rate | 5xx error rate exceeds threshold | critical | Check `continuumUniversalMerchantApi` connectivity; check I-tier process health |
| Merchant API latency spike | P99 latency exceeds threshold | warning | Check `continuumUniversalMerchantApi` health; check network connectivity |
| Proxy failure rate elevated | Proxy passthrough errors exceed threshold | warning | Check upstream booking service base URL availability |

## Common Operations

### Restart Service

Operational procedures to be defined by service owner. Follow I-tier platform standard restart procedures for Node.js web applications.

### Scale Up / Down

Operational procedures to be defined by service owner. Scaling is managed by the I-tier platform infrastructure. Contact the Continuum Platform infrastructure team for scaling adjustments.

### Database Operations

Not applicable. The Merchant Booking Tool is stateless and owns no data stores. Database operations (if needed) are performed against the upstream `continuumUniversalMerchantApi` booking service.

## Troubleshooting

### Booking pages fail to load

- **Symptoms**: Merchants see error pages or blank booking management screens
- **Cause**: `continuumUniversalMerchantApi` is unavailable or returning errors; `mbtMerchantApiClient` calls failing
- **Resolution**: Check `continuumUniversalMerchantApi` health status; verify `MERCHANT_API_BASE_URL` is correctly configured; review I-tier application logs for HTTP error responses from the booking service

### Proxy requests failing

- **Symptoms**: Write or update operations from merchant booking pages return errors
- **Cause**: `mbtProxyController` cannot reach the upstream booking service base URL; request/response normalization error
- **Resolution**: Verify upstream booking service base URL is reachable; check I-tier logs for proxy normalization errors under `/reservations/mbt/proxy/*`

### Google Calendar sync unavailable

- **Symptoms**: Merchants cannot connect or sync their Google Calendar
- **Cause**: Google OAuth integration failure; invalid or expired OAuth credentials
- **Resolution**: Check `GOOGLE_OAUTH_CLIENT_ID` and `GOOGLE_OAUTH_CLIENT_SECRET` configuration; verify Google OAuth 2.0 endpoint availability; review OAuth error responses in logs

### Inbenta support unavailable

- **Symptoms**: Embedded support knowledge base fails to load for merchants
- **Cause**: `mbtInbentaClient` cannot generate support tokens; Inbenta API unavailable or credentials invalid
- **Resolution**: Check `INBENTA_API_KEY` configuration; verify Inbenta API availability; review `mbtInbentaClient` error logs

### Layout not rendering

- **Symptoms**: Booking pages load without the merchant navigation shell or app context
- **Cause**: `continuumLayoutService` is unavailable or returning errors
- **Resolution**: Check `LAYOUT_SERVICE_URL` configuration; verify `continuumLayoutService` health; review I-tier layout rendering logs

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Merchant booking tool completely unavailable — all merchants cannot manage reservations | Immediate | Continuum Merchant Experience Team |
| P2 | Core booking features degraded (e.g., write operations failing, proxy errors) | 30 min | Continuum Merchant Experience Team |
| P3 | Minor feature unavailable (e.g., Google Calendar sync or Inbenta support down) | Next business day | Continuum Merchant Experience Team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `continuumUniversalMerchantApi` | Check booking service health endpoint; verify HTTP 200 from `MERCHANT_API_BASE_URL` | No fallback — booking data unavailable if API is down |
| `continuumLayoutService` | Check layout service health endpoint; verify HTTP 200 from `LAYOUT_SERVICE_URL` | Pages may render without merchant shell |
| `googleOAuth` | Verify Google OAuth 2.0 endpoint reachability | Google Calendar sync unavailable; core booking functions continue |
| Inbenta | Verify Inbenta API reachability and token generation | Embedded support unavailable; core booking functions continue |
