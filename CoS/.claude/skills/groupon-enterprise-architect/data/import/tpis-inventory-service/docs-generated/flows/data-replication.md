---
service: "tpis-inventory-service"
title: "Data Replication"
generated: "2026-03-03"
type: flow
flow_name: "data-replication"
flow_type: batch
trigger: "Scheduled replication pipeline"
participants:
  - "continuumThirdPartyInventoryDb"
  - "edw"
  - "bigQuery"
architecture_ref: ""
---

# Data Replication

## Summary

This flow describes how third-party inventory data is replicated from the TPIS MySQL database to the Enterprise Data Warehouse (EDW) and BigQuery for analytics and reporting. The replication pipeline extracts data from `continuumThirdPartyInventoryDb` and loads it into both downstream analytical stores, enabling data engineering and analytics teams to query and report on third-party inventory metrics.

## Trigger

- **Type**: schedule
- **Source**: Data replication pipeline (managed externally)
- **Frequency**: Scheduled (daily or near-real-time, to be confirmed by service owner)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| 3rd Party Inventory DB | Source of inventory data for replication | `continuumThirdPartyInventoryDb` |
| Enterprise Data Warehouse | Analytical data store for structured reporting | `edw` |
| BigQuery | Cloud analytical data store for ad-hoc querying | `bigQuery` |

## Steps

1. **Extract data from MySQL**: The replication pipeline reads inventory events and product data from the TPIS MySQL database.
   - From: `continuumThirdPartyInventoryDb`
   - To: Replication pipeline
   - Protocol: Database replication / ETL

2. **Load to EDW**: Extracted data is loaded into the Enterprise Data Warehouse.
   - From: Replication pipeline
   - To: `edw`
   - Protocol: Batch ETL

3. **Load to BigQuery**: Extracted data is loaded into BigQuery.
   - From: Replication pipeline
   - To: `bigQuery`
   - Protocol: Batch ETL

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Replication pipeline failure | Alert and retry | Analytics data becomes stale until resolved |
| Schema mismatch | Pipeline halts with error | Manual intervention required to align schemas |
| Partial load | Idempotent reload | Re-run replication for affected partition |

## Sequence Diagram

```
continuumThirdPartyInventoryDb -> ReplicationPipeline: Extract inventory data
ReplicationPipeline -> edw: Load data (Batch ETL)
ReplicationPipeline -> bigQuery: Load data (Batch ETL)
```

## Related

- Related flows: [Partner Inventory Sync](partner-inventory-sync.md), [Inventory Query](inventory-query.md)
