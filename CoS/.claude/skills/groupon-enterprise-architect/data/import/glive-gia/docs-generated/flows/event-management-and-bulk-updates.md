---
service: "glive-gia"
title: "Event Management and Bulk Updates"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "event-management-and-bulk-updates"
flow_type: synchronous
trigger: "Admin user creates, edits, or bulk-updates events on a deal"
participants:
  - "continuumGliveGiaWebApp"
  - "continuumGliveGiaMysqlDatabase"
  - "continuumGliveGiaRedisCache"
architecture_ref: "dynamic-glive-gia-event-management"
---

# Event Management and Bulk Updates

## Summary

GIA allows GrouponLive operations admins to manage live event instances (shows, performances) attached to a deal. Admins can create individual events, update their details, or perform bulk updates across multiple events in a single operation. Changes are persisted to MySQL and, where inventory availability must be reflected in consumer-facing systems, an async job is enqueued to push updates to the Inventory Service.

## Trigger

- **Type**: user-action
- **Source**: Admin accessing `/deals/:id/events` or `/deals/:id/events/bulk_update` in the GIA web UI
- **Frequency**: On-demand

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| GIA Web App | Handles HTTP requests, validates input, orchestrates persistence and job enqueue | `continuumGliveGiaWebApp` |
| GIA MySQL Database | Stores event records; updated on create/edit/bulk-update | `continuumGliveGiaMysqlDatabase` |
| GIA Redis | Receives enqueued Resque job for async Inventory Service sync | `continuumGliveGiaRedisCache` |
| GIA Background Worker | Processes async job to push event updates to Inventory Service | `continuumGliveGiaWorker` |

## Steps

1. **Admin submits event changes**: Admin creates a new event (`POST /deals/:id/events`), edits one (`PATCH /deals/:id/events/:event_id`), or submits a bulk update (`PUT /deals/:id/events/bulk_update`)
   - From: Admin browser
   - To: `continuumGliveGiaWebApp` (`gliveGia_webControllers`)
   - Protocol: REST (HTTP POST/PUT/PATCH)

2. **Validate and write event records**: `gliveGia_webControllers` invokes `businessServices`; `domainModels` validate and persist event records to MySQL; for bulk_update, all affected events are written in a single transaction
   - From: `continuumGliveGiaWebApp` (`businessServices` -> `domainModels`)
   - To: `continuumGliveGiaMysqlDatabase`
   - Protocol: ActiveRecord / MySQL

3. **Paper Trail audit**: Paper Trail records a version entry for each modified event record
   - From: `domainModels` (Paper Trail callbacks)
   - To: `continuumGliveGiaMysqlDatabase` (versions table)
   - Protocol: ActiveRecord / MySQL

4. **Enqueue inventory sync job**: `jobEnqueuer` pushes an async Resque job to Redis to synchronize updated event inventory with the Inventory Service
   - From: `continuumGliveGiaWebApp` (`jobEnqueuer`)
   - To: `continuumGliveGiaRedisCache`
   - Protocol: Resque / Redis

5. **Worker processes inventory sync**: `resqueWorkers_GliGia` pulls the job; `jobServices_GliGia` calls `workerRemoteClients_GliGia` to push updated event data to the Inventory Service
   - From: `continuumGliveGiaWorker` (`resqueWorkers_GliGia` -> `jobServices_GliGia` -> `workerRemoteClients_GliGia`)
   - To: Inventory Service (`inventoryService_unknown_1a2b`)
   - Protocol: REST

6. **Render response**: Controller renders the updated events list or redirects with a success flash
   - From: `continuumGliveGiaWebApp`
   - To: Admin browser
   - Protocol: HTTP 200 / 302

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Event validation failure | ActiveRecord validation errors returned to controller | Admin sees inline errors; no DB write |
| MySQL write failure during bulk_update | Transaction rolls back all event writes | No partial updates; admin sees error |
| Inventory Service unavailable | Resque job fails; retried by Resque | GIA events updated; Inventory Service sync delayed until retry succeeds |
| Bulk update with conflicting state | Business service raises error; transaction aborted | Admin informed of conflict; no partial write |

## Sequence Diagram

```
Admin -> GIA Web App: POST/PATCH /deals/:id/events (or bulk_update)
GIA Web App -> GIA MySQL Database: INSERT/UPDATE events (transactional)
GIA MySQL Database --> GIA Web App: events persisted
GIA Web App -> GIA Redis: RPUSH glive_gia_default (inventory sync job)
GIA Redis --> GIA Web App: job enqueued
GIA Web App --> Admin: 200 OK / redirect to events list
GIA Background Worker -> GIA Redis: LPOP job
GIA Background Worker -> Inventory Service: PUT /products/:id/events (sync updates)
Inventory Service --> GIA Background Worker: 200 OK
```

## Related

- Architecture dynamic view: `dynamic-glive-gia-event-management`
- Related flows: [Deal Creation from DMAPI](deal-creation-from-dmapi.md), [Ticketmaster Event Import](ticketmaster-event-import.md)
