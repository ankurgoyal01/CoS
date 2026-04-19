---
service: "cls-optimus-jobs"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumClsOptimusJobs", "continuumClsHiveWarehouse"]
---

# Architecture Context

## System Context

The CLS Optimus Jobs sit within the **Continuum** platform as a batch data processing service. The jobs are orchestrated by the Optimus on-premise scheduler and operate entirely within the Groupon data infrastructure — Teradata (source of billing and shipping transactional records), the HDFS landing zone (intermediate staging area for exported files), Janus (`grp_gdoop_pde.janus_all` — source of consumer event-based location signals), and Cerebro (target Hive cluster). The unified output table `grp_gdoop_cls_db.coalesce_nonping` is consumed by downstream location-aware services including advertising and search.

External systems referenced by the architecture model (stub-only, not in the federated model):
- `optimusControlPlane` — schedules and triggers all job executions.
- `hdfsLandingZone` — intermediate file staging area between Teradata exports and Hive loads.
- `janusAllDataset` — consumer event stream used by the CDS Janus delta job.
- `countryPincodeLookup` — postal-code-to-lat/lng enrichment reference table.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| CLS Optimus Jobs | `continuumClsOptimusJobs` | Service | YAML, Hive SQL, Optimus | on-premise | Optimus-managed Hive job suite that ingests billing, shipping, and CDS data, then coalesces non-ping location datasets. |
| CLS Hive Warehouse | `continuumClsHiveWarehouse` | Database | Hive (Cerebro) | — | Hive datasets in `grp_gdoop_cls_db` used as both sources and targets for CLS location pipelines. |

## Components by Container

### CLS Optimus Jobs (`continuumClsOptimusJobs`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Billing Ingestion Jobs (`clsOptimus_billingIngestionJobs`) | Backfill and delta billing jobs ingesting NA/EMEA billing address files from Teradata into Hive `cls_billing_address_na` / `cls_billing_address_emea` tables. | Optimus ScriptTask / LibraryTask |
| Shipping Ingestion Jobs (`clsOptimus_shippingIngestionJobs`) | Backfill and delta shipping jobs staging source files via HDFS and loading `cls_shipping_na` / `cls_shipping_emea` datasets. | Optimus ScriptTask / LibraryTask |
| CDS Ingestion Jobs (`clsOptimus_cdsIngestionJobs`) | CDS import jobs loading user profile location records, including Janus-based NA delta transforms into `cls_user_profile_locations_na`. | Optimus ScriptTask / LibraryTask |
| Coalesce Jobs (`clsOptimus_coalesceJobs`) | Jobs merging billing, shipping, and CDS non-ping records into `coalesce_nonping_staging` and `coalesce_nonping` target tables. | Optimus LibraryTask |
| HDFS Transfer Tasks (`clsOptimus_hdfsTransferTasks`) | RemoteHadoopClient-based file transfer steps copying local Teradata exports to HDFS landing paths under `/user/grp_gdoop_cls/optimus/`. | RemoteHadoopClient.py |
| Hive Execution Tasks (`clsOptimus_hqlExecutionTasks`) | HQLExecute-based tasks performing table creation, INSERT INTO ... PARTITION, and DROP TABLE cleanup statements against `grp_gdoop_cls_db`. | HQLExecute.py |
| Data Quality and Normalization (`clsOptimus_dataQualityAndNormalization`) | SQL rules for UUID format validation, postal code normalisation, country code allowlist validation, and lat/lng enrichment joins against `country_pincode_lat_lng_lookup_optimized`. | Hive SQL transformations |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumClsOptimusJobs` | `continuumClsHiveWarehouse` | Reads source tables and writes `cls_*` and `coalesce_nonping` target tables | Hive SQL via HQLExecute.py |
| `clsOptimus_billingIngestionJobs` | `clsOptimus_hqlExecutionTasks` | Runs billing NA/EMEA extraction and load statements | Internal |
| `clsOptimus_shippingIngestionJobs` | `clsOptimus_hdfsTransferTasks` | Stages shipping files into HDFS before Hive loads | Internal |
| `clsOptimus_shippingIngestionJobs` | `clsOptimus_hqlExecutionTasks` | Loads staged shipping datasets into `cls_shipping` tables | Internal |
| `clsOptimus_cdsIngestionJobs` | `clsOptimus_hqlExecutionTasks` | Loads CDS and Janus-derived profile location datasets | Internal |
| `clsOptimus_coalesceJobs` | `clsOptimus_hqlExecutionTasks` | Creates and populates `coalesce_nonping` temp and target tables | Internal |
| `clsOptimus_hqlExecutionTasks` | `clsOptimus_dataQualityAndNormalization` | Applies zipcode, country code, and partition normalisation rules | Internal |
| `clsOptimus_dataQualityAndNormalization` | `clsOptimus_coalesceJobs` | Feeds normalised records into coalesce INSERT operations | Internal |

## Architecture Diagram References

- Component: `components-continuum-cls-optimus-clsOptimus_billingIngestionJobs`
- Dynamic flow: `dynamic-cls-optimus-nonping-coalesce`
