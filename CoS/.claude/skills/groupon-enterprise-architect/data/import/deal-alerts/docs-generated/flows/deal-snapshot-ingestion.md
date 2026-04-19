---
service: "deal-alerts"
title: "Deal Snapshot Ingestion"
generated: "2026-03-03"
type: flow
flow_name: "deal-snapshot-ingestion"
flow_type: batch
trigger: "Scheduled timer or webhook trigger in n8n"
participants:
  - "continuumDealAlertsWorkflows_dealSnapshotsIngestor"
  - "continuumMarketingDealService"
  - "continuumDealAlertsDb_ingestionRuns"
  - "continuumDealAlertsDb_ingestionFunctions"
  - "continuumDealAlertsDb_snapshotStorage"
  - "continuumDealAlertsDb_alertLifecycle"
architecture_ref: "dynamic-deal-alerts-continuumDealAlertsDb_alertLifecycle"
---

# Deal Snapshot Ingestion

## Summary

The Deal Snapshots Ingestor workflow pages the Marketing Deal Service (MDS) API to fetch all active deals, normalizes the data, and inserts snapshots into PostgreSQL. The database-side `insert_snapshots()` PL/pgSQL function atomically computes field-level deltas by comparing old and new snapshots, then generates alerts (SoldOut, DealEnding, DealEnded) based on the detected changes. This is the primary data ingestion pathway that feeds the entire alert lifecycle.

## Trigger

- **Type**: schedule / webhook
- **Source**: n8n scheduled timer or external webhook trigger
- **Frequency**: Periodic (configured in n8n, typically every few minutes)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Deal Snapshots Ingestor | Orchestrates API pagination, data normalization, and database insertion | `continuumDealAlertsWorkflows_dealSnapshotsIngestor` |
| Marketing Deal Service (MDS) | Source of deal data including options, quantities, pricing, and status | `continuumMarketingDealService` |
| Ingestion Bookkeeping | Tracks ingestion execution metadata (counts, status, timestamps) | `continuumDealAlertsDb_ingestionRuns` |
| Snapshot Alerting Functions | PL/pgSQL functions that compute deltas and generate alerts atomically | `continuumDealAlertsDb_ingestionFunctions` |
| Snapshot Storage | Stores deal snapshots and time-partitioned deltas | `continuumDealAlertsDb_snapshotStorage` |
| Alert Lifecycle Tables | Receives generated alert records | `continuumDealAlertsDb_alertLifecycle` |

## Steps

1. **Initiate ingestion run**: The Deal Snapshots Ingestor creates an `ingestion_runs` record to track the execution.
   - From: `continuumDealAlertsWorkflows_dealSnapshotsIngestor`
   - To: `continuumDealAlertsDb_ingestionRuns`
   - Protocol: SQL

2. **Page MDS API**: The workflow fetches deals from MDS in paginated batches, collecting all active deal data.
   - From: `continuumDealAlertsWorkflows_dealSnapshotsIngestor`
   - To: `continuumMarketingDealService`
   - Protocol: HTTP

3. **Normalize and batch deals**: The workflow normalizes deal JSON and batches items for bulk insertion.
   - From: `continuumDealAlertsWorkflows_dealSnapshotsIngestor`
   - To: Internal processing

4. **Insert snapshots**: The workflow calls `insert_snapshots(input_items jsonb)` which for each deal:
   - Acquires a per-deal advisory lock (`pg_advisory_xact_lock`)
   - Loads the existing snapshot and compares body hashes
   - If changed: computes deltas via `get_deal_deltas()` using configured `monitored_fields`
   - Inserts deltas into `deal_deltas` (time-partitioned)
   - Calls `generate_alerts_from_snapshot()` which invokes `resolve_soldout()`, `resolve_deal_ended()`, and `resolve_deal_ending()`
   - Updates the `deal_snapshots` row with the new body
   - From: `continuumDealAlertsWorkflows_dealSnapshotsIngestor`
   - To: `continuumDealAlertsDb_ingestionFunctions`
   - Protocol: SQL (PL/pgSQL function call)

5. **Complete ingestion run**: Updates the ingestion run record with final counts and status.
   - From: `continuumDealAlertsWorkflows_dealSnapshotsIngestor`
   - To: `continuumDealAlertsDb_ingestionRuns`
   - Protocol: SQL

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| MDS API unavailable | n8n workflow retries or fails gracefully | Ingestion run recorded with error status; existing snapshots preserved |
| Duplicate concurrent insert for same deal | Advisory lock (`pg_advisory_xact_lock`) serializes per-deal | Only one write succeeds; no data corruption |
| Unchanged snapshot (same body_hash) | Skip delta computation; update `updated_at` timestamp only | No unnecessary deltas or alerts created |
| Invalid input (null deal_id or body) | `insert_snapshots` skips invalid items via CONTINUE | Other deals in the batch still processed |

## Sequence Diagram

```
DealSnapshotsIngestor -> IngestionRuns: Create ingestion run record
DealSnapshotsIngestor -> MDS: GET /deals (paginated)
MDS --> DealSnapshotsIngestor: Deal data pages
DealSnapshotsIngestor -> SnapshotAlertingFunctions: insert_snapshots(items)
SnapshotAlertingFunctions -> SnapshotStorage: Advisory lock + compare body_hash
SnapshotAlertingFunctions -> SnapshotStorage: Compute get_deal_deltas() + insert deal_deltas
SnapshotAlertingFunctions -> AlertLifecycle: generate_alerts_from_snapshot() -> insert alerts
SnapshotAlertingFunctions -> SnapshotStorage: Update deal_snapshots with new body
DealSnapshotsIngestor -> IngestionRuns: Update run with counts and status
```

## Related

- Architecture dynamic view: `dynamic-deal-alerts-continuumDealAlertsDb_alertLifecycle`
- Related flows: [Action Orchestration](action-orchestration.md), [SoldOut Notification Pipeline](soldout-notification-pipeline.md)
