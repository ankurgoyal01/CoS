---
service: "content-pages"
title: API Surface
generated: "2026-03-03T00:00:00Z"
type: api-surface
protocols: [rest]
auth_mechanisms: [session]
---

# API Surface

## Overview

The Content Pages service exposes HTTP endpoints consumed by end-user browsers and Groupon's routing/CDN layer. Endpoints serve two categories: read-only CMS content pages rendered server-side, and form-based reporting workflows that accept `POST` submissions for incident and infringement reports. All endpoints return rendered HTML except reporting form POSTs, which process submissions and redirect or return confirmation responses.

## Endpoints

### CMS Content Pages

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/pages/{permalink}` | Serves a CMS-managed general content page by permalink | None |
| GET | `/legal/{permalink}` | Serves a legal document page by permalink | None |

### Privacy and Consent

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/privacy-hub` | Renders the Privacy Hub page with table of contents for all privacy-related legal documents | None |
| GET | `/cookie-consent` | Renders the Cookie Consent disclosure page | None |

### Incident Reporting

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/report_incident` | Renders the incident report submission form | None |
| POST | `/report_incident` | Accepts incident report form submission; handles image upload to Image Service and sends email notification via Rocketman | None |

### Infringement Reporting

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/report_infringement` | Renders the intellectual property infringement report form | None |
| POST | `/report_infringement` | Accepts infringement report form submission; sends notification email via Rocketman | None |

### Error Pages

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/404` | Renders the 404 Not Found error page | None |
| GET | `/500` | Renders the 500 Internal Server Error page | None |

## Request/Response Patterns

### Common headers

- `Accept-Language` — used by `itier-localization` to serve locale-appropriate content
- `Content-Type: multipart/form-data` — required for `POST /report_incident` when including image attachments
- `Content-Type: application/x-www-form-urlencoded` — for `POST /report_infringement`

### Error format

Standard iTier HTML error page rendering. HTTP error codes (400, 404, 500) are handled by `errorPagesController` and return rendered HTML error pages.

### Pagination

> Not applicable — all endpoints return single-page HTML documents.

## Rate Limits

> No rate limiting configured.

## Versioning

No URL-path versioning. The service follows the iTier deployment model — a single active version is deployed per environment.

## OpenAPI / Schema References

No standalone OpenAPI specification file was identified in the inventory. Route declarations follow standard iTier/Express conventions.
