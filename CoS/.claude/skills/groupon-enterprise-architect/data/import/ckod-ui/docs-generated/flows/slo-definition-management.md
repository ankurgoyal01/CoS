---
service: "ckod-ui"
title: "SLO Definition Management"
generated: "2026-03-03"
type: flow
flow_name: "slo-definition-management"
flow_type: synchronous
trigger: "Authorised user creates, edits, or soft-deletes an SLO definition via the /slo-management page"
participants:
  - "ckodUi_webUi"
  - "ckodUi_apiRoutes"
  - "authz"
  - "ckodUi_dataAccess"
  - "continuumCkodPrimaryMysql"
architecture_ref: "components-continuumCkodUi"
---

# SLO Definition Management

## Summary

This flow covers how authorised users create, update, or delete SLO/SLA threshold definitions from the `/slo-management` page. Each operation goes through the Next.js API routes (`POST`, `PATCH`, or `DELETE /api/slo-definitions`), which validate the user, apply the change to the appropriate `*_SLA_DEFINITION` or `*_SLO_DEFINITION` table via `prismaRW`, and write an audit log entry to `SLO_AUDIT_LOG`. RTK Query invalidates the relevant cache tags so the list refreshes automatically.

## Trigger

- **Type**: user-action
- **Source**: Engineer interacts with the SLO management table on `/slo-management` (add row, edit inline, delete, bulk edit)
- **Frequency**: On demand

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Web UI | Renders editable SLO definition table; fires RTK Query mutations on change | `ckodUi_webUi` |
| API Routes | Handles `POST`, `PATCH`, `DELETE /api/slo-definitions` | `ckodUi_apiRoutes` |
| Authentication and Authorization | Validates `x-grpn-email`; verifies user is authorised to manage SLOs | `authz` |
| Data Access Layer | Executes write operations via `prismaRW` and reads via `prismaRO` | `ckodUi_dataAccess` |
| CKOD Primary MySQL | Stores SLO definitions and audit log across multiple tables | `continuumCkodPrimaryMysql` |

## Steps

### Create SLO Definition

1. **User adds a new row**: Engineer clicks "Add Row" on the SLO management table and fills in `subjectArea`, `jobName`, `slaUtc`, optional `slaComment`, and platform-specific fields (`jobId`, `priority`, `feedUuid`, etc.).
   - From: `ckodUi_webUi`
   - To: `ckodUi_webUi` (local form state)
   - Protocol: React state / React Hook Form

2. **Submit create request**: Web UI fires `useAddRowMutation` which sends `POST /api/slo-definitions` with `{ type, subjectArea, jobName, slaUtc, ... }` JSON body.
   - From: `ckodUi_webUi`
   - To: `ckodUi_apiRoutes`
   - Protocol: REST

3. **Validate user**: API route checks `x-grpn-email` and team membership.
   - From: `ckodUi_apiRoutes`
   - To: `authz`
   - Protocol: Direct call

4. **Insert SLO definition**: Data access layer inserts a new row into the appropriate table (e.g., `KEBOOLA_SLA_DEFINITION`, `EDW_SLA_DEFINITION`, `pre_af_sla_monitoring`) via `prismaRW`.
   - From: `ckodUi_dataAccess`
   - To: `continuumCkodPrimaryMysql`
   - Protocol: Prisma / MySQL

5. **Write audit log**: Inserts a row into `SLO_AUDIT_LOG` with `ACTION=INSERT`, `USER_EMAIL`, `TABLE_NAME`, and JSON `PAYLOAD`.
   - From: `ckodUi_dataAccess`
   - To: `continuumCkodPrimaryMysql`
   - Protocol: Prisma / MySQL

6. **Invalidate cache and refresh list**: RTK Query invalidates `SLODefinition/LIST-{type}` tag. UI re-fetches and renders the updated list.
   - From: `ckodUi_apiRoutes`
   - To: `ckodUi_webUi`
   - Protocol: REST (200 OK) + RTK Query cache invalidation

### Update SLO Definition

Steps 1–6 above apply with `PATCH /api/slo-definitions` body containing `{ type, id, slaUtc, slaComment, softDelete, ... }`. Supports bulk update via `ids[]` array or Airflow composite keys (`dagId`, `taskId`, `groupId`).

### Soft-Delete SLO Definition

Steps 1–6 above apply with `DELETE /api/slo-definitions?type={type}&id={id}` (or Airflow composite key params). The record is soft-deleted (sets `SOFT_DELETE=true` or removes the row depending on the platform type).

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| User not authorised | Returns HTTP 403 | UI shows error toast; no DB change |
| Validation error (missing required fields) | API returns HTTP 400 with field-level errors | UI shows validation messages via Sonner toast |
| MySQL write failure | Prisma error propagated; HTTP 500 | UI shows error toast; list not refreshed |
| Concurrent edit conflict | No optimistic locking — last write wins | Data may be overwritten; audit log records both changes |

## Sequence Diagram

```
Web UI -> API Routes: POST /api/slo-definitions { type: "keboola", jobName: "...", slaUtc: "..." }
API Routes -> authz: Validate x-grpn-email
authz --> API Routes: Authorised
API Routes -> ckodUi_dataAccess: prismaRW.kEBOOLA_SLA_DEFINITION.create({ data: {...} })
ckodUi_dataAccess -> continuumCkodPrimaryMysql: INSERT INTO KEBOOLA_SLA_DEFINITION (...)
continuumCkodPrimaryMysql --> ckodUi_dataAccess: OK (new record)
ckodUi_dataAccess -> continuumCkodPrimaryMysql: INSERT INTO SLO_AUDIT_LOG (ACTION="INSERT", USER_EMAIL, TABLE_NAME, PAYLOAD)
continuumCkodPrimaryMysql --> ckodUi_dataAccess: OK
ckodUi_dataAccess --> API Routes: { success: true }
API Routes --> Web UI: 200 { success: true }
Web UI -> API Routes: GET /api/slo-definitions?type=keboola (RTK Query cache invalidation re-fetch)
API Routes --> Web UI: { data: [...updated list...] }
```

## Related

- Related flows: [SLO Dashboard Data Fetch](slo-dashboard-fetch.md)
- See [Data Stores](../data-stores.md) for SLO definition and audit log table schemas
- See [API Surface](../api-surface.md) for SLO definition endpoint contracts
