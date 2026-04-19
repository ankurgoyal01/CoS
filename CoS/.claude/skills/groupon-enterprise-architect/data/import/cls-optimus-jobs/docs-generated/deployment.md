---
service: "cls-optimus-jobs"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: false
orchestration: "optimus-on-premise"
environments: ["staging", "production"]
---

# Deployment

## Overview

CLS Optimus Jobs are not containerised and do not use Kubernetes or cloud orchestration. Job definitions are YAML files committed to this Git repository and deployed to the Optimus on-premise job scheduling platform at `https://optimus.groupondev.com/`. Deployment consists of creating or updating job definitions in the Optimus UI under the appropriate user group. Jobs execute on Optimus worker nodes with access to Teradata DSNs and the Cerebro HDFS/Hive cluster.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | None | No Docker or container image — jobs execute as Optimus tasks directly on worker nodes |
| Orchestration | Optimus (on-premise) | `https://optimus.groupondev.com/` — schedules, triggers, and monitors all job runs |
| Compute | Optimus worker nodes | Local sandbox at `/var/groupon/optimus/sandbox/<job_id>/${loadkey}` for temporary files |
| Hive cluster | Cerebro (Hadoop/Tez) | `hdfs://cerebro-namenode.snc1:8020` / `cerebro-namenode-vip` — Hive metastore and compute |
| HDFS landing | Cerebro HDFS | `/user/grp_gdoop_cls/optimus/` — intermediate file storage between Teradata exports and Hive loads |
| Load balancer | None | Not applicable — batch jobs with no inbound traffic |
| CDN | None | Not applicable |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| Staging | Pre-release validation using `cls_staging` database and staging Hive tables | NA (SNC1) | `https://optimus.groupondev.com/` (staging Optimus group) |
| Production | Live data pipelines writing to `grp_gdoop_cls_db` | NA (SNC1) | `https://optimus.groupondev.com/` |

## CI/CD Pipeline

> No evidence found in codebase. No automated CI/CD pipeline is defined in this repository.

- **Tool**: Manual deployment via Optimus UI
- **Config**: YAML job files in this repository root (e.g., `coalesce_billing_na.yml`, `Shipping_data_from_NA_delta`)
- **Trigger**: Manual — developers create or update job definitions directly in the Optimus UI, then capture the YAML and commit it to this repository.

### Deployment Steps (Manual Process)

1. **Develop**: Create or modify job definition in the Optimus UI under the staging user group.
2. **Point to staging**: Configure job to use `cls_staging` database tables.
3. **Review**: Team member reviews the job HQL script for potential issues or improvements.
4. **Validate**: Run job against staging for several days; verify row counts match source.
5. **Capture**: Export the job YAML from Optimus and commit it to this repository.
6. **Promote**: Update job configuration in Optimus to use production database and tables.
7. **Monitor**: Watch job runs in Optimus; cross-check Hive table counts.

## Optimus User Groups

| User Group | Optimus URL | Jobs Included |
|------------|-------------|---------------|
| `cls_billing` | `https://optimus.groupondev.com/#/groups/cls_billing` | `cls-billing-na-delta`, `cls-billing-na-backfill`, `cls-billing-emea-delta`, `cls-billing-emea-backfill` |
| `cls_cds` | `https://optimus.groupondev.com/#/groups/cls_cds` | `CDS_Data_from_NA_delta`, `CDS_Data_NA_from_janus_delta` |
| `cls_shipping` | `https://optimus.groupondev.com/#/groups/cls_shipping` | `Shipping_data_from_NA_delta`, `Shipping_data_from_NA_backfill`, `Shipping_data_from_EMEA_delta`, `Shipping_data_from_EMEA_backfill` |
| `coalesce_nonping` | `https://optimus.groupondev.com/#/groups/coalesce_nonping` | `coalesce_billing_emea_delta`, `coalesce_billing_na_delta`, `coalesce_shipping_emea_delta`, `coalesce_shipping_na_delta`, `coalesce_cds_na_delta` |

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Not applicable — Tez scales query execution across YARN cluster automatically | YARN `public` queue |
| Memory | Tez container: 8192 MB; JVM heap: 6000 MB | `hive.tez.container.size=8192`, `hive.tez.java.opts=-Xmx6000M` |
| CPU | Managed by YARN cluster scheduler | Not configurable at job level |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | Managed by YARN | Managed by YARN |
| Memory (Tez container) | 8192 MB per container | 8192 MB |
| JVM heap | 6000 MB | 6000 MB |
| Local disk | `/var/groupon/optimus/sandbox/<job_id>/${loadkey}` — cleaned up by `__end__` task | Variable per export size |
