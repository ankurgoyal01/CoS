---
service: "JLA_Airflow"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumJlaAirflow"
  containers: ["continuumJlaAirflowOrchestrator", "continuumJlaAirflowMetadataDb"]
---

# Architecture Context

## System Context

JLA Airflow is a batch-oriented orchestration system within the Continuum platform, operated by the FSA (Financial Systems & Analytics) team. It sits at the centre of Groupon's JLA accounting data pipeline, reading source data from Teradata and external systems (Kyriba, PSP settlement files), applying transformations, staging results back to Teradata (`dwh_fsa_prd`), and invoking downstream services (NetSuite integration, JLA EBA service) via HTTP. An administrator manages and monitors DAG operations through the Airflow web UI. Operational alerts are delivered to Google Chat spaces.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| JLA Airflow Orchestrator | `continuumJlaAirflowOrchestrator` | Orchestration | Python, Apache Airflow | 2.x | Schedules and executes accounting and reconciliation DAGs for JLA workflows |
| Airflow Metadata Store | `continuumJlaAirflowMetadataDb` | Database | PostgreSQL | Composer-managed | Stores DAG run state, task metadata, and scheduler bookkeeping |

## Components by Container

### JLA Airflow Orchestrator (`continuumJlaAirflowOrchestrator`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| DAG Execution Engine | Coordinates DAG scheduling and task execution across JLA workflows | Airflow Scheduler/Executor |
| Data Warehouse Connector | Executes SQL and bulk data operations against analytical stores | Custom Teradata/BigQuery hooks and operators (`TeradataEngine`, `BigQueryEngine`, `TeradataOperator`) |
| External Service Adapter | Handles SFTP, NetSuite, and partner endpoint interactions from DAG tasks | Python integration modules and Airflow hooks (`paramiko`, `SimpleHttpOperator`, `SSHHook`) |
| Alerting Adapter | Sends operational status notifications for success/failure outcomes | Google Chat webhook templates (`modules/gchat.py`) |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `administrator` | `continuumJlaAirflowOrchestrator` | Monitors and administers DAG operations | Airflow Web UI |
| `continuumJlaAirflowOrchestrator` | `continuumJlaAirflowMetadataDb` | Stores scheduler, task, and run state | SQL |
| `continuumJlaAirflowOrchestrator` | `bigQueryWarehouse` | Reads and writes analytics datasets | SQL |
| `continuumJlaAirflowOrchestrator` | Teradata (`dwh_fsa_prd`) | Executes ETL and reconciliation SQL workloads | JDBC/SQL |
| `continuumJlaAirflowOrchestrator` | `googleChat` | Sends operational alerts and status summaries | Webhook |
| `continuumJlaAirflowOrchestrator` | `kyriba` | Ingests payment clearing source data | SFTP/API |
| `continuumJlaAirflowOrchestrator` | NetSuite integration service | Triggers accounting update workflows | HTTP |
| `continuumJlaAirflowOrchestrator` | AWS SFTP | Transfers settlement and migration files | SFTP |

## Architecture Diagram References

- System context: `contexts-continuumJlaAirflow`
- Container: `containers-continuumJlaAirflow`
- Component: `components-jlaAirflowOrchestrator`
