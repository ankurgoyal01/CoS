---
service: "arbitration-service"
title: "Delivery Rule Management"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "delivery-rule-management"
flow_type: synchronous
trigger: "Admin CRUD operations on /delivery-rules endpoints"
participants:
  - "continuumArbitrationService"
  - "apiHandlers"
  - "deliveryRuleManager"
  - "campaignMetaAccess"
  - "absPostgres"
  - "continuumJiraService"
  - "notificationAdapterArbSer"
  - "notificationEmailService"
architecture_ref: "dynamic-deliveryRuleManagement"
---

# Delivery Rule Management

## Summary

The delivery rule management flow covers administrative CRUD operations on delivery rules — the configuration records that govern arbitration behavior and campaign eligibility. When rules are created or updated, the service creates or updates an approval workflow ticket in Jira and may send operational notification emails. Updated rules take effect in future arbitration decisions once the in-memory rule cache is refreshed. This flow is used by campaign operators to configure and maintain the decisioning logic.

## Trigger

- **Type**: api-call
- **Source**: Administrative callers (campaign operators or internal tooling) invoking CRUD endpoints on `/delivery-rules`
- **Frequency**: on demand, low frequency relative to decisioning traffic

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| API Handlers | Receives and validates the admin CRUD request; routes to delivery rule manager | `apiHandlers` |
| Delivery Rule Manager | Executes rule create/update/delete logic; triggers approval workflow and notifications | `deliveryRuleManager` |
| Campaign Metadata Access | Reads and writes delivery rule records in PostgreSQL | `campaignMetaAccess` |
| PostgreSQL | Persistent store for delivery rule definitions | `absPostgres` |
| Jira | Receives create/update requests for approval workflow tickets | `continuumJiraService` |
| Notification Adapter | Sends operational notification emails for rule changes | `notificationAdapterArbSer` |
| Notification Email Service | Delivers the operational notification email | `notificationEmailService` |

## Steps

### Create Delivery Rule (`POST /delivery-rules`)

1. **Receive create request**: Admin caller sends new rule definition via `POST /delivery-rules`.
   - From: admin caller
   - To: `apiHandlers`
   - Protocol: REST/HTTPS

2. **Validate and route**: API handler validates the rule payload and routes to delivery rule manager.
   - From: `apiHandlers`
   - To: `deliveryRuleManager`
   - Protocol: direct (in-process)

3. **Persist new rule to PostgreSQL**: Delivery rule manager writes the new rule record to PostgreSQL via campaign metadata access.
   - From: `deliveryRuleManager` via `campaignMetaAccess`
   - To: `absPostgres`
   - Protocol: PostgreSQL

4. **Create Jira approval workflow ticket**: Delivery rule manager calls the Jira API to create a new approval workflow ticket referencing the pending rule change.
   - From: `deliveryRuleManager`
   - To: `continuumJiraService`
   - Protocol: HTTPS

5. **Send operational notification**: Delivery rule manager triggers an email notification for the rule creation event.
   - From: `deliveryRuleManager` via `notificationAdapterArbSer`
   - To: `notificationEmailService`
   - Protocol: SMTP/HTTP

6. **Return confirmation**: API handler returns the created rule record to the caller.
   - From: `apiHandlers`
   - To: admin caller
   - Protocol: REST/HTTPS (JSON response)

### Update Delivery Rule (`PUT /delivery-rules/:id`)

1. **Receive update request**: Admin caller sends updated rule definition for the specified rule ID.
   - From: admin caller
   - To: `apiHandlers`
   - Protocol: REST/HTTPS

2. **Validate and route**: API handler validates the update payload and routes to delivery rule manager.
   - From: `apiHandlers`
   - To: `deliveryRuleManager`
   - Protocol: direct (in-process)

3. **Update rule in PostgreSQL**: Delivery rule manager writes the updated rule record to PostgreSQL.
   - From: `deliveryRuleManager` via `campaignMetaAccess`
   - To: `absPostgres`
   - Protocol: PostgreSQL

4. **Update Jira approval workflow ticket**: Delivery rule manager updates the existing Jira ticket (or creates a new one) to reflect the pending change.
   - From: `deliveryRuleManager`
   - To: `continuumJiraService`
   - Protocol: HTTPS

5. **Return confirmation**: API handler returns the updated rule record.
   - From: `apiHandlers`
   - To: admin caller
   - Protocol: REST/HTTPS (JSON response)

### Delete Delivery Rule (`DELETE /delivery-rules/:id`)

1. **Receive delete request**: Admin caller sends delete request for the specified rule ID.
   - From: admin caller
   - To: `apiHandlers`
   - Protocol: REST/HTTPS

2. **Execute delete in PostgreSQL**: Delivery rule manager removes the rule record from PostgreSQL.
   - From: `deliveryRuleManager` via `campaignMetaAccess`
   - To: `absPostgres`
   - Protocol: PostgreSQL

3. **Return confirmation**: API handler returns a deletion confirmation.
   - From: `apiHandlers`
   - To: admin caller
   - Protocol: REST/HTTPS (JSON response)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| PostgreSQL write failure | Return HTTP 500 | Rule change not persisted; Jira ticket not created |
| Jira API failure | Log error; rule change still persisted to PostgreSQL | Rule is saved but approval workflow ticket creation fails; non-blocking |
| Notification email failure | Log error; rule change and Jira ticket unaffected | Operational notification not sent; non-blocking |
| Rule ID not found on update/delete | Return HTTP 404 | No change made |
| Invalid rule payload | Return HTTP 400 with validation errors | Request rejected before any data store access |

## Sequence Diagram

```
adminCaller -> apiHandlers: POST/PUT/DELETE /delivery-rules[/:id]
apiHandlers -> deliveryRuleManager: invoke rule management operation
deliveryRuleManager -> absPostgres: write/update/delete delivery rule record
absPostgres --> deliveryRuleManager: write confirmation
deliveryRuleManager -> continuumJiraService: create/update approval workflow ticket
continuumJiraService --> deliveryRuleManager: ticket confirmation
deliveryRuleManager -> notificationAdapterArbSer: trigger operational notification
notificationAdapterArbSer -> notificationEmailService: send notification email
notificationEmailService --> notificationAdapterArbSer: send confirmation
deliveryRuleManager --> apiHandlers: operation result
apiHandlers --> adminCaller: HTTP 200/201 (rule record JSON)
```

## Related

- Architecture dynamic view: `dynamic-deliveryRuleManagement`
- Related flows: [Best-For Selection](best-for-selection.md) — uses delivery rules loaded from PostgreSQL
- Related flows: [Startup Cache Loading](startup-cache-loading.md) — preloads delivery rules into memory at startup
