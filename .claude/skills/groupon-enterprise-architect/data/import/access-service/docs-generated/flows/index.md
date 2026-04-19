---
service: "mx-merchant-access"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 6
---

# Flows

Process and flow documentation for the Merchant Access Service.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Create Merchant Contact](create-merchant-contact.md) | synchronous | `POST /v1/contact` API call | Creates a new user-to-merchant binding and grants initial access rights |
| [Assign Application Access](assign-application-access.md) | synchronous | `POST /v1/contact/{account_uuid}/{merchant_uuid}/application/{application_name}/access` API call | Assigns or updates the role of a contact within a specific application |
| [Delete Merchant Contact](delete-merchant-contact.md) | synchronous | `DELETE /v1/contact/{account_uuid}/{merchant_uuid}` API call | Removes a user-to-merchant binding and revokes all associated rights |
| [Set Primary Contact](set-primary-contact.md) | synchronous | `PUT /v1/merchant/{merchant_identifier}/primary_contact` API call | Designates a merchant contact as the primary contact for a merchant |
| [Account Lifecycle Cleanup](account-lifecycle-cleanup.md) | event-driven | MBus event (account_deactivated, account_erased, account_merged) | Removes all merchant access data when a user account is deactivated, erased, or merged |
| [Query Contact Access](query-contact-access.md) | synchronous | `GET /v1/contact` or `GET /v1/contact/{account_uuid}/{merchant_uuid}` API call | Returns contact and access information for a given account-merchant pair or list |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 5 |
| Asynchronous (event-driven) | 1 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

The Account Lifecycle Cleanup flow spans the users-service (publisher) and the Merchant Access Service (consumer) via the MBus `messageBus` container. The event payload originates in the users-service, is routed through MBus, and processed by `accessSvc_mbusConsumers` in `continuumAccessService`. See [Account Lifecycle Cleanup](account-lifecycle-cleanup.md) for the full flow.
