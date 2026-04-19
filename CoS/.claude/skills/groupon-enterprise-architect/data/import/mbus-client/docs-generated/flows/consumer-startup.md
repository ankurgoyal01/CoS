---
service: "mbus-client"
title: "Consumer Startup and Broker Discovery"
generated: "2026-03-03"
type: flow
flow_name: "consumer-startup"
flow_type: synchronous
trigger: "Application code calls ConsumerImpl.start(ConsumerConfig)"
participants:
  - "continuumMbusClientLibrary_consumerApi"
  - "continuumMbusClientLibrary_serverDiscovery"
  - "continuumMbusClientLibrary_stompTransport"
  - "messageBus"
architecture_ref: "dynamic-continuumMbusClientLibrary"
---

# Consumer Startup and Broker Discovery

## Summary

When a host service starts its MBus consumer, the library performs a multi-step startup sequence: it validates the configuration, uses dynamic server discovery to resolve all active broker hosts in the MBus cluster, opens a dedicated STOMP connection to each broker, subscribes to the configured destination on each connection, and starts background prefetch threads. This multi-broker approach enables parallel message prefetching and load distribution across the cluster.

## Trigger

- **Type**: api-call
- **Source**: Embedding application calls `ConsumerImpl.start(ConsumerConfig config)` on service startup
- **Frequency**: Once per consumer instance lifecycle; may repeat on restart

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Consumer API and Implementation | Orchestrates startup; validates config; creates and manages `StompServerFetcher` threads | `continuumMbusClientLibrary_consumerApi` |
| Dynamic Server Discovery | Fetches active broker host list from MBus VIP HTTP endpoint | `continuumMbusClientLibrary_serverDiscovery` |
| STOMP Transport | Opens TCP socket to each broker; sends STOMP CONNECT and SUBSCRIBE frames | `continuumMbusClientLibrary_stompTransport` |
| MBus Broker | Accepts connections; registers subscription; begins pushing messages to consumer | `messageBus` |

## Steps

1. **Application calls start**: The embedding service constructs a `ConsumerConfig` with at least `hostParams` (VIP address), `destinationName`, `destinationType`, and `subscriptionId` (for topics), then calls `ConsumerImpl.start(config)`.
   - From: Embedding application
   - To: `continuumMbusClientLibrary_consumerApi`
   - Protocol: In-process Java call

2. **Validates configuration**: `ConsumerImpl` checks that required config fields are present (`hostParams`, `destinationName`). Throws `InvalidConfigException` if any required field is missing. Validates `Status` is `INITIALIZED` (not already `RUNNING`).
   - From: `continuumMbusClientLibrary_consumerApi`
   - To: Internal validation
   - Protocol: In-process Java call

3. **Fetches active broker host list** (if `useDynamicServerList=true`): `DynamicServerListGetter.fetchHostList()` performs an HTTP GET to `http://{vip-host}:{port}` (derived from the `HostParams` VIP). The endpoint returns a comma-separated list of active broker host:port pairs (e.g., `mbus01.snc1:61613,mbus02.snc1:61613`).
   - From: `continuumMbusClientLibrary_serverDiscovery`
   - To: MBus VIP HTTP endpoint (`messageBus`)
   - Protocol: HTTP GET (connect timeout: 1000 ms, read timeout: 5000 ms)

4. **Parses broker host list**: `DynamicServerListGetter.parseAndReturnHosts()` splits the response by comma and colon delimiters, returning a `Set<HostParams>` representing all active brokers.
   - From: `continuumMbusClientLibrary_serverDiscovery`
   - To: `continuumMbusClientLibrary_consumerApi`
   - Protocol: In-process Java call

5. **Creates StompServerFetcher per broker**: For each resolved broker host, `ConsumerImpl` creates a `StompServerFetcher` instance with the broker's host/port and the full `ConsumerConfig`.
   - From: `continuumMbusClientLibrary_consumerApi`
   - To: `continuumMbusClientLibrary_stompTransport`
   - Protocol: In-process Java instantiation

