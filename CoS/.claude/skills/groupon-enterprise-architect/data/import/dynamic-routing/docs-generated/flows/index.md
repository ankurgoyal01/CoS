---
service: "dynamic-routing"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 5
---

# Flows

Process and flow documentation for Message Bus Dynamic Routing.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Startup Route Loading](startup-route-loading.md) | batch | Application startup | Loads all persisted route definitions from MongoDB and starts their Camel contexts |
| [Route Creation](route-creation.md) | synchronous | Admin UI or API call | Operator creates a new dynamic route; Camel context is built and started; route persisted to MongoDB |
| [Message Forwarding](message-forwarding.md) | asynchronous | Incoming JMS message on source endpoint | Message received on source broker, filtered, transformed, and forwarded to destination broker |
| [Broker Discovery](broker-discovery.md) | synchronous | Admin UI destination picker request | Admin UI requests available queues/topics; Jolokia JMX query returns destination list |
| [Route Start and Stop](route-start-stop.md) | synchronous | Admin UI or API call | Operator starts or stops an existing route; Camel context updated; state persisted to MongoDB |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 3 |
| Asynchronous (event-driven) | 1 |
| Batch / Scheduled | 1 |

## Cross-Service Flows

- **Message Forwarding** spans `continuumDynamicRoutingWebApp` and the JMS broker infrastructure (`messageBusBrokers_9f42`). The route bridges messages between two separate broker endpoints, potentially in different datacenters (snc1, dub1).
- **Broker Discovery** uses the Jolokia HTTP interface on target brokers to enumerate destinations, referenced architecturally as `messageBusBrokers_9f42`.
- Route management flows are internal to `continuumDynamicRoutingWebApp` with reads/writes to `continuumDynamicRoutingMongoDb`.
