---
service: "openvpn-config"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest]
auth_mechanisms: [oauth2]
---

# API Surface

## Overview

OpenVPN Config Automation does not expose its own HTTP API. It acts exclusively as a client to the OpenVPN Cloud Connexa REST API (`/api/beta/*`). All operations — entity listing, creation, and deletion — are performed by the Python scripts against the Cloud Connexa API using OAuth 2.0 client credentials. The API surface documented here describes the Cloud Connexa endpoints that the automation scripts call.

## Endpoints

### Authentication

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/api/beta/oauth/token` | Obtain Bearer access token using client credentials | HTTP Basic (client_id / client_secret) |

### Networks

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/api/beta/networks/page?page={n}&size={s}` | List networks with pagination | Bearer token |
| POST | `/api/beta/networks` | Create a new network with connectors and initial routes | Bearer token |
| POST | `/api/beta/networks/{network_id}/routes` | Add additional routes to an existing network | Bearer token |

### Applications

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/api/beta/applications/page?networkItemType=NETWORK&page={n}&size={s}` | List applications with pagination | Bearer token |
| POST | `/api/beta/applications/bulk?networkItemId={id}&networkItemType=NETWORK` | Bulk-create applications under a network (chunks of 100) | Bearer token |

### IP Services

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/api/beta/ip-services/page?networkItemType=NETWORK&page={n}&size={s}` | List IP services with pagination | Bearer token |
| POST | `/api/beta/ip-services/bulk?networkItemId={id}&networkItemType=NETWORK` | Bulk-create IP services under a network | Bearer token |

### User Groups

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/api/beta/user-groups/page?networkItemType=NETWORK&page={n}&size={s}` | List user groups with pagination | Bearer token |

### Users

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/api/beta/users/page?networkItemType=NETWORK&page={n}&size={s}` | List users with pagination | Bearer token |
| DELETE | `/api/beta/users/{user_id}` | Delete a user by ID | Bearer token |

### Access Groups

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/api/beta/access-groups/page?page={n}&size={s}` | List access groups with pagination | Bearer token |
| POST | `/api/beta/access-groups` | Create a new access group | Bearer token |
| POST | `/api/beta/access-groups/{group_id}/destination` | Add destination entries to an existing access group (chunks of 100) | Bearer token |

## Request/Response Patterns

### Common headers

- `Authorization: Bearer <access_token>` — required on all API calls after token acquisition
- `Content-Type: application/json` — set automatically by `requests` library when `json=` kwarg is used

### Error format

The Cloud Connexa API returns standard HTTP error status codes. The `make_api_call` wrapper in `openvpn_api.py` calls `response.raise_for_status()` on non-429 errors and prints the request args, request body, response headers, and response text to stderr before re-raising.

### Pagination

All list operations use page-based pagination via query parameters:
- `page` — zero-based page index
- `size` — number of items per page (default 1000 as used by automation scripts)

The response envelope contains `content` (array of entities) and `totalPages`. The `list_entities` helper fetches page 0, reads `totalPages`, then iterates pages 1 through `totalPages - 1`.

## Rate Limits

| Tier | Limit | Window |
|------|-------|--------|
| Cloud Connexa API | As reported by response header `x-ratelimit-replenish-time` | Per response (HTTP 429) |

When a `429 Too Many Requests` response is received, the automation sleeps for the number of seconds given in the `x-ratelimit-replenish-time` response header before retrying the same request.

## Versioning

The Cloud Connexa API is versioned via URL path prefix `/api/beta/`. All automation scripts use this beta version exclusively, as evidenced throughout `openvpn_api.py`, `export_backup.py`, `restore_backup.py`, and `delete_user.py`.

## OpenAPI / Schema References

> No evidence found in codebase. OpenVPN Cloud Connexa API schema is maintained by OpenVPN Inc. and is not bundled in this repository.
