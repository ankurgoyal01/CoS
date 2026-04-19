---
service: "bots"
title: "Deal Onboarding and Initialization"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "deal-onboarding-and-initialization"
flow_type: event-driven
trigger: "Message Bus event on deal.onboarding topic"
participants:
  - "messageBus"
  - "botsWorkerMbusConsumersComponent"
  - "botsWorkerJobServicesComponent"
  - "botsApiPersistenceComponent"
  - "botsApiIntegrationClientsComponent"
  - "continuumBotsMysql"
  - "continuumDealManagementService"
  - "continuumDealCatalogService"
  - "salesForce"
architecture_ref: "dynamic-bots-booking-request-flow"
---

# Deal Onboarding and Initialization

## Summary

When a new deal is onboarded onto the Groupon platform, the Deal Management system publishes a `deal.onboarding` event to the Message Bus. BOTS Worker consumes this event and initializes the full merchant booking configuration for that deal: it fetches deal metadata, creates campaign and service records in `continuumBotsMysql`, provisions default availability windows, and synchronizes relevant CRM state with Salesforce. A corresponding `deal.offboarding` event triggers teardown of the same configuration.

## Trigger

- **Type**: event
- **Source**: `deal.onboarding` event published to the Message Bus by the Deal Management platform
- **Frequency**: Per deal onboarding lifecycle event (on-demand, not scheduled)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Message Bus | Delivers the deal.onboarding event to BOTS Worker | `messageBus` |
| Message Bus Consumers | Routes the inbound event to job services | `botsWorkerMbusConsumersComponent` |
| Job Services | Orchestrates onboarding initialization logic | `botsWorkerJobServicesComponent` |
| Persistence Access | Writes campaign, service, and availability records | `botsApiPersistenceComponent` |
| Integration Clients | Calls Deal Management, Deal Catalog, and Salesforce | `botsApiIntegrationClientsComponent` |
| BOTS MySQL | Stores initialized merchant booking configuration | `continuumBotsMysql` |
| Deal Management API | Provides deal metadata for the onboarding event | `continuumDealManagementService` |
| Deal Catalog | Provides deal catalog entities | `continuumDealCatalogService` |
| Salesforce | Receives CRM onboarding state synchronization | `salesForce` |

## Steps

1. **Receive deal.onboarding event**: Message Bus delivers the event to `continuumBotsWorker`.
   - From: `messageBus`
   - To: `botsWorkerMbusConsumersComponent`
   - Protocol: Message Bus

2. **Route to job services**: Consumer component dispatches the event to job services for processing.
   - From: `botsWorkerMbusConsumersComponent`
   - To: `botsWorkerJobServicesComponent`
   - Protocol: Direct

3. **Fetch deal metadata**: Job services retrieve deal details from Deal Management API.
   - From: `botsApiIntegrationClientsComponent`
   - To: `continuumDealManagementService`
   - Protocol: REST

4. **Fetch deal catalog entities**: Job services retrieve catalog configuration for the deal.
   - From: `botsApiIntegrationClientsComponent`
   - To: `continuumDealCatalogService`
   - Protocol: REST

5. **Persist campaign configuration**: Job services write a new campaign record linked to the deal.
   - From: `botsApiPersistenceComponent`
   - To: `continuumBotsMysql`
   - Protocol: JDBC / SQL

6. **Persist service definitions**: Job services write service definitions for the bookable deal.
   - From: `botsApiPersistenceComponent`
   - To: `continuumBotsMysql`
   - Protocol: JDBC / SQL

7. **Provision default availability**: Job services write initial availability windows for the merchant/service.
   - From: `botsApiPersistenceComponent`
   - To: `continuumBotsMysql`
   - Protocol: JDBC / SQL

8. **Sync Salesforce CRM state**: Job services update the merchant onboarding state in Salesforce.
   - From: `botsApiIntegrationClientsComponent`
   - To: `salesForce`
   - Protocol: REST

9. **Acknowledge event**: Consumer acknowledges successful processing to the Message Bus.
   - From: `botsWorkerMbusConsumersComponent`
   - To: `messageBus`
   - Protocol: Message Bus

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Deal Management API unavailable | Retry via Message Bus retry policy | Event reprocessed; initialization delayed |
| Duplicate onboarding event | Idempotent write logic in persistence layer | No duplicate campaign/service records created |
| Salesforce sync failure | Log error; retry on next event redelivery | CRM state may lag; merchant setup still initialized in BOTS |
| DB write failure | Event nacked; retried by Message Bus | Initialization not persisted; retried |
| deal.offboarding event | Same consumer routes to deactivation job | Campaign/service records deactivated in `continuumBotsMysql` |

## Sequence Diagram

```
messageBus -> botsWorkerMbusConsumersComponent: deal.onboarding event
botsWorkerMbusConsumersComponent -> botsWorkerJobServicesComponent: Trigger onboarding job
botsWorkerJobServicesComponent -> botsApiIntegrationClientsComponent: Fetch deal metadata
botsApiIntegrationClientsComponent -> continuumDealManagementService: GET deal details
continuumDealManagementService --> botsApiIntegrationClientsComponent: Deal metadata
botsApiIntegrationClientsComponent -> continuumDealCatalogService: GET catalog entities
continuumDealCatalogService --> botsApiIntegrationClientsComponent: Catalog data
botsWorkerJobServicesComponent -> botsApiPersistenceComponent: Persist campaign, services, availability
botsApiPersistenceComponent -> continuumBotsMysql: INSERT campaign, services, availability records
continuumBotsMysql --> botsApiPersistenceComponent: Success
botsWorkerJobServicesComponent -> botsApiIntegrationClientsComponent: Sync Salesforce CRM state
botsApiIntegrationClientsComponent -> salesForce: PATCH merchant onboarding state
salesForce --> botsApiIntegrationClientsComponent: Updated
botsWorkerMbusConsumersComponent --> messageBus: Acknowledge event
```

## Related

- Architecture dynamic view: `dynamic-bots-booking-request-flow`
- Related flows: [Booking Creation and Confirmation](booking-creation-and-confirmation.md), [GDPR Data Erasure](gdpr-data-erasure.md)
