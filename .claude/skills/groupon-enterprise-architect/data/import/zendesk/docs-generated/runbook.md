---
service: "zendesk"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| CheckMK GSS Zendesk Health Dashboard | http | Configured in CheckMK | Configured in CheckMK |

- **Dashboard**: [https://checkmk-lvl3.groupondev.com/ber1_prod/check_mk/dashboard.py?name=gss_zd_health](https://checkmk-lvl3.groupondev.com/ber1_prod/check_mk/dashboard.py?name=gss_zd_health)
- **Status endpoint**: Disabled (declared `disabled: true` in `.service.yml`)

## Monitoring

### Metrics

> No evidence found in codebase of application-level metrics. Monitoring is provided by CheckMK and PagerDuty integrations managed by the GSS team.

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| GSS Zendesk Health | CheckMK | [https://checkmk-lvl3.groupondev.com/ber1_prod/check_mk/dashboard.py?name=gss_zd_health](https://checkmk-lvl3.groupondev.com/ber1_prod/check_mk/dashboard.py?name=gss_zd_health) |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Zendesk service degradation | Zendesk API unavailable or returning errors | critical | Page GSS on-call via PagerDuty |
| Salesforce sync failure | CRM sync between Zendesk and Salesforce breaks | warning | Investigate Salesforce connector in Zendesk admin; page GSS on-call |

- **PagerDuty service**: [https://groupon.pagerduty.com/services/PN9TCKJ](https://groupon.pagerduty.com/services/PN9TCKJ)
- **PagerDuty notify**: gss-dev@groupon.pagerduty.com
- **Slack channel**: CFED5CCSV
- **Google Chat space**: AAAArQs1V3g

## Common Operations

### Restart Service

> Not applicable. Zendesk is a SaaS platform. There is no Groupon-managed process to restart. If Zendesk is unresponsive, verify Zendesk's status page and contact Zendesk support.

### Scale Up / Down

> Not applicable. Zendesk is a SaaS platform. Scaling is managed by Zendesk. For capacity concerns (e.g., agent seat limits, API rate limits), contact the GSS team to adjust the Zendesk account tier.

### Database Operations

> Not applicable. Zendesk manages all data persistence. Groupon has no direct database access.

## Troubleshooting

### Zendesk API Unavailable
- **Symptoms**: Internal Groupon systems fail to create or retrieve support tickets; GSS agent workflows stall
- **Cause**: Zendesk SaaS outage, expired API credentials, or network connectivity issue between Groupon and Zendesk
- **Resolution**: Check Zendesk status page; verify API credentials are valid in Zendesk admin; check GSS Zendesk Health dashboard; escalate to Zendesk support if SaaS outage confirmed

### Salesforce Sync Failure
- **Symptoms**: Salesforce CRM records do not reflect current Zendesk ticket status; agents report data discrepancy
- **Cause**: Zendesk-Salesforce connector misconfigured or Salesforce API unavailable
- **Resolution**: Review Zendesk's Salesforce integration settings in Zendesk admin; verify Salesforce connectivity; page GSS on-call if sync is severely lagged

### OgWall Identity Integration Failure
- **Symptoms**: Zendesk support workflows fail to resolve user identity; ticket creation fails for specific users
- **Cause**: OgWall service (`continuumOgwallService`) degraded or returning errors for user lookup
- **Resolution**: Verify OgWall health; check OgWall runbook; page relevant on-call if OgWall is down

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Zendesk completely unavailable — no support tickets can be created or managed | Immediate | GSS on-call via PagerDuty (gss-dev@groupon.pagerduty.com) |
| P2 | Zendesk degraded — partial ticket creation failures or Salesforce sync broken | 30 min | GSS on-call via PagerDuty |
| P3 | Minor impact — individual workflow issues, non-critical sync delays | Next business day | GSS team via email (gss@groupon.com) |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| Salesforce | Verify sync status in Zendesk admin connector settings | Tickets remain in Zendesk; CRM records may be stale |
| OgWall (`continuumOgwallService`) | Check OgWall service health endpoint | Support workflows requiring user identity may be degraded |
| Cyclops | Check Cyclops service health | Tooling integration degraded; core ticketing unaffected |
| Global Support Systems | Check GSS service health | Agent workflows using GSS integration may be degraded |

> Further operational procedures are maintained by the GSS team. See the owners manual at [https://confluence.groupondev.com/display/GSS/Owners+Manual+-+Zendesk](https://confluence.groupondev.com/display/GSS/Owners+Manual+-+Zendesk) and the ORR document at [https://docs.google.com/document/d/1mDoR2QY5zt56Q5h-Meo7cnDduBOctpJ4UTmgz54FYak/edit](https://docs.google.com/document/d/1mDoR2QY5zt56Q5h-Meo7cnDduBOctpJ4UTmgz54FYak/edit).
