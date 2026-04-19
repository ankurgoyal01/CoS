---
service: "tpis-inventory-service"
title: "Partner Inventory Sync"
generated: "2026-03-03"
type: flow
flow_name: "partner-inventory-sync"
flow_type: synchronous
trigger: "Partner inventory update or scheduled sync"
participants:
  - "thirdPartyInventory"
  - "continuumThirdPartyInventoryService"
  - "continuumThirdPartyInventoryDb"
architecture_ref: ""
---

# Partner Inventory Sync

## Summary

This flow describes how the Third Party Inventory Service ingests inventory data from external partner platforms. When partners update their inventory (availability changes, new products, booking status updates), TPIS receives the data, processes it, and persists the inventory events and product information to its MySQL database for consumption by downstream Continuum services.

## Trigger

- **Type**: api-call / schedule (inferred)
- **Source**: External 3rd-party inventory partner platforms
- **Frequency**: On-demand (partner-initiated) or scheduled polling

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| 3rd-Party Inventory Systems | Source of partner inventory data | `thirdPartyInventory` |
| Third Party Inventory Service | Receives, processes, and persists partner inventory data | `continuumThirdPartyInventoryService` |
| 3rd Party Inventory DB | Stores inventory events and product data | `continuumThirdPartyInventoryDb` |

## Steps

1. **Receive partner inventory data**: The Third Party Inventory Service receives inventory data from external partner platforms.
   - From: `thirdPartyInventory`
   - To: `continuumThirdPartyInventoryService`
   - Protocol: API (HTTP/REST inferred)

2. **Validate and transform**: The service validates the incoming partner data and transforms it into the internal TPIS data model.
   - From: `continuumThirdPartyInventoryService`
   - To: `continuumThirdPartyInventoryService`
   - Protocol: direct (internal processing)

3. **Persist inventory data**: The processed inventory events and product data are written to the MySQL database.
   - From: `continuumThirdPartyInventoryService`
   - To: `continuumThirdPartyInventoryDb`
   - Protocol: JDBC

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Partner API unavailable | Retry with backoff (inferred) | Sync delayed; stale data served |
| Invalid partner data | Validation rejection | Data rejected; error logged |
| Database write failure | Transaction rollback | Data not persisted; retry required |

## Sequence Diagram

```
thirdPartyInventory -> continuumThirdPartyInventoryService: Send inventory update (API)
continuumThirdPartyInventoryService -> continuumThirdPartyInventoryService: Validate and transform data
continuumThirdPartyInventoryService -> continuumThirdPartyInventoryDb: Write inventory events and products (JDBC)
continuumThirdPartyInventoryDb --> continuumThirdPartyInventoryService: Confirm write
continuumThirdPartyInventoryService --> thirdPartyInventory: Acknowledge receipt
```

## Related

- Related flows: [Inventory Query](inventory-query.md), [Data Replication](data-replication.md)
