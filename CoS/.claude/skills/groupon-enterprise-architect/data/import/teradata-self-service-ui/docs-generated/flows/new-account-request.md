---
service: "teradata-self-service-ui"
title: "New Account Request"
generated: "2026-03-03"
type: flow
flow_name: "new-account-request"
flow_type: synchronous
trigger: "User clicks 'New Account' button on the Accounts view and confirms the dialog"
participants:
  - "continuumTeradataSelfServiceUi"
  - "teradataSelfServiceApi"
architecture_ref: "dynamic-newAccountRequest"
---

# New Account Request

## Summary

This flow covers the path a Groupon employee takes to request a new Teradata database account. The UI collects the user's intent, displays the approving manager's name (pre-populated from the user profile), and on confirmation submits the request to the backend API. The backend creates a pending request and initiates a manager-approval email workflow. The UI immediately refreshes the accounts list to reflect the new pending state.

## Trigger

- **Type**: user-action
- **Source**: User clicks the "New Account" button on the `/accounts` route
- **Frequency**: On demand; a user would only request a new account if they do not already have one

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Browser / SPA | Renders the New Account dialog; dispatches the creation request; refreshes account list | `continuumTeradataSelfServiceUi` |
| teradata-self-service-api | Creates the pending request record; notifies the approving manager | `teradataSelfServiceApi` |

## Steps

1. **User clicks "New Account"**: The `Account.vue` component handles the button click. Before showing the dialog, it checks `user.companyId`. If the value is `'GMS'`, the EventBus emits `gms-restriction` and the flow ends (GMS employees cannot create personal accounts).
   - From: `SPA UI (Account.vue)`
   - To: `SPA UI (GmsEmployeeDialog or NewAccountDialog)`
   - Protocol: EventBus / Vue reactive data

2. **New Account dialog renders**: `NewAccountDialog.vue` is displayed. The dialog shows the approving manager's name (from `state.user.managerName`) and an informational alert that a temporary password will be emailed once approved. The user cannot change the approver.
   - From: `SPA UI`
   - To: `Browser`
   - Protocol: Vue reactive rendering

3. **User clicks "Submit Request"**: `NewAccountDialog.methods.createAccount()` is called. The button enters loading state.
   - From: `Browser`
   - To: `SPA UI (NewAccountDialog)`
   - Protocol: user-action (click event)

4. **Dispatch createAccount action**: The Vuex action `createAccount` is dispatched. It calls `Api.createAccount(state.user.userName)`.
   - From: `SPA UI`
   - To: `Vuex store`
   - Protocol: direct

5. **POST new account request**: The API client calls `POST /api/v1/accounts/:userName` (where `:userName` is the authenticated user's username).
   - From: `continuumTeradataSelfServiceUi` (API Client)
   - To: `teradataSelfServiceApi`
   - Protocol: HTTPS REST (proxied by Nginx)

6. **API creates the request**: The backend creates a pending account-creation request record (with `status: 'PENDING'`, `type: 'NEW_ACCOUNT_CREATION'`, a generated Jira key, and the manager as approver). Returns HTTP 201 with the new request object.
   - From: `teradataSelfServiceApi`
   - To: `continuumTeradataSelfServiceUi` (API Client)
   - Protocol: HTTPS REST

7. **Vuex adds request to history**: The `addHistory` mutation prepends the new request object to `state.history` in the Vuex store.
   - From: `Vuex store`
   - To: `SPA UI (History view)`
   - Protocol: reactive mutation

8. **Success notification emitted**: EventBus emits `success` with the message "Account created and waiting for approval from {managerName}". The `NotificationDialog` component shows a green snackbar.
   - From: `NewAccountDialog`
   - To: `NotificationDialog`
   - Protocol: EventBus

9. **Refresh accounts list**: `store.dispatch('getAccounts')` is called to pull the updated account state from the API (the account may now show a pending status).
   - From: `SPA UI`
   - To: `teradataSelfServiceApi`
   - Protocol: HTTPS REST

10. **Dialog closes**: After a 1.5-second delay, the dialog closes automatically and the Accounts view updates.
    - From: `NewAccountDialog`
    - To: `SPA UI`
    - Protocol: Vue emit event (`onClose`)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| GMS employee attempts to create account | Flow blocked before API call; `gms-restriction` EventBus event emitted | `GmsEmployeeDialog` shown; no API call made |
| `POST /api/v1/accounts/:userName` returns an error | `catch` block in `createAccount()`; EventBus emits `error` with `e.msg`; GA records exception | Error snackbar shown; `createAccountStatus` remains false; dialog stays open |
| `getAccounts` refresh fails after successful create | EventBus emits error "There was a problem retrieving your accounts. Please refresh the page." | Account list may be stale; user prompted to reload |

## Sequence Diagram

```
User -> SPA: Click "New Account"
SPA -> SPA: Check user.companyId !== 'GMS'
SPA -> Browser: Display NewAccountDialog (shows manager name)
User -> SPA: Click "Submit Request"
SPA -> teradataSelfServiceApi: POST /api/v1/accounts/:userName
teradataSelfServiceApi --> SPA: 201 {data: {id, status: "PENDING", type: "NEW_ACCOUNT_CREATION", jiraKey, ...}}
SPA -> SPA: addHistory(request)
SPA -> NotificationDialog: EventBus emit 'success'
SPA -> teradataSelfServiceApi: GET /api/v1/accounts
teradataSelfServiceApi --> SPA: 200 {data: [...updated accounts...]}
SPA -> SPA: setAccounts(accounts)
SPA -> Browser: Close dialog, render updated Accounts view
```

## Related

- Architecture dynamic view: `dynamic-newAccountRequest`
- Related flows: [Application Bootstrap](app-bootstrap.md), [Manager Approval](manager-approval.md), [Account Reactivation](account-reactivation.md)
