---
service: "kafka"
title: Architecture Context
generated: "2026-03-02T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: [continuumKafkaBroker, continuumKafkaController, continuumKafkaConnectWorker, continuumKafkaTrogdorCoordinator, continuumKafkaTrogdorAgent, continuumKafkaLogStorage, continuumKafkaMetadataLog]
---

# Architecture Context

## System Context

Apache Kafka sits at the center of the Continuum platform as the shared asynchronous event bus. All Continuum services that need to communicate asynchronously produce and consume messages via Kafka topics. The Kafka cluster is modeled under `continuumSystem` and exposes the Kafka Wire Protocol to any service holding a valid client configuration. The KRaft controller (`continuumKafkaController`) replaced ZooKeeper and manages all cluster metadata internally. Kafka Connect (`continuumKafkaConnectWorker`) extends the cluster with configurable source and sink connectors. The Trogdor framework (`continuumKafkaTrogdorCoordinator` / `continuumKafkaTrogdorAgent`) provides in-cluster performance testing capability.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Kafka Broker | `continuumKafkaBroker` | Backend | JVM (Scala/Java) | Kafka 4.3.0-SNAPSHOT | Stores topic partitions, serves produce/fetch traffic, replicates records across the cluster |
| Kafka Controller (KRaft) | `continuumKafkaController` | Backend | JVM (Java) | Kafka 4.3.0-SNAPSHOT | Maintains cluster metadata, controller quorum state, and partition leadership decisions |
| Kafka Connect Worker | `continuumKafkaConnectWorker` | Backend | JVM (Java) | Kafka 4.3.0-SNAPSHOT | Runs source and sink connectors for data integration with Kafka topics |
| Trogdor Coordinator | `continuumKafkaTrogdorCoordinator` | Backend | JVM (Java) | Kafka 4.3.0-SNAPSHOT | Coordinates distributed workload generation and fault injection for system testing |
| Trogdor Agent | `continuumKafkaTrogdorAgent` | Backend | JVM (Java) | Kafka 4.3.0-SNAPSHOT | Executes workload tasks on target nodes under coordinator control |
| Kafka Log Storage | `continuumKafkaLogStorage` | Database | Filesystem | — | Persistent segment files storing topic-partition data for brokers |
| KRaft Metadata Log | `continuumKafkaMetadataLog` | Database | Filesystem | — | Replicated metadata log backing KRaft controller state |

## Components by Container

### Kafka Broker (`continuumKafkaBroker`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Network API (`kafkaBrokerNetworkApi`) | Handles produce/fetch/admin requests over the Kafka protocol | Network Layer |
| Replica Manager (`kafkaBrokerReplicaManager`) | Coordinates replication, ISR state, and partition leadership execution | Replication Engine |
| Log Manager (`kafkaBrokerLogManager`) | Manages segment files, retention, and log compaction lifecycle | Storage Engine |

### Kafka Controller (KRaft) (`continuumKafkaController`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Quorum Manager (`kafkaControllerQuorumManager`) | Implements KRaft quorum coordination and metadata replication | Consensus Engine |
| Metadata Loader (`kafkaControllerMetadataLoader`) | Loads and applies metadata records to in-memory state | Metadata Service |
| Broker Lifecycle Manager (`kafkaControllerBrokerLifecycle`) | Tracks broker registration, fencing, and leader election actions | Cluster Control |

### Kafka Connect Worker (`continuumKafkaConnectWorker`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Herder (`kafkaConnectHerder`) | Coordinates connector and task lifecycle across workers | Connect Runtime |
| Connector Runtime (`kafkaConnectConnectorRuntime`) | Executes source/sink connector tasks and transformations | Connect Runtime |
| Offset Store Client (`kafkaConnectOffsetStore`) | Persists connector offsets and task status in Kafka topics | State Management |

### Trogdor Coordinator (`continuumKafkaTrogdorCoordinator`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Coordinator API (`kafkaTrogdorCoordinatorApi`) | Exposes task submission and status endpoints | REST API |
| Task Scheduler (`kafkaTrogdorCoordinatorScheduler`) | Plans and assigns tasks to Trogdor agents | Scheduler |

### Trogdor Agent (`continuumKafkaTrogdorAgent`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Task Runner (`kafkaTrogdorAgentTaskRunner`) | Runs assigned benchmark and fault workloads on the host | Workload Engine |
| Platform Adapter (`kafkaTrogdorAgentPlatformAdapter`) | Interacts with local process, filesystem, and network resources for task execution | Host Integration |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumKafkaBroker` | `continuumKafkaLogStorage` | Appends and reads topic-partition segments | Filesystem I/O |
| `continuumKafkaBroker` | `continuumKafkaMetadataLog` | Reads committed metadata snapshots and deltas | Filesystem I/O |
| `continuumKafkaController` | `continuumKafkaMetadataLog` | Persists and replays controller quorum metadata | Filesystem I/O |
| `continuumKafkaController` | `continuumKafkaBroker` | Manages brokers, leaders, and partition assignments | RPC |
| `continuumKafkaConnectWorker` | `continuumKafkaBroker` | Uses Kafka APIs for source and sink connector I/O | Kafka Wire Protocol |
| `continuumKafkaTrogdorCoordinator` | `continuumKafkaTrogdorAgent` | Schedules benchmark and fault-injection tasks | REST |
| `continuumKafkaTrogdorAgent` | `continuumKafkaBroker` | Generates traffic and operational test actions | Kafka Wire Protocol |
| `kafkaBrokerReplicaManager` | `kafkaControllerQuorumManager` | Receives partition leadership and metadata updates | RPC |
| `kafkaControllerQuorumManager` | `kafkaBrokerReplicaManager` | Propagates metadata changes and leadership decisions | RPC |
| `kafkaConnectConnectorRuntime` | `kafkaBrokerNetworkApi` | Reads and writes connector records via broker APIs | Kafka Wire Protocol |
| `kafkaTrogdorCoordinatorScheduler` | `kafkaTrogdorAgentTaskRunner` | Dispatches workload tasks to agents | REST |
| `kafkaTrogdorAgentTaskRunner` | `kafkaBrokerNetworkApi` | Executes produce/consume workloads against brokers | Kafka Wire Protocol |

## Architecture Diagram References

- System context: `contexts-kafka`
- Container: `containers-kafka`
- Component (Broker): `components-kafka-broker`
- Component (Controller): `components-kafka-controller`
- Component (Connect Worker): `components-kafka-connect-worker`
- Component (Trogdor Coordinator): `components-kafka-trogdor-coordinator`
- Component (Trogdor Agent): `components-kafka-trogdor-agent`
- Dynamic view (KRaft control): `dynamic-kafka-kraft-cluster-control`
