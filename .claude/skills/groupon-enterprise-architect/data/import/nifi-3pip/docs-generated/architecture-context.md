---
service: "nifi-3pip"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: [nifiNode1, nifiNode2, nifiNode3, zookeeper]
---

# Architecture Context

## System Context

nifi-3pip is a container within the `continuumSystem` (Continuum Platform) responsible for third-party inventory data ingestion. It operates as a self-contained, clustered data pipeline platform. Three NiFi nodes form an active cluster with ZooKeeper providing coordination. The service sits at the edge of the Continuum platform, ingesting external third-party inventory data and making it available to downstream Continuum services. No external callers of the cluster API are modeled in the current architecture DSL; flow management is performed by platform operators via the NiFi web UI.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| nifi-1 | `nifiNode1` | Service | Apache NiFi (Docker) | 2.4.0 | NiFi node 1 for third-party inventory ingestion, clustering, and flow execution. |
| nifi-2 | `nifiNode2` | Service | Apache NiFi (Docker) | 2.4.0 | NiFi node 2 for third-party inventory ingestion, clustering, and flow execution. |
| nifi-3 | `nifiNode3` | Service | Apache NiFi (Docker) | 2.4.0 | NiFi node 3 for third-party inventory ingestion, clustering, and flow execution. |
| zookeeper | `zookeeper` | Database | Bitnami ZooKeeper (Docker) | 3.9 | Cluster coordination service used by NiFi nodes for state and leader election. |

## Components by Container

### nifi-1 (`nifiNode1`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Bootstrap Script (`nifiNode1Bootstrap`) | Configures NiFi properties (web ports, cluster settings, ZooKeeper address, JVM heap) and launches the NiFi node process. | Shell Script (`start-http.sh`) |
| NiFi Runtime (`nifiNode1Runtime`) | Executes ingestion flows, participates in cluster protocol communication, and serves HTTP APIs and web UI. | Apache NiFi Runtime |
| Health Check Script (`nifiNode1HealthCheck`) | Probes node status by querying `/nifi-api/controller/cluster` and verifying the node reports `CONNECTED` status. | Shell Script (`health-check.sh`) |

### nifi-2 (`nifiNode2`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Bootstrap Script (`nifiNode2Bootstrap`) | Configures NiFi properties and launches the NiFi node process. | Shell Script (`start-http.sh`) |
| NiFi Runtime (`nifiNode2Runtime`) | Executes ingestion flows, participates in cluster protocol, and serves HTTP APIs and web UI. | Apache NiFi Runtime |
| Health Check Script (`nifiNode2HealthCheck`) | Probes node status via NiFi controller API. | Shell Script (`health-check.sh`) |

### nifi-3 (`nifiNode3`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Bootstrap Script (`nifiNode3Bootstrap`) | Configures NiFi properties and launches the NiFi node process. | Shell Script (`start-http.sh`) |
| NiFi Runtime (`nifiNode3Runtime`) | Executes ingestion flows, participates in cluster protocol, and serves HTTP APIs and web UI. | Apache NiFi Runtime |
| Health Check Script (`nifiNode3HealthCheck`) | Probes node status via NiFi controller API. | Shell Script (`health-check.sh`) |

### zookeeper (`zookeeper`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| ZooKeeper Coordinator (`zookeeperCoordinator`) | Maintains cluster membership, coordination, and election state for all three NiFi nodes. | Apache ZooKeeper |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `nifiNode1` | `zookeeper` | Coordinates cluster state and elections | ZooKeeper client (port 2181) |
| `nifiNode2` | `zookeeper` | Coordinates cluster state and elections | ZooKeeper client (port 2181) |
| `nifiNode3` | `zookeeper` | Coordinates cluster state and elections | ZooKeeper client (port 2181) |
| `nifiNode1` | `nifiNode2` | Replicates cluster state and flow changes | NiFi cluster protocol (port 8082) |
| `nifiNode1` | `nifiNode3` | Replicates cluster state and flow changes | NiFi cluster protocol (port 8082) |
| `nifiNode2` | `nifiNode3` | Replicates cluster state and flow changes | NiFi cluster protocol (port 8082) |
| `nifiNode1Bootstrap` | `nifiNode1Runtime` | Bootstraps node with cluster and web settings | Internal (shell exec) |
| `nifiNode1HealthCheck` | `nifiNode1Runtime` | Probes node and cluster state via NiFi API | HTTP (`/nifi-api/controller/cluster`) |
| `nifiNode1Runtime` | `zookeeperCoordinator` | Uses ZooKeeper for cluster coordination | ZooKeeper protocol |

## Architecture Diagram References

- System context: `contexts-continuumSystem`
- Container: `containers-nifi-3pip`
- Component: `components-nifi-node-1`, `components-nifi-node-2`, `components-nifi-node-3`, `components-zookeeper`
