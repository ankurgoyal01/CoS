---
service: "jira"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumJiraService", "continuumJiraDatabase"]
---

# Architecture Context

## System Context

Jira is a container within the `continuumSystem` (Continuum Platform) software system. It is accessed by Groupon administrators and engineers through a browser-based web UI. All inbound HTTP requests pass through an API proxy (`apiProxy`) that injects SSO identity headers before forwarding to the Jira Server container. Jira writes and reads all persistent data (issues, users, workflows, configuration) through a dedicated MySQL database (`continuumJiraDatabase`) hosted at `jira-db-master-vip.snc1:3306`.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Jira Server | `continuumJiraService` | Application | Java, Atlassian Jira | 5.0.6 (classpath ref) | Atlassian Jira server with custom Gwall Seraph authenticator for SSO and user provisioning |
| Jira MySQL Database | `continuumJiraDatabase` | Database | MySQL | Not pinned | Primary relational database used by Jira for users, issues, and configuration |

## Components by Container

### Jira Server (`continuumJiraService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `gwallAuthenticator` | Reads `X-GRPN-SamAccountName` and `X-OpenID-Extras` SSO headers from each request; resolves or creates the authenticated principal | Java (extends `JiraSeraphAuthenticator`) |
| `jiraUserProvisioning` | Creates a new Jira user when the SSO username is not yet present in the database; maps legacy usernames from `/var/groupon/jira/legacy_usernames.txt` | Atlassian UserUtil API |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `administrator` | `continuumJiraService` | Uses Jira web application | HTTPS (browser) |
| `apiProxy` | `continuumJiraService` | Forwards authenticated requests with identity headers | HTTPS |
| `continuumJiraService` | `continuumJiraDatabase` | Reads and writes issues, users, and workflow data | JDBC/MySQL |
| `gwallAuthenticator` | `jiraUserProvisioning` | Looks up and provisions users from SSO headers | In-process method call |

## Architecture Diagram References

- Component: `components-continuum-jira-service`
