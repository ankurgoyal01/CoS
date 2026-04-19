---
service: "audienceDerivationSpark"
title: "AMS Field Sync"
generated: "2026-03-03"
type: flow
flow_name: "ams-field-sync"
flow_type: scheduled
trigger: "Automatic post-derivation step or manual Fabric task"
participants:
  - "continuumAudienceDerivationOps"
  - "continuumAudienceDerivationSpark"
  - "hiveMetastore"
  - "amsApi"
architecture_ref: "dynamic-nightly_derivation_flow"
---

# AMS Field Sync

## Summary

The AMS Field Sync flow keeps the Audience Management System (AMS) MySQL database in sync with the actual fields present in the derived Hive audience tables. After each successful derivation run, `FieldSyncMain` reads the schema of the newly written derived table from Hive and compares it to AMS field metadata, adding new fields, updating existing ones, and optionally removing stale entries. This flow can also be triggered independently of derivation via Fabric.

## Trigger

- **Type**: schedule (automatic post-derivation) or manual
- **Source**: Called by `tableDerivationEngine` after successful derivation completion; or manually via `fab {stage}:{region} sync_ams_fields`
- **Frequency**: Daily (once per successful derivation run) or on-demand

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Operations Scripts | Triggers standalone sync via `fab sync_ams_fields` | `continuumAudienceDerivationOps` |
| Audience Derivation Spark App | Executes field comparison and sync logic | `continuumAudienceDerivationSpark` (`amsFieldSyncMain`) |
| Hive Metastore | Source of derived table schema | `hiveMetastore` |
| AMS API | Receives field metadata additions/updates | `amsApi` |

## Steps

1. **Invoke FieldSyncMain**: Either called from `tableDerivationEngine` after derivation completes, or submitted as a standalone Spark job from `field_sync.py`.
   - From: `continuumAudienceDerivationSpark` (tableDerivationEngine) or `continuumAudienceDerivationOps` (`FieldSyncer.sync_ams_fields()`)
   - To: `continuumAudienceDerivationSpark` (`FieldSyncMain`)
   - Protocol: Direct internal call or spark-submit

2. **Read derived table schema**: `FieldSyncMain` reads the schema (column names and types) of the derived Hive table.
   - From: `continuumAudienceDerivationSpark`
   - To: `hiveMetastore`
   - Protocol: Spark SQL / Hive Thrift

3. **Read AMS field metadata**: Retrieves the current field list from the AMS database for the given environment and region.
   - From: `continuumAudienceDerivationSpark`
   - To: `amsApi`
   - Protocol: HTTP / gRPC

4. **Compare schemas**: Identifies new fields (in Hive but not in AMS), updated fields (type changes), and stale fields (in AMS but not in Hive).

5. **Push field updates to AMS**: Sends add/update operations for new and changed fields. Lists stale fields for review (does not delete unless `--syncDelete true` is specified).
   - From: `continuumAudienceDerivationSpark`
   - To: `amsApi`
   - Protocol: HTTP / gRPC

6. (Optional) **Delete stale fields**: If `--syncDelete true` flag is passed, also removes fields from AMS that are no longer in the derived table.

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| AMS API unavailable | Spark job throws exception | Field sync fails; derived table is unaffected; run `fab sync_ams_fields` manually after AMS recovers |
| Hive schema read failure | Spark exception | Sync fails; retry manually |
| Accidental syncDelete on wrong environment | No rollback | Deleted fields must be re-added manually; use `create=true` in CQD sync to restore |

## Sequence Diagram

```
FieldSyncMain -> HiveMetastore: describe table (get schema)
FieldSyncMain -> AMS API: get current field list
FieldSyncMain -> FieldSyncMain: diff schema vs AMS fields
FieldSyncMain -> AMS API: add new fields
FieldSyncMain -> AMS API: update changed fields
FieldSyncMain -> operator log: list stale fields (deletion optional)
```

## Related

- Related flows: [Nightly Audience Derivation](nightly-audience-derivation.md)
- Fabric task: `fab {stage}:{region} sync_ams_fields` / `fab {stage}:{region} sync_ams_fields:syncDelete`
- See [Runbook](../runbook.md) for manual sync procedures
