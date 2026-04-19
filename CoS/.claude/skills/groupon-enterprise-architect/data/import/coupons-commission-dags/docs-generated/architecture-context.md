---
service: "coupons-commission-dags"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumCouponsCommissionDags"]
---

# Architecture Context

## System Context

`coupons-commission-dags` is a container within the **Continuum Platform** (`continuumSystem`). It sits in the data pipeline layer of Groupon's accounting automation subsystem, orchestrating multi-stage commission reporting jobs via Apache Airflow. It has no inbound API callers; it is triggered entirely by Airflow schedule intervals. Its outbound dependencies are GCP infrastructure services (`gcpDataprocCluster`, `gcpDataprocMetastore`) and Groupon's internal artifact repository (`grouponArtifactory`).

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Coupons Commission DAGs | `continuumCouponsCommissionDags` | Orchestration | Python / Airflow | 2.x | Airflow DAGs orchestrating coupons commission reporting pipelines in GCP Dataproc |

## Components by Container

### Coupons Commission DAGs (`continuumCouponsCommissionDags`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `sourcingDag` — Coupons Commission Sourcing DAG | Creates a Dataproc cluster and submits the sourcing Spark job for the monthly coupons commission report | Airflow DAG |
| `transformDag` — Coupons Commission Transform DAG | Creates a Dataproc cluster and submits the transformation Spark job for the monthly coupons commission report | Airflow DAG |
| `aggregationDag` — Coupons Commission Aggregation DAG | Creates a Dataproc cluster and submits the aggregation Spark job for the monthly coupons commission report | Airflow DAG |
| `dailyAwinSourcingDag` — Daily Awin Sourcing DAG | Creates a Dataproc cluster and submits the Awin sourcing Spark job for daily reporting | Airflow DAG |
| `dailyAwinTransformDag` — Daily Awin Transform DAG | Creates a Dataproc cluster and submits the Awin transformation Spark job for daily reporting | Airflow DAG |
| `dailyAwinAggregationDag` — Daily Awin Aggregation DAG | Creates a Dataproc cluster and submits the Awin aggregation Spark job for daily reporting | Airflow DAG |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumCouponsCommissionDags` | `gcpDataprocCluster` | Creates ephemeral clusters and submits Spark jobs | GCP SDK / Airflow Dataproc Operators |
| `continuumCouponsCommissionDags` | `grouponArtifactory` | References Spark job JAR URIs from Artifactory HTTP | HTTP |
| `gcpDataprocCluster` | `gcpDataprocMetastore` | Uses for Hive metadata during Spark job execution | Internal GCP |

> Note: `gcpDataprocCluster`, `gcpDataprocMetastore`, and `grouponArtifactory` are external to the federated Continuum model. Relationships are defined in `models/relations.dsl` and `models/components-relations.dsl` as stubs.

## Architecture Diagram References

- System context: `contexts-CouponsCommissionDagsComponents`
- Container: `containers-CouponsCommissionDagsComponents`
- Component: `CouponsCommissionDagsComponents`
