---
service: "pingdom"
title: Overview
generated: "2026-03-03"
type: overview
domain: "SRE / Monitoring"
platform: "Continuum"
team: "pingdom"
status: active
tech_stack:
  language: "Not applicable"
  language_version: "Not applicable"
  framework: "Not applicable"
  framework_version: "Not applicable"
  runtime: "Not applicable"
  runtime_version: "Not applicable"
  build_tool: "Not applicable"
  package_manager: "Not applicable"
---

# Pingdom Overview

## Purpose

Pingdom is Groupon's external uptime monitoring integration entry point within the Continuum platform. It acts as a service metadata and operational integration endpoint that registers Groupon's presence in the Pingdom SaaS platform, maintaining service ownership records and providing SRE workflows with validated Pingdom status and dashboard links. The service exists to give internal tooling (such as the `ein_project` ProdCAT portal and the `tdo-team` shift-report cron) a stable, federated reference for Pingdom check ownership and status URLs.

## Scope

### In scope

- Maintaining and publishing service metadata for Pingdom ownership in internal operational tooling
- Resolving and validating Pingdom status and dashboard links for service definitions
- Providing the authoritative SRE contact point (`pingdom@groupon.com`) and PagerDuty integration (`P45XDA0`)
- Supplying the canonical status dashboard URL (`https://status.pingdom.com/`) to consuming systems
- Registering SRE channels (Slack `CDVLKLM4K`, PagerDuty `P45XDA0`) associated with Pingdom monitoring

### Out of scope

- Running Pingdom uptime checks directly (executed by the Pingdom SaaS platform)
- Collecting and storing uptime metrics (handled by `ein_project` / ProdCAT portal)
- Generating shift reports from Pingdom API data (handled by `tdo-team` pingdom-shift-report cron job)
- Sending JSM uptime alerts based on check results (handled by `ein_project` uptime_alert task)

## Domain Context

- **Business domain**: SRE / Monitoring
- **Platform**: Continuum
- **Upstream consumers**: Internal operational tooling including `ein_project` (ProdCAT portal), `tdo-team` shift-report cron job, and Groupon service-portal operational review workflows
- **Downstream dependencies**: Pingdom SaaS API (`https://api.pingdom.com/api/2.1`) — reads status and service-health context over HTTPS

## Stakeholders

| Role | Description |
|------|-------------|
| Team Owner | coaustin — primary service owner registered in `.service.yml` |
| Team Member | psoncek — registered team member |
| SRE On-Call | pingdom@groupon.com mailing list — SRE notification target |
| IMOC Team | Incident Management On-Call team — receives JSM alerts for services below uptime threshold |

## Tech Stack

### Core

> No evidence found in codebase. The Pingdom entry is a service metadata / SaaS integration endpoint with no application runtime of its own. All implementation is in consuming services (`ein_project`, `tdo-team`).

### Key Libraries

> No evidence found in codebase. The Pingdom service registry entry does not contain application source code. Key libraries used by integrating services (e.g., `toolbox.modules.pingdom.PD` Python client used by `ein_project`) belong to those services' own dependency manifests.
