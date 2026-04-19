---
service: "partner-service"
title: "Deal Mapping Reconciliation"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "deal-mapping-reconciliation"
flow_type: scheduled
trigger: "Quartz scheduled job fires on configured interval"
participants:
  - "continuumPartnerService"
  - "continuumPartnerServicePostgres"
  - "continuumDealCatalogService"
  - "continuumDealManagementApi"
  - "continuumGeoPlacesService"
  - "messageBus"
architecture_ref: "dynamic-deal-mapping-reconciliation"
---

# Deal Mapping Reconciliation

## Summary

The deal mapping reconciliation flow is a batch process that compares the partner-to-deal and product-to-place mappings stored in `continuumPartnerServicePostgres` against the live state in Deal Catalog, Deal Management API, and Geo Places. Any drift detected — missing mappings, stale references, or mismatched division assignments — is corrected and the reconciliation result is published as a partner workflow event to MBus.

## Trigger

- **Type**: schedule
- **Source**: Quartz job managed by `partnerSvc_mbusAndScheduler`
- **Frequency**: Scheduled interval (specific cron expression managed in service configuration)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Partner Service | Batch orchestrator; reads local state, calls external systems, writes corrections | `continuumPartnerService` |
| Partner Service Postgres | Source of local mapping records; receives corrected state writes | `continuumPartnerServicePostgres` |
| Deal Catalog Service | Authoritative source for current deal catalog entity state | `continuumDealCatalogService` |
| Deal Management API | Authoritative source for current merchant and deal lifecycle state | `continuumDealManagementApi` |
| Geo Places Service | Authoritative source for geographic division and place metadata | `continuumGeoPlacesService` |
| MBus | Receives reconciliation summary and correction events | `messageBus` |

## Steps

1. **Quartz job fires**: Scheduled reconciliation job triggers the reconciliation use case.
   - From: `partnerSvc_mbusAndScheduler`
   - To: `partnerSvc_domainServices`
   - Protocol: direct

2. **Loads partner mapping records**: Reads all active partner mappings and product-place associations from local store.
   - From: `partnerSvc_domainServices`
   - To: `continuumPartnerServicePostgres`
   - Protocol: JDBC

3. **Fetches current deal catalog state**: Queries Deal Catalog Service for current deal entity state for each mapped deal ID.
   - From: `partnerSvc_integrationClients`
   - To: `continuumDealCatalogService`
   - Protocol: HTTP/JSON

4. **Fetches current deal lifecycle state**: Queries Deal Management API for current merchant and deal lifecycle status.
   - From: `partnerSvc_integrationClients`
   - To: `continuumDealManagementApi`
   - Protocol: HTTP/JSON

5. **Fetches geographic division and place metadata**: Queries Geo Places Service to validate product-to-place associations.
   - From: `partnerSvc_integrationClients`
   - To: `continuumGeoPlacesService`
   - Protocol: HTTP/JSON

6. **Identifies drift**: Compares fetched external state against local mapping records to detect missing, stale, or mismatched entries.
   - From: `partnerSvc_domainServices`
   - To: `partnerSvc_domainServices`
   - Protocol: direct (in-process comparison)

7. **Applies corrections**: Writes corrected mapping records and division assignments to the local store.
   - From: `partnerSvc_domainServices`
   - To: `continuumPartnerServicePostgres`
   - Protocol: JDBC

8. **Publishes reconciliation result event**: Emits a workflow event summarizing corrections applied or drift detected.
   - From: `partnerSvc_mbusAndScheduler`
   - To: `messageBus`
   - Protocol: JMS/STOMP

9. **Writes audit log entry**: Records reconciliation run and any corrections applied.
   - From: `partnerSvc_domainServices`
   - To: `continuumPartnerServicePostgres`
   - Protocol: JDBC

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Deal Catalog Service unavailable | Job aborts for that batch; scheduled retry on next run | Mapping corrections deferred |
| Deal Management API unavailable | Job aborts for that batch; scheduled retry on next run | Lifecycle corrections deferred |
| Geo Places Service unavailable | Place association validation skipped; partial reconciliation | Product-place drift not corrected in this run |
| Database write failure on correction | Exception logged; no partial correction committed | Local state unchanged; drift persists until next run |
| Partial batch failure | Successfully processed records committed; failed records retried next run | Incremental correction |

## Sequence Diagram

```
partnerSvc_mbusAndScheduler -> partnerSvc_domainServices: Trigger reconciliation job
partnerSvc_domainServices -> continuumPartnerServicePostgres: Load all active mappings
continuumPartnerServicePostgres --> partnerSvc_domainServices: Mapping records
partnerSvc_integrationClients -> continuumDealCatalogService: Fetch deal catalog state
continuumDealCatalogService --> partnerSvc_integrationClients: Deal entities
partnerSvc_integrationClients -> continuumDealManagementApi: Fetch deal lifecycle state
continuumDealManagementApi --> partnerSvc_integrationClients: Merchant/deal state
partnerSvc_integrationClients -> continuumGeoPlacesService: Fetch division/place metadata
continuumGeoPlacesService --> partnerSvc_integrationClients: Geographic metadata
partnerSvc_domainServices -> partnerSvc_domainServices: Identify drift
partnerSvc_domainServices -> continuumPartnerServicePostgres: Write corrections
partnerSvc_domainServices -> continuumPartnerServicePostgres: Write audit log entry
partnerSvc_mbusAndScheduler -> messageBus: Publish reconciliation result event
```

## Related

- Architecture dynamic view: `dynamic-deal-mapping-reconciliation`
- Related flows: [Partner Onboarding Workflow](partner-onboarding-workflow.md), [Partner Uptime and Metrics Reporting](partner-uptime-and-metrics-reporting.md)
