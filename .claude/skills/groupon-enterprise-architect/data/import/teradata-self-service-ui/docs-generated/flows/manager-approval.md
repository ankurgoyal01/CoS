---
service: "teradata-self-service-ui"
title: "Manager Approval"
generated: "2026-03-03"
type: flow
flow_name: "manager-approval"
flow_type: synchronous
trigger: "Manager navigates to the Requests view and approves or declines a pending request"
participants:
  - "continuumTeradataSelfServiceUi"
  - "teradataSelfServiceApi"
architecture_ref: "dynamic-managerApproval"
---

# Manager Approval

## Summary

When an employee submits a new Teradata account request, the designated approving manager receives a notification (handled by `teradata-self-service-api`). The manager logs into the Teradata Self Service UI and navigates to the Requests view, where all pending requests requiring their approval are shown. The manager clicks a request to open the `ProcessRequestDialog`, reviews the details, and approves or declines. The UI calls the API approval endpoint, moves the request from the Pending queue to History, and shows a confirmation notification.

## Trigger

- **Type**: user-action
- **Source**: Manager navigates to `/requests` and clicks a pending request item
- **Frequency**: On demand; driven by the approval workflow for each new account request

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Browser / SPA (manager session) | Renders the pending requests list and the approval dialog; submits the decision | `continuumTeradataSelfServiceUi` |
| teradata-self-service-api | Records the approval/decline decision; provisions or rejects the Teradata account | `teradataSelfServiceApi` |

## Steps

1. **Manager navigates to Requests view**: The router loads `/requests`. The Vuex `state.requests` array (populated during bootstrap with items where `approver === currentUser && status === 'PENDING'`) is rendered as a list sorted by `lastUpdatedAt` ascending.
   - From: `Browser`
   - To: `SPA UI (Requests.vue)`
   - Protocol: Vue Router navigation

2. **Manager clicks a request**: The router navigates to `/requests/:id`. The `RequestRouter` renders both the `Requests` list and the `ProcessRequestDialog` as named router views. The `findRequest(id)` Vuex getter retrieves the matching request from `state.requests`.
   - From: `Browser`
   - To: `SPA UI (ProcessRequestDialog)`
   - Protocol: Vue Router named route `RequestItem`

3. **Process Request dialog renders**: The dialog displays the request details (requester, Jira key, request type, timestamps) and presents "Approve" and "Decline" action buttons.
   - From: `SPA UI`
   - To: `Browser`
   - Protocol: Vue reactive rendering

4. **Manager clicks Approve or Decline**: The dialog dispatches the Vuex `processRequest` action with `{ id, approved: true|false }`.
   - From: `Browser`
   - To: `SPA UI (ProcessRequestDialog)`
   - Protocol: user-action (click event)

5. **PUT approval decision to API**: The API client calls `PUT /api/v1/requests/:requestId/approvals` with body `{ approved: true|false }`.
   - From: `continuumTeradataSelfServiceUi` (API Client)
   - To: `teradataSelfServiceApi`
   - Protocol: HTTPS REST (proxied by Nginx)

6. **API processes the decision**: The backend updates the request status to `APPROVED` or `DECLINED`, provisions or rejects the Teradata account accordingly, and returns the updated request object.
   - From: `teradataSelfServiceApi`
   - To: `continuumTeradataSelfServiceUi` (API Client)
   - Protocol: HTTPS REST

7. **UI refreshes requests**: After a successful response, the UI re-dispatches `getRequests` to reload the pending/history split from the API, ensuring the approved request moves out of the pending queue.
   - From: `SPA UI`
   - To: `teradataSelfServiceApi`
   - Protocol: HTTPS REST

8. **Success notification shown**: EventBus emits `success`. The `NotificationDialog` shows a green snackbar confirming the decision.
   - From: `SPA UI`
   - To: `NotificationDialog`
   - Protocol: EventBus

9. **Dialog closes**: The router navigates back to `/requests`, showing the updated (shorter) pending list.
   - From: `SPA UI`
   - To: `Browser`
   - Protocol: Vue Router programmatic navigation

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| `PUT /api/v1/requests/:requestId/approvals` returns error | API client intercepts; GA exception event fired; EventBus emits `error` | Error snackbar shown; request remains in pending queue; dialog stays open |
| `getRequests` refresh fails after successful approval | Error notification shown | Pending queue may be stale; user prompted to refresh |
| Manager navigates directly to `/requests/:id` for a non-existent ID | `findRequest(id)` returns `undefined`; dialog renders with no data | Empty dialog displayed; no API call made until action is taken |

## Sequence Diagram

```
Manager -> SPA: Navigate to /requests
SPA -> Browser: Render pending requests list (from state.requests)
Manager -> SPA: Click request item → navigate to /requests/:id
SPA -> Browser: Open ProcessRequestDialog with request details
Manager -> SPA: Click "Approve" (or "Decline")
SPA -> teradataSelfServiceApi: PUT /api/v1/requests/:requestId/approvals {approved: true}
teradataSelfServiceApi --> SPA: 200 {data: {id, status: "APPROVED", ...}}
SPA -> teradataSelfServiceApi: GET /api/v1/requests
teradataSelfServiceApi --> SPA: 200 {data: [...updated requests...]}
SPA -> SPA: setRequests() — request moves from pending to history
SPA -> NotificationDialog: EventBus emit 'success'
SPA -> Browser: Navigate to /requests (updated pending list)
```

## Related

- Architecture dynamic view: `dynamic-managerApproval`
- Related flows: [New Account Request](new-account-request.md), [Application Bootstrap](app-bootstrap.md)
