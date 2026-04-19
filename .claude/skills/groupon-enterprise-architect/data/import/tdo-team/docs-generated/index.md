---
service: "tdo-team"
title: "TDO Team Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers:
    - "continuumTdoTeamIrAutomationJob"
    - "continuumTdoTeamAdvisoryActionsRemindersJob"
    - "continuumTdoTeamSubtaskRemindersJob"
    - "continuumTdoTeamCloseLogbooksJob"
    - "continuumTdoTeamSev4RemindersJob"
    - "continuumTdoTeamWeekendOncallJob"
    - "continuumTdoTeamPingdomShiftReportJob"
    - "continuumTdoTeamImocOooWeekendJob"
tech_stack:
  language: "Python 3.12"
  framework: "click"
  runtime: "Python 3.12-alpine (Docker)"
---

# TDO Team Documentation

A collection of Kubernetes CronJobs that automate incident management operations for Groupon's Incident Management Team (TDO/IMOC), including Jira ticket lifecycle automation, Pingdom shift reporting, on-call notifications, and Google Workspace IR document creation.

## Contents

| Document | Description |
|----------|-------------|
| [Overview](overview.md) | Service identity, purpose, domain context, tech stack |
| [Architecture Context](architecture-context.md) | Containers, components, C4 references |
| [API Surface](api-surface.md) | Endpoints, contracts, protocols |
| [Events](events.md) | Async messages published and consumed |
| [Data Stores](data-stores.md) | Databases, caches, storage |
| [Integrations](integrations.md) | External and internal dependencies |
| [Configuration](configuration.md) | Environment, flags, secrets |
| [Flows](flows/index.md) | Process and flow documentation |
| [Deployment](deployment.md) | Infrastructure and environments |
| [Runbook](runbook.md) | Operations, monitoring, troubleshooting |

## Quick Facts

| Property | Value |
|----------|-------|
| Language | Python 3.12 |
| Framework | click (CLI framework), pipenv (package manager) |
| Runtime | Python 3.12-alpine (Docker) |
| Build tool | Docker + Helm 3 (cmf-generic-cron-job chart v3.89.0) |
| Platform | Continuum (Kubernetes CronJobs on GCP) |
| Domain | Incident Management / SRE Operations |
| Team | Incident Management Team (TDO/IMOC) |
