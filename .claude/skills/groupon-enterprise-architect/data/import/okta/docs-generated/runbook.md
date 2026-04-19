---
service: "okta"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| Status endpoint disabled (per `.service.yml`) | — | — | — |
| SolarWinds SEUM transaction monitor | http | Not specified | Not specified |

The service has its status endpoint explicitly disabled in `.service.yml`. Availability monitoring is performed via the SolarWinds SEUM dashboard: http://usch1swnet01.group.on/Orion/SEUM/TransactionDetails.aspx?NetObject=T:8

## Monitoring

### Metrics

> No evidence found in codebase. Specific metric names and alert thresholds are not defined in the repository snapshot.

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| SEUM Transaction Monitor | SolarWinds Orion | http://usch1swnet01.group.on/Orion/SEUM/TransactionDetails.aspx?NetObject=T:8 |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| SSO outage | SSO flow failures exceed threshold | critical | Page it-sys-engineering@groupon.pagerduty.com (PagerDuty service PQPJUWN) |
| Provisioning sync failure | SCIM provisioning events failing | critical | Page it-sys-engineering@groupon.pagerduty.com (PagerDuty service PQPJUWN) |

## Common Operations

### Restart Service

> Operational procedures to be defined by service owner. Contact the Okta team (syseng@groupon.com) or on-call via PagerDuty service PQPJUWN.

### Scale Up / Down

> Operational procedures to be defined by service owner.

### Database Operations

> Operational procedures to be defined by service owner. The `continuumOktaConfigStore` (PostgreSQL) holds tenant mappings, provisioning configuration, and connector metadata. Any migrations or backfills must be coordinated with the Okta team.

## Troubleshooting

### SSO Login Failure
- **Symptoms**: Users cannot log in via Okta SSO; OIDC token exchange fails or returns errors.
- **Cause**: Okta IdP unreachable, misconfigured OIDC client credentials, or expired tokens.
- **Resolution**: Verify connectivity to `https://groupon.okta.com`; check Okta admin console for application status; validate client credentials configuration in `continuumOktaConfigStore`.

### Provisioning Sync Not Applying
- **Symptoms**: User accounts not created or updated in Continuum after Okta provisioning events.
- **Cause**: SCIM callback from Okta not reaching the service, or `continuumUsersService` returning errors during sync.
- **Resolution**: Check Okta provisioning logs in the Okta admin console; verify `continuumUsersService` health; review `continuumOktaConfigStore` for correct tenant/connector configuration.

### Configuration Store Connectivity
- **Symptoms**: Service fails to start or returns errors resolving tenant mappings.
- **Cause**: `continuumOktaConfigStore` (PostgreSQL) is unreachable or credentials are invalid.
- **Resolution**: Verify database connectivity and credentials; check PostgreSQL service health.

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down — SSO and provisioning completely unavailable | Immediate | Okta team via PagerDuty PQPJUWN (it-sys-engineering@groupon.pagerduty.com); Slack: CHW6USSV9 |
| P2 | Degraded — partial provisioning failures or intermittent SSO errors | 30 min | Okta team via PagerDuty PQPJUWN |
| P3 | Minor impact — non-critical sync lag or configuration warnings | Next business day | Okta team email: syseng@groupon.com |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `oktaIdp` (Okta IdP) | Verify `https://groupon.okta.com` responds to status/health endpoint; check Okta status page | SSO and provisioning unavailable; no fallback defined |
| `continuumUsersService` | Check internal service health endpoint | User profile updates queued or dropped; behavior not specified in codebase |
| `continuumOktaConfigStore` | PostgreSQL connectivity check | Service unable to resolve tenant configuration; operations fail |
