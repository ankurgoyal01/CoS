---
service: "kafka"
title: API Surface
generated: "2026-03-02T00:00:00Z"
type: api-surface
protocols: [kafka-wire-protocol, rest]
auth_mechanisms: [ssl-mutual-tls, sasl]
---

# API Surface

## Overview

Apache Kafka exposes two distinct API surfaces. The primary interface is the **Kafka Wire Protocol** — a binary, length-delimited TCP protocol used by all producers, consumers, and admin clients. The secondary interface is a **REST API** served via Jetty/Jersey and used for broker admin operations, metrics retrieval, and Trogdor test coordination. Consumers and producers interact exclusively through the Wire Protocol using official Kafka client libraries.

## Endpoints

### Kafka Wire Protocol (Binary TCP — default port 9092)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| Produce API (v0–v11) | `Produce` request key `0` | Append records to a topic-partition | SASL / mTLS |
| Fetch API (v0–v17) | `Fetch` request key `1` | Retrieve records from a topic-partition at a given offset | SASL / mTLS |
| ListOffsets API | `ListOffsets` request key `2` | Query earliest, latest, or timestamp-based offsets | SASL / mTLS |
| Metadata API | `Metadata` request key `3` | Fetch cluster metadata and partition leadership | SASL / mTLS |
| OffsetCommit API | `OffsetCommit` request key `8` | Commit consumer group offsets | SASL / mTLS |
| OffsetFetch API | `OffsetFetch` request key `9` | Fetch committed consumer group offsets | SASL / mTLS |
| FindCoordinator API | `FindCoordinator` request key `10` | Locate the group or transaction coordinator broker | SASL / mTLS |
| JoinGroup / SyncGroup | `JoinGroup` key `11`, `SyncGroup` key `14` | Consumer group rebalancing protocol | SASL / mTLS |
| Heartbeat API | `Heartbeat` request key `12` | Keep consumer group session alive | SASL / mTLS |
| CreateTopics API | `CreateTopics` request key `19` | Administratively create new topics | SASL / mTLS |
| DeleteTopics API | `DeleteTopics` request key `20` | Administratively delete topics | SASL / mTLS |
| DescribeConfigs API | `DescribeConfigs` request key `32` | Retrieve broker or topic configuration | SASL / mTLS |
| AlterConfigs API | `AlterConfigs` request key `33` | Update broker or topic configuration dynamically | SASL / mTLS |

### Broker REST API (Jetty/Jersey — admin/metrics)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/metrics` | Expose broker JMX metrics over HTTP | None (internal) |

### Trogdor Coordinator REST API (Jetty/Jersey — default port 8765)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/coordinator/task` | Submit a new workload or fault-injection task | None (internal) |
| GET | `/coordinator/task/{id}` | Retrieve task status by ID | None (internal) |
| DELETE | `/coordinator/task/{id}` | Cancel a running task | None (internal) |
| GET | `/coordinator/tasks` | List all active and completed tasks | None (internal) |

### Trogdor Agent REST API (Jetty/Jersey — default port 8888)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/agent/task` | Receive and start a task from the coordinator | None (internal) |
| GET | `/agent/task/{id}` | Report task execution status to coordinator | None (internal) |

## Request/Response Patterns

### Common headers

The Kafka Wire Protocol does not use HTTP headers. Each request frame includes:
- `api_key` (int16) — identifies the request type
- `api_version` (int16) — negotiated protocol version
- `correlation_id` (int32) — used to match responses to requests
- `client_id` (nullable string) — identifies the calling client

### Error format

The Kafka Wire Protocol returns a numeric error code within the response envelope for each request. Error code `0` indicates success. Non-zero codes map to named `Errors` enum values (e.g., `LEADER_NOT_AVAILABLE`, `NOT_ENOUGH_REPLICAS`, `OFFSET_OUT_OF_RANGE`).

### Pagination

Fetch requests use offset-based pagination: clients supply a `fetch_offset` per partition and receive up to `max_bytes` of records starting from that offset.

## Rate Limits

> No rate limiting configured at the protocol level. Throughput is governed by broker-level quota settings (`producer_byte_rate`, `consumer_byte_rate`, `request_percentage`) configured per client ID or user principal.

## Versioning

The Kafka Wire Protocol uses per-API versioning. Each request carries an `api_version` field; brokers advertise supported version ranges via the `ApiVersions` API (key `18`). Clients negotiate the highest mutually supported version. REST endpoints have no explicit versioning.

## OpenAPI / Schema References

> No OpenAPI spec is generated for the REST endpoints. Kafka Wire Protocol request/response schemas are defined in the Kafka source under `clients/src/main/resources/common/message/` as JSON message definitions compiled to Java classes via the Kafka message generator.
