---
service: "jira"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Developer Tooling / Operations"
platform: "Continuum"
team: "Systems Engineering"
status: active
tech_stack:
  language: "Java"
  language_version: ""
  framework: "Atlassian Jira Server"
  framework_version: "5.0.6 (classpath reference)"
  runtime: "Apache Tomcat (Catalina)"
  runtime_version: ""
  build_tool: "Manual (javac)"
  package_manager: ""
---

# Jira Overview

## Purpose

Groupon's internal Atlassian Jira Server instance provides issue tracking, workflow management, and project coordination for all engineering and operations teams. It is hosted at `jira.groupondev.com` within the `snc1` data center colo and integrates with Groupon's internal SSO system (Gwall) to authenticate users without requiring a separate login step. A custom Seraph authenticator (`GwallAuthenticator`) provisions new users on first login by reading identity headers injected by the API proxy.

## Scope

### In scope
- Issue creation, assignment, and lifecycle management (open, in-progress, resolved, closed)
- Workflow management via configurable Jira workflows (transitions, screens, validators)
- Project and board administration for engineering teams
- User provisioning via SSO header-driven auto-registration
- Legacy username mapping from a static file (`/var/groupon/jira/legacy_usernames.txt`)
- Search and filtering via JQL (Jira Query Language), with configurable result limits
- Outgoing and incoming email notifications
- SOAP and REST API access for integrations

### Out of scope
- Identity management and authentication credential storage (handled by Okta/Gwall)
- Database hosting (managed by DaaS MySQL / `daas_mysql`)
- Confluence, Bitbucket, or other Atlassian products (separate instances)
- User directory management (read from Crowd Embedded directory ID 1)

## Domain Context

- **Business domain**: Developer Tooling / Operations
- **Platform**: Continuum
- **Upstream consumers**: Groupon engineers, administrators, and automated tooling that call the Jira web UI or REST/SOAP API
- **Downstream dependencies**: MySQL database (`jira-db-master-vip.snc1:3306/jiranewdb`), Okta (identity/SSO via `daas_mysql`), API proxy (`apiProxy`) for SSO header injection

## Stakeholders

| Role | Description |
|------|-------------|
| Systems Engineering | Service owner and operator (`syseng@groupon.com`, `rwetterich`) |
| Operations and Compliance Tools team | Team page on Confluence |
| All Groupon engineers | Primary end-users of the issue tracker |
| SRE on-call | PagerDuty service `P2UCC96`, notified at `page-sa@groupon.pagerduty.com` |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | Not pinned | `jira_sso/GwallAuthenticator.java`, `sys_config/setenv.sh` |
| Framework | Atlassian Jira Server | 5.0.6 (classpath ref) | `jira_sso/README` |
| Runtime | Apache Tomcat (Catalina) | Not pinned | `sys_config/setenv.sh` (`CATALINA_HOME`, `CATALINA_BASE`, `CATALINA_PID`) |
| Build tool | Manual (`javac`) | N/A | `jira_sso/README` |
| Package manager | None (prebuilt Atlassian distribution) | | |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `com.atlassian.seraph` | Bundled with Jira | auth | Seraph security framework; base class for `GwallAuthenticator` |
| `com.atlassian.jira.security.login.JiraSeraphAuthenticator` | Bundled with Jira | auth | Standard Jira authenticator extended by `GwallAuthenticator` |
| `com.atlassian.jira.user.util.UserUtil` | Bundled with Jira | auth | User lookup and creation (`createUserNoNotification`) |
| `com.atlassian.crowd` | Embedded (directory ID 1) | auth | Embedded Crowd user directory |
| `org.apache.log4j` | Bundled with Jira | logging | Log4j 1.x logging; `JiraHomeAppender` for rotating file logs |
| `com.atlassian.jira.logging.JiraHomeAppender` | Bundled with Jira | logging | Jira-specific rolling file appender |
| `com.atlassian.jira.ofbiz.LoggingSQLInterceptor` | Bundled with Jira | orm | OFBiz ORM SQL logging interceptor |
| `org.ofbiz.core.entity` | Bundled with Jira | orm | OFBiz entity engine (Jira's ORM layer) |
| `com.atlassian.jira.jql` | Bundled with Jira | validation | JQL parser and resolver |
| `com.mysql.jdbc.Driver` | Bundled connector | db-client | MySQL JDBC connector (`jdbc:mysql://`) |
| `com.opensymphony` (WebWork/XWork) | Bundled with Jira | http-framework | WebWork action framework for Jira web layer |
| `com.sun.jersey` | Bundled with Jira | http-framework | JAX-RS (Jersey) REST framework |
| `net.sf.ehcache` | Bundled with Jira | state-management | EHCache for distributed/local caching |
| `org.apache.shindig` | Bundled with Jira | ui-framework | Gadget container (OpenSocial) for dashboard gadgets |
| `org.quartz` (via `com.atlassian.jira.scheduler`) | Bundled with Jira | scheduling | Background job scheduling (Quartz Scheduler) |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
