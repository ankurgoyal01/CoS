---
service: "proximity-notification-service"
title: "Hotzone Management Flow"
generated: "2026-03-03"
type: flow
flow_name: "hotzone-management-flow"
flow_type: synchronous
trigger: "API call from Proximity UI or internal admin tooling"
participants:
  - "continuumProximityNotificationService"
  - "continuumProximityNotificationPostgres"
architecture_ref: "dynamic-hotzone_management_flow"
---

# Hotzone Management Flow

## Summary

The Proximity UI and internal admin tooling interact with the service's hotzone management API to create, update, browse, and delete Hotzone deals and their associated category campaigns. These operations directly read from and write to PostgreSQL via the Hotzone Workflow and Persistence Layer components. This flow also covers email notifications sent to consumers for specific hotzone deals.

## Trigger

- **Type**: api-call
- **Source**: Proximity UI (admin interface at `https://github.groupondev.com/Emerging-Channels/proximity-ui`) or internal scripts
- **Frequency**: On-demand (admin operations)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Proximity UI / Admin caller | Initiates CRUD requests for hotzone deals and campaigns | External admin UI |
| API Resources | Routes hotzone management requests to the Hotzone Workflow | `continuumProximityNotificationService` / `proximitynotificationservice_apiResources` |
| Hotzone Workflow | Executes business logic for hotzone entity management | `continuumProximityNotificationService` / `hotzoneWorkflow` |
| Persistence Layer | Reads and writes hotzone and campaign records via JDBI DAOs | `continuumProximityNotificationService` / `proximitynotificationservice_persistenceLayer` |
| PostgreSQL | Stores hotzone deals, category campaigns, and UI user records | `continuumProximityNotificationPostgres` |

## Steps

### Hotzone Deal CRUD

1. **Ingest hotzone deals**: Caller POSTs a `PostHotzoneRequest` body containing a list of `HotzoneDeal` objects to `POST /v1/proximity/location/hotzone`.
   - From: Proximity UI
   - To: `continuumProximityNotificationService` (API Resources)
   - Protocol: HTTPS/JSON

2. **Persists deals to PostgreSQL**: Hotzone Workflow calls the Persistence Layer to upsert the deal records.
   - From: Hotzone Workflow
   - To: `continuumProximityNotificationPostgres`
   - Protocol: JDBI/JDBC

3. **Browse hotzone deals**: Caller POSTs a `DatatableRequest` to `POST /v1/proximity/location/hotzone/browse` to retrieve paginated results.
   - From: Proximity UI
   - To: `continuumProximityNotificationService`
   - Protocol: HTTPS/JSON

4. **Read single deal**: Caller GETs `GET /v1/proximity/location/hotzone/{hotzoneId}` to retrieve a specific deal by UUID.
   - From: Proximity UI
   - To: `continuumProximityNotificationService` → `continuumProximityNotificationPostgres`
   - Protocol: HTTPS/JSON → JDBI/JDBC

5. **Delete deal by ID**: Caller sends `DELETE /v1/proximity/location/hotzone/{hotZoneId}`.
   - From: Proximity UI
   - To: `continuumProximityNotificationService` → `continuumProximityNotificationPostgres`
   - Protocol: HTTPS/JSON → JDBI/JDBC

6. **Delete expired deals**: Caller POSTs to `POST /v1/proximity/location/hotzone/delete-expired`; all deals with `expires < now` are removed.
   - From: Proximity UI or scheduler
   - To: `continuumProximityNotificationService` → `continuumProximityNotificationPostgres`
   - Protocol: HTTPS/JSON → JDBI/JDBC

### Campaign Management

7. **Create/update/delete campaigns**: Caller uses `POST /v1/proximity/location/hotzone/campaign` (create), `POST /v1/proximity/location/hotzone/campaign/{id}` (update), or `DELETE /v1/proximity/location/hotzone/campaign/{id}` (delete) to manage `HotzoneCategoryCampaign` records.
   - From: Proximity UI
   - To: `continuumProximityNotificationService` → `continuumProximityNotificationPostgres`
   - Protocol: HTTPS/JSON → JDBI/JDBC

### Email Notification

8. **Send email for consumer**: Caller POSTs to `POST /v1/proximity/location/hotzone/{consumer_id}/send-email`. The Hotzone Workflow retrieves the consumer's relevant hotzone deal and dispatches an email via the Rocketman service using `PushNotificationEmailRequest`.
   - From: Proximity UI
   - To: `continuumProximityNotificationService` → Rocketman push service
   - Protocol: HTTPS/JSON → HTTP/JSON

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Deal or campaign not found | HTTP 404 response | Client receives error, no data modified |
| Invalid request body | HTTP 400 (Dropwizard validation) | Request rejected before reaching database |
| PostgreSQL write failure | JDBI exception propagated to HTTP 500 | Operation fails; client must retry |
| Email send failure | `SendEmailException` thrown and logged | Email not delivered; HTTP 500 returned |

## Sequence Diagram

```
ProximityUI           -> ProximityNotificationService: POST/GET/DELETE hotzone or campaign endpoint
ProximityNotificationService -> HotzoneWorkflow: route management request
HotzoneWorkflow       -> PostgreSQL: read/write hotzone deal or campaign
PostgreSQL            --> HotzoneWorkflow: result
HotzoneWorkflow       --> ProximityNotificationService: result
ProximityNotificationService --> ProximityUI: HTTP response (deal/campaign data or confirmation)
```

## Related

- Architecture component: `hotzoneWorkflow` within `continuumProximityNotificationService`
- Related flows: [Hotzone Batch Generation Flow](hotzone-batch-generation-flow.md), [Geofence Notification Flow](geofence-notification-flow.md)
