---
service: "jdbc-refresh-api-longlived"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 7
internal_count: 7
---

# Integrations

## Overview

The platform integrates with 7 external GCP-managed services for compute, storage, networking, security, and observability, and depends on 7 internal Groupon services declared in `.service.yml`. All cluster-level communications occur over private networking (internal IP only) within the shared VPC. No public IP addresses are assigned to any cluster node.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| GCP Dataproc | GCP API | Provisions and manages Hadoop/Spark cluster lifecycle | yes | `continuumAnalyticsBackendCluster` |
| GCP Cloud SQL for MySQL | JDBC (private IP) | Hosts Ranger policy and metadata database | yes | `continuumRangerDbMysql` |
| GCP Cloud KMS | GCP API | Encrypts and decrypts Ranger credentials stored in GCS | yes | `continuumKms` |
| GCP Cloud Storage (GCS) | gsutil / GCS API | Stores staging artifacts, init scripts, encrypted secrets | yes | `continuumBuckets` |
| GCP Cloud Monitoring | Metrics API | Receives cluster metrics; evaluates alert conditions | yes | `continuumMonitorDataprocNmDown` |
| GCP Cloud DNS | DNS API | Registers A-records for Dataproc cluster master nodes | no | (DNS zone: `dz-prod-sharedvpc01-data-comp-prod`) |
| LDAP Directory | LDAP (port 389) | Provides group-to-user mapping for Hadoop authorization | yes | (host: `ldap://use2p3wadc01.group.on:389`) |
| BigQuery Warehouse | Spark SQL/JDBC | Analytical data read/write target for backend clusters | yes | `bigQueryWarehouse` |
| Dataproc Metastore Service | Managed API | Hive-compatible metastore for analytics and pipelines clusters | yes | (URI: `grpn-dpms-prod-analytics`, `grpn-dpms-prod-pipelines`) |

### GCP Dataproc Detail

- **Protocol**: GCP API (Terraform `google_dataproc_cluster`)
- **Base URL / SDK**: `provider = google-beta`
- **Auth**: Terraform service account `grpn-sa-terraform-data-compute`
- **Purpose**: Core compute fabric — provisions master and worker nodes, installs Hadoop/Spark/Hive ecosystem components, executes initialization actions
- **Failure mode**: Cluster creation failure blocks all JDBC/Refresh API access; cluster node failure triggers NodeManager and HDFS alerts
- **Circuit breaker**: No; Dataproc SLA is Google-managed

### Cloud SQL for MySQL (Ranger DB) Detail

- **Protocol**: JDBC over private IP
- **Base URL / SDK**: `dataproc:ranger.cloud-sql.instance.connection.name = {project}:{region}:prod-ranger-mysql-db`
- **Auth**: KMS-encrypted root and Ranger admin passwords stored in GCS, consumed by Dataproc Ranger component at startup
- **Purpose**: Persists Ranger authorization policies, user/group mappings, and audit events
- **Failure mode**: Ranger policy evaluation fails; all new queries are denied (Ranger safe mode)
- **Circuit breaker**: No explicit circuit breaker; Cloud SQL HA failover handles instance-level failures

### Cloud KMS Detail

- **Protocol**: GCP KMS API
- **Base URL / SDK**: `projects/{project}/locations/{region}/keyRings/jdbc-refresh-api-key-ring/cryptoKeys/op-crypto-key`
- **Auth**: Terraform service account IAM; Dataproc service account `loc-sa-dataproc-longlived-jdbc`
- **Purpose**: Encrypts MySQL root password, Ranger admin password, and Ranger DB admin password before storing in GCS
- **Failure mode**: Cluster bootstrap fails if KMS is unavailable during init action execution
- **Circuit breaker**: No

### LDAP Directory Detail

- **Protocol**: LDAP (plaintext port 389)
- **Base URL / SDK**: `ldap://use2p3wadc01.group.on:389`
- **Auth**: None declared (`hadoop.security.group.mapping.ldap.ssl = false`)
- **Purpose**: Resolves LDAP group memberships for Hadoop `CompositeGroupsMapping`; maps AD/LDAP groups to Hadoop authorization groups
- **Failure mode**: Group lookup falls back to OS groups (`osgroups` provider in composite mapping)
- **Circuit breaker**: Hadoop group mapping has built-in OS group fallback

### BigQuery Warehouse Detail

- **Protocol**: Spark SQL / JDBC
- **Base URL / SDK**: BigQuery Storage API via Spark connector
- **Auth**: Dataproc service account `loc-sa-dataproc-longlived-jdbc` (scope `cloud-platform`)
- **Purpose**: Primary analytical data read/write target; backend clusters process and write curated datasets
- **Failure mode**: Query jobs fail and return errors to JDBC clients; no automatic retry at the infrastructure layer
- **Circuit breaker**: No

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| kafka | Event streaming | Pipeline workloads on backend clusters consume Kafka topics | (external service) |
| consumer-data-engineering | Internal | Consumer data pipelines run on provisioned clusters | (internal service) |
| grpn-gcloud-data-pipelines | Internal | GCP data pipeline jobs execute on backend clusters | (internal service) |
| revmgmt-decision-science | Internal | Revenue management workloads on analytics clusters | (internal service) |
| ams | Internal | AMS workloads depend on cluster availability | (internal service) |
| janus-engine | Internal | Optimus Prime query execution on OP backend cluster | `continuumOpBackendCluster` |
| janus-muncher | Internal | Janus data processing on backend cluster | (internal service) |
| janus-realtime | Internal | Real-time Janus workloads on backend cluster | (internal service) |
| janus-yati | Internal | Janus analytics on backend cluster | (internal service) |
| janus-metric | Internal | Janus metric computation on backend cluster | (internal service) |

## Consumed By

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| Tableau and BI clients | JDBC via Knox | Ad-hoc and refresh queries via `continuumTableauBackendCluster` through `continuumAnalyticsProxyLlCluster` |
| Programmatic JDBC clients (Python, Java, Scala) | JDBC via Knox | Interactive and ad-hoc data access via Knox proxy |
| Optimus Prime | Dataproc jobs | Batch data processing on `continuumOpBackendCluster` |
| Pipeline jobs (grpn-gcloud-data-pipelines) | Dataproc / Spark | Refresh API pipeline execution on `continuumPipelinesBackendCluster` |

> Upstream consumers are also tracked in the central architecture model under `continuumSystem`.

## Dependency Health

- LDAP group resolution uses `CompositeGroupsMapping` with OS group fallback, providing resilience against LDAP unavailability
- Cloud SQL backups and binary logging are enabled for Ranger DB, supporting point-in-time recovery
- Dataproc NodeManager, HDFS datanode, YARN memory, long-running job, stale job, and stale cluster monitors provide automated alerting via Cloud Monitoring
- All cluster nodes use `internal_ip_only = true` to reduce attack surface; no external IP exposure
