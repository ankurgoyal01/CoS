---
service: "gazebo"
title: "Editorial Copy Creation"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "editorial-copy-creation"
flow_type: synchronous
trigger: "Editor saves or publishes deal copy via the Gazebo web UI"
participants:
  - "continuumGazeboWebApp"
  - "continuumGazeboMysql"
  - "continuumGazeboRedis"
  - "continuumDealCatalogService"
  - "mbusSystem_18ea34"
architecture_ref: "dynamic-gazebo-editorial-copy-creation"
---

# Editorial Copy Creation

## Summary

An editorial team member creates or edits deal copy for a Groupon deal using the Gazebo web application. The application validates the submitted content, persists the copy treatment to MySQL, and publishes a copy change event to the Message Bus to notify downstream systems of the content update or publish action.

## Trigger

- **Type**: user-action
- **Source**: Editorial staff member interacting with the Gazebo web UI in a browser
- **Frequency**: on-demand (whenever an editor creates or updates deal copy)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Editor (user) | Initiates copy creation or edit | — |
| Gazebo Web App | Receives request, validates, persists, publishes event | `continuumGazeboWebApp` |
| Gazebo MySQL | Persists deal and copy treatment data | `continuumGazeboMysql` |
| Gazebo Redis | Provides session auth and feature flag state | `continuumGazeboRedis` |
| Deal Catalog Service | Provides deal metadata for editorial context | `continuumDealCatalogService` |
| Message Bus | Receives published copy change event | `mbusSystem_18ea34` |

## Steps

1. **Editor opens deal for editing**: Editor navigates to a deal via `GET /v2/deals` or `GET /v2/deals/search`.
   - From: `Editor (browser)`
   - To: `continuumGazeboWebApp`
   - Protocol: REST (HTTP)

2. **Web app loads deal context**: Gazebo fetches deal metadata from Deal Catalog Service to populate the editorial form.
   - From: `continuumGazeboWebApp`
   - To: `continuumDealCatalogService`
   - Protocol: REST (HTTP)

3. **Feature flags checked**: Gazebo reads active feature flags from Redis to determine which editor features are enabled for this session.
   - From: `continuumGazeboWebApp`
   - To: `continuumGazeboRedis`
   - Protocol: Redis

4. **Editor submits copy**: Editor submits the created or updated deal copy via `PUT /v2/deals`.
   - From: `Editor (browser)`
   - To: `continuumGazeboWebApp`
   - Protocol: REST (HTTP)

5. **Rails validates content**: The web app validates the submitted copy treatment fields (presence, format, length constraints).
   - From: `continuumGazeboWebApp`
   - To: `continuumGazeboWebApp` (internal Rails model validation)
   - Protocol: direct

6. **Copy treatment persisted**: Validated copy treatment is written to the `copy_treatments` table and the associated `deals` record is updated in MySQL.
   - From: `continuumGazeboWebApp`
   - To: `continuumGazeboMysql`
   - Protocol: MySQL

7. **Outbound message record created**: An outbound message record is inserted into the `outbound_messages` table in MySQL to track the pending event.
   - From: `continuumGazeboWebApp`
   - To: `continuumGazeboMysql`
   - Protocol: MySQL

8. **Copy change event published**: Gazebo publishes a copy change event to the Message Bus `editorial/copy` topic via the Messagebus client.
   - From: `continuumGazeboWebApp`
   - To: `mbusSystem_18ea34`
   - Protocol: message-bus

9. **Success response returned**: The web app responds to the editor's browser with a success status and updated deal state.
   - From: `continuumGazeboWebApp`
   - To: `Editor (browser)`
   - Protocol: REST (HTTP)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Validation failure (invalid copy fields) | Rails model validation returns error messages | HTTP 422 returned to editor with field-level error messages; copy not persisted |
| Deal Catalog Service unavailable | HTTP call fails; deal context form loads with partial data | Editor may proceed with reduced context; deal metadata may be stale |
| MySQL write failure | ActiveRecord exception raised; transaction rolled back | HTTP 500 returned; copy not persisted; editor prompted to retry |
| Message Bus publish failure | Publish exception caught; outbound message record retained for retry | Event will be retried; copy is already persisted in MySQL |

## Sequence Diagram

```
Editor -> continuumGazeboWebApp: GET /v2/deals (load deal for editing)
continuumGazeboWebApp -> continuumDealCatalogService: fetch deal metadata
continuumDealCatalogService --> continuumGazeboWebApp: deal metadata response
continuumGazeboWebApp -> continuumGazeboRedis: read feature flags
continuumGazeboRedis --> continuumGazeboWebApp: flag state
continuumGazeboWebApp --> Editor: editorial form with deal context
Editor -> continuumGazeboWebApp: PUT /v2/deals (submit copy)
continuumGazeboWebApp -> continuumGazeboWebApp: validate copy treatment
continuumGazeboWebApp -> continuumGazeboMysql: write copy_treatments + deals
continuumGazeboMysql --> continuumGazeboWebApp: write confirmation
continuumGazeboWebApp -> continuumGazeboMysql: insert outbound_messages record
continuumGazeboWebApp -> mbusSystem_18ea34: publish editorial/copy event
mbusSystem_18ea34 --> continuumGazeboWebApp: publish acknowledgement
continuumGazeboWebApp --> Editor: success response
```

## Related

- Architecture dynamic view: `dynamic-gazebo-editorial-copy-creation`
- Related flows: [Merchandising Checklist Validation](merchandising-checklist-validation.md), [Message Bus Event Processing](message-bus-event-processing.md)
