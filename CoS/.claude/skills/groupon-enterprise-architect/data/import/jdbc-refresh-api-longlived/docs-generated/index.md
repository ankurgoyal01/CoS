---
service: "jdbc-refresh-api-longlived"
title: "jdbc-refresh-api-longlived Documentation"
generated: "2026-03-03"
type: index
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
    - continuumMonitorDataprocNmDown
    - continuumMonitorDpcHdfsDatanodeLow
    - continuumMonitorDpcLongRunningJob
    - continuumMonitorDpcStaleCluster
    - continuumMonitorDpcStaleJob
    - continuumMonitorYarnPendingMemory
tech_stack:
  language: "HCL (Terraform)"
  framework: "Terragrunt"
  runtime: "GCP Dataproc 1.5-debian10"
---

# GCP Dataproc Long-Lived Clusters Documentation

Terraform/Terragrunt infrastructure-as-code repository that provisions and manages long-lived GCP Dataproc clusters, Apache Knox proxy gateways, Ranger authorization databases, KMS encryption keys, GCS buckets, and Cloud Monitoring alert policies to provide secure JDBC and Refresh API access for data analysts, BI tools, and pipeline workloads.

## Contents

| Document | Description |
|----------|-------------|
| [Overview](overview.md) | Service identity, purpose, domain context, tech stack |
| [Architecture Context](architecture-context.md) | Containers, components, C4 references |
| [API Surface](api-surface.md) | Endpoints, contracts, protocols |
| [Events](events.md) | Async messages published and consumed |
| [Data Stores](data-stores.md) | Databases, caches, storage |
| [Integrations](integrations.md) | External and internal dependencies |
| [Configuration](configuration.md) | Environment, flags, secrets |
| [Flows](flows/index.md) | Process and flow documentation |
| [Deployment](deployment.md) | Infrastructure and environments |
| [Runbook](runbook.md) | Operations, monitoring, troubleshooting |

## Quick Facts

| Property | Value |
|----------|-------|
| Language | HCL (Terraform) |
| Framework | Terragrunt |
| Runtime | GCP Dataproc 1.5-debian10 |
| Build tool | Terragrunt + Make |
| Platform | GCP (Continuum Data Platform) |
| Domain | Data & Analytics Infrastructure |
| Team | gdoop-dev (gdoop-dev@groupon.com) |
