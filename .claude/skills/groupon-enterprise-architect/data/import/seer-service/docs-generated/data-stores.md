---
service: "seer-service"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumSeerServicePostgres"
    type: "postgresql"
    purpose: "Stores all ingested engineering metrics, reports, and integration data"
---

# Data Stores

## Overview

Seer Service owns a single PostgreSQL database that acts as the central store for all ingested engineering metrics. Data flows into it from seven external systems via scheduled Quartz jobs and manual API triggers. All reads serve REST API responses. No caches or secondary stores are used.

## Stores

### Seer Service Postgres (`continuumSeerServicePostgres`)

| Property | Value |
|----------|-------|
| Type | postgresql |
| Architecture ref | `continuumSeerServicePostgres` |
| Purpose | Stores Seer metrics, sprint reports, incident data, build records, deployment history, pull-request data, OpsGenie alerts, SonarQube metrics, and service metadata |
| Ownership | owned |
| Migrations path | Managed via `jtier-migrations` (PostgresMigrationBundle) and `jtier-quartz-postgres-migrations`; migration files reside under the standard JTier migrations directory |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `sprint_reports` | Stores sprint-level metrics for each Jira board | sprint ID, board ID, metrics |
| `incidents_info` | Stores GPROD incident records from Jira | `jira_key`, `summary`, `service_name`, `assignee`, `status`, `sev`, `resolution_at`, `created_at`, `environment` |
| `issue_metadata` | Stores Jira issue details | issue key, project, assignee, status, story points |
| `issue_assignee_changes` | Tracks assignee changes on Jira issues | issue key, previous assignee, new assignee, changed_at |
| `issue_status_changes` | Tracks status transitions on Jira issues | issue key, previous status, new status, changed_at |
| `issue_sprint_mappings` | Maps Jira issues to sprints | issue key, sprint ID |
| `issue_story_point_mappings` | Maps story-point values to issues over time | issue key, story points, recorded_at |
| `issue_time_logs` | Stores time-tracking logs for Jira issues | issue key, time spent |
| `issue_estimated_time_logs` | Stores estimated time for Jira issues | issue key, original estimate |
| `project_board_mappings` | Maps Jira projects to boards | project key, board ID |
| `board_sprint_mappings` | Maps boards to their sprints | board ID, sprint ID, sprint name |
| `sprint_custom_reports` | Custom sprint report data | board ID, sprint ID, custom fields |
| `jenkins_build_info` | Stores Jenkins build records per service | service name, build number, duration, status, build_at |
| `pull_request_info` | Stores GitHub PR records | PR ID, repo, service name, state, created_at, merged_at, author |
| `deployment_info` | Stores Deploybot deployment records | service name, environment, version, deployed_at |
| `service_info` | Stores service ownership data from Service Portal | service name, owner, team |
| `sonarqube_service_info` | Stores SonarQube quality metrics per project | project key, metric name, metric value |
| `opsgenie_team_info` | Stores OpsGenie team records | team ID, team name |
| `opsgenie_member_info` | Stores OpsGenie team-member records | member ID, team ID, username |
| `opsgenie_alerts` | Stores OpsGenie alert records | alert ID, team ID, severity, created_at, closed_at |

#### Access Patterns

- **Read**: Point-in-time queries by date range (start/end date parameters on all report endpoints), by service name, by board/sprint ID, and by team ID. All reads go through JDBI DAO interfaces.
- **Write**: Upsert-style inserts from Quartz jobs and manual POST triggers. Incidents use `ON CONFLICT (jira_key) DO NOTHING` to avoid duplicates. Other tables follow similar insert-if-not-exists patterns managed per DAO.
- **Indexes**: Specific index definitions are not visible in source; Quartz metadata tables use standard indexes provided by `jtier-quartz-postgres-migrations`.

## Caches

> No evidence found in codebase. No caching layer is used.

## Data Flows

All data enters the PostgreSQL store from external systems:

- **Jira** → sprint reports, issue metadata, assignee/status/story-point/time changes, incidents, project-board mappings, board-sprint mappings
- **Jenkins** → build records per service
- **GitHub Enterprise** → pull-request records enriched with service ownership from Service Portal
- **Deploybot** → deployment records per service
- **OpsGenie** → team, member, and alert records
- **SonarQube** → quality metric records per project
- **Service Portal** → service ownership and metadata

Data flows out via the REST API to downstream consumers. No CDC, replication, or ETL pipelines originate from this store.
