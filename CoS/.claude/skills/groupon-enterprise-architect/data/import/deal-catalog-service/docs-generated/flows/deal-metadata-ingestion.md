---
service: "deal-catalog-service"
title: "Deal Metadata Ingestion"
generated: "2026-03-03"
type: flow
flow_name: "deal-metadata-ingestion"
flow_type: synchronous
trigger: "Salesforce push or Deal Management API call"
participants:
  - "salesForce"
  - "continuumDealManagementApi"
  - "dealCatalog_api"
  - "dealCatalog_merchandisingService"
  - "dealCatalog_repository"
  - "dealCatalog_indexer"
  - "dealCatalog_messagePublisher"
  - "continuumDealCatalogDb"
  - "messageBus"
architecture_ref: "dynamic-continuum-deal-creation"
---

# Deal Metadata Ingestion

## Summary

This flow describes how deal metadata enters the Deal Catalog Service. Salesforce pushes deal metadata (title, category, availability) to the Catalog API via a REST integration, or the Deal Management API registers new deal metadata during the deal creation workflow. The Catalog API validates and persists the data, applies merchandising rules, emits reindex events, and publishes deal lifecycle events to the Message Bus.

## Trigger

- **Type**: API call (Salesforce push or Deal Management API registration)
- **Source**: Salesforce CRM (merchant deal creation/update) or Deal Management API (`continuumDealManagementApi`)
- **Frequency**: On demand -- each time a deal is created or updated in Salesforce

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Salesforce | Initiates deal metadata push | `salesForce` |
| Deal Management API | Registers deal metadata during creation workflow | `continuumDealManagementApi` |
| Catalog API | Receives and validates inbound deal metadata | `dealCatalog_api` |
| Merchandising Service | Applies merchandising business rules | `dealCatalog_merchandisingService` |
| Catalog Repository | Persists deal metadata to database | `dealCatalog_repository` |
| Search Indexer | Publishes updates to search platform | `dealCatalog_indexer` |
| Message Publisher | Publishes deal lifecycle events to MBus | `dealCatalog_messagePublisher` |
| Deal Catalog DB | Stores deal metadata | `continuumDealCatalogDb` |
| Message Bus | Distributes deal lifecycle events to downstream consumers | `messageBus` |

## Steps

1. **Salesforce pushes deal metadata**: Salesforce sends deal metadata (title, category, availability, merchandising attributes) to the Catalog API.
   - From: `salesForce`
   - To: `dealCatalog_api`
   - Protocol: REST / Integration

2. **Catalog API persists deal metadata**: The Catalog API validates the incoming payload and delegates to the Catalog Repository for persistence.
   - From: `dealCatalog_api`
   - To: `dealCatalog_repository`
   - Protocol: SQL (JPA)

3. **Catalog Repository writes to database**: The repository layer writes the deal record to MySQL via JDBC.
   - From: `dealCatalog_repository`
   - To: `continuumDealCatalogDb`
   - Protocol: JDBC

4. **Catalog API applies merchandising rules**: The Catalog API delegates to the Merchandising Service to apply business rules to the deal.
   - From: `dealCatalog_api`
   - To: `dealCatalog_merchandisingService`
   - Protocol: Direct (in-process)

5. **Merchandising Service reads/writes deals**: The Merchandising Service reads and writes deal data through the repository as needed by the business rules.
   - From: `dealCatalog_merchandisingService`
   - To: `dealCatalog_repository`
   - Protocol: Direct (in-process)

6. **Merchandising Service publishes lifecycle events**: After applying rules, the Merchandising Service delegates to the Message Publisher.
   - From: `dealCatalog_merchandisingService`
   - To: `dealCatalog_messagePublisher`
   - Protocol: Direct (in-process)

7. **Message Publisher sends events to MBus**: The Message Publisher writes deal lifecycle events (deal-created or deal-updated) to configured MBus topics.
   - From: `dealCatalog_messagePublisher`
   - To: `messageBus`
   - Protocol: Async (MBus)

8. **Catalog API emits reindex event**: The Catalog API triggers the Search Indexer to update the search platform with the new/updated deal data.
   - From: `dealCatalog_api`
   - To: `dealCatalog_indexer`
   - Protocol: Event / Batch

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Invalid payload from Salesforce | Validation error returned to caller | Deal not persisted; Salesforce receives error response |
| Database write failure | Transaction rollback | Deal not persisted; error returned to caller |
| MBus publish failure | Logged and potentially retried | Deal persisted but downstream consumers not notified; manual retry may be needed |
| Search indexing failure | Logged; indexing can be retried | Deal persisted but search index stale until next successful index |

## Sequence Diagram

```
Salesforce -> Catalog API: Push deal metadata (REST)
Catalog API -> Catalog Repository: Persist deal metadata (SQL)
Catalog Repository -> Deal Catalog DB: Write deal record (JDBC)
Deal Catalog DB --> Catalog Repository: Confirm write
Catalog API -> Merchandising Service: Apply merchandising rules
Merchandising Service -> Catalog Repository: Read/write deals
Merchandising Service -> Message Publisher: Publish lifecycle events
Message Publisher -> Message Bus: Deal lifecycle event (Async)
Catalog API -> Search Indexer: Emit reindex event
```

## Related

- Architecture dynamic view: `dynamic-continuum-deal-creation`
- Related flows: [Deal Lifecycle Event Publishing](deal-lifecycle-event-publishing.md), [Deal Browsing and Retrieval](deal-browsing-retrieval.md)
