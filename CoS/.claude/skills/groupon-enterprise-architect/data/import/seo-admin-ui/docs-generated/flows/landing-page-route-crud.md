---
service: "seo-admin-ui"
title: "Landing Page Route CRUD"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "landing-page-route-crud"
flow_type: synchronous
trigger: "Operator creates, updates, or deletes a landing page route in the admin UI"
participants:
  - "seoAdminUiItier"
  - "LPAPI"
  - "memcachedSeoAdminUi"
architecture_ref: "dynamic-seoAdminUiItier"
---

# Landing Page Route CRUD

## Summary

This flow handles the full lifecycle management of landing page routes through the SEO Admin UI. Operators use the admin console to create new landing page routes, update existing route metadata, or remove routes that are no longer needed. All persistence is delegated to LPAPI (`@grpn/lpapi-client`); the admin UI acts as a thin orchestrator and display layer.

## Trigger

- **Type**: user-action
- **Source**: SEO engineer or content operator submits a form in the seo-admin-ui admin console
- **Frequency**: On demand

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| SEO Admin UI | Receives operator request; validates input; delegates to LPAPI | `seoAdminUiItier` |
| LPAPI | Owns landing page route data; executes the CRUD operation | > No Structurizr ID in inventory. |
| Memcached | Caches LPAPI list responses; cache invalidated on write operations | `memcachedSeoAdminUi` |

## Steps

1. **Receive operator request**: Operator submits a create/update/delete action from the landing pages screen.
   - From: `Operator browser`
   - To: `seoAdminUiItier`
   - Protocol: REST / HTTP (I-Tier session authenticated)

2. **Validate input**: seo-admin-ui validates the submitted route data (required fields, URL format).
   - From: `seoAdminUiItier`
   - To: `seoAdminUiItier` (internal)
   - Protocol: direct

3. **Call LPAPI**: seo-admin-ui invokes the appropriate LPAPI endpoint via `@grpn/lpapi-client` (POST to create, PUT to update, DELETE to remove).
   - From: `seoAdminUiItier`
   - To: `LPAPI`
   - Protocol: REST / HTTP

4. **Invalidate cache**: On successful write, Memcached cache entries for the landing page list are invalidated.
   - From: `seoAdminUiItier`
   - To: `memcachedSeoAdminUi`
   - Protocol: Memcached protocol

5. **Return result to operator**: seo-admin-ui renders the updated route list or a confirmation message to the operator.
   - From: `seoAdminUiItier`
   - To: `Operator browser`
   - Protocol: HTTP / HTML or JSON

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| LPAPI returns 4xx (validation error) | Surface error message to operator | Operator corrects input and resubmits |
| LPAPI returns 5xx (server error) | Log error; display generic error message | Operator retries; route not modified |
| LPAPI unreachable (network timeout) | Timeout after configured threshold | Operator notified; operation fails safe |
| Memcached unavailable | Skip cache invalidation; log warning | Stale data may be served temporarily; LPAPI remains authoritative |

## Sequence Diagram

```
Operator -> seoAdminUiItier: Submit route create/update/delete
seoAdminUiItier -> seoAdminUiItier: Validate input
seoAdminUiItier -> LPAPI: POST/PUT/DELETE /landing-pages[/:id]
LPAPI --> seoAdminUiItier: 200 OK / error response
seoAdminUiItier -> memcachedSeoAdminUi: Invalidate landing page list cache
memcachedSeoAdminUi --> seoAdminUiItier: OK
seoAdminUiItier --> Operator: Render result
```

## Related

- Architecture dynamic view: `dynamic-seoAdminUiItier`
- Related flows: [SEO Deal Attributes](seo-deal-attributes.md), [Page Route Auditing](page-route-auditing.md)
