---
service: "dynamic-routing"
title: "Message Forwarding"
generated: "2026-03-03"
type: flow
flow_name: "message-forwarding"
flow_type: asynchronous
trigger: "Incoming JMS message on a configured source endpoint"
participants:
  - "continuumDynamicRoutingWebApp"
  - "messageBusBrokers_9f42"
architecture_ref: "components-continuumDynamicRoutingWebApp"
---

# Message Forwarding

## Summary

When a JMS message arrives on the source endpoint of an active dynamic route, Apache Camel's route DSL processes it through a pipeline: deduplication, filter chain evaluation, header enrichment, optional transformation, and fire-and-forget delivery to the destination endpoint. This is the core operational flow that delivers the message bridging functionality between brokers and datacenters.

## Trigger

- **Type**: Event (incoming JMS message)
- **Source**: JMS broker (HornetQ queue/topic, Artemis queue/topic) or HTTP REST ingestion endpoint
- **Frequency**: Continuous — triggered for every message arriving on any active route's source endpoint

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Source JMS Broker | Delivers incoming message to the Camel consumer | `messageBusBrokers_9f42` |
| Camel Route Builder (source `from()`) | Camel consumer — receives the message from the JMS broker or REST endpoint | `continuumDynamicRoutingWebApp` → `routeBuilder` |
| Message Transformers | Applies header processors and optional body transformer | `continuumDynamicRoutingWebApp` → `messageTransformers` |
| Backend Service Client | Called by transformer if entity enrichment is needed | `continuumDynamicRoutingWebApp` → `backendServiceClient` |
| Destination JMS Broker | Receives the forwarded message | `messageBusBrokers_9f42` |

## Steps

1. **Receive message from source endpoint**: The Camel `from(sourceEndpoint.getCamelUri())` consumer receives a JMS message (or HTTP POST body for REST endpoints). For REST endpoints, the body is first converted to `String`.
   - From: Source JMS Broker (or HTTP client)
   - To: Camel route consumer
   - Protocol: JMS (HornetQ Netty / Artemis) or HTTP

2. **Idempotency check**: The message's `id` field is checked against an in-memory idempotent repository (capacity 500,000 entries). If the message has already been processed (duplicate), it is skipped according to the `skipDuplicates` setting on the source endpoint.
   - From: Camel idempotent consumer
   - To: In-memory `MemoryIdempotentRepository`
   - Protocol: Direct (in-process)

3. **Apply filter chain**: The configured `FilterChain` is applied. Each filter evaluates a predicate against the message headers or body. Messages that do not pass all filters are dropped (the `stop()` branch in the Camel route DSL).
   - From: `routeBuilder`
   - To: `messageTransformers`
   - Protocol: Direct (Apache Camel processor chain)

4. **Copy mbus-client info headers**: `CopyMbusClientInfoHeadersProcessor` copies mbus-client metadata headers from the incoming message into the forwarded message.
   - From: `messageTransformers`
   - To: Camel Exchange headers
   - Protocol: Direct

5. **Add dynamic routing headers**: `AddDynamicRoutingHeadersProcessor` adds provenance headers identifying the dynamic routing service instance and route name.
   - From: `messageTransformers`
   - To: Camel Exchange headers
   - Protocol: Direct

6. **Add chunk/tracing headers**: `AddChunkHeadersProcessor` adds tracing chunk headers if `tracing.chunkSize > 0` on the route definition. Used for message tracing/debugging.
   - From: `messageTransformers`
   - To: Camel Exchange headers
   - Protocol: Direct

7. **Apply transformer**: The route's `Transformer` (if configured) is applied. May modify the message body (e.g., JSON transformation) and/or call backend services for entity enrichment via `BackendServiceClient.getBackendEntityForId()`.
   - From: `messageTransformers`
   - To: `backendServiceClient` (if entity enrichment is needed)
   - Protocol: HTTP GET (`http://<besHost>/bs/<type>/<id>?key=<token>`)

8. **Route on body presence**: Camel `choice()` branches on `body().isNotNull()`. If the transformer nulled the body (e.g., filtered out), the message is dropped via `stop()`. Otherwise, forwarding proceeds.
   - From: `routeBuilder`
   - To: `routeBuilder` (DSL choice)
   - Protocol: Direct

9. **Forward to destination (fire-and-forget)**: `inOnly(destinationUris())` sends the message to the configured destination JMS endpoint. The destination URI is built from `destinationEndpoint.getCamelUri()`. A log destination (`INFO` level, `de.groupon.jms.route.<routeName>`) is also included in the destination list (except for file endpoints).
   - From: Camel producer
   - To: Destination JMS Broker
   - Protocol: JMS (HornetQ Netty / Artemis)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Destination broker unreachable | Camel dead-letter channel — 3 redelivery attempts at 5s initial delay (2x multiplier, 5s max); retried delivery logged at WARN | After 3 failures, message routed to `deadletter.<routeName>` log destination; ERROR logged |
| Filter predicate fails (throws) | Camel error handler catches and routes to dead-letter | Message not forwarded; dead-letter logging |
| Transformer throws `BSConnectionException` | Propagates to Camel error handler; dead-letter channel activated | 3 retries then dead-letter log |
| Idempotency repository full | Oldest entries evicted (LRU); duplicate check less reliable | Potential duplicate delivery for very high-volume routes |
| REST source body not a string | `convertBodyTo(String.class)` converts or fails with Camel type conversion exception | Dead-letter routing |

## Sequence Diagram

```
Source JMS Broker -> CamelConsumer: deliver JMS message
CamelConsumer -> IdempotentRepository: check id (duplicate?)
IdempotentRepository --> CamelConsumer: not duplicate (proceed)
CamelConsumer -> FilterChain: apply filters
FilterChain --> CamelConsumer: message passes filters
CamelConsumer -> CopyMbusClientInfoHeadersProcessor: copy mbus headers
CamelConsumer -> AddDynamicRoutingHeadersProcessor: add routing headers
CamelConsumer -> AddChunkHeadersProcessor: add tracing chunk headers
CamelConsumer -> Transformer: apply body/header transformation
Transformer -> BackendServiceClient: GET /bs/<type>/<id>?key=<token> [if enrichment needed]
BackendServiceClient --> Transformer: entity JSON
Transformer --> CamelConsumer: transformed message
CamelConsumer -> Destination JMS Broker: inOnly(destinationUri) [fire-and-forget]
CamelConsumer -> LogDestination: inOnly(logUri) [INFO log]
Destination JMS Broker --> CamelConsumer: ack (async)
```

## Related

- Architecture dynamic view: `components-continuumDynamicRoutingWebApp`
- Related flows: [Route Creation](route-creation.md), [Startup Route Loading](startup-route-loading.md)
