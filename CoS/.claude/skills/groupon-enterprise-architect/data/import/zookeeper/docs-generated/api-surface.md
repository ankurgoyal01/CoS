---
service: "zookeeper"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [zookeeper-client-protocol, tcp, http-admin]
auth_mechanisms: [sasl, kerberos, digest-md5, tls]
---

# API Surface

## Overview

ZooKeeper exposes two primary interfaces: the ZooKeeper binary client protocol over TCP/2181, and an administrative HTTP endpoint for diagnostics and runtime control. The binary client protocol is the primary interface consumed by all Continuum microservices using ZooKeeper for coordination. The admin endpoint is used by operators and monitoring systems. An optional contrib REST gateway (`zookeeperRestGateway`) wraps the binary protocol over HTTP for convenience clients.

## Endpoints

### Client Protocol (TCP/2181)

ZooKeeper uses a custom binary protocol over TCP. The following operations are supported by the `requestProcessorPipeline`:

| Operation | Direction | Purpose | Auth |
|-----------|-----------|---------|------|
| `create` | Client to Server | Creates a new znode at a specified path | Session |
| `delete` | Client to Server | Deletes a znode at a specified path | Session |
| `exists` | Client to Server | Checks existence of a znode and optionally sets a watch | Session |
| `getData` | Client to Server | Retrieves data stored in a znode | Session |
| `setData` | Client to Server | Writes data to an existing znode | Session |
| `getChildren` | Client to Server | Lists child znodes under a path | Session |
| `getACL` / `setACL` | Client to Server | Reads or writes access control lists on a znode | Session |
| `sync` | Client to Server | Forces the server to sync to latest state before responding | Session |
| `multi` | Client to Server | Executes a batch of operations atomically | Session |

### Admin Command Endpoint (HTTP)

The `adminCommandEndpoint` component exposes an HTTP interface (Jetty-backed) for operational diagnostics. Default port is not configured in `zoo_sample.cfg`; enabled separately.

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/commands` | Lists all available admin commands | None (local) |
| `GET` | `/commands/stat` | Returns server statistics (connections, latency) | None (local) |
| `GET` | `/commands/mntr` | Returns monitoring metrics in key=value format | None (local) |
| `GET` | `/commands/ruok` | Health check: returns `imok` if server is running | None (local) |
| `GET` | `/commands/conf` | Returns current server configuration | None (local) |
| `GET` | `/commands/envi` | Returns server environment (JVM, OS info) | None (local) |
| `GET` | `/commands/dump` | Returns outstanding sessions and ephemeral nodes | None (local) |
| `GET` | `/commands/isro` | Checks if server is in read-only mode | None (local) |

### Four-Letter Word Commands (TCP/2181 or dedicated port)

Legacy diagnostic interface used by `zkServer.sh status` and monitoring systems via `FourLetterWordMain`:

| Command | Purpose |
|---------|---------|
| `ruok` | Health ping — responds `imok` |
| `srvr` | Full server status including mode (leader/follower/observer) |
| `stat` | Connection statistics |
| `mntr` | Monitoring metrics |
| `dump` | Session and ephemeral node dump |
| `conf` | Server configuration dump |

### REST Gateway (contrib — `zookeeperRestGateway`)

> No rate limits or versioning evidence found in codebase. The REST gateway translates standard HTTP operations to ZooKeeper client protocol requests against `zookeeperServer` on TCP/2181.

## Request/Response Patterns

### Common headers

> Not applicable — the ZooKeeper binary client protocol does not use HTTP headers. Admin endpoint responses are plain-text or JSON depending on command.

### Error format

The binary protocol returns error codes as part of the ZooKeeper response envelope. Common error codes include:

- `ZNODEEXISTS` — node already exists on create
- `ZNONODE` — node not found on read/delete
- `ZBADVERSION` — optimistic concurrency check failed on setData
- `ZSESSIONEXPIRED` — client session timed out
- `ZCONNECTIONLOSS` — connection to server lost

### Pagination

> Not applicable — ZooKeeper does not paginate responses. `getChildren` returns all child nodes in a single response.

## Rate Limits

| Tier | Limit | Window |
|------|-------|--------|
| Default | 60 connections per host | Configurable via `maxClientCnxns` in `zoo.cfg` |

> `maxClientCnxns` defaults to 60 connections per client IP. Set to 0 to disable. Configured in `conf/zoo_sample.cfg`.

## Versioning

ZooKeeper does not use API versioning in the traditional sense. Protocol compatibility is maintained across patch versions. The version in use is `3.10.0-SNAPSHOT` as defined in `pom.xml`. Clients negotiate protocol version during session establishment.

## OpenAPI / Schema References

> No evidence found in codebase. The ZooKeeper binary protocol is defined by the Jute serialization format in the `zookeeper-jute` module. No OpenAPI or protobuf schema files are present in the repository.
