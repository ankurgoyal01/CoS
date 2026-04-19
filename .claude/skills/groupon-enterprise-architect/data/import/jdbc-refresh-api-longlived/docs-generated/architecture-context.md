---
service: "jdbc-refresh-api-longlived"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers:
    - continuumAnalyticsProxyLlCluster
    - continuumAnalyticsBackendCluster
    - continuumAnalyticsProxyCluster
    - continuumPipelinesBackendCluster
    - continuumOpBackendCluster
    - continuumTableauBackendCluster
    - continuumSoxBackendCluster
    - continuumSoxProxyCluster
    - continuumRangerDbMysql
    - continuumSoxRangerDbMysql
    - continuumKms
    - continuumSoxKms
    - continuumBuckets
    - continuumSoxBuckets
    - continuumGcsBucket
    - continuumMonitorDataprocNmDown
    - continuumMonitorDpcHdfsDatanodeLow
    - continuumMonitorDpcLongRunningJob
    - continuumMonitorDpcStaleCluster
    - continuumMonitorDpcStaleJob
    - continuumMonitorYarnPendingMemory
---

# Architecture Context

## System Context

The `jdbc-refresh-api-longlived` service is part of Groupon's `continuumSystem` (Continuum Platform). It sits within the **GCP Data Platform** layer and provides the compute, proxy, and authorization infrastructure required for interactive and scheduled access to data lake assets. Data analysts and BI tools connect via Apache Knox endpoints on the proxy clusters, which route traffic to the backend Dataproc clusters that execute Hive/Spark SQL queries. The backend clusters integrate with the Dataproc Metastore Service (Hive-compatible), read/write BigQuery datasets via Spark SQL/JDBC, and enforce access policies via Apache Ranger backed by Cloud SQL for MySQL.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Analytics Proxy LL Cluster | `continuumAnalyticsProxyLlCluster` | Compute | GCP Dataproc + Apache Knox | 1.5-debian10 | Long-lived proxy cluster exposing Knox front-door endpoints for JDBC and refresh API access |
| Analytics Backend Cluster | `continuumAnalyticsBackendCluster` | Compute | GCP Dataproc | 1.5-debian10 | Dataproc long-lived backend cluster for analytics workloads and refresh APIs |
| Analytics Proxy Cluster | `continuumAnalyticsProxyCluster` | Compute | GCP Dataproc | 1.5-debian10 | Proxy-tier Dataproc cluster for controlled analytics access patterns |
| Pipelines Backend Cluster | `continuumPipelinesBackendCluster` | Compute | GCP Dataproc | 1.5-debian10 | Dataproc backend cluster supporting pipeline-oriented refresh API workflows |
| OP Backend Cluster | `continuumOpBackendCluster` | Compute | GCP Dataproc | 1.5-debian10 | Dataproc backend cluster dedicated to Optimus Prime and OP data flows |
| Tableau Backend Cluster | `continuumTableauBackendCluster` | Compute | GCP Dataproc | 1.5-debian10 | Dataproc backend cluster for BI/Tableau refresh and JDBC-centric workloads |
| SOX Backend Cluster | `continuumSoxBackendCluster` | Compute | GCP Dataproc | 1.5-debian10 | SOX-scoped Dataproc backend cluster for controlled workloads |
| SOX Proxy Cluster | `continuumSoxProxyCluster` | Compute | GCP Dataproc + Apache Knox | 1.5-debian10 | SOX-scoped proxy cluster for secure data access pathways |
| Ranger DB MySQL | `continuumRangerDbMysql` | Database | Cloud SQL for MySQL | MYSQL_5_7 | MySQL instance for Ranger policy and metadata services |
| SOX Ranger DB MySQL | `continuumSoxRangerDbMysql` | Database | Cloud SQL for MySQL | MYSQL_5_7 | SOX-scoped MySQL instance for Ranger policy and metadata persistence |
| KMS Infrastructure | `continuumKms` | Security | Terraform + Cloud KMS | Managed | KMS key ring and crypto keys for Ranger password encryption |
| SOX KMS Infrastructure | `continuumSoxKms` | Security | Terraform + Cloud KMS | Managed | SOX-specific KMS key ring and crypto keys |
| Buckets Infrastructure | `continuumBuckets` | Storage | Terraform + GCS | Managed | Shared GCS buckets for Dataproc staging and Ranger secrets |
| SOX Buckets Infrastructure | `continuumSoxBuckets` | Storage | Terraform + GCS | Managed | SOX-specific GCS buckets |
| GCS Bucket Infrastructure | `continuumGcsBucket` | Storage | Terraform + GCS | Managed | Dedicated GCS bucket resources for the platform |
| Dataproc NodeManager Down Monitor | `continuumMonitorDataprocNmDown` | Monitoring | Terraform + Cloud Monitoring | Managed | Alert policy for NodeManager availability incidents |
| HDFS Datanode Capacity Monitor | `continuumMonitorDpcHdfsDatanodeLow` | Monitoring | Terraform + Cloud Monitoring | Managed | Alert policy for low HDFS datanode health/capacity |
| Long Running Job Monitor | `continuumMonitorDpcLongRunningJob` | Monitoring | Terraform + Cloud Monitoring | Managed | Alert policy for jobs running >= 2 hours |
| Stale Cluster Monitor | `continuumMonitorDpcStaleCluster` | Monitoring | Terraform + Cloud Monitoring | Managed | Alert policy for clusters with no running jobs for >= 1 hour |
| Stale Job Monitor | `continuumMonitorDpcStaleJob` | Monitoring | Terraform + Cloud Monitoring | Managed | Alert policy for jobs stuck in PENDING state for >= 10 minutes |
| YARN Pending Memory Monitor | `continuumMonitorYarnPendingMemory` | Monitoring | Terraform + Cloud Monitoring | Managed | Alert policy for YARN pending memory > 200,000 MB for >= 10 minutes |

