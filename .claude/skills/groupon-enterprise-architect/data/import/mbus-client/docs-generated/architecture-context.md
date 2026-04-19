---
service: "mbus-client"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumMbusClientLibrary"]
---

# Architecture Context

## System Context

The MBus Java Client Library (`mbus-client`) is a shared library component within the Continuum platform. It is not a deployed service but a Maven artifact embedded into Groupon Java services that require asynchronous messaging. These host services interact with the MessageBus broker cluster (`messageBus`) over the STOMP protocol using port 61613. The library emits client-side metrics to the `metricsStack` and logs to the `loggingStack`. Dynamic broker host lists are retrieved via HTTP from MBus VIP endpoints (e.g., `mbus-vip.snc1:8081`).

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| MBus Java Client Library | `continuumMbusClientLibrary` | Library (JAR) | Java 8, Maven, Apache Thrift | 1.6.x | Java library used by Groupon services to publish and consume Message Bus topics and queues over STOMP |

## Components by Container

### MBus Java Client Library (`continuumMbusClientLibrary`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Producer API and Implementation | Manages `ProducerConfig`, STOMP connection lifecycle, and publish workflows with `send` (fire-and-forget) and `sendSafe` (receipt-confirmed) semantics; handles retry on failure up to `publishMaxRetryAttempts` | Java |
| Consumer API and Implementation | Manages `ConsumerConfig`, multi-broker thread pool, message receive dispatch (round-robin across broker fetchers), and acknowledgment routing (`ack`, `ackSafe`, `nack`) | Java |
| STOMP Transport | Implements the STOMP wire protocol: frame serialization/deserialization, socket open/close, CONNECT, SUBSCRIBE, SEND, ACK, NACK, RECEIPT, keepalive, and ERROR frame handling | Java |
| Dynamic Server Discovery | Fetches the active MBus broker host list from a VIP HTTP endpoint (`http://{vip}:{port}`) and returns a parsed `Set<HostParams>` for consumer broker connections | Java |
| Message and Thrift Serialization | Defines the `Message` model with factory methods for `STRING`, `JSON`, and `BINARY` payloads; encodes/decodes using generated Thrift classes `MessageInternal` and `MessagePayload` | Java, Apache Thrift |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumMbusClientLibrary` | `messageBus` | Publishes and consumes queue/topic messages | STOMP (TCP port 61613) |
| `continuumMbusClientLibrary` | `metricsStack` | Emits client-side operational metrics (publish count, latency) | metricslib (JMX) |
| `continuumMbusClientLibrary` | `loggingStack` | Emits client and transport logs | SLF4J |
| `continuumMbusClientLibrary_producerApi` | `continuumMbusClientLibrary_stompTransport` | Sends STOMP frames with receipt validation | In-process |
| `continuumMbusClientLibrary_consumerApi` | `continuumMbusClientLibrary_stompTransport` | Subscribes, receives, acks and nacks over STOMP | In-process |
| `continuumMbusClientLibrary_consumerApi` | `continuumMbusClientLibrary_serverDiscovery` | Resolves active broker hosts when dynamic server mode is enabled | In-process |
| `continuumMbusClientLibrary_producerApi` | `continuumMbusClientLibrary_messageSerialization` | Builds and serializes message payloads before sending | In-process |
| `continuumMbusClientLibrary_consumerApi` | `continuumMbusClientLibrary_messageSerialization` | Parses and materializes received payloads after receive | In-process |

## Architecture Diagram References

- System context: `contexts-continuumMbusClientLibrary`
- Container: `containers-continuumMbusClientLibrary`
- Component: `components-continuumMbusClientLibrary`
