---
service: "jdbc-refresh-api-longlived"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Data & Analytics Infrastructure"
platform: "GCP Continuum Data Platform"
team: "gdoop-dev"
status: active
tech_stack:
  language: "HCL"
  language_version: "Terraform >= 1.x"
  framework: "Terragrunt"
  framework_version: ""
  runtime: "GCP Dataproc"
  runtime_version: "1.5-debian10"
  build_tool: "Make + Terragrunt"
  package_manager: "Terragrunt module-ref"
---

# GCP Dataproc Long-Lived Clusters Overview

## Purpose

The `jdbc-refresh-api-longlived` repository provisions and manages the infrastructure for Groupon's long-lived GCP Dataproc cluster platform. It delivers secure, controlled access to analytical data for business intelligence tools (Tableau), ad-hoc JDBC queries, programmatic client access (Python, Java, Scala), Optimus Prime (OP) data flows, and scheduled Refresh API workloads. The platform uses Apache Knox as a proxy gateway to enforce authentication and authorization, and Apache Ranger to enforce row- and column-level data access policies backed by a Cloud SQL for MySQL instance.

## Scope

### In scope

- Provisioning and lifecycle management of long-lived GCP Dataproc clusters (analytics backend, pipelines backend, OP backend, Tableau backend, SOX backend, proxy, SOX proxy, analytics proxy LL)
- Apache Knox gateway configuration and topology templates for JDBC and Refresh API endpoints
- Apache Ranger policy enforcement backed by Cloud SQL for MySQL (standard and SOX-scoped)
- Cloud KMS key ring and crypto key provisioning for Ranger password encryption (standard and SOX-scoped)
- GCS bucket provisioning for Dataproc staging, initialization scripts, and Ranger secrets (standard and SOX-scoped)
- Dataproc autoscaling policy management (YARN-based, JDBC ad-hoc and pipelines policies)
- Cloud Monitoring alert policies for NodeManager health, HDFS datanode capacity, long-running jobs, stale clusters, stale jobs, and YARN pending memory
- DNS A-record management for cluster master nodes in the shared VPC DNS zone
- LDAP group mapping integration for Hadoop authorization
- Multi-environment deployment across dev, stable, and prod GCP projects (data-compute and sox-compute account families)

### Out of scope

- Ephemeral/on-demand Dataproc clusters (managed by other repositories)
- Application-level query logic or Spark job code
- Data pipeline DAG definitions (managed by `grpn-gcloud-data-pipelines` and consumer teams)
- Kafka or other messaging infrastructure (declared as external dependency in `.service.yml`)
- End-user authentication flows (handled upstream by Janus identity services)

## Domain Context

- **Business domain**: Data & Analytics Infrastructure
- **Platform**: GCP Continuum Data Platform (project `prj-grp-data-comp-prod-c9a5`)
- **Upstream consumers**: Data analysts using BI tools (Tableau), programmatic JDBC clients, Optimus Prime (`janus-engine`, `janus-muncher`, `janus-realtime`, `janus-yati`, `janus-metric`), pipeline jobs (`grpn-gcloud-data-pipelines`), AMS, consumer-data-engineering
- **Downstream dependencies**: BigQuery Warehouse (Spark SQL/JDBC), Google Cloud Logging, Cloud Monitoring, Cloud Trace (OpenTelemetry), LDAP directory (`ldap://use2p3wadc01.group.on:389`), Dataproc Metastore Service

## Stakeholders

| Role | Description |
|------|-------------|
| Service Owner | rshanmugasundar (gdoop-dev team) |
| Primary Contact | gdoop-dev@groupon.com |
| GChat Space | AAAArqovlCY |
| Consumers | Data analysts, BI engineers, pipeline engineers, Optimus Prime team |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| IaC Language | HCL (Terraform) | >= 1.x | `modules/**/*.tf` |
| IaC Orchestration | Terragrunt | -- | `envs/**/terragrunt.hcl` |
| Build tool | Make | -- | `envs/.terraform-tooling/Makefile` |
| Compute Platform | GCP Dataproc | 1.5-debian10 | `envs/data-compute-prod/account.hcl` (`image_version`) |
| Proxy Gateway | Apache Knox | Dataproc-bundled | `modules/analytics-proxy-ll-cluster/proxy-cluster.tf` |
| Authorization | Apache Ranger | Dataproc-bundled | `modules/analytics-backend-cluster/backend.tf` |
| Auth Audit Search | Apache Solr | Dataproc-bundled | `modules/analytics-backend-cluster/backend.tf` |
| Metastore | Dataproc Metastore Service | Managed | `envs/data-compute-prod/account.hcl` |
| Secrets Encryption | Google Cloud KMS | Managed | `modules/kms/kms.tf` |
| Authorization DB | Cloud SQL for MySQL | MYSQL_5_7 | `modules/ranger-db-mysql/mysql-db.tf` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| google_dataproc_cluster | Terraform resource | compute | Provisions long-lived Dataproc clusters |
| google_dataproc_autoscaling_policy | Terraform resource | scheduling | YARN-based autoscaling for worker nodes |
| google_monitoring_alert_policy | Terraform resource | metrics | Cloud Monitoring alert policy definitions |
| google_kms_key_ring / google_kms_crypto_key | Terraform resource | auth | KMS key ring and crypto key for password encryption |
| google_sql_database_instance | Terraform resource | db-client | Cloud SQL for MySQL backing Apache Ranger |
| google_storage_bucket | Terraform resource | storage | GCS buckets for staging, init scripts, Ranger secrets |
| google_dns_record_set | Terraform resource | networking | DNS A-records for cluster master node IPs |
| Apache Knox | Dataproc-bundled | http-framework | Front-door HTTPS/JDBC gateway with topology-based routing |
| Apache Ranger | Dataproc-bundled | auth | Row/column-level data access policy enforcement |
| LDAP Groups Mapping | Hadoop core-site | auth | Maps AD/LDAP groups to Hadoop authorization |
| LZO Codec | Hadoop core | serialization | LZO/LZop compression codec for cluster-level I/O |
