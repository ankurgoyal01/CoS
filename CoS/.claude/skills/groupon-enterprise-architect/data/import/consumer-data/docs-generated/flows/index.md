---
service: "consumer-data"
title: Flows
generated: "2026-03-03T00:00:00Z"
type: flows-index
flow_count: 6
---

# Flows

Process and flow documentation for Consumer Data Service 2.0.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Consumer Profile Fetch](consumer-profile-fetch.md) | synchronous | API call `GET /v1/consumers/:id` | Retrieves a consumer profile record from MySQL and returns it to the caller |
| [Consumer Profile Create/Update](consumer-profile-create-update.md) | synchronous | API call `PUT /v1/consumers/:id` | Writes consumer profile changes to MySQL and publishes a change event |
| [GDPR Account Erasure](gdpr-account-erasure.md) | event-driven | MessageBus event `jms.topic.gdpr.account.v1.erased` | Anonymises/deletes consumer record and publishes erasure completion event |
| [Account Creation Async](account-creation-async.md) | event-driven | MessageBus event `jms.topic.users.account.v1.created` | Provisions a new consumer profile row when a user account is created |
| [Location Management](location-management.md) | synchronous | API calls on `/v1/locations` | CRUD operations on consumer locations with optional geo enrichment via bhoomi |
| [Preference Management](preference-management.md) | synchronous | API calls on `/v1/preferences` | CRUD operations on consumer preferences persisted to MySQL |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 3 |
| Asynchronous (event-driven) | 2 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

- The [GDPR Account Erasure](gdpr-account-erasure.md) flow spans the GDPR orchestration service (publisher of the erasure event) and this service (processor), completing with a confirmation event back to the GDPR orchestrator.
- The [Account Creation Async](account-creation-async.md) flow originates in the Users Service and is consumed here to ensure consumer profile records are created in sync with account creation.
