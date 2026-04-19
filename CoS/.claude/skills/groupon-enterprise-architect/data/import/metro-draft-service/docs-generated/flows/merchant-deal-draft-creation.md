---
service: "metro-draft-service"
title: "Merchant Deal Draft Creation"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "merchant-deal-draft-creation"
flow_type: synchronous
trigger: "HTTP POST /api/deals — caller submits deal draft payload"
participants:
  - "continuumMetroDraftService_dealsResource"
  - "continuumMetroDraftService_permissionFilter"
  - "continuumMetroDraftService_dealService"
  - "continuumMetroDraftService_dealStatusService"
  - "continuumMetroDraftService_dynamicPdsService"
  - "continuumMetroDraftService_historyEventService"
  - "continuumMetroDraftService_dealDao"
  - "continuumMetroDraftService_dealStatusDao"
  - "continuumMetroDraftService_historyDao"
  - "continuumMetroDraftService_editorActionPublisher"
  - "continuumMetroDraftDb"
  - "continuumMetroDraftMessageBus"
  - "continuumRbacService"
  - "continuumInferPdsService"
  - "continuumTaxonomyService"
  - "continuumGeoPlacesService"
architecture_ref: "dynamic-continuum-metro-draft-continuumMetroDraftService_dealService-deal-creation"
---

# Merchant Deal Draft Creation

## Summary

A caller (Metro internal tooling or merchant self-service portal) submits a new deal draft payload to Metro Draft Service. The service enforces permissions, validates and enriches the deal with dynamic pricing structure defaults and fine print, persists the draft to the primary PostgreSQL database, records an audit history event, and publishes an editor action event to MBus. The result is a persisted draft deal ready for subsequent editing and eventual publishing.

## Trigger

- **Type**: api-call
- **Source**: Metro internal tooling or merchant self-service portal calling `POST /api/deals`
- **Frequency**: On demand — per merchant deal creation request

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Deals Resource | Receives HTTP request; delegates to business logic | `continuumMetroDraftService_dealsResource` |
| Permission Filter | Intercepts request; validates caller permissions via RBAC | `continuumMetroDraftService_permissionFilter` |
| RBAC Service | Evaluates caller's role and permissions | `continuumRbacService` |
| Deal Service | Core draft creation logic; orchestrates enrichment and persistence | `continuumMetroDraftService_dealService` |
| Deal Status Service | Sets initial draft status and validates eligibility | `continuumMetroDraftService_dealStatusService` |
| Dynamic PDS Service | Generates pricing defaults and fine print for the deal | `continuumMetroDraftService_dynamicPdsService` |
| Infer PDS Service | Supplies pricing recommendations used by Dynamic PDS | `continuumInferPdsService` |
| Geo & Taxonomy Clients | Validate taxonomy classification and geo metadata | `continuumMetroDraftService_geoTaxonomyClients` |
| Taxonomy Service | Returns taxonomy metadata for deal classification | `continuumTaxonomyService` |
| GeoPlaces Service | Returns geo enrichment for merchant place | `continuumGeoPlacesService` |
| History Event Service | Builds and persists audit event; triggers MBus publish | `continuumMetroDraftService_historyEventService` |
| Deal DAO | Writes draft deal record to primary database | `continuumMetroDraftService_dealDao` |
| Deal Status DAO | Writes initial status to database | `continuumMetroDraftService_dealStatusDao` |
| History DAO | Persists audit event record | `continuumMetroDraftService_historyDao` |
| Editor Action Publisher | Publishes editor/recommendation action to MBus | `continuumMetroDraftService_editorActionPublisher` |
| Metro Draft DB | Stores the created draft deal, status, and audit record | `continuumMetroDraftDb` |
| Metro Draft Message Bus | Receives published editor action event | `continuumMetroDraftMessageBus` |

## Steps

1. **Receive draft creation request**: Deals Resource receives `POST /api/deals` with deal payload.
   - From: Caller (Metro tooling / self-service portal)
   - To: `continuumMetroDraftService_dealsResource`
   - Protocol: REST HTTP

2. **Enforce permissions**: Permission Filter evaluates caller permissions against RBAC Service; caches result in Redis.
   - From: `continuumMetroDraftService_permissionFilter`
   - To: `continuumRbacService`
   - Protocol: HTTP/Retrofit

3. **Delegate to Deal Service**: Deals Resource calls Deal Service with the validated request payload.
   - From: `continuumMetroDraftService_dealsResource`
   - To: `continuumMetroDraftService_dealService`
   - Protocol: Internal call (JAX-RS)

4. **Resolve merchant context**: Deal Service reads merchant record from Merchant DAO.
   - From: `continuumMetroDraftService_dealService`
   - To: `continuumMetroDraftService_merchantDao` -> `continuumMetroDraftDb`
   - Protocol: JDBI

5. **Generate pricing defaults and fine print**: Deal Service calls Dynamic PDS Service with deal type, merchant, and geo context.
   - From: `continuumMetroDraftService_dealService`
   - To: `continuumMetroDraftService_dynamicPdsService`
   - Protocol: Internal call

