---
service: "jira"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumJiraDatabase"
    type: "mysql"
    purpose: "Primary relational database for issues, users, workflows, and configuration"
---

# Data Stores

## Overview

Jira owns a single primary MySQL database (`jiranewdb`) hosted at `jira-db-master-vip.snc1` in the `snc1` data center. All application state — including issues, projects, users, workflows, attachments metadata, and plugin configuration — is persisted in this database. No separate cache tier (e.g., Redis, Memcached) is configured; Jira uses EHCache (in-process) for internal caching. The database is managed by DaaS MySQL (`daas_mysql`).

## Stores

### Jira MySQL Database (`continuumJiraDatabase`)

| Property | Value |
|----------|-------|
| Type | MySQL |
| Architecture ref | `continuumJiraDatabase` |
| Purpose | Primary relational store for all Jira application data |
| Ownership | owned |
| Migrations path | Managed by Jira Server upgrade tasks (in-process) |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `jiraissue` | Stores all issues (bugs, tasks, stories, etc.) | issue key, summary, status, assignee, reporter, project, created/updated timestamps |
| `project` | Project definitions and metadata | project key, name, lead, workflow scheme |
| `cwd_user` | User accounts (Crowd Embedded directory) | username, email, display name, `directory_id` (=1 for production) |
| `workflowscheme` | Workflow-to-project mappings | workflow name, project, issue type |
| `jiraworkflows` | Workflow XML definitions | workflow name, descriptor (XML) |
| `propertyentry` | Key-value configuration store (EntityProperty) | entity name, key, value |

#### Access Patterns

- **Read**: All Jira read operations (issue search via JQL, user lookups, project listing) go directly to the MySQL database via OFBiz entity engine over JDBC. Search queries may also hit the Lucene index (internal, on-disk).
- **Write**: Issue creation, updates, transitions, comments, and user provisioning all write to MySQL via JDBC. Connection pool configured with min/max size of 20 connections, max wait 30,000 ms, abandoned connection timeout 300 s.
- **Indexes**: Not inspectable from the source evidence; managed by Jira Server upgrade tasks. Lucene full-text index maintained separately by `DefaultIndexManager` in the Jira home directory.

#### Connection Details (from `sys_config/dbconfig.xml`)

| Parameter | Value |
|-----------|-------|
| JDBC URL | `jdbc:mysql://jira-db-master-vip.snc1:3306/jiranewdb?useUnicode=true&characterEncoding=UTF8&sessionVariables=storage_engine=InnoDB` |
| Driver | `com.mysql.jdbc.Driver` |
| Username | `jirauser` |
| Pool min/max | 20 / 20 |
| Max wait | 30,000 ms |
| Validation query | `select 1` |
| Storage engine | InnoDB |

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| EHCache (internal) | In-memory | Jira application-level caching (user sessions, project configuration, permission schemes) | Managed by Jira internals |

## Data Flows

All data flows are synchronous JDBC reads and writes between `continuumJiraService` and `continuumJiraDatabase`. There is no CDC, ETL pipeline, or replication visible in the source evidence. Lucene index updates are triggered in-process after write operations by `DefaultIndexManager`.
