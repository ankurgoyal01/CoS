---
service: "zookeeper"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 0
internal_count: 4
---

# Integrations

## Overview

ZooKeeper has no external third-party service dependencies. As a foundational infrastructure service, it is consumed by other Continuum Platform components rather than consuming them. Four internal containers interact with `zookeeperServer`: the CLI, the Prometheus metrics provider, the REST gateway, and the Loggraph analysis tool. All interactions target `zookeeperServer` over TCP/2181 or via direct filesystem access.

## External Dependencies

> No evidence found in codebase. ZooKeeper has no external service dependencies. It depends only on the JVM, filesystem, and network stack.

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| `zookeeperCli` | TCP/2181 (ZooKeeper client protocol) | Operator and developer access for reading/writing znodes interactively | `zookeeperCli` |
| `zookeeperPrometheusMetrics` | HTTP scrape | Exports ZooKeeper runtime metrics to Prometheus | `zookeeperPrometheusMetrics` |
| `zookeeperRestGateway` | TCP/2181 (via ZooKeeper client protocol) | Translates HTTP REST operations into ZooKeeper client protocol requests | `zookeeperRestGateway` |
| `zookeeperLoggraph` | Filesystem / TCP | Reads transaction logs from `dataDir` for visualization and analysis | `zookeeperLoggraph` |
| `zooInspectorApp` | TCP/2181 (ZooKeeper client protocol) | Desktop GUI for browsing znode trees and metadata | `zooInspectorApp` |

### `zookeeperCli` Detail

- **Protocol**: ZooKeeper binary client protocol over TCP/2181
- **Auth**: SASL/Kerberos or digest-MD5 (inherits server auth configuration)
- **Purpose**: Interactive command-line access to create, read, update, and delete znodes; operator troubleshooting and ad-hoc configuration
- **Failure mode**: CLI sessions time out on disconnect; no impact to server

### `zookeeperPrometheusMetrics` Detail

- **Protocol**: HTTP scrape (Prometheus pull model)
- **Base URL**: Configurable via `metricsProvider.httpHost` and `metricsProvider.httpPort` (default 7000) in `zoo.cfg`
- **Auth**: None configured by default
- **Purpose**: Exports server-side metrics (request latency, outstanding requests, connection counts, watch counts) to Prometheus
- **Failure mode**: Metrics unavailable; server continues to operate

### `zookeeperRestGateway` Detail

- **Protocol**: HTTP to `zookeeperServer` via ZooKeeper client API
- **Purpose**: Enables HTTP clients to perform ZooKeeper operations without embedding the Java client library
- **Failure mode**: REST gateway unavailable; direct TCP clients unaffected

### `zookeeperLoggraph` Detail

- **Protocol**: Filesystem read of transaction log files; optionally TCP connection for live data
- **Purpose**: Visualizes transaction history for debugging and audit
- **Failure mode**: Analysis tool unavailable; server unaffected

## Consumed By

> Upstream consumers are tracked in the central architecture model. Any Continuum service that embeds the ZooKeeper client library and connects to TCP/2181 is a consumer. Known integration pattern: services use ephemeral znodes for leader election and persistent znodes for shared configuration.

## Dependency Health

ZooKeeper itself is a foundational dependency with no upstream service dependencies to health-check. Quorum health is verified via the `srvr` four-letter word command and the `ruok` health ping. The `zookeeperPrometheusMetrics` container exposes ensemble health metrics for alerting. No circuit breakers are needed at the ZooKeeper layer.
