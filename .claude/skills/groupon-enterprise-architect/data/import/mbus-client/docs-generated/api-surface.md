---
service: "mbus-client"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: ["stomp", "library-api"]
auth_mechanisms: ["username-password"]
---

# API Surface

## Overview

The MBus Java Client Library does not expose an HTTP API. Its API surface is the Java library interface consumed by host application code. The library provides two main API contracts — `Producer` and `Consumer` — both configured via config objects and backed by STOMP connections to the MBus broker. Authentication to the broker is via username/password credentials provided in configuration.

## Producer API

The `Producer` interface (`com.groupon.messagebus.api.Producer`) is the entry point for publishing messages to MBus queues and topics.

### Lifecycle Operations

| Method | Purpose | Notes |
|--------|---------|-------|
| `start(ProducerConfig config)` | Opens STOMP connection and starts producer | Throws `InvalidConfigException`, `TooManyConnectionRetryAttemptsException`, `InvalidStatusException` |
| `stop()` | Closes STOMP connection and stops producer | Throws `BrokerConnectionCloseFailedException`, `InvalidStatusException` |
| `refreshConnection()` | Reconnects to the broker | Used when connection breaks during send or on periodic refresh |
| `getStatus()` | Returns current producer status | Returns `INITIALIZED`, `RUNNING`, or `STOPPED` |

### Publish Operations

| Method | Semantics | Throughput | Reliability |
|--------|-----------|-----------|-------------|
| `send(Message message)` | Fire-and-forget send to configured destination | 1500+ QPS | No receipt confirmation; messages may be lost on broker failure |
| `send(Message message, Map<String,String> headers)` | Fire-and-forget with custom headers | 1500+ QPS | No receipt confirmation |
| `send(Message message, String destinationName, Map<String,String> headers)` | Fire-and-forget to specified destination | 1500+ QPS | No receipt confirmation |
| `sendSafe(Message message)` | Receipt-confirmed send to configured destination | 150+ QPS | Waits for STOMP `RECEIPT` frame; retries up to `publishMaxRetryAttempts` |
| `sendSafe(Message message, Map<String,String> headers)` | Receipt-confirmed send with custom headers | 150+ QPS | Retries on timeout; receipt timeout per attempt is `receiptTimeoutMillis` |
| `sendSafe(Message message, String destinationName, Map<String,String> headers)` | Receipt-confirmed send to specified destination | 150+ QPS | Receipt confirmed per attempt |

## Consumer API

The `Consumer` interface (`com.groupon.messagebus.api.Consumer`) is the entry point for subscribing to and receiving messages from MBus queues and topics.

### Lifecycle Operations

| Method | Purpose | Notes |
|--------|---------|-------|
| `start(ConsumerConfig config)` | Opens connections to broker(s), starts prefetch threads | Returns `true` on success; throws `InvalidConfigException`, `InvalidStatusException` |
| `stop()` | Closes all broker connections, stops prefetch threads | Optionally unsubscribes if `autoUnsubscribe=true` |
| `keepAlive()` | Sends heartbeat to all connected brokers | Prevents connection timeout |
| `getStatus()` | Returns current consumer status | Returns `INITIALIZED`, `RUNNING`, or `STOPPED` |

### Receive Operations

| Method | Blocking | Timeout |
|--------|----------|---------|
| `receive()` | Blocking (infinite) | No timeout |
| `receive(long timeout)` | Blocking | Specified timeout in milliseconds; throws `ReceiveTimeoutException` on expiry |
| `receiveImmediate()` | Non-blocking | Returns `null` immediately if no message available |

### Acknowledgment Operations

| Method | Type | Notes |
|--------|------|-------|
| `ack()` | Fire-and-forget ack of last received message | Does not wait for server confirmation |
| `ack(String ackId)` | Fire-and-forget ack by message ack ID | |
| `ackSafe()` | Confirmed ack of last received message | Blocks until STOMP `RECEIPT` received (default 1000 ms timeout) |
| `ackSafe(String ackId)` | Confirmed ack by ack ID | |
| `ackSafe(long timeout)` | Confirmed ack with specified timeout | Throws `AckFailedException` on timeout |
| `ackSafe(String ackId, long timeout)` | Confirmed ack by ack ID with specified timeout | |
| `nack(String ackId)` | Negative ack — returns message to broker for redelivery | |
| `nack()` | Negative ack of last received message | |

## Message Factory

The `Message` class (`com.groupon.messagebus.api.Message`) provides factory methods for creating typed message instances:

| Factory Method | Payload Type | Notes |
|---------------|-------------|-------|
| `Message.createStringMessage(String payload)` | `STRING` | Auto-generates MD5-hashed UUID message ID |
| `Message.createStringMessage(String messageId, String payload)` | `STRING` | Uses provided message ID |
| `Message.createBinaryMessage(byte[] payload)` | `BINARY` | Auto-generates message ID |
| `Message.createBinaryMessage(String messageId, byte[] payload)` | `BINARY` | Uses provided message ID |
| `Message.createJsonMessage(Object objectPayload)` | `JSON` | Serializes via Gson; uses Gson date format `yyyy-MM-dd'T'HH:mm:ss'Z'` |
| `Message.createJsonMessage(String messageId, Object payload)` | `JSON` | Uses provided message ID |
| `Message.createJsonStringMessage(String jsonString)` | `JSON` | Accepts pre-serialized JSON string |
| `Message.createJsonStringMessage(String messageId, String jsonString)` | `JSON` | Uses provided message ID |

## Request/Response Patterns

### Destination naming convention

MBus destinations follow JMS naming conventions:
- Topics: `jms.topic.{TopicName}` — example: `jms.topic.grouponTestTopic1`
- Queues: `jms.queue.{QueueName}` — example: `jms.queue.myQueue`

The `DestinationType` enum (`QUEUE` or `TOPIC`) must match the destination name prefix.

### Authentication

The library authenticates to the MBus broker using username/password credentials sent in the STOMP `CONNECT` frame. The default credentials (`rocketman` / `rocketman`) are used when not overridden. Credentials are set via `ConsumerConfig.setUserName()` / `setPassword()` or `ProducerConfig.setUserName()` / `setPassword()`.

### Error format

Broker-level errors are delivered as STOMP `ERROR` frames. The library maps them to typed exceptions:

| Exception | Cause |
|-----------|-------|
| `BrokerConnectionFailedException` | Cannot establish or maintain TCP connection to broker |
| `TooManyConnectionRetryAttemptsException` | Exceeded `MAX_RETRY_COUNT` (3) broker reconnect attempts |
| `SendFailedException` | STOMP SEND frame rejected by broker |
| `AckFailedException` | STOMP ACK failed (e.g., broken connection, timeout) |
| `NackFailedException` | STOMP NACK failed |
| `InvalidConfigException` | Required configuration missing or invalid |
| `ReceiveTimeoutException` | `receive(long timeout)` expired without message |

## Rate Limits

> No rate limiting configured in the client library. Throughput limits are enforced server-side by the MBus broker cluster.

## Versioning

The library uses semantic versioning (`MAJOR.MINOR.PATCH`). The current stable version series is `1.6.x` (module `java/pom.xml`). Releases are published to `https://artifactory.groupondev.com/artifactory/releases`. Consumers pin an explicit version in their `pom.xml` dependency declaration.

## OpenAPI / Schema References

The Thrift IDL defining message payload types is located at `thrift/messagebus.thrift`. Generated stubs are pre-committed for Java, Python, Perl, and Ruby in the `thrift-gen/` directory.
