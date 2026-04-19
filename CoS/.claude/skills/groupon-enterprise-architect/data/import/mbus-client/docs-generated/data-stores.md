---
service: "mbus-client"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores: []
---

# Data Stores

## Overview

> This service is stateless and does not own any data stores.

The MBus Java Client Library is a pure transport library. It holds no persistent state of its own. All message durability, retention, and storage are managed by the MBus broker cluster (`messageBus`). The library maintains only transient in-memory state during operation:

- **Prefetch cache** (`LinkedBlockingQueue<StompFrame>` per broker connection): Buffers messages received from the broker before the application calls `receive()`. Cleared on connection reset or consumer stop.
- **Awaiting receipts map** (`Hashtable<String, SettableFuture<StompFrame>>`): Tracks in-flight receipt IDs for `sendSafe` and `ackSafe` operations. Cleared on connection reset.

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| `preFetchedCache` (per `StompServerFetcher`) | In-memory (`LinkedBlockingQueue`) | Buffers prefetched STOMP MESSAGE frames from a single broker connection | No TTL; evicted on `receive()` poll or connection reset |
| `awaitingReceipts` (per `StompServerFetcher`) | In-memory (`Hashtable`) | Maps receipt IDs to `SettableFuture` instances awaiting STOMP RECEIPT frames | Evicted on receipt arrival or `AckFailedException`; cleared on connection reset |

## Data Flows

The library receives messages from the MBus broker over a persistent TCP/STOMP connection. The data flow for received messages is:

1. `StompServerFetcher` thread reads a STOMP `MESSAGE` frame from the TCP socket.
2. Frame is placed into the in-memory `preFetchedCache` (`LinkedBlockingQueue`).
3. Application code calls `ConsumerImpl.receive()`, which polls the cache round-robin across all broker fetchers.
4. Application processes the message and calls `ack()` or `nack()`, which sends an ACK or NACK STOMP frame back to the broker over the same connection.

No data is written to disk by the library at any point.
