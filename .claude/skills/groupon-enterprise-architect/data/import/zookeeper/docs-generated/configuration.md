---
service: "zookeeper"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [config-files, env-vars]
---

# Configuration

## Overview

ZooKeeper is configured primarily through a `zoo.cfg` file (the main server configuration) and through environment variables sourced by `bin/zkEnv.sh` before server startup. The sample configuration template is located at `conf/zoo_sample.cfg`. Logging is controlled by `conf/logback.xml`. Optional per-environment JVM tuning can be placed in `conf/java.env` and `conf/zookeeper-env.sh`, which are sourced automatically by `bin/zkEnv.sh` if present.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `JAVA_HOME` | Path to JDK installation used to launch server and CLI | yes (if `java` not on PATH) | None | env |
| `ZK_SERVER_HEAP` | Maximum JVM heap in MB for the ZooKeeper server process | no | `1000` (1 GB) | `bin/zkEnv.sh` |
| `ZK_CLIENT_HEAP` | Maximum JVM heap in MB for the ZooKeeper CLI client | no | `256` MB | `bin/zkEnv.sh` |
| `SERVER_JVMFLAGS` | Additional JVM flags appended to the server startup command | no | None | `bin/zkEnv.sh` |
| `CLIENT_JVMFLAGS` | Additional JVM flags for the CLI client (e.g., SSL truststore config) | no | None | `bin/zkEnv.sh` |
| `ZOOCFGDIR` | Path to the directory containing `zoo.cfg` | no | `../conf` or `/etc/zookeeper` | `bin/zkEnv.sh` |
| `ZOOCFG` | Name of the ZooKeeper configuration file | no | `zoo.cfg` | `bin/zkEnv.sh` |
| `ZOO_LOG_DIR` | Directory for ZooKeeper log output | no | `../logs` | `bin/zkEnv.sh` |
| `ZOO_LOG_FILE` | Log file name | no | `zookeeper-$USER-server-$HOSTNAME.log` | `bin/zkServer.sh` |
| `ZOO_DATADIR_AUTOCREATE_DISABLE` | If set, prevents automatic creation of `dataDir` on startup | no | Unset (autocreate enabled) | `bin/zkServer.sh` |
| `JMXPORT` | Remote JMX port for management access | no | Local JMX only | `bin/zkServer.sh` |
| `JMXAUTH` | Whether to require authentication for remote JMX | no | `false` | `bin/zkServer.sh` |
| `JMXSSL` | Whether to use SSL for remote JMX | no | `false` | `bin/zkServer.sh` |
| `JMXDISABLE` | Set to `true` to disable JMX entirely | no | `false` (JMX enabled) | `bin/zkServer.sh` |
| `JMXLOCALONLY` | Restrict JMX to local connections only | no | `false` | `bin/zkServer.sh` |
| `JMXHOSTNAME` | Hostname advertised for remote JMX | no | None | `bin/zkServer.sh` |

> IMPORTANT: Never document actual secret values. Only document variable names and purposes.

## Feature Flags

> No evidence found in codebase of feature flag framework integration. ZooKeeper configuration is static, applied at startup via `zoo.cfg`.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `conf/zoo.cfg` (or `zoo_sample.cfg` as template) | Java Properties | Primary server configuration (ports, timeouts, data directories, cluster peers) |
| `conf/logback.xml` | XML | Logback logging configuration (appenders, log levels, rolling policy) |
| `conf/zookeeper-env.sh` | Bash | Optional environment variable overrides sourced before server startup |
| `conf/java.env` | Bash | Optional JVM flag overrides sourced before server startup |
| `conf/configuration.xsl` | XSLT | XSL transform for rendering configuration documentation |

### Key `zoo.cfg` Parameters

| Parameter | Purpose | Default (sample) |
|-----------|---------|-----------------|
| `tickTime` | Heartbeat interval in milliseconds | `2000` |
| `initLimit` | Max ticks for initial sync between leader and followers | `10` |
| `syncLimit` | Max ticks allowed between follower and leader for request/response | `5` |
| `dataDir` | Directory for snapshots and (optionally) transaction logs | `/tmp/zookeeper` |
| `clientPort` | TCP port for client connections | `2181` |
| `maxClientCnxns` | Max simultaneous client connections per host | `60` (commented out) |
| `autopurge.snapRetainCount` | Number of snapshots to retain during autopurge | Commented out |
| `autopurge.purgeInterval` | Hours between autopurge runs (0 = disabled) | Commented out |
| `metricsProvider.className` | Metrics provider class (Prometheus) | Commented out |
| `metricsProvider.httpHost` | Host for Prometheus metrics HTTP server | Commented out |
| `metricsProvider.httpPort` | Port for Prometheus metrics HTTP server | `7000` (commented out) |
| `metricsProvider.exportJvmInfo` | Whether to export JVM metrics via Prometheus | Commented out |

## Secrets

> No evidence found in codebase of vault, AWS Secrets Manager, or Kubernetes secrets integration. Authentication credentials for SASL/Kerberos are managed via system keytab files and JAAS configuration, which are referenced by JVM system properties passed via `SERVER_JVMFLAGS` or `CLIENT_JVMFLAGS`.

## Per-Environment Overrides

ZooKeeper environments differ primarily in three areas:

- **Cluster size**: Development typically runs a single standalone node; staging and production use a multi-server quorum ensemble (3 or 5 nodes). Ensemble members are listed via `server.N=host:peerPort:leaderPort` entries in `zoo.cfg`.
- **Data directories**: `dataDir` is set to a persistent volume path in staging and production; `/tmp/zookeeper` is only appropriate for local development.
- **JVM heap**: `ZK_SERVER_HEAP` should be increased for production workloads beyond the default 1 GB.
- **Autopurge**: `autopurge.snapRetainCount` and `autopurge.purgeInterval` should be enabled in production to prevent unbounded disk growth.
