---
service: "data_pipelines_glossary"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

> No evidence found in codebase. The `.service.yml` declares `sre.dashboards: n/a`, indicating no SRE dashboards are configured. As a static documentation site, no programmatic health check endpoints are defined.

## Monitoring

### Metrics

> No evidence found in codebase. Operational procedures to be defined by service owner.

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| SRE Dashboards | N/A | Not configured (`sre.dashboards: n/a` in `.service.yml`) |

### Alerts

> No evidence found in codebase. Operational procedures to be defined by service owner.

## Common Operations

### Restart Service

> Not applicable. The Data Pipelines Glossary is a static site and does not run as a live service process requiring restart procedures.

### Scale Up / Down

> Not applicable. Static sites do not require application-level scaling operations.

### Database Operations

> Not applicable. This service does not own any data stores.

## Troubleshooting

### Content is outdated or incorrect
- **Symptoms**: Engineers land on the glossary and find links to deprecated or renamed repositories.
- **Cause**: Content has not been updated to reflect repository changes.
- **Resolution**: Open a pull request against the repository to update the relevant navigation links or glossary entries. Contact the `grpn-gcloud-data-pipelines` team for content ownership questions.

### Glossary site is unreachable
- **Symptoms**: Engineers cannot access the static site URL.
- **Cause**: Hosting provider or CDN outage; deployment misconfiguration.
- **Resolution**: Check the hosting platform status. Deployment configuration is managed externally — contact the `grpn-gcloud-data-pipelines` platform team.

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Site completely unreachable, blocking all data pipeline discovery | Immediate | grpn-gcloud-data-pipelines team |
| P2 | Degraded navigation (broken links, missing sections) | 30 min | grpn-gcloud-data-pipelines team |
| P3 | Stale content, minor inaccuracies | Next business day | grpn-gcloud-data-pipelines team |

## Dependencies Health

> Not applicable. This service has no runtime dependencies.
