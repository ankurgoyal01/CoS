---
service: "push-client-proxy"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars, config-files, spring-profiles]
---

# Configuration

## Overview

push-client-proxy is configured through Spring Boot property files selected by the `SPRING_PROFILES_ACTIVE` environment variable. A `CONFIG_FILE` environment variable points to an environment-specific YAML file mounted from Kubernetes secrets/config. Kafka, Redis, SMTP, database, and metrics settings are all externalized. Kafka is conditionally enabled via `spring.kafka.enabled=true`.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `SPRING_PROFILES_ACTIVE` | Selects active Spring profile (e.g., `production-us-central1`, `staging-us-central1`) | yes | `local` | env (Kubernetes) |
| `CONFIG_FILE` | Path to mounted environment-specific YAML config file | yes (production/staging) | — | env (Kubernetes) |
| `MALLOC_ARENA_MAX` | Limits glibc memory arenas to prevent virtual memory explosion | no | `4` | Kubernetes common.yml |

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| `spring.kafka.enabled` | Enables all Kafka consumers and producers; when false the service runs as HTTP-only | `false` | global |
| `email.injector.injector.noopSendLogging.enable` | Enables no-op logging mode for SMTP sends (testing/debug) | `false` | global |
| `metrics.enabled` | Enables or disables InfluxDB metrics flushing | `true` | global |

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `src/main/resources/application.properties` | properties | Base Spring Boot configuration (not present in repo root; loaded from classpath) |
| `.meta/deployment/cloud/components/app/common.yml` | YAML | Common Kubernetes deployment config (replicas, ports, resources, log config) |
| `.meta/deployment/cloud/components/app/production-us-central1.yml` | YAML | Production US Central1 overrides (min 50 / max 100 replicas, CPU 6000m–12000m, memory 5–10 GB) |
| `.meta/deployment/cloud/components/app/production-europe-west1.yml` | YAML | Production EU West1 GCP overrides |
| `.meta/deployment/cloud/components/app/production-eu-west-1.yml` | YAML | Production EU West1 AWS overrides |
| `.meta/deployment/cloud/components/app/staging-us-central1.yml` | YAML | Staging US Central1 overrides (min 1 / max 2 replicas, memory 2–4 GB) |
| `.meta/deployment/cloud/components/app/staging-europe-west1.yml` | YAML | Staging EU West1 overrides |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| Kafka SSL keystore | Client certificate for Kafka TLS authentication (`/var/groupon/kafka.client.keystore.jks`) | Kubernetes secret (mounted volume `client-certs`) |
| Kafka SSL truststore | CA trust for Kafka cluster (`/var/groupon/kafka-cacerts`) | Kubernetes secret (mounted volume `client-certs`) |
| Redis credentials | Host and port for Redis clusters; no password observed in cluster mode | Kubernetes / config file |
| SMTP credentials | Email injector session credentials (configured via `EmailConfiguration`) | Kubernetes / config file |
| InfluxDB credentials | `metrics.username` / `metrics.password` for InfluxDB write access | Kubernetes / config file |
| PostgreSQL credentials | JPA datasource username/password for main and exclusions DBs | Kubernetes / config file |
| MySQL credentials | JPA datasource username/password for users lookup DB | Kubernetes / config file |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

| Setting | Development | Staging | Production |
|---------|-------------|---------|------------|
| Kafka concurrency | 1 consumer | 3 consumers | 5–15 consumers |
| Min replicas | 1 | 1 | 50 |
| Max replicas | 2 | 2 | 100 |
| Memory request/limit | — | 2 Gi / 4 Gi | 5 Gi / 10 Gi |
| CPU request/limit | — | (default) | 6000m / 12000m |
| Log level | DEBUG | INFO | WARN |
| Kafka bootstrap | `localhost:9092` | `staging-kafka:9092` | `kafka-grpn-kafka-bootstrap.kafka-production.svc.cluster.local:9093` (SSL) |
| Redis host | `localhost` | staging Redis | `mta-client-proxy--redis.prod.prod.eu-west-1.aws.groupondev.com` |
| JVM heap | `-Xms512m -Xmx2g` | `-Xms512m -Xmx2g` | `-Xms512m -Xmx2g` (Dockerfile default; pod limits govern actual max) |

### Key Kafka Consumer Properties (defaults)

| Property | Default |
|----------|---------|
| `spring.kafka.consumer.group-id` | `push-client-proxy-group` |
| `spring.kafka.consumer.max-poll-records` | `1` |
| `spring.kafka.listener.concurrency` | `15` |
| `spring.kafka.consumer.session-timeout-ms` | `30000` |
| `spring.kafka.consumer.heartbeat-interval-ms` | `10000` |
| `spring.kafka.consumer.max-poll-interval-ms` | `300000` |
| `spring.kafka.consumer.isolation-level` | `read_committed` |
| `spring.kafka.listener.poll-timeout` | `10000` |
| `spring.kafka.listener.idle-between-polls` | `1000` |

### SMTP Injector Properties

| Property | Purpose |
|----------|---------|
| `email.injector.injector.type` | Injector type selector |
| `email.injector.injector.defaultHostname` | SMTP relay hostname |
| `email.injector.injector.defaultPort` | SMTP port |
| `email.injector.injector.smtpPoolEnabled` | Enable/disable SMTP connection pool |
| `email.injector.injector.retriesOnConnectErrors` | Retry count on SMTP connect failure |
| `email.injector.injector.millisecondDelayBetweenConnectionRetries` | Delay between SMTP connect retries |
| `email.injector.injector.numThreads` | SMTP thread pool size |
| `email.injector.injector.whiteListedAddresses` | Addresses always permitted to receive email |
