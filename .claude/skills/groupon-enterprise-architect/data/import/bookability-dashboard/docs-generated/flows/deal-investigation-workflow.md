---
service: "bookability-dashboard"
title: "Deal Investigation Workflow"
generated: "2026-03-03"
type: flow
flow_name: "deal-investigation-workflow"
flow_type: synchronous
trigger: "User acknowledges, categorizes, or resolves a problematic deal"
participants:
  - "continuumBookabilityDashboardWeb"
  - "bookDash_appShell"
  - "bookDash_investigationClient"
  - "apiProxy"
  - "continuumPartnerService"
architecture_ref: "dynamic-bookability-dashboard-data-fetch"
---

# Deal Investigation Workflow

## Summary

When a deal is identified as problematic (failing one or more health checks), operations staff can open an investigation workflow directly in the dashboard. The workflow allows a user to acknowledge the issue, assign it to an issue category, optionally reassign ownership to another internal user, and ultimately mark it as resolved. All investigation state is persisted in `continuumPartnerService` via the `/v1/deals/investigation` endpoint.

## Trigger

- **Type**: user-action
- **Source**: User opens `InvestigationModal` or `InvestigationControls` from the Deal Details view or Deals Overview
- **Frequency**: On demand, per investigation action

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Dashboard App Shell | Renders investigation controls; updates deal state in React after investigation actions | `bookDash_appShell` |
| Investigation API Client | Makes POST and GET calls to the investigation endpoints | `bookDash_investigationClient` |
| API Proxy | Routes requests to Partner Service | `apiProxy` |
| Partner Service | Persists and returns deal investigation records | `continuumPartnerService` |

## Steps

1. **Load investigation history**: When the investigation modal opens, `fetchDealInvestigationHistory(dealId)` sends `GET /v1/deals/investigation/{dealId}?clientId=tpis`. The response is a `DealInvestigation[]` array showing all past investigation records for the deal.
   - From: `bookDash_investigationClient`
   - To: `continuumPartnerService` (via `apiProxy`)
   - Protocol: REST (HTTPS GET)

2. **Acknowledge deal**: When the user clicks "Acknowledge", `acknowledgeDeal(dealId, userEmail)` sends `POST /v1/deals/investigation?clientId=tpis` with body `{ dealId, userEmail, status: "ACKNOWLEDGED", category: null }`. This creates a new investigation record.
   - From: `bookDash_investigationClient`
   - To: `continuumPartnerService` (via `apiProxy`)
   - Protocol: REST (HTTPS POST, `Content-Type: application/json`)

3. **Assign issue category**: When the user selects an issue category (one of `MERCHANT_ISSUE`, `ENGINEERING_BUG`, `CONFIGURATION_ISSUE`), `updateInvestigationCategory(dealId, userEmail, category)` sends `POST /v1/deals/investigation?clientId=tpis` with body `{ dealId, userEmail, status: "ACKNOWLEDGED", category }`.
   - From: `bookDash_investigationClient`
   - To: `continuumPartnerService` (via `apiProxy`)
   - Protocol: REST (HTTPS POST)

4. **Reassign to another user**: `updateInvestigationUser(dealId, userEmail, status, category)` sends `POST /v1/deals/investigation?clientId=tpis` with the new user's email. This transfers investigation ownership while preserving status and category.
   - From: `bookDash_investigationClient`
   - To: `continuumPartnerService` (via `apiProxy`)
   - Protocol: REST (HTTPS POST)

5. **Resolve deal**: When the user marks the deal as resolved, `resolveDealInvestigation(dealId, userEmail, category)` sends `POST /v1/deals/investigation?clientId=tpis` with body `{ dealId, userEmail, status: "HEALTHY", category }`. This transitions the deal's investigation status to healthy.
   - From: `bookDash_investigationClient`
   - To: `continuumPartnerService` (via `apiProxy`)
   - Protocol: REST (HTTPS POST)

6. **Update local state**: After a successful investigation action, `onDealUpdate(dealId, updatedData)` is called in `AppShell` to update the deal's `investigation` field in the React state without a full data reload. The Deals view re-renders with the updated investigation status.
   - From: `bookDash_appShell`
   - To: React state (`setDeals`)
   - Protocol: In-process

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| POST investigation returns HTTP error | Error propagated; `ToastNotification` displayed to user | Investigation state unchanged in Partner Service |
| GET investigation history returns empty | Empty array returned; "No history" shown in modal | User can still initiate a new investigation |
| Concurrent investigation actions | No explicit lock; last write wins in Partner Service | Investigation state reflects the most recent action |
| User session expired during investigation | API returns 401; `user` set to `null`; login flow triggered | User redirected to login; investigation action must be retried |

## Sequence Diagram

```
User -> AppShell: Open investigation modal for deal
AppShell -> InvestigationClient: fetchDealInvestigationHistory(dealId)
InvestigationClient -> PartnerService: GET /v1/deals/investigation/{dealId}?clientId=tpis
PartnerService --> InvestigationClient: DealInvestigation[]
InvestigationClient --> AppShell: history array
AppShell -> Browser: Render InvestigationModal with history

User -> AppShell: Click "Acknowledge"
AppShell -> InvestigationClient: acknowledgeDeal(dealId, userEmail)
InvestigationClient -> PartnerService: POST /v1/deals/investigation (status=ACKNOWLEDGED)
PartnerService --> InvestigationClient: DealInvestigation (created)
InvestigationClient --> AppShell: updated investigation record
AppShell -> AppShell: onDealUpdate(dealId, { investigation: ... })

User -> AppShell: Select category "MERCHANT_ISSUE"
AppShell -> InvestigationClient: updateInvestigationCategory(dealId, userEmail, category)
InvestigationClient -> PartnerService: POST /v1/deals/investigation (status=ACKNOWLEDGED, category=MERCHANT_ISSUE)
PartnerService --> InvestigationClient: DealInvestigation (updated)

User -> AppShell: Click "Resolve"
AppShell -> InvestigationClient: resolveDealInvestigation(dealId, userEmail, category)
InvestigationClient -> PartnerService: POST /v1/deals/investigation (status=HEALTHY)
PartnerService --> InvestigationClient: DealInvestigation (resolved)
InvestigationClient --> AppShell: resolved record
AppShell -> AppShell: onDealUpdate(dealId, { investigation: { status: HEALTHY } })
AppShell -> Browser: Re-render deals list with resolved status
```

## Related

- Architecture dynamic view: `dynamic-bookability-dashboard-data-fetch`
- Related flows: [Deal Health Check Monitoring](deal-health-check-monitoring.md), [Dashboard Data Load](dashboard-data-load.md)
