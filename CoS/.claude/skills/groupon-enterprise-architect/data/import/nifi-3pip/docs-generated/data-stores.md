---
service: "nifi-3pip"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "nifi-content-repository"
    type: "filesystem"
    purpose: "Stores FlowFile content data for in-flight NiFi records"
  - id: "nifi-provenance-repository"
    type: "filesystem"
    purpose: "Stores NiFi provenance event history"
  - id: "nifi-flowfile-repository"
    type: "filesystem"
    purpose: "Stores FlowFile state and attributes for in-flight records"
  - id: "zookeeper-data"
    type: "filesystem"
    purpose: "ZooKeeper cluster coordination state"
---

# Data Stores

## Overview

nifi-3pip uses local persistent volumes (backed by Kubernetes PersistentVolumeClaims) for NiFi's three internal repository types and for ZooKeeper cluster state. A PostgreSQL JDBC driver (`postgresql-42.7.5.jar`) is bundled in the Docker image, indicating NiFi flows are configured to connect to external PostgreSQL databases, but no PostgreSQL connection details are present in the infrastructure configuration files in this repository.

## Stores

### NiFi Content Repository (`nifi-content-repository`)

| Property | Value |
|----------|-------|
| Type | filesystem (Kubernetes PersistentVolumeClaim) |
| Architecture ref | `nifiNode1`, `nifiNode2`, `nifiNode3` |
| Purpose | Stores the content (body) of FlowFiles being processed by NiFi pipelines |
| Ownership | owned |
| Mount path | `/opt/nifi/nifi-current/content_repository` |

#### Access Patterns

- **Read**: NiFi processors read FlowFile content during pipeline execution
- **Write**: NiFi processors write FlowFile content when creating or transforming records
- **Size**: 20 GiB per node (Kubernetes PVC)

---

### NiFi Provenance Repository (`nifi-provenance-repository`)

| Property | Value |
|----------|-------|
| Type | filesystem (Kubernetes PersistentVolumeClaim) |
| Architecture ref | `nifiNode1`, `nifiNode2`, `nifiNode3` |
| Purpose | Stores the history of data provenance events for auditing and replay |
| Ownership | owned |
| Mount path | `/opt/nifi/nifi-current/provenance_repository` |

#### Access Patterns

- **Read**: Operators query provenance history via the NiFi UI or REST API
- **Write**: NiFi runtime appends provenance events as FlowFiles move through processors
- **Size**: 10 GiB per node (Kubernetes PVC)

---

### NiFi FlowFile Repository (`nifi-flowfile-repository`)

| Property | Value |
|----------|-------|
| Type | filesystem (Kubernetes PersistentVolumeClaim) |
| Architecture ref | `nifiNode1`, `nifiNode2`, `nifiNode3` |
| Purpose | Stores FlowFile state and attributes so in-flight records survive node restarts |
| Ownership | owned |
| Mount path | `/opt/nifi/nifi-current/flowfile_repository` |

#### Access Patterns

- **Read**: NiFi runtime reads FlowFile state on startup to resume in-flight records
- **Write**: NiFi runtime writes FlowFile state changes during pipeline execution
- **Size**: 5 GiB per node (Kubernetes PVC)

---

### ZooKeeper Data (`zookeeper-data`)

| Property | Value |
|----------|-------|
| Type | filesystem (Kubernetes PersistentVolumeClaim) |
| Architecture ref | `zookeeper` |
| Purpose | Stores ZooKeeper cluster membership, leader election state, and NiFi cluster coordination data |
| Ownership | owned |
| Mount path | `/bitnami/zookeeper/data` |

#### Access Patterns

- **Read**: ZooKeeper reads ensemble state on startup; NiFi nodes read cluster coordination data
- **Write**: ZooKeeper writes leader election and cluster state changes
- **Size**: 10 GiB per ZooKeeper node (Kubernetes PVC)

---

### External PostgreSQL (bundled driver)

| Property | Value |
|----------|-------|
| Type | postgresql |
| Architecture ref | External — not modeled in this repo's DSL |
| Purpose | Target database for NiFi ingestion flows (driver bundled: `drivers/postgresql-42.7.5.jar`) |
| Ownership | external |
| Migrations path | Not applicable — managed outside this service |

> No PostgreSQL connection strings or credentials are present in this repository's infrastructure configuration. Connection details are expected to be configured within NiFi flow definitions via the NiFi UI.

## Caches

> No evidence found in codebase of dedicated caching layers. NiFi's internal `WriteAheadLocalStateProvider` provides local state persistence with a checkpoint interval of 2 minutes.

## Data Flows

NiFi local state is written to the FlowFile repository on each node using the `WriteAheadLocalStateProvider` (checkpoint interval: 2 minutes, 16 partitions). Cluster-level state is synchronized to ZooKeeper using the `ZooKeeperStateProvider` (session timeout: 10 seconds, root node: `/nifi`). An additional `KubernetesConfigMapStateProvider` is configured for Kubernetes-native cluster state storage.
