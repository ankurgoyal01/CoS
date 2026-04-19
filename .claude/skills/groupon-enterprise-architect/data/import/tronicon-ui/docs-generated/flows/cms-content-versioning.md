---
service: "tronicon-ui"
title: "CMS Content Versioning"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "cms-content-versioning"
flow_type: synchronous
trigger: "Operator creates, edits, versions, or archives CMS content via the Tronicon UI browser application"
participants:
  - "troniconUiWeb"
  - "troniconUi_webControllers"
  - "troniconUi_dataAccess"
  - "continuumTroniconUiDatabase"
  - "troniconCms"
architecture_ref: "dynamic-troniconUi-cms-content-versioning"
---

# CMS Content Versioning

## Summary

This flow describes the full CMS content lifecycle managed within Tronicon UI: operators create new CMS entries, edit existing content, create new versions to preserve history, archive entries that are no longer active, and review the audit trail of changes. CMS content is persisted in `continuumTroniconUiDatabase` with versioning metadata, and the Tronicon CMS service (`troniconCms`) is called for content synchronization. An audit trail is maintained for every state transition.

## Trigger

- **Type**: user-action
- **Source**: Operator accesses the CMS management interface at `GET /cms` and performs a create, edit, version, archive, or audit review action
- **Frequency**: On-demand, as content is created, updated, or retired by the merchandising team

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Operator (browser) | Initiates all CMS content lifecycle actions | — |
| Tronicon UI Web App | Routes CMS requests and orchestrates persistence and external CMS calls | `troniconUiWeb` |
| Web Controllers | Handles `/cms` endpoint routing, input validation, and audit recording | `troniconUi_webControllers` |
| Data Access Layer | Reads and writes CMS content, version, status, and audit records | `troniconUi_dataAccess` |
| Tronicon UI Database | Persists all CMS content entries, versions, and audit trail | `continuumTroniconUiDatabase` |
| Tronicon CMS | External CMS service synced with content updates | `troniconCms` |

## Steps

1. **Lists CMS content**: Operator navigates to `GET /cms`; controller retrieves the current list of CMS content entries with status and version information.
   - From: `Operator`
   - To: `troniconUi_webControllers`
   - Protocol: REST/HTTP (browser GET)

2. **Reads CMS entries from database**: Data access layer queries the `cms` table, joining version and status metadata.
   - From: `troniconUi_dataAccess`
   - To: `continuumTroniconUiDatabase`
   - Protocol: SQL over TCP

3. **Creates or edits CMS content**: Operator submits `POST /cms` with content body, metadata, and action type (create, edit, version, archive).
   - From: `Operator`
   - To: `troniconUi_webControllers`
   - Protocol: REST/HTTP (browser form POST)

4. **Validates content submission**: Controller validates required fields and permitted state transitions (e.g., cannot archive an already-archived entry).
   - From: `troniconUi_webControllers`
   - To: `troniconUi_webControllers`
   - Protocol: direct (in-process)

5. **Persists content to database**: Data access layer executes INSERT (for new content or new version) or UPDATE (for edits or archive state change) on the `cms` table.
   - From: `troniconUi_dataAccess`
   - To: `continuumTroniconUiDatabase`
   - Protocol: SQL over TCP

6. **Records audit entry**: Controller writes an audit trail record capturing the operator identity, action type, timestamp, and content snapshot.
   - From: `troniconUi_dataAccess`
   - To: `continuumTroniconUiDatabase`
   - Protocol: SQL over TCP

7. **Syncs content to Tronicon CMS**: Controller calls Tronicon CMS (`troniconCms`) to propagate the content change to the CMS service.
   - From: `troniconUiWeb`
   - To: `troniconCms`
   - Protocol: REST/HTTP

8. **Tronicon CMS acknowledges sync**: Tronicon CMS returns a success response confirming the content update was received.
   - From: `troniconCms`
   - To: `troniconUiWeb`
   - Protocol: REST/HTTP

9. **Reviews audit trail**: Operator requests the audit view for a specific CMS entry; controller retrieves the audit record history from the database.
   - From: `Operator`
   - To: `troniconUi_webControllers`
   - Protocol: REST/HTTP (browser GET with audit action parameter)

10. **Reads audit records from database**: Data access layer queries audit entries linked to the specified CMS content ID.
    - From: `troniconUi_dataAccess`
    - To: `continuumTroniconUiDatabase`
    - Protocol: SQL over TCP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Content validation fails | Controller returns validation error | Operator sees error message; content not persisted; operator must correct and resubmit |
| Invalid state transition (e.g., archive already-archived) | Controller rejects action | HTTP error response; no database change; audit entry not created |
| Database write fails | SQLAlchemy raises exception; controller returns HTTP 500 | Content not persisted; operator must retry |
| Tronicon CMS sync fails | HTTP error from `troniconCms`; Tronicon UI logs the error | Content persisted locally in `continuumTroniconUiDatabase`; CMS sync may be out of sync until retry |

## Sequence Diagram

```
Operator -> troniconUiWeb: GET /cms
troniconUiWeb -> continuumTroniconUiDatabase: SELECT cms entries + versions
continuumTroniconUiDatabase --> troniconUiWeb: CMS content list
troniconUiWeb --> Operator: CMS management page

Operator -> troniconUiWeb: POST /cms (action=create|edit|version|archive)
troniconUiWeb -> troniconUiWeb: Validate content and state transition
troniconUiWeb -> continuumTroniconUiDatabase: INSERT/UPDATE cms content
continuumTroniconUiDatabase --> troniconUiWeb: OK
troniconUiWeb -> continuumTroniconUiDatabase: INSERT audit record
continuumTroniconUiDatabase --> troniconUiWeb: OK
troniconUiWeb -> troniconCms: POST /content (sync update)
troniconCms --> troniconUiWeb: 200 OK
troniconUiWeb --> Operator: Content saved

Operator -> troniconUiWeb: GET /cms?action=audit&id=:id
troniconUiWeb -> continuumTroniconUiDatabase: SELECT audit records WHERE cms_id=:id
continuumTroniconUiDatabase --> troniconUiWeb: Audit trail
troniconUiWeb --> Operator: Audit history view
```

## Related

- Architecture dynamic view: `dynamic-troniconUi-cms-content-versioning`
- Related flows: [Theme Configuration](theme-configuration.md)
- See [Integrations](../integrations.md) for Tronicon CMS (`troniconCms`) details
- See [Data Stores](../data-stores.md) for `cms` entity and audit trail context
