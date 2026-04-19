---
service: "dynamic-routing"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [config-files, system-properties, jvm-properties]
---

# Configuration

## Overview

The service is configured through two primary properties files (`dynamic-routing-config.properties` and `brokerInfo.properties`), a `logback.xml` for logging, and JVM system properties passed at startup. The file paths are supplied via JVM system properties at container launch time. Environment-specific configurations (staging, production) are packaged in `src/main/conf/envs/<env>/`. There is no external config store (Consul, Vault, etc.) referenced in the codebase.

## Environment Variables / JVM System Properties

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `app.instance.key` | Instance identifier (datacenter + environment key, e.g. `local_local`) | Yes | `local_local` | JVM system property |
| `app.instance.config` | Path to configuration directory | Yes | `<basedir>/conf` | JVM system property |
| `app.instance.logs` | Path to log output directory | Yes | `<basedir>/target/log` | JVM system property |
| `application.properties.file` | Full path to `dynamic-routing-config.properties` | Yes | `<app.instance.config>/dynamic-routing-config.properties` | JVM system property |
| `logback.configurationFile` | Full path to `logback.xml` | Yes | `<app.instance.config>/logback.xml` | JVM system property |
| `jvm.process.name` | JVM process name suffix; used to compute Jolokia port (`5<pid[1:4]>`) and service ID | No | None | JVM system property |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are documented here.

## Application Configuration Properties (`dynamic-routing-config.properties`)

| Property | Purpose | Required | Default |
|----------|---------|----------|---------|
| `app.admin.username` | Admin UI username | Yes | None |
| `app.admin.password` | BCrypt-encoded admin UI password | Yes | None |
| `app.version` | Application version string surfaced in `/status` response | No | `unknown` |
| `mongodb.hosts` | Comma-separated MongoDB host(s); supports `host:port` format | Yes | `localhost` |
| `mongodb.database` | MongoDB database name | No | `dynamic-routing` |
| `mongodb.username` | MongoDB authentication username | No | (empty — unauthenticated) |
| `mongodb.password` | MongoDB authentication password | No | (empty) |
| `mongodb.authDatabase` | MongoDB authentication database; defaults to `mongodb.database` if empty | No | (empty) |

## Feature Flags

> No feature flags are configured in the codebase.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `src/main/conf/envs/production/brokerInfo.properties` | Properties | Defines production broker registry (name, host, Jolokia port) for dub1 production |
| `src/main/conf/envs/staging/brokerInfo.properties` | Properties | Defines staging broker registry (port-broker, travel-broker, master-broker, snc1-broker) |
| `src/main/conf/envs/production/logback.xml` | XML | Production logging configuration (Steno encoder) |
| `src/main/conf/envs/staging/logback.xml` | XML | Staging logging configuration |
| `conf/dynamic-routing-conf.properties` (runtime) | Properties | Admin credentials and MongoDB connection (created at deploy time, not committed) |
| `conf/brokerInfo.properties` (runtime) | Properties | Broker registry for the deployed instance (created at deploy time) |

### brokerInfo.properties Format

Each line defines one broker:
```
<broker_id> = <Display Name>,<host>,<jolokia-port>[,<clientType: jms|mbus>]
```

Example entries from `src/main/conf/envs/production/brokerInfo.properties`:
```properties
port-broker=Dublin PortBroker,10.12.237.204,11201
travel-broker=Dublin TravelBroker,10.12.237.204,11209
master-broker=Dublin MasterBroker,10.12.252.57,11200
```

`clientType` defaults to `mbus`; use `jms` for Artemis JMS acceptor or HornetQ JNDI connections.

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `app.admin.password` | BCrypt-encoded admin UI password | Properties file (deployed by Ansible) |
| `mongodb.password` | MongoDB authentication password | Properties file (deployed by Ansible) |
| `lupBesAccessToken` / `hkgBesAccessToken` | Backend service API keys for entity enrichment | Properties file / Spring XML wiring |

> Secret values are NEVER documented. Only names and rotation policies are listed here.

## Per-Environment Overrides

- **Production (dub1)**: `brokerInfo.properties` contains Dublin production broker IPs and ports (port-broker on `10.12.237.204:11201`, travel-broker on `10.12.237.204:11209`, master-broker on `10.12.252.57:11200`)
- **Staging (snc1)**: `brokerInfo.properties` contains staging broker IPs including snc1-broker on `10.23.64.52:11210`
- **Deployed environments** (from `.service.yml`): snc1 production (`http://mbus-camel1.snc1`), snc1 staging (`http://mbus-camel1-staging.snc1`), snc1 EMEA staging (`http://mbus-camel1-emea-staging.snc1`), snc1 UAT (`http://mbus-camel1-uat.snc1`), dub1 production (`http://mbus-camel1.dub1`)
- **Local development**: Uses `conf/` directory in project root with locally defined broker and application properties; started with `mvn jetty:run`
