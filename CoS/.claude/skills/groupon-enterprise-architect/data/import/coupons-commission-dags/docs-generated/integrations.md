---
service: "coupons-commission-dags"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 3
internal_count: 0
---

# Integrations

## Overview

coupons-commission-dags has three external infrastructure dependencies: GCP Dataproc (cluster provisioning and Spark job execution), GCP Dataproc Metastore (Hive metadata for Spark jobs), and Groupon Artifactory (Spark JAR artifact delivery). There are no internal Groupon service dependencies; the DAGs do not call any other Continuum microservices. The service has no discoverable upstream callers other than the Airflow scheduler itself.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| GCP Dataproc | GCP SDK (Airflow Dataproc Operators) | Ephemeral cluster provisioning and Spark job execution | yes | `gcpDataprocCluster` |
| GCP Dataproc Metastore | Internal GCP | Hive-compatible metadata for Spark jobs on each cluster | yes | `gcpDataprocMetastore` |
| Groupon Artifactory | HTTP | Source of Spark JAR assembly files for each pipeline stage | yes | `grouponArtifactory` |

### GCP Dataproc Detail

- **Protocol**: GCP Dataproc API via `apache-airflow-providers-google` — `DataprocCreateClusterOperator`, `DataprocSubmitJobOperator`, `DataprocDeleteClusterOperator`
- **Base URL / SDK**: GCP project `prj-grp-c-common-prod-ff2b`, region `us-central1`, zone `us-central1-f`
- **Auth**: GCP Service Account `loc-sa-c-coupons-comm-dataproc@prj-grp-c-common-prod-ff2b.iam.gserviceaccount.com` with `https://www.googleapis.com/auth/cloud-platform` scope
- **Purpose**: Creates an ephemeral `n1-standard-8` cluster (1 master + 2 workers, 500 GB pd-standard each) per pipeline run, submits the Spark job, then deletes the cluster
- **Failure mode**: If Dataproc cluster creation fails, the DAG task fails with no retries (`retries=0`); subsequent stages do not execute; cluster is still deleted in the `delete_dataproc_cluster` task
- **Circuit breaker**: No evidence found in codebase

### GCP Dataproc Metastore Detail

- **Protocol**: Internal GCP — configured as `metastore_config` in each cluster's `cluster_config`
- **Base URL / SDK**: `projects/prj-grp-datalake-prod-8a19/locations/us-central1/services/grpn-dpms-prod-analytics` (prod)
- **Auth**: Inherited from GCP Dataproc cluster service account
- **Purpose**: Provides Hive-compatible metadata catalog for Spark jobs executing SQL-style queries on commission data
- **Failure mode**: Spark jobs fail if metastore is unavailable; DAG tasks fail without retry
- **Circuit breaker**: No evidence found in codebase

### Groupon Artifactory Detail

- **Protocol**: HTTP — JAR URIs referenced in `jar_file_uris` field of `DataprocSubmitJobOperator` job config
- **Base URL / SDK**: `http://artifactory.groupondev.com/artifactory/releases/` (prod/stable) and `http://artifactory.groupondev.com/artifactory/snapshots/` (dev/staging)
- **Auth**: No evidence found in codebase (likely internal network access only)
- **Purpose**: Delivers versioned Spark assembly JARs for each pipeline stage:
  - Sourcing: `coupons-commission-sourcing_2-4-8_2.12-0.51-assembly.jar` (`com.groupon.accountingautomation.SourcingMainJob`)
  - Transformation: `coupons-commission-transformation_2-4-8_2.12-0.49-assembly.jar` (`com.groupon.accountingautomation.DataTransformationJob`)
  - Aggregation: `coupons-commission-aggregation_2-4-8_2.12-0.33-assembly.jar` (`com.groupon.accountingautomation.DataAggregationJob`)
- **Failure mode**: Dataproc cluster fails to execute the Spark job if the JAR URI is unreachable; DAG task fails
- **Circuit breaker**: No evidence found in codebase

## Internal Dependencies

> No evidence found in codebase. coupons-commission-dags does not call any internal Groupon microservices.

## Consumed By

> Upstream consumers are tracked in the central architecture model. These DAGs are triggered exclusively by the Airflow scheduler on their configured `schedule_interval` values, or manually via the Airflow UI.

## Dependency Health

> No evidence found in codebase of explicit health check, retry, or circuit breaker patterns for infrastructure dependencies. All Dataproc operators use `retries=0`, meaning failed tasks do not retry automatically.
