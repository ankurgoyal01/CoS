---
service: "seo-admin-ui"
title: "SEO Deal Attributes"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "seo-deal-attributes"
flow_type: synchronous
trigger: "Operator manages SEO-specific attributes for a deal page"
participants:
  - "seoAdminUiItier"
  - "Deal Catalog (GAPI)"
  - "SEO Deal API"
  - "seo-deal-page library"
architecture_ref: "dynamic-seoAdminUiItier"
---

# SEO Deal Attributes

## Summary

This flow enables content operators to manage the SEO-specific attributes of deal pages on Groupon. The admin UI fetches deal metadata from the Deal Catalog via GraphQL, presents it alongside SEO attribute fields, and saves SEO-specific overrides (titles, descriptions, canonical hints) to the SEO Deal API. The `seo-deal-page` library handles page rendering logic for previewing how deal pages will appear to search engines.

## Trigger

- **Type**: user-action
- **Source**: Content operator opens or updates a deal in the SEO deals management screen
- **Frequency**: On demand

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| SEO Admin UI | Orchestrates the flow; renders the SEO deal management form | `seoAdminUiItier` |
| Deal Catalog (GAPI) | Provides deal metadata (title, category, pricing) via GraphQL | > No Structurizr ID in inventory. |
| SEO Deal API | Stores and retrieves SEO attribute overrides for deal pages | > No Structurizr ID in inventory. |
| seo-deal-page | Renders SEO deal page preview based on current attributes | `seoAdminUiItier` (internal library) |

## Steps

1. **Operator opens SEO deals screen**: Operator navigates to the SEO deals management section and selects a deal.
   - From: `Operator browser`
   - To: `seoAdminUiItier`
   - Protocol: REST / HTTP (I-Tier session authenticated)

2. **Fetch deal metadata**: seo-admin-ui queries Deal Catalog via GraphQL for the deal's title, category, pricing, and description.
   - From: `seoAdminUiItier`
   - To: `Deal Catalog (GAPI)`
   - Protocol: GraphQL / HTTP via `@grpn/graphql-gapi`

3. **Fetch existing SEO attributes**: seo-admin-ui queries SEO Deal API for any existing SEO attribute overrides for the deal.
   - From: `seoAdminUiItier`
   - To: `SEO Deal API`
   - Protocol: REST / HTTP

4. **Render management form**: seo-admin-ui merges deal metadata with SEO attributes and renders the edit form with a page preview via `seo-deal-page`.
   - From: `seoAdminUiItier`
   - To: `Operator browser`
   - Protocol: HTTP / HTML

5. **Operator submits SEO attribute changes**: Operator updates SEO title, description, or canonical hints and submits.
   - From: `Operator browser`
   - To: `seoAdminUiItier`
   - Protocol: REST / HTTP (I-Tier session authenticated)

6. **Save SEO attributes**: seo-admin-ui posts the updated SEO attribute values to the SEO Deal API.
   - From: `seoAdminUiItier`
   - To: `SEO Deal API`
   - Protocol: REST / HTTP

7. **Confirm to operator**: seo-admin-ui displays a success confirmation with updated attribute values.
   - From: `seoAdminUiItier`
   - To: `Operator browser`
   - Protocol: HTTP / HTML

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Deal Catalog (GAPI) unavailable | Log error; display error message | SEO deal form cannot load; operator retries |
| SEO Deal API save fails | Log error; surface error to operator | Attributes not saved; operator retries |
| GraphQL query returns null deal | Surface "deal not found" message | Operator verifies deal ID and retries |

## Sequence Diagram

```
Operator -> seoAdminUiItier: Open SEO deal management for deal ID
seoAdminUiItier -> DealCatalogGAPI: GraphQL query deal metadata
DealCatalogGAPI --> seoAdminUiItier: Deal title, category, pricing
seoAdminUiItier -> SEODealAPI: GET SEO attributes for deal ID
SEODealAPI --> seoAdminUiItier: Existing SEO overrides
seoAdminUiItier --> Operator: Render SEO deal form with preview
Operator -> seoAdminUiItier: Submit updated SEO attributes
seoAdminUiItier -> SEODealAPI: POST/PUT SEO attributes
SEODealAPI --> seoAdminUiItier: 200 OK
seoAdminUiItier --> Operator: Confirmation
```

## Related

- Architecture dynamic view: `dynamic-seoAdminUiItier`
- Related flows: [Landing Page Route CRUD](landing-page-route-crud.md), [Auto-Index Worker](auto-index-worker.md)
