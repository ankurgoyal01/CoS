---
service: "jira"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: ["rest", "soap", "http-form"]
auth_mechanisms: ["sso-header", "session-cookie", "basic"]
---

# API Surface

## Overview

Jira Server exposes multiple API surfaces to consumers. The primary interface is the browser-based web UI served at `http://jira.groupondev.com`. Jira also provides a REST API (via Jersey/JAX-RS) and a legacy SOAP API. All access is brokered through the API proxy, which injects Gwall SSO identity headers. Consumers can also use HTTP Basic authentication by appending `?os_authType=basic` to any URL.

## Endpoints

### Web UI (WebWork Actions)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET/POST | `/secure/Dashboard.jspa` | Default dashboard | SSO session |
| GET/POST | `/secure/CreateIssue.jspa` | Issue creation form | SSO session |
| GET/POST | `/secure/Logout!default.jspa` | User logout | SSO session |
| GET/POST | `/secure/XsrfErrorAction.jspa` | XSRF error forward target | SSO session |
| GET | `/login.jsp` | Login page (redirect target for unauthenticated requests) | None |

### REST API

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET/POST | `/rest/api/*` | Jira REST API (issues, projects, users, workflows) | SSO session or Basic |
| GET | `/rest/gadget/*` | Gadget REST endpoints | SSO session |

### SOAP API

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/rpc/soap/jirasoapservice-v2` | Legacy SOAP RPC API | HTTP Basic or session |

## Request/Response Patterns

### Common headers

- `X-GRPN-SamAccountName`: Injected by `apiProxy`; contains the authenticated user's Active Directory `sAMAccountName`. Required for Gwall SSO path.
- `X-OpenID-Extras`: Injected by `apiProxy`; URL-encoded string containing `email`, `firstname`, `lastname`, and `username`. Used for new user provisioning.
- `Cookie: seraph.rememberme.cookie`: Remember-me cookie set on successful authentication; max age 1,209,600 seconds (2 weeks).
- `?os_authType=basic`: Query parameter to trigger HTTP Basic authentication instead of SSO.

### Error format

Standard Jira HTML error pages for web UI requests. REST API returns JSON error responses in the standard Atlassian REST format (`{"errorMessages":[], "errors":{}}`).

### Pagination

REST API uses offset-based pagination. JQL search results are limited by `jira.search.views.default.max=3000` and `jira.search.views.max.limit=3000` (configured in `sys_config/jira-config.properties`).

## Rate Limits

> No rate limiting configured in the source evidence. Traffic shaping, if any, is managed upstream by the API proxy.

## Versioning

The REST API uses URL path versioning (e.g., `/rest/api/2/`). The SOAP API is unversioned. There is no explicit versioning strategy beyond the Atlassian Jira release version.

## OpenAPI / Schema References

> No evidence found in codebase. Atlassian Jira's REST API is documented externally in Atlassian's public developer documentation.
