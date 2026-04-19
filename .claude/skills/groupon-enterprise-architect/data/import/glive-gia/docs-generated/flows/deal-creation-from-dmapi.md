---
service: "glive-gia"
title: "Deal Creation from DMAPI"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "deal-creation-from-dmapi"
flow_type: synchronous
trigger: "Admin user initiates deal creation via the GIA multi-step wizard"
participants:
  - "continuumGliveGiaWebApp"
  - "continuumDealManagementApi"
  - "continuumGliveGiaMysqlDatabase"
  - "continuumCustomFieldsService"
architecture_ref: "dynamic-glive-gia-deal-creation"
---

# Deal Creation from DMAPI

## Summary

When a GrouponLive operations admin creates a new live event deal, GIA walks them through a multi-step wizard (powered by the `wicked` gem). At each step, the wizard fetches deal and product data from the Deal Management API, retrieves custom field definitions from the Custom Fields Service, and assembles a local deal record. On completion, the deal is persisted to MySQL in its initial draft state, ready for event and ticketing provider configuration.

## Trigger

- **Type**: user-action
- **Source**: GrouponLive operations admin accessing `/deals/new` in the GIA web UI
- **Frequency**: On-demand

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| GIA Web App | Hosts the wizard UI, orchestrates steps, calls external services | `continuumGliveGiaWebApp` |
| Deal Management API | Source of deal and product catalog data | `continuumDealManagementApi` |
| Custom Fields Service | Provides custom field definitions for deal configuration | `continuumCustomFieldsService` |
| GIA MySQL Database | Persists the new deal record on completion | `continuumGliveGiaMysqlDatabase` |

## Steps

1. **Admin initiates deal creation**: Admin navigates to `/deals/new`; `gliveGia_webControllers` renders the first wizard step
   - From: Admin browser
   - To: `continuumGliveGiaWebApp`
   - Protocol: REST (HTTP GET)

2. **Fetch deal data from DMAPI**: `gliveGia_repositories` calls `gliveGia_remoteClients` to retrieve deal or product data from the Deal Management API to pre-populate wizard fields
   - From: `continuumGliveGiaWebApp` (`gliveGia_repositories` -> `gliveGia_remoteClients`)
   - To: `continuumDealManagementApi`
   - Protocol: REST

3. **Fetch custom field definitions**: `gliveGia_remoteClients` calls the Custom Fields Service to retrieve field definitions applicable to live event deals
   - From: `continuumGliveGiaWebApp` (`gliveGia_remoteClients`)
   - To: `continuumCustomFieldsService`
   - Protocol: REST

4. **Map remote data to domain attributes**: `mappers` translate DMAPI and Custom Fields API responses into deal domain model attributes
   - From: `gliveGia_repositories`
   - To: `mappers`
   - Protocol: Direct (in-process)

5. **Admin completes each wizard step**: Admin fills in deal details across wizard steps and submits each step; controller validates and stores step data
   - From: Admin browser
   - To: `continuumGliveGiaWebApp` (`gliveGia_webControllers`)
   - Protocol: REST (HTTP POST/PATCH)

6. **Persist deal record**: On final wizard step submission, `businessServices` creates the deal via `domainModels` (ActiveRecord); deal is written to MySQL in `draft` state
   - From: `continuumGliveGiaWebApp` (`businessServices` -> `domainModels`)
   - To: `continuumGliveGiaMysqlDatabase`
   - Protocol: ActiveRecord / MySQL

7. **Render confirmation**: Controller redirects admin to the new deal's detail page
   - From: `continuumGliveGiaWebApp`
   - To: Admin browser
   - Protocol: HTTP 302 redirect

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| DMAPI unavailable | HTTP error returned by remote client; wizard step renders error message | Deal creation blocked; admin retries or contacts support |
| Custom Fields Service unavailable | HTTP error; wizard renders without custom fields or with error | Deal may be created without custom field values |
| MySQL write failure | ActiveRecord exception; Rails renders error response | Deal not persisted; admin sees error and can retry |
| Validation failure on wizard step | Rails model validation errors returned | Admin corrects input and resubmits step |

## Sequence Diagram

```
Admin -> GIA Web App: GET /deals/new (start wizard)
GIA Web App -> Deal Management API: GET /products/:id (fetch deal data)
Deal Management API --> GIA Web App: deal/product attributes
GIA Web App -> Custom Fields Service: GET /custom_fields (deal type)
Custom Fields Service --> GIA Web App: field definitions
GIA Web App -> Admin: Render wizard step with pre-populated fields
Admin -> GIA Web App: POST /deals (submit each wizard step)
GIA Web App -> GIA MySQL Database: INSERT deals (persist on final step)
GIA MySQL Database --> GIA Web App: deal record created
GIA Web App --> Admin: Redirect to deal detail page
```

## Related

- Architecture dynamic view: `dynamic-glive-gia-deal-creation`
- Related flows: [Event Management and Bulk Updates](event-management-and-bulk-updates.md), [Salesforce Deal Sync](salesforce-deal-sync.md)
