---
service: "jira"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 2
internal_count: 1
---

# Integrations

## Overview

Jira has two declared external dependencies (`okta` and `daas_mysql`) and one internal Continuum dependency (`apiProxy`). All user authentication is brokered through Okta/Gwall via the API proxy. The database is a managed MySQL service provided by DaaS. There are no outbound HTTP service calls from Jira to other internal microservices visible in the source evidence.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Okta | SSO (HTTPS header injection) | Identity provider; supplies `X-GRPN-SamAccountName` and `X-OpenID-Extras` headers via Gwall/`apiProxy` | yes | `apiProxy` (stub) |
| DaaS MySQL (`daas_mysql`) | JDBC/MySQL | Managed MySQL hosting for `jiranewdb` database | yes | `continuumJiraDatabase` |

### Okta Detail

- **Protocol**: SSO via HTTP header injection (not a direct OIDC/SAML call from Jira itself)
- **Base URL / SDK**: Okta provides identity upstream; Gwall injects identity headers into requests forwarded by `apiProxy`
- **Auth**: Headers `X-GRPN-SamAccountName` (username) and `X-OpenID-Extras` (email, firstname, lastname)
- **Purpose**: Provides authenticated user identity to Jira without a separate Jira login. Enables auto-provisioning of new users on first access.
- **Failure mode**: If headers are absent, `GwallAuthenticator` falls back to `JiraSeraphAuthenticator` (standard Jira login page)
- **Circuit breaker**: No — fallback is handled by null header detection in `GwallAuthenticator`

### DaaS MySQL Detail

- **Protocol**: JDBC over TCP (port 3306)
- **Base URL / SDK**: `jdbc:mysql://jira-db-master-vip.snc1:3306/jiranewdb`
- **Auth**: Username `jirauser` with password stored externally (blank in config file)
- **Purpose**: Persistent storage for all Jira application data
- **Failure mode**: Jira becomes unavailable; no read-only fallback configured
- **Circuit breaker**: No explicit circuit breaker; JDBC pool has abandoned connection detection (timeout 300 s)

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| `apiProxy` | HTTPS | Forwards all inbound requests to Jira with SSO identity headers attached | `apiProxy` (stub) |

## Consumed By

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| Groupon administrators and engineers | HTTPS (browser) | Issue tracking, project management, workflow operations |
| Automated tooling / CI systems | REST or SOAP over HTTPS | Programmatic issue creation, status updates, and queries |

> Upstream consumers beyond administrators are tracked in the central architecture model.

## Dependency Health

- **MySQL**: Validated via `select 1` query at pool creation and during idle eviction (every 300,000 ms). Abandoned connections removed after 300 s.
- **Okta/Gwall**: No health check from Jira's side. If `apiProxy` is unreachable, no requests reach Jira. GwallAuthenticator detects missing headers at the request level and falls back to standard login.
- **No circuit breakers** are implemented within Jira itself for any dependency.
