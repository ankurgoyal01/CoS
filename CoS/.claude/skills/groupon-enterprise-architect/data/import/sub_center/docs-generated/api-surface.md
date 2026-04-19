---
service: "sub_center"
title: API Surface
generated: "2026-03-03T00:00:00Z"
type: api-surface
protocols: [rest]
auth_mechanisms: [session]
---

# API Surface

## Overview

sub_center exposes HTTP endpoints that render subscription management pages and process unsubscribe actions. Consumers are end-user browsers arriving via email unsubscribe links or direct navigation. The service follows the I-Tier pattern: routes are defined by the HTTP Router component and handled by Keldor controllers, which invoke business logic handlers and return server-rendered HTML.

## Endpoints

### Subscription Center Pages

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/subscription-center` | Renders the subscription preferences management page | Session |
| GET | `/subscription-center/unsubscribe` | Renders the email unsubscribe confirmation page | Token / Session |
| POST | `/subscription-center/unsubscribe` | Processes an email unsubscribe action | Token / Session |
| GET | `/subscription-center/sms-unsubscribe` | Renders the SMS unsubscribe page | Token / Session |
| POST | `/subscription-center/sms-unsubscribe` | Processes an SMS unsubscribe action | Token / Session |
| POST | `/subscription-center/preferences` | Updates subscription channel preferences | Session |

> Exact route paths are inferred from the I-Tier routing pattern and DSL component model. Verify against the service's router configuration file.

## Request/Response Patterns

### Common headers

- Standard Groupon I-Tier request headers (user session, locale, device type)
- Unsubscribe token passed via query parameter on inbound email links

### Error format

> No evidence found in codebase. Error handling follows standard I-Tier / Express conventions; errors are rendered as HTML error pages.

### Pagination

> Not applicable. All endpoints return single-page HTML views.

## Rate Limits

> No rate limiting configured. Rate limiting for I-Tier services is managed at the infrastructure / load balancer layer.

## Versioning

No explicit versioning strategy. Routes are not versioned by path prefix. Updates are deployed as in-place replacements following standard Continuum deployment practices.

## OpenAPI / Schema References

> No evidence found in codebase. No OpenAPI spec, proto files, or GraphQL schema are present in the federated architecture module.