6. **Connects to each broker (STOMP CONNECT)**: Each `StompServerFetcher.connect()` opens a TCP socket to the broker and sends a STOMP `CONNECT` frame with credentials (`userName`, `password`) and `client-id` (= `subscriptionId` for topics).
   - From: `continuumMbusClientLibrary_stompTransport`
   - To: `messageBus`
   - Protocol: STOMP over TCP (port 61613)

7. **Subscribes to destination (STOMP SUBSCRIBE)**: After successful CONNECT, sends a STOMP `SUBSCRIBE` frame with the destination name, ack mode (`CLIENT` or `INDIVIDUAL`), and optional headers: `durable-subscriber-name` (for durable topics), `consumer-credits`, `message-ttl`, `selector`.
   - From: `continuumMbusClientLibrary_stompTransport`
   - To: `messageBus`
   - Protocol: STOMP over TCP (port 61613)

8. **Starts prefetch threads**: Each `StompServerFetcher` is submitted to the internal thread pool. Each thread enters a continuous `run()` loop: calls `refreshConnection()` then `preFetchMessage()` to drain incoming STOMP frames into its `preFetchedCache`.
   - From: `continuumMbusClientLibrary_consumerApi`
   - To: `continuumMbusClientLibrary_stompTransport`
   - Protocol: In-process Java thread management

9. **Consumer transitions to RUNNING**: `ConsumerImpl.status` is set to `RUNNING`. `start()` returns `true` to the caller. The consumer is now ready to serve `receive()` calls.
   - From: `continuumMbusClientLibrary_consumerApi`
   - To: Embedding application
   - Protocol: In-process Java call

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Required config missing | `InvalidConfigException` thrown from `start()` | Consumer does not start; application must fix config |
| Dynamic server discovery HTTP fails | `IOException` from `DynamicServerListGetter`; propagated to `start()` | `start()` returns `false`; application may retry |
| STOMP CONNECT rejected (bad credentials, destination not found) | `BrokerConnectionFailedException` or `InvalidDestinationException` | Connection retried up to `MAX_RETRY_COUNT` (3); if all fail, exception propagated |
| Broker unreachable after 3 retries | `TooManyConnectionRetryAttemptsException` wrapped in `BrokerConnectionFailedException` | `StompServerFetcher` thread sleeps `FAILURE_RETRY_INTERVAL` (60000 ms) before retrying in background |
| Consumer already `RUNNING` | `InvalidStatusException` thrown | Application must stop consumer before restarting |

## Sequence Diagram

```
Application         -> ConsumerImpl         : start(ConsumerConfig)
ConsumerImpl        -> ConsumerImpl         : validateConfig()
ConsumerImpl        -> DynamicServerListGetter : fetchHostList(http://vip-host:port)
DynamicServerListGetter -> MBus VIP         : HTTP GET /
MBus VIP            --> DynamicServerListGetter : "mbus01.snc1:61613,mbus02.snc1:61613"
DynamicServerListGetter --> ConsumerImpl    : Set<HostParams>
ConsumerImpl        -> StompServerFetcher   : new StompServerFetcher(host, port, config) [per broker]
ConsumerImpl        -> ThreadPool           : submit(fetcher) [per broker]
StompServerFetcher  -> StompConnection      : open(host, port)
StompConnection     -> MBus Broker          : TCP STOMP CONNECT (user, password, client-id)
MBus Broker         --> StompConnection     : STOMP CONNECTED
StompConnection     -> MBus Broker          : STOMP SUBSCRIBE (destination, ack, headers)
MBus Broker         --> StompConnection     : (subscription registered, messages begin flowing)
ConsumerImpl        --> Application         : true (RUNNING)
```

## Related

- Architecture dynamic view: `dynamic-continuumMbusClientLibrary`
- Related flows: [Consumer Receive and Acknowledge](consumer-receive-ack.md), [Connection Lifecycle and Keepalive](connection-lifecycle.md)
