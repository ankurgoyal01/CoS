---
service: "gaurun"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 4
internal_count: 1
---

# Integrations

## Overview

Gaurun depends on four external systems (Apple APNs, Google FCM, Kafka, Telegraf/InfluxDB) and one internal Logstash sidecar for log shipping. All external push-delivery integrations are outbound-only; Gaurun does not receive callbacks from APNs or FCM. Kafka is both read and written. The single internal integration is the Logstash sidecar container in the same Pod.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Apple APNs | HTTP/2 | Deliver iOS push notifications | yes | `appleApns_7f1d6a` |
| Google FCM | HTTP | Deliver Android push notifications | yes | `googleFcm_9c4e1b` |
| Kafka cluster | Kafka (SSL/TLS) | Notification queuing, retry topic, log shipping | yes | `kafkaCluster_2f6b9d` |
| Telegraf/InfluxDB | InfluxDB line protocol (UDP/HTTP) | Delivery metrics reporting | no | `telegrafInfluxdb_3a8c2e` |

### Apple APNs Detail

- **Protocol**: HTTP/2 (APNs provider API)
- **Base URL / SDK**: `api.push.apple.com` (production), `api.sandbox.push.apple.com` (sandbox). Implemented via `buford/push` (embedded fork) and `buford/token` for JWT.
- **Auth**: Certificate-based (PEM cert + key from `conf/grpn-ios-cert/` and `conf/ls-ios-cert/`) or token-based (`.p8` auth key with `token_auth_key_id` and `token_auth_team_id`). Configured per iOS context in `[ios-context.*]` TOML sections.
- **Purpose**: Send push notifications to Groupon iOS app (`com.groupon.grouponapp`), LivingSocial iOS app (`com.livingsocial.deals`), and catfood/dogfood builds.
- **Failure mode**: On APNs error (`IdleTimeout`, `Shutdown`, `InternalServerError`, `ServiceUnavailable`), the push worker retries up to `ios.retry_max` times (default 5). If still failing, the notification is published to `mta.gaurun.retry`.
- **Circuit breaker**: No circuit breaker configured. Retry logic is linear with count cap.

### Google FCM Detail

- **Protocol**: HTTP (Firebase Cloud Messaging v1 API via `google.golang.org/api`)
- **Base URL / SDK**: `google.golang.org/api` v0.169.0 — uses `GoogleApi` service account or legacy `apikey` depending on context. Multiple Android contexts: `android-fcm-consumer`, `android-consumer`, `android-merchant`.
- **Auth**: Legacy API key (`android.apikey`) for standard contexts; service account (`android-context.*.service_account`) for newer contexts. Configured per Android context in `[android-context.*]` TOML sections.
- **Purpose**: Send push notifications to Groupon Android consumer app, LivingSocial app, and Merchant app.
- **Failure mode**: On FCM error (`Unavailable`, `InternalServerError`, timeout), the push worker retries up to `android.retry_max` times (default 5). If still failing, the notification is published to `mta.gaurun.retry`.
- **Circuit breaker**: No circuit breaker configured.

### Kafka Cluster Detail

- **Protocol**: Kafka over SSL/TLS (`security.protocol=ssl`)
- **Base URL / SDK**: `confluent-kafka-go/v2` v2.5.3. Broker addresses configured via `kafka.read_host` (consumers) and `kafka.write_host` (producers) in TOML. Logstash connects to `kafka-grpn-kafka-bootstrap.kafka-production.svc.cluster.local:9093` (production GCP/AWS) and `kafka-grpn-kafka-bootstrap.kafka-staging.svc.cluster.local:9093` (staging).
- **Auth**: Mutual TLS — `kafka.ca_cert_path`, `kafka.tls_cert_path`, `kafka.tls_key_path`. SSL certificate verification disabled (`enable.ssl.certificate.verification=false`).
- **Purpose**: Three topics — `android_gaurun_pn` and `ios_gaurun_pn` for notification queuing, `mta.gaurun.retry` for failed notification retry.
- **Failure mode**: On Kafka local queue full, producer flushes with a 30-second timeout before retrying. If the Kafka cluster is unavailable, notifications buffer in in-memory channels (capacity 100,000 per platform) until backpressure causes `429 Too Many Requests` responses.
- **Circuit breaker**: No circuit breaker configured.

### Telegraf/InfluxDB Detail

- **Protocol**: InfluxDB line protocol (HTTP write to local Telegraf agent)
- **Base URL / SDK**: `influxdata/influxdb1-client` — writes to database `telegraf`, retention policy `default`.
- **Auth**: None documented (local Telegraf agent assumed).
- **Purpose**: Emit push delivery metrics: `gaurun.requests` (with `valid` and `platform` tags), `gaurun.succeeded.push` (with `deviceType` tag), `gaurun.failed.push` (with `deviceType` tag), `gaurun.queue.size` (with `queue_name` tag), `gaurun.retry.attempt`, `gaurun.retry.exhausted`.
- **Failure mode**: Metric write failures are logged as errors but do not affect notification delivery. Non-critical dependency.
- **Circuit breaker**: No circuit breaker. `clientLock` mutex serialises writes.

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Logstash sidecar | File (shared volume) | Tails send/failed log files and ships to Kafka cluster | `gaurunAccessLogger` (via mounted volume) |

## Consumed By

> Upstream consumers are tracked in the central architecture model. The DSL stub `notificationProducerService_4b2a5c` represents the internal notification producer service(s) that POST to Gaurun's HTTP endpoints. Specific caller identities are not discoverable from this repository.

## Dependency Health

- **APNs**: Keep-alive connections maintained per context (`ios.keepalive_conns`, default CPU count; `ios.keepalive_timeout`, default 30 seconds). Push timeout is 15 seconds (`ios.timeout`).
- **FCM**: Keep-alive connections maintained (`android.keepalive_conns`, `android.keepalive_timeout`). Push timeout is 15 seconds (`android.timeout`).
- **Kafka**: Consumer heartbeat interval is 100 ms. No explicit health check endpoint for Kafka connectivity.
- **InfluxDB/Telegraf**: No health check. Write errors are logged and ignored.
- **Healthcheck endpoint**: `GET /grpn/healthcheck` returns `200 ok` — used by Kubernetes readiness/liveness probes.