6. **Fetch pricing recommendations**: Dynamic PDS Service calls Infer PDS Service for price suggestions.
   - From: `continuumMetroDraftService_dynamicPdsService`
   - To: `continuumInferPdsService`
   - Protocol: HTTP/Retrofit

7. **Validate taxonomy and geo metadata**: Dynamic PDS Service calls Geo & Taxonomy Clients to validate deal classification and merchant location.
   - From: `continuumMetroDraftService_dynamicPdsService`
   - To: `continuumTaxonomyService`, `continuumGeoPlacesService`
   - Protocol: HTTP/Retrofit

8. **Load PDS configuration**: Dynamic PDS Service reads stored PDS config from PDS Config DAO.
   - From: `continuumMetroDraftService_dynamicPdsService`
   - To: `continuumMetroDraftService_pdsConfigDao` -> `continuumMetroDraftDb`
   - Protocol: JDBI

9. **Set initial deal status**: Deal Service calls Deal Status Service to validate and set the initial draft status.
   - From: `continuumMetroDraftService_dealService`
   - To: `continuumMetroDraftService_dealStatusService`
   - Protocol: Internal call

10. **Persist draft deal**: Deal DAO writes the new draft deal record (with enriched pricing) to the primary database.
    - From: `continuumMetroDraftService_dealService` -> `continuumMetroDraftService_dealDao`
    - To: `continuumMetroDraftDb`
    - Protocol: JDBI/PostgreSQL

11. **Persist initial status**: Deal Status DAO writes the initial status record.
    - From: `continuumMetroDraftService_dealStatusService` -> `continuumMetroDraftService_dealStatusDao`
    - To: `continuumMetroDraftDb`
    - Protocol: JDBI/PostgreSQL

12. **Publish audit event**: History Event Service builds audit event and delegates to Editor Action Publisher.
    - From: `continuumMetroDraftService_dealService` -> `continuumMetroDraftService_historyEventService`
    - To: `continuumMetroDraftService_historyDao` (persist) + `continuumMetroDraftService_editorActionPublisher` (publish)
    - Protocol: Internal call / JDBI

13. **Emit editor action to MBus**: Editor Action Publisher sends the event to Metro Draft Message Bus.
    - From: `continuumMetroDraftService_editorActionPublisher`
    - To: `continuumMetroDraftMessageBus`
    - Protocol: MBus

14. **Return created draft**: Deals Resource returns the created deal ID and draft state to the caller.
    - From: `continuumMetroDraftService_dealsResource`
    - To: Caller
    - Protocol: REST HTTP 201 Created

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Permission denied (RBAC returns unauthorized) | Permission Filter returns 403 immediately | Request rejected; no draft created |
| Invalid deal payload (validation failure) | Deal Service throws validation error | 400 returned; no draft persisted |
| Infer PDS Service unavailable | Dynamic PDS Service falls back to stored PDS config defaults | Draft created with default pricing (no AI-recommended prices) |
| Database write failure | JDBI exception propagates; transaction rolled back | 500 returned; no partial draft state persisted |
| MBus publish failure | Editor Action Publisher logs error; does not block draft creation response | Draft is persisted; editor action event may be lost |

## Sequence Diagram

```
Caller -> DealsResource: POST /api/deals
DealsResource -> PermissionFilter: enforce permissions
PermissionFilter -> RbacService: evaluate caller permissions
RbacService --> PermissionFilter: allowed
PermissionFilter --> DealsResource: permitted
DealsResource -> DealService: createDraft(payload)
DealService -> MerchantDao: read merchant record
MerchantDao --> DealService: merchant data
DealService -> DynamicPdsService: generateDefaults(dealType, merchant, geo)
DynamicPdsService -> InferPdsService: getPriceSuggestions()
InferPdsService --> DynamicPdsService: pricing recommendations
DynamicPdsService -> GeoTaxonomyClients: validateTaxonomy/Geo
GeoTaxonomyClients --> DynamicPdsService: taxonomy + geo metadata
DynamicPdsService -> PdsConfigDao: loadPdsConfig
PdsConfigDao --> DynamicPdsService: PDS config
DynamicPdsService --> DealService: enriched pricing defaults + fine print
DealService -> DealStatusService: setInitialStatus()
DealStatusService -> DealStatusDao: persistStatus
DealStatusDao --> DealStatusService: ok
DealService -> DealDao: persistDraft()
DealDao --> DealService: deal ID
DealService -> HistoryEventService: buildAuditEvent()
HistoryEventService -> HistoryDao: persistAudit
HistoryEventService -> EditorActionPublisher: publishEditorAction()
EditorActionPublisher -> MetroDraftMessageBus: editor-action event
DealService --> DealsResource: draft created (deal ID)
DealsResource --> Caller: 201 Created { dealId }
```

## Related

- Architecture dynamic view: `dynamic-continuum-metro-draft-continuumMetroDraftService_dealService-deal-creation`
- Related flows: [Deal Publishing Orchestration](deal-publishing-orchestration.md), [Dynamic Pricing and Structure Generation](dynamic-pricing-and-structure-generation.md)
