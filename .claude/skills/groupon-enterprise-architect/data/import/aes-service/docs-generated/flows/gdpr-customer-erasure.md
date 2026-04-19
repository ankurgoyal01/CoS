---
service: "aes-service"
title: "GDPR Customer Erasure"
generated: "2026-03-03"
type: flow
flow_name: "gdpr-customer-erasure"
flow_type: event-driven
trigger: "MBus erasure topic event OR DELETE /api/v1/utils/erasure/deleteCustomer/{customerId}"
participants:
  - "aesMessagingConsumers"
  - "aesApiResources"
  - "aesDataAccessLayer"
  - "aesIntegrationClients"
  - "continuumAudienceExportPostgres"
  - "continuumCerebroWarehouse"
  - "messageBus"
  - "facebookAds"
  - "googleAds"
  - "microsoftAds"
  - "tiktokAds"
architecture_ref: "components-continuumAudienceExportService"
---

# GDPR Customer Erasure

## Summary

When a customer exercises their right to erasure under GDPR, AES must remove all personally identifiable data from its Postgres tables and delete the customer from every ad-network partner audience they are part of. The erasure can be triggered either by an account erasure event consumed from the MBus erasure topic, or directly via two sequential REST API calls (part one: Postgres tables; part two: denylist and Cerebro). After deletion, the customer ID is added to a denylist to prevent future re-export.

## Trigger

- **Type**: event or api-call
- **Source**: MBus erasure topic (automated GDPR pipeline) OR `DELETE /api/v1/utils/erasure/deleteCustomer/{customerId}` + `DELETE /api/v1/utils/erasure/deleteCerebro/{customerId}` (manual/API-driven)
- **Frequency**: Per-customer, on demand

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Messaging Consumers | Receives and processes MBus erasure events | `aesMessagingConsumers` |
| API Resources | Handles direct REST erasure API calls | `aesApiResources` |
| Data Access Layer | Deletes customer records from AES Postgres tables | `aesDataAccessLayer` |
| Integration Clients | Coordinates removal from ad-network partner audiences | `aesIntegrationClients` |
| AES Postgres | Tables where customer records are removed; denylist table updated | `continuumAudienceExportPostgres` |
| Cerebro Warehouse | Cerebro-side customer data removed in Part 2 | `continuumCerebroWarehouse` |
| MBus | Delivers the account erasure event | `messageBus` |
| Facebook Ads | Customer removed from all Facebook Custom Audiences | `facebookAds` |
| Google Ads | Customer removed from all Google Customer Match audiences | `googleAds` |
| Microsoft Bing Ads | Customer removed from Microsoft audience customer lists | `microsoftAds` |
| TikTok Ads | Customer removed from TikTok audience segments | `tiktokAds` |

## Steps

### Part 1 — Postgres deletion

1. **Receive erasure trigger**: Either an `AccountErasureRequest` event arrives on the MBus erasure topic, or an operator calls `DELETE /api/v1/utils/erasure/deleteCustomer/{customerId}`.
   - From: MBus / Caller
   - To: `aesMessagingConsumers` / `aesApiResources`
   - Protocol: MBus / HTTPS/REST

2. **Delete customer from AES Postgres tables**: Removes customer records from all relevant tables (audience data, filtered users, email/device ID mappings).
   - From: `aesDataAccessLayer`
   - To: `continuumAudienceExportPostgres`
   - Protocol: JDBC

3. **Add customer to denylist**: Inserts a denylist entry to prevent future re-export of this customer.
   - From: `aesDataAccessLayer`
   - To: `continuumAudienceExportPostgres`
   - Protocol: JDBC

4. **Remove customer from all partner audiences**: For each active ad-network partner, calls the Integration Client to delete the customer's hashed identifiers from every audience they belong to.
   - From: `aesIntegrationClients`
   - To: `facebookAds` / `googleAds` / `microsoftAds` / `tiktokAds`
   - Protocol: HTTPS/REST, HTTPS/gRPC, HTTPS/Bulk API

### Part 2 — Cerebro and denylist tasks (REST path only)

5. **Trigger Cerebro erasure**: Operator calls `DELETE /api/v1/utils/erasure/deleteCerebro/{customerId}`.
   - From: Caller
   - To: `aesApiResources`
   - Protocol: HTTPS/REST

6. **Remove customer from Cerebro tables**: Coordinates deletion of customer records from Cerebro warehouse tables via Integration Clients.
   - From: `aesIntegrationClients`
   - To: `continuumCerebroWarehouse`
   - Protocol: JDBC

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| MBus event processing failure | MBus platform retry semantics apply | Erasure retried; monitored via MBus ELK dashboard |
| Partner API failure during deletion | Error logged; operation may need manual follow-up | Customer may remain in partner audience temporarily |
| Cerebro deletion failure | Error logged | Requires manual intervention or re-call of `deleteCerebro` endpoint |

## Sequence Diagram

```
MBus/Caller -> aesMessagingConsumers/aesApiResources: Account erasure event or DELETE request
aesMessagingConsumers -> aesDataAccessLayer: Delete customer from all AES Postgres tables
aesDataAccessLayer -> continuumAudienceExportPostgres: DELETE rows; INSERT denylist entry
aesMessagingConsumers -> aesIntegrationClients: Remove customer from partner audiences
aesIntegrationClients -> facebookAds: Delete user from Custom Audiences
aesIntegrationClients -> googleAds: Remove user from Customer Match lists
aesIntegrationClients -> microsoftAds: Remove user from customer lists
aesIntegrationClients -> tiktokAds: Remove user from audience segments
```

## Related

- Architecture dynamic view: `components-continuumAudienceExportService`
- Related flows: [Scheduled Audience Export](scheduled-audience-export.md)
- Events: [Events](../events.md)
- API reference: `DELETE /api/v1/utils/erasure/deleteCustomer/{customerId}` and `deleteCerebro/{customerId}` — [API Surface](../api-surface.md)
