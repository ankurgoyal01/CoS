---
service: "proxykong"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest]
auth_mechanisms: [okta-headers, cookie]
---

# API Surface

## Overview

ProxyKong exposes an HTTP REST API consumed by its own browser UI. All mutation endpoints require Okta authentication, enforced by the `authBridge` component which inspects the `x-grpn-email` header (or the `proxyKong_email` cookie when the `enable_okta_cookie_user` feature flag is active). Read endpoints (GET) return JSON data from the locally mounted `api-proxy-config` config tools. Write endpoints (POST) orchestrate Jira ticket creation and GitHub pull request submission.

## Endpoints

### UI Routes

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/proxykong` | Serves the ProxyKong route management UI | Okta |
| GET | `/reporting` | Serves the Argus reporting UI | Okta |

### Route and Configuration Query Endpoints

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/getRouteGroupDestinations` | Returns route group destinations for the specified env and region | Okta |
| GET | `/getRouteGroups` | Returns route groups for a given destination, env, and region | Okta |
| GET | `/getRoutes` | Returns routes for a given destination, route group, env, and region | Okta |
| GET | `/getDestinations` | Returns all destinations for the specified env and region | Okta |
| GET | `/getExperiments` | Returns active experiments for the specified env and region | Okta |
| GET | `/getDestinationPreview` | Returns a destination preview (config snapshot) for a given destination | Okta |
| GET | `/doesDestinationVipExist` | Checks whether a given destination VIP exists in env/region | Okta |
| GET | `/doesDestinationExist` | Checks whether a destination name is registered | Okta |
| GET | `/doesRouteGroupExist` | Checks whether a route group ID is registered | Okta |
| POST | `/doRoutesExist` | Checks whether specified routes already exist for a destination/route group | Okta |
| GET | `/validateServiceName` | Probes the Hybrid Boundary to verify a service name is reachable | None |
| GET | `/getServiceInfoFromServicePortal` | Fetches service metadata from Service Portal by service name | None |

### Route Mutation Endpoints

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/proxyRouteDo` | Creates Jira ticket(s) and GitHub PR for adding new routes | Okta |
| POST | `/promoteRoute` | Creates Jira ticket(s) and GitHub PR for promoting an existing route | Okta |
| POST | `/removeRoute` | Creates Jira ticket(s) and GitHub PR for deleting routes | Okta |
| POST | `/cleanExperiments` | Creates a GitHub PR to delete specified experiments from config | Okta |

### Reporting Endpoints

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/retrieveRobinReport` | Queries Argus performance data for a service/date range/colo/env | Okta |
| POST | `/sendEmail` | Sends a performance report email via the Robin library | Okta |

## Request/Response Patterns

### Common headers

All mutation and query endpoints require the following Okta identity headers to be present (injected by the Groupon network/VPN):

- `x-grpn-email` — authenticated user email (required for auth check)
- `x-grpn-username` — authenticated user's username
- `x-grpn-firstname` — first name
- `x-grpn-lastname` — last name
- `x-grpn-groups` — group memberships
- `x-grpn-samaccountname` — SAM account name

Alternatively, when the `enable_okta_cookie_user` feature flag is set, the cookies `proxyKong_email` and `proxyKong_username` are used.

### Error format

Authentication failures return HTTP `401` with a JSON body: `{ "err": "Missing Okta authentication info" }`. Application-level errors are returned as JSON with the caught exception message.

### Pagination

> No evidence found in codebase. Endpoints return complete result sets without pagination.

## Rate Limits

> No rate limiting configured. This is an internal tool accessed over VPN.

## Versioning

No API versioning strategy is applied. All endpoints are served at the root path without version prefixes.

## OpenAPI / Schema References

OpenAPI-style route declarations exist in:
- `modules/proxyroutes/open-api.js` — proxyroutes module endpoint definitions
- `modules/reporting/open-api.js` — reporting module endpoint definitions

These files use the iTier `x-route-to` convention to map paths to action handlers.
