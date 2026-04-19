---
service: "partner-service"
title: "Partner Onboarding Workflow"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "partner-onboarding-workflow"
flow_type: asynchronous
trigger: "Operator API call or MBus workflow event initiating new 3PIP partner creation"
participants:
  - "continuumPartnerService"
  - "continuumPartnerServicePostgres"
  - "messageBus"
  - "salesForce"
  - "continuumDealCatalogService"
  - "continuumDealManagementApi"
  - "continuumEpodsService"
  - "continuumUsersService"
architecture_ref: "dynamic-partner-onboarding-workflow"
---

# Partner Onboarding Workflow

## Summary

The partner onboarding workflow creates and fully configures a new 3PIP partner record within the Continuum platform. It orchestrates a sequence of calls across Salesforce (CRM account sync), Deal Management API (merchant creation), Deal Catalog (deal setup), ePOS (inventory sync), and Users Service (contact resolution), persisting state at each stage to `continuumPartnerServicePostgres` and publishing progress events to MBus. The workflow is designed to resume from the last completed stage after a failure.

## Trigger

- **Type**: api-call or event
- **Source**: Operator tooling calls `/partner-service/v1/partners` to initiate onboarding, or a MBus message triggers the workflow for async continuation
- **Frequency**: On-demand, once per new partner

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Partner Service | Workflow orchestrator; persists state and coordinates all steps | `continuumPartnerService` |
| Partner Service Postgres | Durable workflow state store; records stage completion and partner config | `continuumPartnerServicePostgres` |
| MBus | Async event bus for workflow progress events and inter-step coordination | `messageBus` |
| Salesforce | CRM system of record for partner account and opportunity data | `salesForce` |
| Deal Management API | Creates and manages merchant entities for the new partner | `continuumDealManagementApi` |
| Deal Catalog Service | Creates and links deal catalog entities for the partner | `continuumDealCatalogService` |
| ePOS Service (ePods) | Synchronizes partner merchant and inventory data into the commerce engine | `continuumEpodsService` |
| Users Service | Resolves user and contact information associated with the partner record | `continuumUsersService` |

## Steps

1. **Receives onboarding request**: Operator or automated process calls the partner onboarding endpoint or publishes a workflow trigger event.
   - From: `partnerSvc_apiResources` or `partnerSvc_mbusAndScheduler`
   - To: `partnerSvc_domainServices`
   - Protocol: direct

2. **Persists initial partner record**: Creates a new partner entity in pending state with the provided configuration.
   - From: `partnerSvc_domainServices`
   - To: `continuumPartnerServicePostgres`
   - Protocol: JDBC

3. **Resolves user and contact data**: Retrieves user and contact information to associate with the new partner record.
   - From: `partnerSvc_integrationClients`
   - To: `continuumUsersService`
   - Protocol: HTTP/JSON

4. **Synchronizes Salesforce account**: Creates or links the partner account in Salesforce and retrieves opportunity metadata.
   - From: `partnerSvc_integrationClients`
   - To: `salesForce`
   - Protocol: HTTPS/REST

5. **Creates merchant via Deal Management API**: Initiates merchant entity creation to represent the partner in the commerce engine.
   - From: `partnerSvc_integrationClients`
   - To: `continuumDealManagementApi`
   - Protocol: HTTP/JSON

6. **Creates deal catalog entries**: Creates and links deal catalog entities for the partner's products.
   - From: `partnerSvc_integrationClients`
   - To: `continuumDealCatalogService`
   - Protocol: HTTP/JSON

7. **Synchronizes ePOS inventory data**: Pushes partner merchant and inventory data into the ePOS system for commerce availability.
   - From: `partnerSvc_integrationClients`
   - To: `continuumEpodsService`
   - Protocol: HTTP/JSON

8. **Updates partner record to active**: Marks the partner entity as fully onboarded and active in `continuumPartnerServicePostgres`.
   - From: `partnerSvc_domainServices`
   - To: `continuumPartnerServicePostgres`
   - Protocol: JDBC

9. **Publishes onboarding completion event**: Emits a partner workflow event to MBus signaling successful onboarding.
   - From: `partnerSvc_mbusAndScheduler`
   - To: `messageBus`
   - Protocol: JMS/STOMP

10. **Writes audit log entry**: Records the completed onboarding operation in the audit log.
    - From: `partnerSvc_domainServices`
    - To: `continuumPartnerServicePostgres`
    - Protocol: JDBC

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Salesforce API unavailable | Workflow stage marked failed in DB; retry via MBus message on next attempt | Onboarding paused at Salesforce step |
| Deal Management API returns error | Stage failure recorded; workflow halted; error event published to MBus | Partner record remains in pending state |
| Deal Catalog call fails | Stage failure recorded; workflow halted; operator notified via MBus event | Deal catalog entries not created |
| ePOS sync failure | Retry eligible; if exhausted, stage failure recorded | Inventory not visible until re-sync |
| Users Service unavailable | Non-blocking for some sub-flows; contact data may be incomplete | Partner created without full contact resolution |
| Database write failure | Exception propagated; workflow aborts; no event published | No partial state committed |

## Sequence Diagram

```
Operator/MBus -> partnerSvc_apiResources: POST /v1/partners (onboarding request)
partnerSvc_apiResources -> partnerSvc_domainServices: Invoke onboarding use case
partnerSvc_domainServices -> continuumPartnerServicePostgres: Insert partner record (pending)
partnerSvc_domainServices -> partnerSvc_integrationClients: Resolve user/contact
partnerSvc_integrationClients -> continuumUsersService: GET user/contact data
continuumUsersService --> partnerSvc_integrationClients: User/contact response
partnerSvc_integrationClients -> salesForce: Sync partner account
salesForce --> partnerSvc_integrationClients: Account/opportunity response
partnerSvc_integrationClients -> continuumDealManagementApi: Create merchant
continuumDealManagementApi --> partnerSvc_integrationClients: Merchant created
partnerSvc_integrationClients -> continuumDealCatalogService: Create deal catalog entries
continuumDealCatalogService --> partnerSvc_integrationClients: Catalog entries created
partnerSvc_integrationClients -> continuumEpodsService: Sync inventory data
continuumEpodsService --> partnerSvc_integrationClients: Sync confirmed
partnerSvc_domainServices -> continuumPartnerServicePostgres: Update partner to active
partnerSvc_domainServices -> continuumPartnerServicePostgres: Write audit log entry
partnerSvc_mbusAndScheduler -> messageBus: Publish onboarding completion event
```

## Related

- Architecture dynamic view: `dynamic-partner-onboarding-workflow`
- Related flows: [Deal Mapping Reconciliation](deal-mapping-reconciliation.md), [Partner Uptime and Metrics Reporting](partner-uptime-and-metrics-reporting.md)
