---
service: "tdo-team"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Incident Management / SRE Operations"
platform: "Continuum"
team: "Incident Management Team (TDO/IMOC)"
status: active
tech_stack:
  language: "Python"
  language_version: "3.12"
  framework: "click"
  framework_version: "*"
  runtime: "Python 3.12-alpine (Docker)"
  runtime_version: "3.12-alpine"
  build_tool: "Docker + Helm 3"
  package_manager: "pipenv"
---

# TDO Team Overview

## Purpose

The tdo-team service is a suite of Kubernetes CronJobs that automate the operational workflows of Groupon's Incident Management Team (TDO/IMOC). It reduces manual effort in incident review, Jira ticket housekeeping, on-call scheduling communications, and external monitoring reporting. Each cronjob runs on a defined schedule and interacts with Jira, Google Workspace, OpsGenie, Pingdom, Slack, and Google Chat to keep incident management processes running reliably.

## Scope

### In scope

- Automated creation and linking of Incident Review (IR) documents in Google Drive from resolved GPROD Jira incidents
- Scheduled Jira comment reminders for advisory action items approaching due dates (30-day interval)
- Scheduled Jira comment reminders for GPROD subtasks and Immediate Actions at 3-, 10-, and 30-day intervals
- Automated closure of GPROD logbook tickets open more than 10 days past planned start date, with a Jira comment explaining the closure
- Periodic Jira reminders for open SEV4 incidents that need status updates per SLA
- Weekend on-call schedule retrieval from OpsGenie and posting to Google Chat (IMOC space)
- Pingdom shift report generation every 4 hours, reporting monitor flaps, downtime, and response time anomalies to Google Chat
- IMOC out-of-office weekend notifications posted to the Production Google Chat space

### Out of scope

- Incident detection or alerting (handled by OpsGenie and Pingdom natively)
- Jira project configuration or workflow management
- Human escalation decisions during incidents
- Service reliability or uptime monitoring (handled by Pingdom and Wavefront)

## Domain Context

- **Business domain**: Incident Management / SRE Operations
- **Platform**: Continuum (Kubernetes on GCP)
- **Upstream consumers**: No upstream callers; all cronjobs are schedule-triggered
- **Downstream dependencies**: Jira (groupondev.atlassian.net), Google Drive/Docs API, Slack/Google Chat webhooks, OpsGenie API, Pingdom API v2.1, Service Portal (`http://service-portal.production.service`)

## Stakeholders

| Role | Description |
|------|-------------|
| Incident Management Team (TDO/IMOC) | Primary owners and consumers of all automated workflows |
| Service owners (all Groupon services) | Recipients of Jira comment reminders and IR document notifications |
| On-call engineers (IMOC) | Recipients of weekend on-call and shift-report notifications |
| SRE / Platform teams | Consumers of Pingdom shift reports |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Python | 3.12 | `Dockerfile`, `cronjobs/ir-automation/Pipfile` |
| CLI Framework | click | * (latest) | `cronjobs/ir-automation/Pipfile` |
| Runtime base | Python Alpine Docker image | 3.12-alpine | `Dockerfile` |
| Build tool | Docker + Helm 3 | cmf-generic-cron-job chart v3.89.0 | `.meta/deployment/cloud/scripts/deploy.sh` |
| Package manager | pipenv | latest | `Dockerfile`, `cronjobs/ir-automation/Pipfile` |
| Shell runtime (most cronjobs) | Bash | system | `cronjobs/*.sh` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| click | * | http-framework | CLI entry point for `tdo ir` command |
| google-api-python-client | * | auth | Google Drive and Docs API access |
| google-auth-httplib2 | * | auth | HTTP transport for Google OAuth |
| google-auth-oauthlib | * | auth | OAuth 2.0 flow for Google APIs |
| jira | * | db-client | Jira REST API client for incident ticket queries and updates |
| influxdb | * | metrics | InfluxDB client (referenced in Pipfile; metrics writes) |
| requests | latest | http-framework | HTTP calls to Slack webhook and Service Portal |
| httplib2 | latest | http-framework | HTTP transport layer, upgraded in Dockerfile |
| cryptography | latest | auth | Cryptographic support for authentication |
| jq | system | serialization | JSON parsing in Bash cronjob scripts |
| curl | system | http-framework | HTTP calls to Jira, Pingdom, OpsGenie, Service Portal, and Google Chat in Bash scripts |