## Components by Container

### Analytics Proxy LL Cluster (`continuumAnalyticsProxyLlCluster`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Proxy Bootstrap Automation | Executes Terraform-managed init actions and shell scripts that configure long-lived proxy cluster nodes at startup | Shell + Terraform |
| Knox Gateway Configuration | Configures the Apache Knox service, lifecycle management, and ingress routing for secure external access | Apache Knox |
| Topology Templates | Environment-specific Knox topology XML definitions that map analytics, pipelines, OP, and Tableau refresh API routes to backend cluster endpoints | XML configuration |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumAnalyticsProxyLlCluster` | `continuumAnalyticsBackendCluster` | Routes authenticated JDBC and refresh API traffic to backend compute | Knox gateway |
| `continuumAnalyticsProxyCluster` | `continuumAnalyticsBackendCluster` | Forwards proxy traffic for analytics workloads | Proxy routing |
| `continuumProxyCluster` | `continuumPipelinesBackendCluster` | Routes pipeline refresh API calls | Knox gateway |
| `continuumTableauBackendCluster` | `continuumAnalyticsProxyLlCluster` | Consumes secured proxy endpoints for BI refresh | HTTPS/JDBC |
| `continuumOpBackendCluster` | `continuumAnalyticsBackendCluster` | Shares backend data processing capabilities | Dataproc jobs |
| `continuumAnalyticsBackendCluster` | `continuumRangerDbMysql` | Reads Ranger policies and authorization metadata | JDBC |
| `continuumSoxBackendCluster` | `continuumSoxRangerDbMysql` | Reads SOX Ranger policies and authorization metadata | JDBC |
| `continuumAnalyticsBackendCluster` | `bigQueryWarehouse` | Reads and writes curated analytical datasets | Spark SQL/JDBC |
| `continuumPipelinesBackendCluster` | `bigQueryWarehouse` | Reads and writes pipeline datasets | Spark SQL/JDBC |
| `continuumAnalyticsBackendCluster` | `loggingStack` | Emits operational and application logs | Cloud Logging |
| `continuumAnalyticsBackendCluster` | `metricsStack` | Emits cluster and workload metrics | Cloud Monitoring |
| `continuumAnalyticsBackendCluster` | `tracingStack` | Emits distributed trace signals | OpenTelemetry |
| `continuumMonitorDataprocNmDown` | `metricsStack` | Evaluates NodeManager availability signals | Alert policy |
| `continuumMonitorDpcHdfsDatanodeLow` | `metricsStack` | Evaluates HDFS datanode health signals | Alert policy |
| `continuumMonitorDpcLongRunningJob` | `metricsStack` | Evaluates long-running Dataproc job signals | Alert policy |
| `continuumMonitorDpcStaleCluster` | `metricsStack` | Evaluates stale cluster signals | Alert policy |
| `continuumMonitorDpcStaleJob` | `metricsStack` | Evaluates stale job signals | Alert policy |
| `continuumMonitorYarnPendingMemory` | `metricsStack` | Evaluates pending YARN memory pressure signals | Alert policy |

## Architecture Diagram References

- System context: `contexts-continuumSystem`
- Container: `containers-jdbc-refresh-api-longlived`
- Component: `components-continuum-analytics-proxy-ll-cluster`
