---
service: "gazebo"
title: "Merchandising Checklist Validation"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "merchandising-checklist-validation"
flow_type: synchronous
trigger: "Editor works through the quality checklist for a deal before publishing"
participants:
  - "continuumGazeboWebApp"
  - "continuumGazeboMysql"
architecture_ref: "dynamic-gazebo-merchandising-checklist-validation"
---

# Merchandising Checklist Validation

## Summary

Before editorial copy can be published, editors are required to complete a merchandising quality checklist tied to the deal. The checklist enforces that all required quality criteria are acknowledged. The Gazebo web app tracks checklist item state in MySQL and gates the publish action on full checklist completion, preventing low-quality or incomplete copy from being published.

## Trigger

- **Type**: user-action
- **Source**: Editorial staff member working through a deal's merchandising checklist in the Gazebo web UI
- **Frequency**: on-demand (once per deal before each publish attempt)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Editor (user) | Progresses through checklist items and initiates publish | — |
| Gazebo Web App | Serves checklist, validates completion state, gates publish | `continuumGazeboWebApp` |
| Gazebo MySQL | Persists checklist item state and completion status | `continuumGazeboMysql` |

## Steps

1. **Editor opens merchandising checklist**: Editor navigates to the checklist for a specific deal via `GET /merchandising_checklist`.
   - From: `Editor (browser)`
   - To: `continuumGazeboWebApp`
   - Protocol: REST (HTTP)

2. **Web app loads checklist state**: Rails queries MySQL for the current checklist record associated with the deal, returning all items and their checked/unchecked state.
   - From: `continuumGazeboWebApp`
   - To: `continuumGazeboMysql`
   - Protocol: MySQL

3. **Checklist rendered to editor**: The web app returns the checklist view with item-level state (checked/unchecked, required/optional).
   - From: `continuumGazeboWebApp`
   - To: `Editor (browser)`
   - Protocol: REST (HTTP)

4. **Editor checks a checklist item**: Editor marks a checklist item as complete via `PUT /merchandising_checklist`.
   - From: `Editor (browser)`
   - To: `continuumGazeboWebApp`
   - Protocol: REST (HTTP)

5. **Checklist item state persisted**: Rails updates the checklist record in MySQL to mark the item as checked.
   - From: `continuumGazeboWebApp`
   - To: `continuumGazeboMysql`
   - Protocol: MySQL

6. **Repeat for all items**: Steps 4 and 5 repeat until all required checklist items are checked.
   - From: `Editor (browser)`
   - To: `continuumGazeboWebApp`
   - Protocol: REST (HTTP)

7. **Editor attempts to publish deal copy**: Editor submits the publish action (via `PUT /v2/deals` or publish-specific endpoint).
   - From: `Editor (browser)`
   - To: `continuumGazeboWebApp`
   - Protocol: REST (HTTP)

8. **Web app validates checklist completion**: Rails queries MySQL to verify that all required checklist items for the deal are in a checked state before allowing the publish to proceed.
   - From: `continuumGazeboWebApp`
   - To: `continuumGazeboMysql`
   - Protocol: MySQL

9. **Publish gate decision**: If all required items are checked, the publish proceeds (continuing to the [Editorial Copy Creation](editorial-copy-creation.md) flow). If any required items are unchecked, the publish is blocked.
   - From: `continuumGazeboWebApp`
   - To: `continuumGazeboWebApp` (internal gate logic)
   - Protocol: direct

10. **Response returned to editor**: Editor receives either a publish success response or a validation error listing the unchecked required items.
    - From: `continuumGazeboWebApp`
    - To: `Editor (browser)`
    - Protocol: REST (HTTP)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Publish attempted with incomplete checklist | Validation check fails; publish blocked | HTTP 422 returned; editor sees list of unchecked required items |
| Checklist record not found for deal | Rails returns 404 or creates a new checklist record | Editor prompted to complete checklist from scratch |
| MySQL write failure on item check | ActiveRecord exception; transaction rolled back | HTTP 500 returned; item remains unchecked; editor prompted to retry |
| Optional checklist items unchecked | Validation only enforces required items | Publish proceeds; optional items skipped |

## Sequence Diagram

```
Editor -> continuumGazeboWebApp: GET /merchandising_checklist (open checklist)
continuumGazeboWebApp -> continuumGazeboMysql: query checklist record for deal
continuumGazeboMysql --> continuumGazeboWebApp: checklist items + state
continuumGazeboWebApp --> Editor: checklist view
Editor -> continuumGazeboWebApp: PUT /merchandising_checklist (check item)
continuumGazeboWebApp -> continuumGazeboMysql: update checklist item (checked: true)
continuumGazeboMysql --> continuumGazeboWebApp: write confirmation
continuumGazeboWebApp --> Editor: item checked confirmation
Editor -> continuumGazeboWebApp: PUT /v2/deals (publish)
continuumGazeboWebApp -> continuumGazeboMysql: query checklist completion state
continuumGazeboMysql --> continuumGazeboWebApp: all required items checked
continuumGazeboWebApp -> continuumGazeboMysql: write publish state (proceeds to editorial copy creation flow)
continuumGazeboWebApp --> Editor: publish success
```

## Related

- Architecture dynamic view: `dynamic-gazebo-merchandising-checklist-validation`
- Related flows: [Editorial Copy Creation](editorial-copy-creation.md), [Task Management](task-management.md)
