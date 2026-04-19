---
service: "airflow_gcp"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: [continuumAirflowGcpSfdcEtlOrchestrator, continuumSfdcEtlWorkingStorageGcs]
---

# Architecture Context

## System Context

The Airflow GCP SFDC ETL service is a component of the **Continuum Platform** (`continuumSystem`). It sits at the boundary between Groupon's internal data infrastructure and the external Salesforce CRM system. The orchestrator pulls source data from Teradata EDW and Hive via SQL/JDBC, stages it in GCS, and pushes reconciled updates into Salesforce via the Bulk API. It has no inbound callers — all execution is driven by Airflow's internal scheduler running on Cloud Composer. Secrets are fetched from Google Secret Manager at runtime.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Airflow GCP SFDC ETL Orchestrator | `continuumAirflowGcpSfdcEtlOrchestrator` | Service | Python, Apache Airflow | — | Python DAG orchestration package deployed to Cloud Composer for Salesforce data integration pipelines |
| SFDC ETL Working Storage (GCS) | `continuumSfdcEtlWorkingStorageGcs` | Storage | Google Cloud Storage | — | Bucket paths used for temporary CSV inputs, outputs, retries, and JDBC artifacts |

## Components by Container

### Airflow GCP SFDC ETL Orchestrator (`continuumAirflowGcpSfdcEtlOrchestrator`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| DAG Definitions (`airflowGcp_dagDefinitions`) | DAG modules defining schedules and task flows for all 28+ pipelines | Apache Airflow DAGs |
| DAG Helpers (`airflowGcp_dagHelpers`) | Shared task helpers for query execution, GCS I/O orchestration, retries, and cert handling | Python module |
| Salesforce Hook (`airflowGcp_salesforceHook`) | Salesforce API and Bulk API integration wrapper; handles SOQL queries and bulk inserts/updates | simple-salesforce, salesforce-bulk |
| Teradata Connector (`airflowGcp_teradataConnector`) | Executes Teradata SQL queries and streams records to GCS staging | teradatasql, pandas |
| Hive Connector (`airflowGcp_hiveConnector`) | Executes Hive SQL queries via JDBC over SSL | jaydebeapi, pandas |
| Config Helper (`airflowGcp_configHelper`) | Provides environment-aware access to variable and connection configuration from JSON files | Python module |
| GCS I/O Utilities (`airflowGcp_gcsIo`) | Handles CSV upload/download and object lifecycle operations in GCS | google-cloud-storage, smart-open |
| Secret Manager Utilities (`airflowGcp_secretManager`) | Retrieves secrets for TLS certificates and runtime credentials from Google Secret Manager | Google Secret Manager API |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumAirflowGcpSfdcEtlOrchestrator` | `continuumSfdcEtlWorkingStorageGcs` | Reads and writes staging CSVs, results, and JDBC artifacts | GCS API |
| `continuumAirflowGcpSfdcEtlOrchestrator` | `salesForce` | Queries and updates Salesforce objects via Bulk API | HTTPS |
| `airflowGcp_dagDefinitions` | `airflowGcp_dagHelpers` | Invokes shared DAG task utilities | direct (Python) |
| `airflowGcp_dagDefinitions` | `airflowGcp_configHelper` | Loads environment and connection settings | direct (Python) |
| `airflowGcp_dagHelpers` | `airflowGcp_salesforceHook` | Uses Salesforce query and bulk update operations | direct (Python) |
| `airflowGcp_dagHelpers` | `airflowGcp_teradataConnector` | Uses EDW query execution | direct (Python) |
| `airflowGcp_dagHelpers` | `airflowGcp_hiveConnector` | Uses Hive query execution | direct (Python) |
| `airflowGcp_dagHelpers` | `airflowGcp_gcsIo` | Persists and reads intermediate datasets | direct (Python) |
| `airflowGcp_dagHelpers` | `airflowGcp_secretManager` | Reads secrets for certificates and credentials | direct (Python) |
| `airflowGcp_salesforceHook` | `airflowGcp_gcsIo` | Reads and writes CSV batches in GCS | direct (Python) |

> Note: Relationships to Teradata EDW, Hive, and Google Secret Manager are modelled as stubs in the federated architecture model because those systems are not yet part of the federated Structurizr model.

## Architecture Diagram References

- System context: `contexts-continuumSystem`
- Container: `containers-continuumAirflowGcpSfdcEtlOrchestrator`
- Component: `components-continuum-airflow-gcp-sfdc-etl-orchestrator`
- Dynamic view: `dynamic-airflow-gcp-dwh-dag-sync`
