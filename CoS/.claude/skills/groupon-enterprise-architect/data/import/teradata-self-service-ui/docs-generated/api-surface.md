---
service: "teradata-self-service-ui"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest]
auth_mechanisms: [cookie, header]
---

# API Surface

## Overview

The Teradata Self Service UI is a pure frontend application. It does not expose any server-side API of its own. All REST calls visible in the browser originate from the Vue.js SPA and are reverse-proxied by Nginx to the `teradata-self-service-api` backend. The endpoint paths listed below are the paths the SPA calls (and that Nginx proxies); they are defined in the backend service, not this repository.

The UI also exposes two Nginx-handled paths directly:

- `GET /grpn/healthcheck` — returns HTTP 200 `"ok\n"` (used by Kubernetes liveness/readiness probes)
- All other paths fall through to `index.html` (SPA history-mode routing)

## Endpoints

### Proxied to `teradata-self-service-api` (via Nginx `/api/` location)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/api/v1/users/:userName` | Fetch user profile (display name, email, manager) | Cookie `tss-user` + `user-id` header |
| `GET` | `/api/v1/configuration` | Fetch global app configuration (password expiry, lock duration, Jira base URL) | Cookie `tss-user` + `user-id` header |
| `GET` | `/api/v1/accounts` | List all Teradata accounts for the authenticated user (personal + managed service accounts) | Cookie `tss-user` + `user-id` header |
| `POST` | `/api/v1/accounts/:userName` | Request creation of a new Teradata account for the given user | Cookie `tss-user` + `user-id` header |
| `PUT` | `/api/v1/accounts/:accountName/credentials` | Update (reset) the password for a Teradata account | Cookie `tss-user` + `user-id` header |
| `GET` | `/api/v1/requests` | List all account requests visible to the authenticated user (pending approvals + history) | Cookie `tss-user` + `user-id` header |
| `GET` | `/api/v1/requests/:requestId` | Fetch a single request by ID | Cookie `tss-user` + `user-id` header |
| `PUT` | `/api/v1/requests/:requestId/approvals` | Approve or decline a pending account creation request | Cookie `tss-user` + `user-id` header |
| `GET` | `/api/v1/healthcheck` | Backend health check (used by MSW mock; not directly surfaced in UI) | None |

### Nginx-served directly

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/grpn/healthcheck` | Kubernetes liveness/readiness health check; returns `200 ok` | None |
| `GET` | `/*` | Serves `index.html` for all SPA routes | SSO headers injected by upstream proxy |

## Request/Response Patterns

### Common headers

- `user-id`: Injected by the Axios API client from the `tss-user` cookie value. This identifies the authenticated user to the backend.
- `X-GRPN-USERNAME`, `X-GRPN-EMAIL`, `X-GRPN-FIRSTNAME`, `X-GRPN-LASTNAME`: Injected by the upstream corporate SSO proxy. Nginx reads these and writes them as browser cookies (`tss-user`, `tss-email`, `tss-firstname`, `tss-lastname`).

### Error format

API errors from the backend are classified by the Axios response interceptor in `src/service/Api.js` into three categories:

```
{
  code: "NETWORK_ERROR" | "UNKNOWN_ERROR" | <http-status-code> | <backend-error-code>,
  msg: <human-readable message>,
  detail: <stringified error for GA logging>
}
```

Errors surface to the UI as dismissible notification snackbars. All error events are also forwarded to Google Analytics under the `exception` event category.

### Pagination

> No evidence found in codebase. All list endpoints (`/accounts`, `/requests`) return full result sets.

## Rate Limits

> No rate limiting configured at the UI layer. Rate limiting, if any, is enforced by `teradata-self-service-api`.

## Versioning

All proxied API paths use the `/api/v1/` prefix, indicating version 1 of the backend API. The versioning strategy is URL-path-based. No v2 paths are called by the production application (v2 mock fixtures exist for development purposes only).

## OpenAPI / Schema References

> No evidence found in codebase. OpenAPI specification, if it exists, is maintained in the `teradata-self-service-api` repository.
