---
service: "teradata-self-service-ui"
title: "Password Reset"
generated: "2026-03-03"
type: flow
flow_name: "password-reset"
flow_type: synchronous
trigger: "User clicks 'Reset Password' on their account item in the Accounts view"
participants:
  - "continuumTeradataSelfServiceUi"
  - "teradataSelfServiceApi"
architecture_ref: "dynamic-passwordReset"
---

# Password Reset

## Summary

This flow allows a Groupon employee to update the password for their personal Teradata account or a managed service account. The user selects the account to update, enters a new password in the `ResetPasswordDialog`, and the UI calls the backend credentials endpoint. The backend applies the change directly to the Teradata account. No approval workflow is required for password resets.

## Trigger

- **Type**: user-action
- **Source**: User clicks the "Reset Password" action on an account item in the `/accounts` view
- **Frequency**: On demand; the UI warns users that passwords expire every `configuration.passwordExpiryInDays` days (default 90)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Browser / SPA | Renders the Reset Password dialog; collects and submits the new password | `continuumTeradataSelfServiceUi` |
| teradata-self-service-api | Validates and applies the new password to the Teradata account | `teradataSelfServiceApi` |

## Steps

1. **User clicks "Reset Password" on an account item**: `AccountItems.vue` emits the `onResetPassword` event. `Account.vue` sets `showResetPassword = true` and records the selected account name in `state.accountName` via the `setAccountName` Vuex mutation.
   - From: `SPA UI (AccountItems)`
   - To: `SPA UI (Account.vue)`
   - Protocol: Vue event emit

2. **Reset Password dialog renders**: `ResetPasswordDialog.vue` is displayed, prompting the user to enter and confirm a new password.
   - From: `SPA UI`
   - To: `Browser`
   - Protocol: Vue reactive rendering

3. **User enters and submits new password**: The user types the new password and clicks the submit button. The dialog calls `store.dispatch('updatePassword', password)`.
   - From: `Browser`
   - To: `SPA UI (ResetPasswordDialog)`
   - Protocol: user-action

4. **Dispatch updatePassword action**: The Vuex action `updatePassword` calls `Api.updatePassword(state.accountName, { accountName: state.accountName, password: password })`.
   - From: `SPA UI`
   - To: `Vuex store`
   - Protocol: direct

5. **PUT credentials to API**: The API client calls `PUT /api/v1/accounts/:accountName/credentials` with body `{ accountName, password }`.
   - From: `continuumTeradataSelfServiceUi` (API Client)
   - To: `teradataSelfServiceApi`
   - Protocol: HTTPS REST (proxied by Nginx)

6. **API updates the Teradata account password**: The backend validates the new password against Teradata policy rules and applies it. Returns a success response.
   - From: `teradataSelfServiceApi`
   - To: `continuumTeradataSelfServiceUi` (API Client)
   - Protocol: HTTPS REST

7. **Success notification shown**: EventBus emits `success`. A green snackbar confirms the password has been updated.
   - From: `SPA UI`
   - To: `NotificationDialog`
   - Protocol: EventBus

8. **Dialog closes**: `ResetPasswordDialog` emits `onClose`. The `Account.vue` sets `showResetPassword = false`.
   - From: `ResetPasswordDialog`
   - To: `SPA UI`
   - Protocol: Vue event emit

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| `PUT /api/v1/accounts/:accountName/credentials` fails | API client interceptor fires; error code and message extracted; GA exception event sent; EventBus emits `error` | Error snackbar shown; dialog stays open; user can retry |
| Password does not meet Teradata policy (backend validation error) | Backend returns error code + message; API client maps to `{ code, msg }` | Error message shown in snackbar from `e.msg` |
| Network error (API unreachable) | Classified as `NETWORK_ERROR`; GA exception event fired | "Network Error" snackbar shown |

## Sequence Diagram

```
User -> SPA: Click "Reset Password" on account item
SPA -> SPA: setAccountName(accountName), showResetPassword = true
SPA -> Browser: Render ResetPasswordDialog
User -> SPA: Enter new password and click Submit
SPA -> teradataSelfServiceApi: PUT /api/v1/accounts/:accountName/credentials {accountName, password}
teradataSelfServiceApi --> SPA: 200 {newPasswordResponse}
SPA -> NotificationDialog: EventBus emit 'success'
SPA -> Browser: Close ResetPasswordDialog
```

## Related

- Architecture dynamic view: `dynamic-passwordReset`
- Related flows: [Application Bootstrap](app-bootstrap.md), [Account Reactivation](account-reactivation.md)
