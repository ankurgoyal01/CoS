---
service: "teradata-self-service-ui"
title: "Account Reactivation"
generated: "2026-03-03"
type: flow
flow_name: "account-reactivation"
flow_type: synchronous
trigger: "User clicks 'Reactivate' on an account shown with INACTIVE status"
participants:
  - "continuumTeradataSelfServiceUi"
  - "teradataSelfServiceApi"
architecture_ref: "dynamic-accountReactivation"
---

# Account Reactivation

## Summary

Teradata accounts that have been inactive for a period of time are placed in the `INACTIVE` status. This flow allows a Groupon employee to reactivate such an account through the same manager-approval workflow used for new account creation. The user confirms via the `ReactivateAccountDialog`, the UI calls the same `POST /api/v1/accounts/:userName` endpoint, and the request enters the pending approval queue. The GMS employee restriction applies to this flow as well.

## Trigger

- **Type**: user-action
- **Source**: User clicks the "Reactivate" action on an account item that has `status: 'INACTIVE'`
- **Frequency**: On demand; infrequent; triggered only when an account has been deactivated due to inactivity or policy

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Browser / SPA | Renders the Reactivate Account dialog; dispatches the reactivation request | `continuumTeradataSelfServiceUi` |
| teradata-self-service-api | Creates a reactivation request; routes to manager approval | `teradataSelfServiceApi` |

## Steps

1. **User clicks "Reactivate" on an account item**: `AccountItems.vue` emits `onReactivateAccount`. `Account.vue` handles this in `handleReactivateAccountClick()`. Before showing the dialog, it checks `user.companyId`. If the value is `'GMS'`, EventBus emits `gms-restriction` and the flow ends.
   - From: `SPA UI (AccountItems)`
   - To: `SPA UI (Account.vue)`
   - Protocol: Vue event emit

2. **Reactivate Account dialog renders**: `ReactivateAccountDialog.vue` is displayed. It shows the approving manager's name and explains that reactivation requires manager approval, matching the new account creation experience.
   - From: `SPA UI`
   - To: `Browser`
   - Protocol: Vue reactive rendering

3. **User clicks "Submit Request"**: The dialog dispatches `store.dispatch('createAccount')` — the same Vuex action used for new account creation.
   - From: `Browser`
   - To: `SPA UI (ReactivateAccountDialog)`
   - Protocol: user-action

4. **POST reactivation request**: The API client calls `POST /api/v1/accounts/:userName`. The backend interprets this as a reactivation request for an existing inactive account (rather than a brand-new account).
   - From: `continuumTeradataSelfServiceUi` (API Client)
   - To: `teradataSelfServiceApi`
   - Protocol: HTTPS REST (proxied by Nginx)

5. **API creates the reactivation request**: The backend creates a new pending request with `type: 'NEW_ACCOUNT_CREATION'` (same type as new account; the backend determines reactivation context from account state). Returns HTTP 201 with the new request object.
   - From: `teradataSelfServiceApi`
   - To: `continuumTeradataSelfServiceUi` (API Client)
   - Protocol: HTTPS REST

6. **Vuex adds request to history**: The `addHistory` mutation prepends the new request to `state.history`.
   - From: `Vuex store`
   - To: `SPA UI`
   - Protocol: reactive mutation

7. **Success notification shown**: EventBus emits `success`. Green snackbar confirms the reactivation request is pending manager approval.
   - From: `SPA UI`
   - To: `NotificationDialog`
   - Protocol: EventBus

8. **Accounts list refreshed**: `store.dispatch('getAccounts')` is called to reflect the updated account status.
   - From: `SPA UI`
   - To: `teradataSelfServiceApi`
   - Protocol: HTTPS REST

9. **Dialog closes**: After a 1.5-second delay, `ReactivateAccountDialog` emits `onClose`.
   - From: `ReactivateAccountDialog`
   - To: `SPA UI`
   - Protocol: Vue event emit

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| GMS employee attempts to reactivate account | Flow blocked before API call; `gms-restriction` EventBus event emitted | `GmsEmployeeDialog` shown; no API call made |
| `POST /api/v1/accounts/:userName` fails | `catch` block in dialog; EventBus emits `error` with `e.msg` | Error snackbar shown; dialog stays open |
| `getAccounts` refresh fails | EventBus emits error | Account list may be stale; user prompted to reload |

## Sequence Diagram

```
User -> SPA: Click "Reactivate" on INACTIVE account
SPA -> SPA: Check user.companyId !== 'GMS'
SPA -> Browser: Render ReactivateAccountDialog (shows manager name)
User -> SPA: Click "Submit Request"
SPA -> teradataSelfServiceApi: POST /api/v1/accounts/:userName
teradataSelfServiceApi --> SPA: 201 {data: {id, status: "PENDING", type: "NEW_ACCOUNT_CREATION", ...}}
SPA -> SPA: addHistory(request)
SPA -> NotificationDialog: EventBus emit 'success'
SPA -> teradataSelfServiceApi: GET /api/v1/accounts
teradataSelfServiceApi --> SPA: 200 {data: [...updated accounts...]}
SPA -> SPA: setAccounts(accounts)
SPA -> Browser: Close dialog, render updated Accounts view
```

## Related

- Architecture dynamic view: `dynamic-accountReactivation`
- Related flows: [New Account Request](new-account-request.md), [Manager Approval](manager-approval.md), [Application Bootstrap](app-bootstrap.md)
