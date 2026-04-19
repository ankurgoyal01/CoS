---
service: "push-infrastructure"
title: Configuration
generated: "2026-03-02T00:00:00Z"
type: configuration
config_sources: [config-files, env-vars]
---

# Configuration

## Overview

Push Infrastructure is a Play Framework 2.2.1 / SBT application. Configuration is managed through Play's standard `application.conf` (HOCON format) with environment-specific overrides. Connection parameters for all external dependencies (Kafka, Redis, PostgreSQL/MySQL, RabbitMQ, SMTP, FCM, APNs, HDFS, InfluxDB) are supplied via config files and/or environment variables at deployment time. Credentials and secrets are externalized and must never be committed to source.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `KAFKA_BOOTSTRAP_SERVERS` | Kafka broker addresses for consumer connections | yes | none | env |
| `KAFKA_GROUP_ID` | Consumer group identifier for Kafka topic subscriptions | yes | none | env |
| `REDIS_HOST` | Redis cluster hostname or sentinel address | yes | none | env |
| `REDIS_PORT` | Redis cluster port | yes | 6379 | env |
| `REDIS_PASSWORD` | Redis authentication password | yes | none | env / vault |
| `DB_URL` | JDBC connection URL for PostgreSQL/MySQL transactional database | yes | none | env |
| `DB_USER` | Database username | yes | none | env |
| `DB_PASSWORD` | Database password | yes | none | env / vault |
| `RABBITMQ_HOST` | RabbitMQ broker hostname | yes | none | env |
| `RABBITMQ_PORT` | RabbitMQ broker port | yes | 5672 | env |
| `RABBITMQ_USER` | RabbitMQ username | yes | none | env |
| `RABBITMQ_PASSWORD` | RabbitMQ password | yes | none | env / vault |
| `SMTP_HOST` | SMTP relay hostname | yes | none | env |
| `SMTP_PORT` | SMTP relay port | yes | 25 | env |
| `SMTP_USER` | SMTP AUTH username | no | none | env |
| `SMTP_PASSWORD` | SMTP AUTH password | no | none | env / vault |
| `FCM_SERVER_KEY` | Firebase Cloud Messaging server key | yes | none | env / vault |
| `APNS_CERT_PATH` | Path to APNs certificate file | yes | none | env |
| `APNS_CERT_PASSWORD` | APNs certificate passphrase | yes | none | env / vault |
| `SMS_GATEWAY_URL` | SMS gateway API base URL | yes | none | env |
| `SMS_GATEWAY_API_KEY` | SMS gateway API key | yes | none | env / vault |
| `HDFS_NAMENODE_HOST` | HDFS namenode address for log archival | no | none | env |
| `INFLUXDB_URL` | InfluxDB endpoint for metrics writes | no | none | env |
| `INFLUXDB_DB` | InfluxDB database name | no | none | env |
| `MBUS_BROKER_URL` | MBus broker connection URL | yes | none | env |
| `APP_SECRET` | Play Framework application secret (HMAC key) | yes | none | env / vault |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are listed above.

## Feature Flags

> No feature flag system (LaunchDarkly, Unleash, config-based flags) was identified in the inventory. Feature behavior is controlled via `application.conf` values.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `conf/application.conf` | HOCON | Main Play Framework config — database, Redis, Kafka, RabbitMQ, SMTP, scheduling, metrics |
| `conf/routes` | Play routes DSL | HTTP route definitions mapping paths to controllers |
| `conf/logback.xml` | XML | Logging configuration (log levels, appenders) |
| `project/build.properties` | properties | SBT version pin (`sbt.version=0.13.18`) |
| `build.sbt` | SBT DSL | Project definition, dependency declarations, compile settings |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `REDIS_PASSWORD` | Redis cluster authentication | env / vault |
| `DB_PASSWORD` | Transactional database password | env / vault |
| `RABBITMQ_PASSWORD` | RabbitMQ broker password | env / vault |
| `SMTP_PASSWORD` | SMTP relay authentication | env / vault |
| `FCM_SERVER_KEY` | Firebase Cloud Messaging delivery key | env / vault |
| `APNS_CERT_PASSWORD` | APNs certificate passphrase | env / vault |
| `SMS_GATEWAY_API_KEY` | SMS gateway authentication | env / vault |
| `APP_SECRET` | Play Framework HMAC application secret | env / vault |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

Play Framework supports environment-specific config layering via `conf/application.conf` include directives and system property overrides (`-Dkey=value` JVM flags at startup). Typical pattern:

- **Development**: Local config with mock/stub broker addresses; reduced Kafka topic subscriptions; debug-level logging
- **Staging**: Staging-tier broker addresses; full Kafka topic subscriptions; delivery channels may target sandbox endpoints (FCM sandbox, SMTP catch-all)
- **Production**: Production broker addresses; all seven Kafka topics active; live SMTP/FCM/APNs/SMS delivery; InfluxDB metrics active; HDFS archival active
