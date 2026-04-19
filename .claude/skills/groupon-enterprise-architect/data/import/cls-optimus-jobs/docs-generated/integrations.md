---
service: "cls-optimus-jobs"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 4
internal_count: 1
---

# Integrations

## Overview

CLS Optimus Jobs integrates with four external data systems and one internal Hive database. Source data is pulled from two Teradata instances (NA and EMEA) and the Janus event dataset. All file-based exports transit through an HDFS landing zone. The Optimus control plane (external to this repository's federated model) orchestrates all job scheduling and execution. No HTTP-based service integrations exist.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Optimus Control Plane | Proprietary (Optimus scheduler) | Schedules and executes all CLS job definitions | yes | `optimusControlPlane_1bb5a5e5` (stub) |
| Teradata NA (`user_gp` schema) | SQL over DSN (`shipping_Data_Jobs`, `hive_underjob`) | Source of NA billing and shipping transactional records | yes | Not in federated model |
| Teradata EMEA (`user_edwprod` schema) | SQL over DSN (`shipping_Data_Jobs`) | Source of EMEA billing and shipping transactional records | yes | Not in federated model |
| HDFS Landing Zone | HDFS (`hdfs://cerebro-namenode-vip/user/grp_gdoop_cls/optimus/`) | Intermediate staging for Teradata-exported files before Hive load | yes | `hdfsLandingZone_790f81de` (stub) |
| Janus All Dataset (`grp_gdoop_pde.janus_all`) | Hive SQL | Source of consumer event-based location signals for CDS Janus delta job | yes | `janusAllDataset_57a5c2d1` (stub) |
| Country Pincode Lookup (`grp_gdoop_cls_db.country_pincode_lat_lng_lookup_optimized`) | Hive SQL | Reference table for postal code to latitude/longitude enrichment | yes | `countryPincodeLookup_7ecf56f1` (stub) |

### Optimus Control Plane Detail

- **Protocol**: Proprietary Optimus job scheduler (on-premise at `https://optimus.groupondev.com/`)
- **Base URL / SDK**: `https://optimus.groupondev.com/#/groups/`
- **Auth**: Optimus user group access control
- **Purpose**: Schedules job execution, injects date parameters (`start_date`, `end_date`, `record_date`, `janus_record_date`), manages job dependencies and failure notifications.
- **Failure mode**: Jobs fail and PagerDuty alert is triggered to `consumer-location-service@groupon.pagerduty.com`.
- **Circuit breaker**: No — Optimus retries are managed per-job configuration.

### Teradata NA (`shipping_Data_Jobs` DSN) Detail

- **Protocol**: SQL over JDBC/ODBC Teradata DSN
- **Base URL / SDK**: DSN `shipping_Data_Jobs` (adapter: Teradata); `user_gp.orders`, `user_gp.parent_orders`, `user_gp.user_billing_records`, `user_gp.user_profile_locations`
- **Auth**: Teradata DSN credentials managed by Optimus
- **Purpose**: Exports NA billing, shipping order, and CDS user profile location records to local files for subsequent HDFS transfer.
- **Failure mode**: `SQLExport` task fails; downstream HDFS transfer and Hive load tasks are blocked; job fails and PagerDuty fires.
- **Circuit breaker**: No

### Teradata EMEA (`shipping_Data_Jobs` DSN) Detail

- **Protocol**: SQL over JDBC/ODBC Teradata DSN
- **Base URL / SDK**: DSN `shipping_Data_Jobs` (adapter: Teradata); `user_edwprod.orders`, `user_edwprod.parent_orders`; EMEA billing via `billing_address`, `billing_record` tables
- **Auth**: Teradata DSN credentials managed by Optimus
- **Purpose**: Exports EMEA shipping order and billing address records for ingestion into Hive.
- **Failure mode**: Same as NA — job fails, PagerDuty alert triggered.
- **Circuit breaker**: No

### HDFS Landing Zone Detail

- **Protocol**: HDFS (`RemoteHadoopClient.py`, `copyfromlocal` action)
- **Base URL / SDK**: `hdfs://cerebro-namenode-vip/user/grp_gdoop_cls/optimus/billing/na`, `/billing/emea`, `/shipping/na`, `/shipping/emea`, `/cds/na`, `/grp20/na`
- **Auth**: Hadoop cluster authentication via Optimus `optimus_app` user
- **Purpose**: Staging area between Teradata SQL exports (written to `${local_dir}`) and Hive external table creation.
- **Failure mode**: `RemoteHadoopClient.py` step fails; Hive load is blocked; job fails.
- **Circuit breaker**: No

### Janus All Dataset Detail

- **Protocol**: Hive SQL (`grp_gdoop_pde.janus_all`, filtered by `ds` partition and `event='consumerAccount'`)
- **Base URL / SDK**: Hive table `grp_gdoop_pde.janus_all`
- **Auth**: Hive DSN `cds_hive_access_underjob`
- **Purpose**: Provides consumer account-level location signals (city, geostate, postalcode, country) for the `CDS_Data_NA_from_janus_delta` job.
- **Failure mode**: HQL step fails; `coalesce_nonping` for CDS Janus records is not updated for that day.
- **Circuit breaker**: No

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| CLS Hive Warehouse | Hive SQL | Reads source `cls_*` tables and writes coalesced output to `coalesce_nonping` | `continuumClsHiveWarehouse` |

## Consumed By

> Upstream consumers are tracked in the central architecture model.

The `grp_gdoop_cls_db.coalesce_nonping` table is consumed by advertising targeting, search relevance, and retargeting pipelines. Direct consumers are not defined within this repository.

## Dependency Health

No automated health checks, retries, or circuit breakers are configured within the job definitions. Job failure detection relies on Optimus job monitoring with PagerDuty alerting. Manual re-run procedures are documented in [Runbook](runbook.md).
