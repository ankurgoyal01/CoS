---
service: "channel-manager-integrator-derbysoft"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 1
internal_count: 3
---

# Integrations

## Overview

The service has one external partner dependency (Derbysoft Channel Manager API) and three internal Groupon platform dependencies: the MBus broker, the Kafka broker, and the Getaways Inventory API. Outbound HTTP calls to Derbysoft and Inventory use Retrofit2 clients managed by the `jtier-retrofit` bundle. MBus and Kafka connections are managed by `jtier-messagebus-client` and `kafka-clients` respectively.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Derbysoft Channel Manager API | REST (HTTPS/JSON) | Submits prebook, book, cancellation, and reservation detail requests; receives ARI push from partner systems | yes | `derbysoftCmApi` (stub — not in federated model) |

### Derbysoft Channel Manager API Detail

- **Protocol**: HTTPS/JSON via Retrofit2 (`DerbysoftClient` interface)
- **Base URL / SDK**: Configured at runtime via `derbysoftClient` Retrofit configuration block in the service YAML; actual URL not stored in the repository
- **Auth**: HTTP Authorization header — value set via `derbysoftAuthenticationConfig.authorizationHeaderValue` (secret, stored in Kubernetes secrets / `.meta/deployment/cloud/secrets`)
- **Purpose**: Provides hotel reservation management (prebook/book/cancel/detail) and acts as the source of inbound ARI push calls to Groupon
- **Failure mode**: Booking workflow emits a failure `ResponseMessageContainer` back to MBus, and the reservation is marked failed in the database. ARI push returns an error response to the Derbysoft caller.
- **Circuit breaker**: No evidence found in codebase. Retrofit2 call failures propagate as exceptions caught by the state processors.

#### Derbysoft Client Endpoints Called (Outbound)

| Method | Path | Purpose |
|--------|------|---------|
| `POST` | `reservation/detail` | Retrieve reservation details from Derbysoft |
| `POST` | `reservation/prebook` | Submit a prebook request to hold inventory |
| `POST` | `reservation/book` | Confirm a booking with Derbysoft |
| `POST` | `reservation/cancel` | Cancel an existing reservation with Derbysoft |

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| MBus Broker | STOMP/JMS (MBus) | Receives `RequestMessageContainer` booking/cancel messages from ISW; publishes `ResponseMessageContainer` booking outcomes | `continuumMbusBroker` |
| Kafka Broker | Kafka (TLS-enabled in production) | Publishes `ARIMessage` payloads from validated ARI push requests | `continuumKafkaBroker` |
| Getaways Inventory API | REST (HTTP/JSON) via Retrofit2 | Fetches hotel hierarchy data (`GET /getaways/v2/inventory/hierarchy`) to validate and build hotel/room-type/rate-plan mappings | `getawaysInventoryApi` (stub — not in federated model) |

### MBus Broker Detail

- **Protocol**: STOMP/JMS via `jtier-messagebus-client` (`MbusReader`, `MbusWriter`)
- **Base URL / SDK**: Destination configured via `mbusConfiguration.iswBookingMessageListenerConfig.destination`, `dlqMessageListenerConfig.destination`, and `cmiBookingResponseProducerConfig.destination`
- **Auth**: Broker-level credentials managed by the MBus infrastructure
- **Purpose**: Decouples booking request dispatch from synchronous HTTP; enables at-least-once delivery semantics
- **Failure mode**: Message nack causes re-delivery; unrecoverable failures land in the DLQ destination
- **Circuit breaker**: No evidence found in codebase

### Kafka Broker Detail

- **Protocol**: Kafka (TLS enabled via `kafkaConfig.tlsEnabled`, `kafkaConfig.securityProtocol`, keystore/truststore configured)
- **Base URL / SDK**: Broker list configured via `kafkaConfig.brokerList`; topic via `kafkaConfig.topic`; client ID via `kafkaConfig.clientId`
- **Auth**: TLS mutual authentication; keystore/truststore credentials stored as secrets
- **Purpose**: Forwards validated ARI payloads to downstream consumers as `ARIMessage` events
- **Failure mode**: If Kafka is unavailable or disabled (`kafkaConfig.enabled = false`), the `WorkerKafkaMessageProducer` is initialized with a null producer and ARI publishing is skipped
- **Circuit breaker**: No evidence found in codebase

### Getaways Inventory API Detail

- **Protocol**: REST (HTTP/JSON) via Retrofit2 (`InventoryServiceClient`)
- **Endpoint called**: `GET /getaways/v2/inventory/hierarchy?ids={ids}&idType={idType}`
- **Base URL / SDK**: Configured via `inventoryServiceClientConfig` Retrofit block in service YAML
- **Auth**: Internal service-to-service (no explicit auth mechanism visible in code)
- **Purpose**: Provides hotel hierarchy data (hotel → channel managers → room types → rate plans) used to validate ARI push mappings and build `ExternalHierarchyMapping` records
- **Failure mode**: Mapping validation fails; ARI push is rejected with an appropriate error response
- **Circuit breaker**: No evidence found in codebase

## Consumed By

> Upstream consumers are tracked in the central architecture model. The following are observable from this repo:

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| Derbysoft Partner Systems | REST (HTTPS/JSON inbound) | Push Daily ARI updates to `POST /ari/daily/push` |
| Groupon Inventory Service Worker (ISW) | MBus (STOMP/JMS) | Sends `RESERVE` and `CANCEL` booking request messages |

## Dependency Health

- **Derbysoft API**: No explicit health check or circuit breaker. The service relies on Retrofit2 timeout configuration (`derbysoftClient` Retrofit block) to bound outbound call duration.
- **MBus Broker**: Monitored via the JTier MBus listener lifecycle; unhealthy broker causes consumer threads to stop receiving messages (visible via Wavefront dashboard).
- **Kafka Broker**: `kafkaConfig.requestTimeOutInMillis` and `producerThreadResponseTimeOutInMillis` bound producer calls. TLS certificates must be valid (managed via `kafka-tls.sh` at container startup).
- **Inventory API**: No dedicated health check; failures during mapping validation are logged and returned as error responses.
