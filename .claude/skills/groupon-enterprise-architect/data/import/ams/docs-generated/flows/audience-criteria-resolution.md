---
service: "ams"
title: "Audience Criteria Resolution"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "audience-criteria-resolution"
flow_type: synchronous
trigger: "API call — GET /criteria, GET /ca-attributes/{id}, GET /attribute"
participants:
  - "ams_apiResources"
  - "ams_audienceOrchestration"
  - "ams_persistenceLayer"
  - "continuumAudienceManagementDatabase"
architecture_ref: "components-continuum-audience-management-service"
---

# Audience Criteria Resolution

## Summary

This flow resolves and returns audience criteria definitions and CA attribute records in response to API queries. Callers use this flow to discover available audience-building criteria, validate criteria expressions before submitting audience definitions, and retrieve specific attribute configurations. Results are read from the MySQL store and returned synchronously.

## Trigger

- **Type**: api-call
- **Source**: Ads platform, CRM tools, or audience authoring interfaces calling `GET /criteria`, `GET /ca-attributes/{id}`, or `GET /attribute`
- **Frequency**: On-demand; high frequency during audience authoring and validation workflows

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| API Resources | Receives criteria/attribute lookup request | `ams_apiResources` |
| Audience Orchestration | Routes and applies any access-scoping logic | `ams_audienceOrchestration` |
| Persistence Layer | Queries criteria and attribute records | `ams_persistenceLayer` |
| Audience Management Database | Source of criteria and attribute definitions | `continuumAudienceManagementDatabase` |

## Steps

1. **Receive criteria/attribute request**: API Resources receives a GET request for criteria definitions or a specific CA attribute by ID.
   - From: `caller`
   - To: `ams_apiResources`
   - Protocol: REST/JSON

2. **Route to Audience Orchestration**: API Resources routes the resolved lookup to Audience Orchestration for any scoping or authorization filtering.
   - From: `ams_apiResources`
   - To: `ams_audienceOrchestration`
   - Protocol: In-process

3. **Delegate to Persistence Layer**: Audience Orchestration delegates the data retrieval to the Persistence Layer with the resolved query parameters.
   - From: `ams_audienceOrchestration`
   - To: `ams_persistenceLayer`
   - Protocol: In-process

4. **Query criteria/attributes from MySQL**: Persistence Layer executes a SELECT against the criteria or attribute tables in `continuumAudienceManagementDatabase`.
   - From: `ams_persistenceLayer`
   - To: `continuumAudienceManagementDatabase`
   - Protocol: JPA/JDBC

5. **Return resolved criteria/attributes**: Persistence Layer returns the record(s) to Audience Orchestration; results are serialized by API Resources and returned to the caller.
   - From: `ams_apiResources`
   - To: `caller`
   - Protocol: REST/JSON (HTTP 200)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Criteria record not found | Empty result from Persistence Layer | HTTP 404 Not Found returned to caller |
| Attribute ID not found | Empty result from Persistence Layer | HTTP 404 Not Found returned to caller |
| Database read failure | Exception propagated from Persistence Layer | HTTP 500 returned to caller |
| Invalid query parameters | Rejected at API Resources layer | HTTP 400 Bad Request |

## Sequence Diagram

```
caller -> ams_apiResources: GET /criteria OR GET /ca-attributes/{id} OR GET /attribute
ams_apiResources -> ams_audienceOrchestration: route lookup request
ams_audienceOrchestration -> ams_persistenceLayer: query criteria/attributes
ams_persistenceLayer -> continuumAudienceManagementDatabase: SELECT criteria / attributes
continuumAudienceManagementDatabase --> ams_persistenceLayer: records
ams_persistenceLayer --> ams_audienceOrchestration: resolved definitions
ams_audienceOrchestration --> ams_apiResources: serializable result
ams_apiResources --> caller: HTTP 200 (criteria/attribute definitions)
```

## Related

- Architecture dynamic view: `components-continuum-audience-management-service`
- Related flows: [Audience Creation and Persistence](audience-creation-persistence.md), [Custom Query Execution](custom-query-execution.md)
