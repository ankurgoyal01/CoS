---
service: "replay-tool"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: [mbus]
---

# Events

## Overview

The MBus Replay Tool does not subscribe to or consume async events from the Message Bus. Its interaction with MBus is strictly as a producer: it publishes replayed messages on demand, when an administrator triggers execution of a loaded replay batch. Messages are published to MBus broker targets via STOMP using the `mbus-client` Producer API. The tool reads source messages from Boson log files over SSH rather than from a live bus subscription.

## Published Events

The tool re-publishes existing MBus messages to operator-specified destinations. These are not new event types — they are replayed versions of intercepted messages loaded from Boson logs.

| Topic / Queue | Event Type | Trigger | Key Payload Fields |
|---------------|-----------|---------|-------------------|
| Operator-specified MBus queue or topic (e.g., `jms.queue.*`, `jms.topic.*`) | Replayed message (original payload type preserved) | Administrator triggers `POST /replay/request/{uuid}/execute` | Original message headers, original payload (JSON string or STRING type), `replayed: true`, `replayRequestUuid`, `bosonRequestUuid` |

### Replayed Message Detail

- **Topic**: Operator-specified at request time via `targetDestination` field — any valid MBus queue (`jms.queue.*`) or topic (`jms.topic.*`)
- **Trigger**: Administrator calls `POST /replay/request/{uuid}/execute` after a load operation has completed
- **Payload**: Original message payload preserved as-is from Boson log entry; only messages of type `JSON` or `STRING` are supported. Binary or other payload types are skipped (added to `notSentMessages`)
- **Additional STOMP headers injected**:
  - `replayed: true`
  - `replayRequestUuid: <uuid>` — identifies the replay batch
  - `bosonRequestUuid: <uuid>` — identifies the Boson load sub-request
- **Consumers**: Whichever services normally consume the target MBus destination
- **Guarantees**: At-most-once — no retry on `SendFailedException` or `TooManyConnectionRetryAttemptsException`; failed messages are tracked in `notSentMessages` list but not retried

## Consumed Events

> Not applicable. This service does not subscribe to or consume events from any message bus topic or queue.

## Dead Letter Queues

> Not applicable. The replay tool does not configure or use dead letter queues. Failed message sends are recorded in the `ReplayExecutionResult.sendFailed` list and reflected in the execution status response.
