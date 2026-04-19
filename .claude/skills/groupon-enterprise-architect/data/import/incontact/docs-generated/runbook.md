---
service: "incontact"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

> No evidence found in codebase.

The `.service.yml` declares `status_endpoint.disabled: true`, indicating no programmatic health check endpoint is exposed by this service. Health of the InContact SaaS platform is determined through the vendor's own status page and the SRE on-call routing below.

## Monitoring

### Metrics

> No evidence found in codebase.

No metrics instrumentation is present in this repository. Monitoring of the InContact SaaS platform is vendor-managed.

### Dashboards

> No evidence found in codebase.

Operational procedures to be defined by service owner.

### Alerts

> No evidence found in codebase.

SRE alerts are routed to `gss-dev@groupon.pagerduty.com` via PagerDuty service PN9TCKJ.

## Common Operations

### Restart Service

> Not applicable — InContact is a SaaS platform. There is no Groupon-managed process to restart. For platform issues, contact NICE inContact vendor support and escalate through the GSS team (gss@groupon.com).

### Scale Up / Down

> Not applicable — InContact is a SaaS platform scaled by the vendor under the Groupon SaaS agreement.

### Database Operations

> Not applicable — InContact does not own any Groupon-managed data stores.

## Troubleshooting

### InContact Platform Unavailable
- **Symptoms**: GSS agents unable to log in to InContact agent desktop; inbound calls or chats not routing
- **Cause**: Vendor SaaS outage or network connectivity issue between Groupon and InContact
- **Resolution**: Check NICE inContact vendor status page; escalate to gss-dev@groupon.pagerduty.com (PagerDuty PN9TCKJ); contact NICE inContact vendor support if confirmed platform issue

### Agent Login Issues
- **Symptoms**: Individual agents cannot authenticate or see incorrect routing groups
- **Cause**: User provisioning or configuration issue within the InContact admin portal
- **Resolution**: GSS team administrator reviews InContact admin configuration; refer to Owners Manual at https://confluence.groupondev.com/display/GSS/Owners+Manual+-+InContact

### Integration with `global_support_systems` Degraded
- **Symptoms**: Support data not flowing between InContact and GSS systems
- **Cause**: Dependency disruption between `continuumIncontactService` and `global_support_systems`
- **Resolution**: Contact GSS team via Slack channel CFED5CCSV or Google Chat space AAAArQs1V3g; escalate via PagerDuty PN9TCKJ for P1/P2

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down — GSS agents cannot handle customer contacts | Immediate | gss-dev@groupon.pagerduty.com, PagerDuty PN9TCKJ |
| P2 | Degraded — partial contact centre capability loss | 30 min | GSS team Slack CFED5CCSV, PagerDuty PN9TCKJ |
| P3 | Minor impact — individual agent or feature issue | Next business day | gss@groupon.com |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| NICE InContact SaaS | Vendor status page; GSS admin portal login test | Escalate to vendor support; notify agents via alternative channels |
| `ogwall` | Check ogwall service health endpoints | Operational procedures to be defined by service owner |
| `global_support_systems` | Check global_support_systems service health | Operational procedures to be defined by service owner |

> Operational procedures beyond what is captured in `.service.yml` are to be defined by the service owner (flueck) and the GSS team. Reference documents: [Architecture doc](https://drive.google.com/file/d/1hogsBRetYJ2CU-cpiQVX4s26wnB21psS/view), [ORR](https://docs.google.com/document/d/1dTYLn-9erMy6XpWYGzm5YllmpkwHgHtvIq79xGESEfc/edit), [Owners Manual](https://confluence.groupondev.com/display/GSS/Owners+Manual+-+InContact).
