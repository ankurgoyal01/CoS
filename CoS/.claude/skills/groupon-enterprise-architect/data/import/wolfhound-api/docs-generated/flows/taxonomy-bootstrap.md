---
service: "wolfhound-api"
title: "Taxonomy Bootstrap Flow"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "taxonomy-bootstrap"
flow_type: batch
trigger: "Service startup or manual POST /wh/v2/taxonomies trigger"
participants:
  - "wolfApi_apiResources"
  - "orchestrationServices"
  - "wolfhoundApi_persistenceDaos"
  - "externalGatewayClients"
  - "cacheAndBootstraps"
  - "continuumWolfhoundPostgres"
  - "continuumTaxonomyService"
architecture_ref: "dynamic-wolfhound-page-publish-flow"
---

# Taxonomy Bootstrap Flow

## Summary

The Taxonomy Bootstrap Flow seeds and refreshes the taxonomy data that Wolfhound API uses for category hierarchy and SEO page classification. At service startup, the `cacheAndBootstraps` component triggers the bootstrap sequence: it calls Taxonomy Service via the `externalGatewayClients` to fetch the full category hierarchy and taxonomy metadata, persists the entries to Wolfhound Postgres via the Persistence Layer, and loads the result into the in-memory taxonomy cache. The flow can also be triggered manually via `POST /wh/v2/taxonomies` to force a re-sync of taxonomy data.

## Trigger

- **Type**: schedule / manual
- **Source**: Service startup (automatic) or `POST /wh/v2/taxonomies` (manual operator trigger)
- **Frequency**: Once at each service startup; on demand when taxonomy data must be refreshed

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| API Resources Layer | Accepts manual taxonomy bootstrap trigger | `wolfApi_apiResources` |
| Domain Services Layer | Orchestrates taxonomy fetch, persist, and cache load | `orchestrationServices` |
| Persistence Layer | Persists taxonomy entries to database | `wolfhoundApi_persistenceDaos` |
| External Gateway Clients | Calls Taxonomy Service for hierarchy data | `externalGatewayClients` |
| Cache and Bootstrapping | Loads taxonomy data into in-memory cache at startup | `cacheAndBootstraps` |
| Wolfhound Postgres | Stores persisted taxonomy entries | `continuumWolfhoundPostgres` |
| Taxonomy Service | Authoritative source of category hierarchy and metadata | `continuumTaxonomyService` |

## Steps

1. **Initiate bootstrap**: At service startup, Cache and Bootstrapping initiates the taxonomy bootstrap sequence. (For manual triggers, API Resources Layer receives `POST /wh/v2/taxonomies` and delegates to Domain Services Layer.)
   - From: `cacheAndBootstraps` (startup) or `wolfApi_apiResources` (manual)
   - To: `orchestrationServices`
   - Protocol: Direct (in-process)

2. **Request taxonomy data**: Domain Services Layer calls External Gateway Clients to fetch the taxonomy hierarchy.
   - From: `orchestrationServices`
   - To: `externalGatewayClients`
   - Protocol: Direct (in-process)

3. **Fetch category hierarchy**: External Gateway Clients calls Taxonomy Service to retrieve the full category hierarchy and taxonomy metadata.
   - From: `externalGatewayClients`
   - To: `continuumTaxonomyService`
   - Protocol: HTTP

4. **Return taxonomy data**: Taxonomy Service responds with the category hierarchy and metadata.
   - From: `continuumTaxonomyService`
   - To: `externalGatewayClients`
   - Protocol: HTTP

5. **Persist taxonomy entries**: Domain Services Layer instructs Persistence Layer to upsert the taxonomy entries into Wolfhound Postgres.
   - From: `orchestrationServices`
   - To: `wolfhoundApi_persistenceDaos`
   - Protocol: Direct (in-process)

6. **Write to database**: Persistence Layer executes JDBI upsert operations for all taxonomy entries.
   - From: `wolfhoundApi_persistenceDaos`
   - To: `continuumWolfhoundPostgres`
   - Protocol: JDBI/JDBC

7. **Seed in-memory cache**: Cache and Bootstrapping loads the persisted taxonomy entries from Wolfhound Postgres into its in-memory cache for fast runtime lookups.
   - From: `cacheAndBootstraps`
   - To: `wolfhoundApi_persistenceDaos`
   - Protocol: Direct (in-process)

8. **Bootstrap complete**: In-memory taxonomy cache is populated; service is ready to serve taxonomy-enriched page responses.
   - From: `cacheAndBootstraps`
   - To: `orchestrationServices`
   - Protocol: Direct (in-process)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Taxonomy Service unavailable at startup | Bootstrap fails; service starts with empty taxonomy cache | Taxonomy-dependent page enrichment returns empty/default data until retry |
| Taxonomy Service unavailable on manual trigger | API returns error to caller | Existing persisted taxonomy data retained; cache unchanged |
| Database write fails during persist | Error logged; transaction rolled back | Taxonomy entries not updated in Postgres; cache retains previous state |
| Partial taxonomy data returned | Partial upsert; cache loaded with available data | Some taxonomy categories may be missing until next full bootstrap |

## Sequence Diagram

```
cacheAndBootstraps -> orchestrationServices: Initiates taxonomy bootstrap (service startup)
orchestrationServices -> externalGatewayClients: Retrieves taxonomy hierarchy data
externalGatewayClients -> continuumTaxonomyService: Fetches category hierarchy and taxonomy metadata
continuumTaxonomyService --> externalGatewayClients: Category hierarchy and metadata
externalGatewayClients --> orchestrationServices: Taxonomy data
orchestrationServices -> wolfhoundApi_persistenceDaos: Reads and writes taxonomy domain state
wolfhoundApi_persistenceDaos -> continuumWolfhoundPostgres: Upserts taxonomy entries (JDBI/JDBC)
continuumWolfhoundPostgres --> wolfhoundApi_persistenceDaos: Write confirmation
wolfhoundApi_persistenceDaos --> orchestrationServices: Persist complete
orchestrationServices -> cacheAndBootstraps: Triggers cache refresh with new taxonomy records
cacheAndBootstraps -> wolfhoundApi_persistenceDaos: Loads and refreshes cached taxonomy records from storage
wolfhoundApi_persistenceDaos --> cacheAndBootstraps: Taxonomy records
cacheAndBootstraps --> orchestrationServices: Cache seeded
orchestrationServices --> wolfApi_apiResources: Bootstrap complete
```

## Related

- Architecture dynamic view: `dynamic-wolfhound-page-publish-flow`
- Related flows: [Page Publish Flow](page-publish.md), [Page Retrieval and Enrichment Flow](page-retrieval-enrichment.md)
- Flows index: [Flows](index.md)
