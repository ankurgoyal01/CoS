---
service: "ams"
title: "Custom Query Execution"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "custom-query-execution"
flow_type: synchronous
trigger: "API call — POST /custom-query/*"
participants:
  - "ams_apiResources"
  - "ams_audienceOrchestration"
  - "ams_persistenceLayer"
  - "continuumAudienceManagementDatabase"
architecture_ref: "components-continuum-audience-management-service"
---

# Custom Query Execution

## Summary

This flow handles execution of custom queries against audience data. A caller submits a query specification to the AMS custom query endpoint; AMS validates the query, routes it through Audience Orchestration, executes it via the Persistence Layer against the configured data stores, and returns the result set synchronously. This supports ad-hoc audience data exploration and reporting without triggering full Spark compute jobs.

## Trigger

- **Type**: api-call
- **Source**: Internal Groupon platform services, reporting tools, or operator tooling calling `POST /custom-query/*`
- **Frequency**: On-demand

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| API Resources | Receives and validates custom query request | `ams_apiResources` |
| Audience Orchestration | Validates query semantics and routes execution | `ams_audienceOrchestration` |
| Persistence Layer | Executes the query against audience data stores | `ams_persistenceLayer` |
| Audience Management Database | Primary query target for audience metadata and definitions | `continuumAudienceManagementDatabase` |

## Steps

1. **Receive custom query request**: API Resources receives `POST /custom-query/*` with the query specification.
   - From: `caller`
   - To: `ams_apiResources`
   - Protocol: REST/JSON

2. **Validate query request**: API Resources validates the request payload structure and routes to Audience Orchestration.
   - From: `ams_apiResources`
   - To: `ams_audienceOrchestration`
   - Protocol: In-process

3. **Validate query semantics**: Audience Orchestration validates the query against allowed query patterns and audience access permissions.
   - From: `ams_audienceOrchestration`
   - To: `ams_audienceOrchestration`
   - Protocol: In-process

4. **Execute query via Persistence Layer**: Audience Orchestration delegates query execution to the Persistence Layer, which translates the specification to SQL or JDBI query.
   - From: `ams_audienceOrchestration`
   - To: `ams_persistenceLayer`
   - Protocol: In-process

5. **Query database**: Persistence Layer executes the query against `continuumAudienceManagementDatabase`.
   - From: `ams_persistenceLayer`
   - To: `continuumAudienceManagementDatabase`
   - Protocol: JPA/JDBC

6. **Return result set**: Persistence Layer returns results to Audience Orchestration; results are serialized and returned to the caller.
   - From: `ams_apiResources`
   - To: `caller`
   - Protocol: REST/JSON (HTTP 200)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Invalid query specification | Rejected at API Resources or Orchestration validation | HTTP 400 Bad Request |
| Query references non-existent audience | Orchestration returns not-found error | HTTP 404 Not Found |
| Database query timeout | JDBC timeout exception from Persistence Layer | HTTP 504 / 500 returned to caller |
| Disallowed query pattern | Semantic validation rejection | HTTP 403 Forbidden or HTTP 422 Unprocessable Entity |

## Sequence Diagram

```
caller -> ams_apiResources: POST /custom-query/* (query spec)
ams_apiResources -> ams_audienceOrchestration: validate and route
ams_audienceOrchestration -> ams_persistenceLayer: execute query
ams_persistenceLayer -> continuumAudienceManagementDatabase: SELECT (custom query)
continuumAudienceManagementDatabase --> ams_persistenceLayer: result rows
ams_persistenceLayer --> ams_audienceOrchestration: result set
ams_audienceOrchestration --> ams_apiResources: serialized results
ams_apiResources --> caller: HTTP 200 (result set)
```

## Related

- Architecture dynamic view: `components-continuum-audience-management-service`
- Related flows: [Audience Criteria Resolution](audience-criteria-resolution.md), [Audience Creation and Persistence](audience-creation-persistence.md)
