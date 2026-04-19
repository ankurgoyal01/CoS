---
service: "ams"
title: "Audience Creation and Persistence"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "audience-creation-persistence"
flow_type: synchronous
trigger: "API call — POST /audience/*"
participants:
  - "ams_apiResources"
  - "ams_audienceOrchestration"
  - "ams_persistenceLayer"
  - "continuumAudienceManagementDatabase"
architecture_ref: "components-continuum-audience-management-service"
---

# Audience Creation and Persistence

## Summary

This flow handles the creation of a new audience definition in AMS. A caller submits an audience specification via the REST API; AMS validates the request, resolves criteria references, constructs the audience domain entity, and persists it to the MySQL store. The audience is placed in an initial state ready for subsequent computation scheduling.

## Trigger

- **Type**: api-call
- **Source**: Internal Groupon service (ads platform, CRM pipeline, or operator tooling) calling `POST /audience/*`
- **Frequency**: On-demand

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| API Resources | Receives and validates inbound HTTP request | `ams_apiResources` |
| Audience Orchestration | Coordinates domain validation and entity construction | `ams_audienceOrchestration` |
| Persistence Layer | Writes audience entity to database | `ams_persistenceLayer` |
| Audience Management Database | Stores the persisted audience record | `continuumAudienceManagementDatabase` |

## Steps

1. **Receive audience creation request**: API Resources receives `POST /audience/*` with the audience specification payload.
   - From: `caller`
   - To: `ams_apiResources`
   - Protocol: REST/JSON

2. **Validate and route request**: API Resources validates the request schema and routes the workflow to Audience Orchestration.
   - From: `ams_apiResources`
   - To: `ams_audienceOrchestration`
   - Protocol: In-process

3. **Resolve criteria references**: Audience Orchestration queries the Persistence Layer to resolve any referenced criteria definitions and validate their existence.
   - From: `ams_audienceOrchestration`
   - To: `ams_persistenceLayer`
   - Protocol: In-process

4. **Read criteria from database**: Persistence Layer retrieves criteria records from MySQL.
   - From: `ams_persistenceLayer`
   - To: `continuumAudienceManagementDatabase`
   - Protocol: JPA/JDBC

5. **Construct audience entity**: Audience Orchestration builds the audience domain entity with initial lifecycle state, attaches resolved criteria, and assigns metadata.
   - From: `ams_audienceOrchestration`
   - To: `ams_audienceOrchestration`
   - Protocol: In-process

6. **Persist audience record**: Audience Orchestration instructs the Persistence Layer to write the new audience entity to MySQL.
   - From: `ams_audienceOrchestration`
   - To: `ams_persistenceLayer`
   - Protocol: In-process

7. **Write to database**: Persistence Layer executes INSERT/UPDATE against `continuumAudienceManagementDatabase`.
   - From: `ams_persistenceLayer`
   - To: `continuumAudienceManagementDatabase`
   - Protocol: JPA/JDBC

8. **Write audit log entry**: Persistence Layer records the creation event in the audit log.
   - From: `ams_persistenceLayer`
   - To: `continuumAudienceManagementDatabase`
   - Protocol: JPA/JDBC

9. **Return audience ID and status**: API Resources returns the newly created audience identifier and initial status to the caller.
   - From: `ams_apiResources`
   - To: `caller`
   - Protocol: REST/JSON (HTTP 201 Created)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Invalid request schema | Request rejected at API Resources layer | HTTP 400 Bad Request returned to caller |
| Criteria reference not found | Audience Orchestration returns validation error | HTTP 422 Unprocessable Entity returned to caller |
| Database write failure | Exception propagated from Persistence Layer | HTTP 500 returned; no partial audience record created |
| Duplicate audience definition | Constraint violation from MySQL | HTTP 409 Conflict returned to caller |

## Sequence Diagram

```
caller -> ams_apiResources: POST /audience/* (audience spec)
ams_apiResources -> ams_audienceOrchestration: validate and route
ams_audienceOrchestration -> ams_persistenceLayer: resolve criteria
ams_persistenceLayer -> continuumAudienceManagementDatabase: SELECT criteria
continuumAudienceManagementDatabase --> ams_persistenceLayer: criteria records
ams_persistenceLayer --> ams_audienceOrchestration: resolved criteria
ams_audienceOrchestration -> ams_persistenceLayer: persist new audience
ams_persistenceLayer -> continuumAudienceManagementDatabase: INSERT audience + audit log
continuumAudienceManagementDatabase --> ams_persistenceLayer: success
ams_persistenceLayer --> ams_audienceOrchestration: audience ID
ams_audienceOrchestration --> ams_apiResources: created audience entity
ams_apiResources --> caller: HTTP 201 (audience ID, status)
```

## Related

- Architecture dynamic view: `dynamic-ams-audience-calculation`
- Related flows: [Audience Criteria Resolution](audience-criteria-resolution.md), [Audience Schedule Execution](audience-schedule-execution.md), [Sourced Audience Calculation](sourced-audience-calculation.md)
