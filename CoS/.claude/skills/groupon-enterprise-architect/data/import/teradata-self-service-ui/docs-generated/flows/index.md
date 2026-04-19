---
service: "teradata-self-service-ui"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 5
---

# Flows

Process and flow documentation for Teradata Self Service UI.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Application Bootstrap](app-bootstrap.md) | synchronous | User navigates to the application URL | Initialises the SPA: reads SSO cookies, fetches user profile, configuration, accounts, and requests from the API, then renders the main UI |
| [New Account Request](new-account-request.md) | synchronous | User clicks "New Account" and submits the dialog | Submits a new Teradata account creation request to the API, which initiates a manager-approval workflow |
| [Manager Approval](manager-approval.md) | synchronous | Manager clicks a pending request and approves or declines | Fetches request detail, manager approves or declines via the API, request moves from Pending to History |
| [Password Reset](password-reset.md) | synchronous | User clicks "Reset Password" on their account | User sets a new password for their Teradata account via the API |
| [Account Reactivation](account-reactivation.md) | synchronous | User clicks "Reactivate" on an inactive account | Submits a reactivation request (same account-creation API endpoint) to restore an inactive Teradata account |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 5 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

All flows that mutate state cross the UI boundary into `teradata-self-service-api`. The API service is responsible for all Teradata provisioning operations, Jira ticket creation, and manager email notifications. These cross-service interactions are represented in the architecture model as a stub relationship from `continuumTeradataSelfServiceUi` to `teradataSelfServiceApi`.
