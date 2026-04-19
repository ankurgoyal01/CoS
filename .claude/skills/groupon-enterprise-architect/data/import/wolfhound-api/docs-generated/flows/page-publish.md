---
service: "wolfhound-api"
title: "Page Publish Flow"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "page-publish"
flow_type: synchronous
trigger: "API call to POST /wh/v2/pages/{id}/publish or POST /wh/v3/pages/{id}/publish"
participants:
  - "wolfApi_apiResources"
  - "orchestrationServices"
  - "wolfhoundApi_persistenceDaos"
  - "externalGatewayClients"
  - "cacheAndBootstraps"
  - "continuumWolfhoundPostgres"
  - "continuumLpapiService"
  - "continuumExpyService"
architecture_ref: "dynamic-wolfhound-page-publish-flow"
---

# Page Publish Flow

## Summary

The Page Publish Flow is triggered when an operator or authoring tool submits a publish request for a specific page version. The flow validates the request, checks external dependencies (LPAPI page references and active experiment state via Expy), persists the updated publish state and version snapshot to Wolfhound Postgres, and then refreshes the in-memory page, subdirectory, and translation caches so that downstream consumers immediately see the new published content.

## Trigger

- **Type**: api-call
- **Source**: `POST /wh/v2/pages/{id}/publish` or `POST /wh/v3/pages/{id}/publish`
- **Frequency**: On demand — each time an operator publishes a page

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| API Resources Layer | Receives and validates the publish request | `wolfApi_apiResources` |
| Domain Services Layer | Orchestrates publish business logic | `orchestrationServices` |
| Persistence Layer | Persists page versions and publish state | `wolfhoundApi_persistenceDaos` |
| External Gateway Clients | Calls LPAPI and Expy for dependency checks | `externalGatewayClients` |
| Cache and Bootstrapping | Refreshes in-memory page, subdirectory, translation caches | `cacheAndBootstraps` |
| Wolfhound Postgres | Stores persisted page publish state | `continuumWolfhoundPostgres` |
| LPAPI Service | Validates page references and list queries | `continuumLpapiService` |
| Expy Service | Checks and manages experiment dependencies | `continuumExpyService` |

## Steps

1. **Receive publish request**: API Resources Layer receives the `POST /wh/v2/pages/{id}/publish` or `POST /wh/v3/pages/{id}/publish` call and validates request parameters.
   - From: `wolfApi_apiResources`
   - To: `orchestrationServices`
   - Protocol: Direct (in-process)

2. **Check LPAPI dependencies**: Domain Services Layer calls External Gateway Clients to resolve any LPAPI page references embedded in the page content.
   - From: `orchestrationServices`
   - To: `externalGatewayClients`
   - Protocol: Direct (in-process)

3. **Resolve LPAPI references**: External Gateway Clients calls LPAPI Service to validate page references and list queries referenced by the page.
   - From: `externalGatewayClients`
   - To: `continuumLpapiService`
   - Protocol: HTTP

4. **Check experiment dependencies**: Domain Services Layer calls External Gateway Clients to evaluate and validate experiment assignments associated with the page.
   - From: `orchestrationServices`
   - To: `externalGatewayClients`
   - Protocol: Direct (in-process)

5. **Evaluate experiments**: External Gateway Clients calls Expy Service to check active experiments relevant to the page being published.
   - From: `externalGatewayClients`
   - To: `continuumExpyService`
   - Protocol: HTTP

6. **Persist publish state**: Domain Services Layer instructs Persistence Layer to write the new page version snapshot and update the publish state record.
   - From: `orchestrationServices`
   - To: `wolfhoundApi_persistenceDaos`
   - Protocol: Direct (in-process)

7. **Write to database**: Persistence Layer writes page versions, publish state, and any schedule updates to Wolfhound Postgres via JDBI/JDBC.
   - From: `wolfhoundApi_persistenceDaos`
   - To: `continuumWolfhoundPostgres`
   - Protocol: JDBI/JDBC

8. **Refresh in-memory caches**: Domain Services Layer triggers Cache and Bootstrapping to reload the published page, subdirectory, and translation entries.
   - From: `orchestrationServices`
   - To: `cacheAndBootstraps`
   - Protocol: Direct (in-process)

9. **Reload cache from storage**: Cache and Bootstrapping reads the freshly published records from Wolfhound Postgres to populate the in-memory cache.
   - From: `cacheAndBootstraps`
   - To: `wolfhoundApi_persistenceDaos`
   - Protocol: Direct (in-process)

10. **Return publish confirmation**: API Resources Layer returns the publish success response to the caller.
    - From: `wolfApi_apiResources`
    - To: caller
    - Protocol: REST/HTTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| LPAPI reference resolution fails | Publish flow returns error to caller | Page remains in draft state; LPAPI must be healthy before retry |
| Expy experiment check fails | Publish flow returns error to caller | Page remains in draft state; experiment dependencies must be valid |
| Database write fails | Transaction rollback via JDBI | Page state unchanged; caller receives 500 error |
| Cache refresh fails | Warning logged; publish state persisted | Page is published in DB but cache may be stale until next refresh or restart |

## Sequence Diagram

```
wolfApi_apiResources -> orchestrationServices: Receives publish request and validates parameters
orchestrationServices -> externalGatewayClients: Checks LPAPI and experiment dependencies
externalGatewayClients -> continuumLpapiService: Resolves LPAPI page references and list queries
continuumLpapiService --> externalGatewayClients: Reference validation result
externalGatewayClients -> continuumExpyService: Evaluates and manages experiments
continuumExpyService --> externalGatewayClients: Experiment state result
externalGatewayClients --> orchestrationServices: Dependency check results
orchestrationServices -> wolfhoundApi_persistenceDaos: Persists page versions, publish state, and schedules
wolfhoundApi_persistenceDaos -> continuumWolfhoundPostgres: Writes page version and publish state (JDBI/JDBC)
continuumWolfhoundPostgres --> wolfhoundApi_persistenceDaos: Write confirmation
orchestrationServices -> cacheAndBootstraps: Refreshes page/subdirectory/translation caches
cacheAndBootstraps -> wolfhoundApi_persistenceDaos: Loads and refreshes cached records from storage
wolfhoundApi_persistenceDaos --> cacheAndBootstraps: Published records
cacheAndBootstraps --> orchestrationServices: Cache refresh complete
orchestrationServices --> wolfApi_apiResources: Publish success
wolfApi_apiResources --> caller: HTTP 200 publish confirmation
```

## Related

- Architecture dynamic view: `dynamic-wolfhound-page-publish-flow`
- Related flows: [Page Retrieval and Enrichment Flow](page-retrieval-enrichment.md), [Taxonomy Bootstrap Flow](taxonomy-bootstrap.md)
- Flows index: [Flows](index.md)
