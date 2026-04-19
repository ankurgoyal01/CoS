---
service: "mbus-isimud"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumMbusIsimudService", "continuumMbusIsimudPostgres"]
---

# Architecture Context

## System Context

mbus-isimud is a utility service within the Continuum platform (`continuumSystem`). It does not participate in live commerce flows. Instead it acts as an on-demand load and validation harness: engineers call its REST API to drive configurable message workloads through existing or candidate message brokers. The service connects outbound to one or more broker hosts (Artemis or RabbitMQ) and writes execution history to a dedicated PostgreSQL database. There are no inbound dependencies from other Continuum services at runtime.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| mbus-isimud Service | `continuumMbusIsimudService` | Backend API | Java 17, Dropwizard | JTier 5.14.1 | REST API that generates and executes randomized message-broker validation workloads |
| mbus-isimud Postgres | `continuumMbusIsimudPostgres` | Database | PostgreSQL | DaaS-managed | Stores execution history, job state, and topology execution metadata |

## Components by Container

### mbus-isimud Service (`continuumMbusIsimudService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `TopologyResource` | REST endpoints for listing topologies, generating dry-run messages, and triggering real executions against a named or custom topology | JAX-RS (Dropwizard) |
| `ExecutionResource` | REST endpoints for querying paginated execution history and canceling in-flight executions | JAX-RS (Dropwizard) |
| `MessagesService` | Generates randomized message payloads from configured topology and generator definitions using statistical distributions | Java, commons-math3 |
| `TopologyExecutionService` | Coordinates execution runs, allocates workers, and drives end-to-end topology processing | Java, ExecutorService |
| `MessagesExecutionServiceFactory` | Builds execution handlers for configured broker types (Artemis STOMP, RabbitMQ STOMP, RabbitMQ AMQP) and destination mappings | Java |
| `Broker Adapter Layer` | STOMP proxy and AMQP connection factories — intercepts STOMP traffic and proxies it to the target broker | STOMP, AMQP |
| `ExecutionDao` | Persists and retrieves execution records; backed by either PostgreSQL (JDBI3) or an in-memory DAO when Postgres is not configured | JDBI3 / in-memory |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumMbusIsimudService` | `continuumMbusIsimudPostgres` | Reads/writes execution history and state | JDBI/PostgreSQL |
| `continuumMbusIsimudTopologyResource` | `continuumMbusIsimudMessagesService` | Handles topology and message generation API calls | direct |
| `continuumMbusIsimudExecutionResource` | `continuumMbusIsimudExecutionDao` | Reads and updates execution records | direct |
| `continuumMbusIsimudTopologyExecutionService` | `continuumMbusIsimudExecutionDao` | Persists execution lifecycle and stats | direct |
| `continuumMbusIsimudTopologyExecutionService` | `continuumMbusIsimudMessagesService` | Generates messages for execution | direct |
| `continuumMbusIsimudMessagesExecutionFactory` | `continuumMbusIsimudBrokerAdapter` | Creates broker-specific execution handlers | direct |
| `continuumMbusIsimudTopologyExecutionService` | `continuumMbusIsimudMessagesExecutionFactory` | Delegates broker execution setup | direct |

## Architecture Diagram References

- System context: `contexts-continuumSystem`
- Container: `containers-continuumSystem`
- Component: `components-continuum-mbus-isimud-continuumMbusIsimudMessagesService`
- Dynamic view: `dynamic-mbus-isimud-execute-topology`
