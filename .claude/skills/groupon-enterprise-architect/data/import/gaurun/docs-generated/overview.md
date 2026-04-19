---
service: "gaurun"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Mobile Push Notifications"
platform: "Continuum"
team: "MTA"
status: active
tech_stack:
  language: "Go"
  language_version: "1.23"
  framework: "net/http"
  framework_version: "stdlib"
  runtime: "Go runtime"
  runtime_version: "1.23"
  build_tool: "Make"
  package_manager: "Go modules"
---

# Gaurun Overview

## Purpose

Gaurun is Groupon's general-purpose push notification proxy server written in Go. It accepts inbound HTTP push requests from internal services, buffers them through Kafka-backed queues, and asynchronously dispatches notifications to Apple APNs (via HTTP/2) and Google FCM. It is designed for high-throughput bulk sending — handling millions of pushes — and supports crash-recovery replay from access logs.

## Scope

### In scope

- Accepting and validating inbound push notification requests via HTTP
- Routing notifications by platform (iOS, Android, Merchant) and named context (e.g., `iphone-consumer`, `android-fcm-consumer`)
- Buffering notifications through in-memory and Kafka-backed queues
- Dispatching to Apple APNs using certificate-based or token-based (JWT) provider connections
- Dispatching to Google FCM using API key or service-account credentials
- Retry logic for transient failures via the `mta.gaurun.retry` Kafka topic
- Emitting delivery metrics (success, failure, queue depth) to InfluxDB/Telegraf
- Shipping send logs to Kafka via a Logstash sidecar for downstream analytics
- Dry-run mode to simulate pushes without actual delivery
- Runtime configuration of pusher concurrency via `PUT /config/pushers`

### Out of scope

- Managing device token registration or user-to-token mapping
- Campaign scheduling or audience segmentation (handled by upstream notification producers)
- Generating notification content or personalization
- Storing notification history or delivery receipts in a database

## Domain Context

- **Business domain**: Mobile Push Notifications — the MTA (Mobile/Transactional/Alerting) domain
- **Platform**: Continuum
- **Upstream consumers**: Internal notification producer services that POST to Gaurun's HTTP endpoints (referenced as `notificationProducerService_4b2a5c` in the architecture model)
- **Downstream dependencies**: Apple APNs (`appleApns_7f1d6a`), Google FCM (`googleFcm_9c4e1b`), Kafka cluster (`kafkaCluster_2f6b9d`), Telegraf/InfluxDB (`telegrafInfluxdb_3a8c2e`)

## Stakeholders

| Role | Description |
|------|-------------|
| MTA Team | Service owners; responsible for operation and development |
| Mobile App Teams | Consumers of push notification delivery capability |
| Data/Analytics | Consumers of send logs shipped via Logstash to Kafka |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Go | 1.23 | `go.mod` |
| Toolchain | Go | 1.24 (toolchain directive) | `go.mod` |
| Framework | net/http (stdlib) | — | `gaurun/server.go` |
| Runtime container | Alpine Linux | 3.20 (builder), latest (runtime) | `Dockerfile` |
| Build tool | Make | — | `Makefile` |
| Package manager | Go modules | — | `go.mod` |
| Config format | TOML | — | `conf/gaurun.toml`, `CONFIGURATION.md` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `github.com/confluentinc/confluent-kafka-go/v2` | v2.5.3 | message-client | Kafka producer and consumer for notification queuing and retry |
| `github.com/influxdata/influxdb1-client` | v0.0.0-20220302092344 | metrics | Writes push delivery metrics to Telegraf/InfluxDB |
| `go.uber.org/zap` | v1.21.0 | logging | Structured access, error, and accept logging |
| `github.com/pelletier/go-toml` | v1.9.5 | serialization | Parses TOML configuration file with env-var substitution |
| `github.com/golang-jwt/jwt/v4` | v4.5.0 | auth | JWT generation for APNs token-based provider auth |
| `google.golang.org/api` | v0.169.0 | message-client | Google FCM HTTP client via googleapis |
| `github.com/a-h/templ` | v0.3.857 | ui-framework | Optional frontend payload upload form |
| `github.com/fukata/golang-stats-api-handler` | v1.0.0 | metrics | Go runtime stats endpoint (`/stat/go`) |
| `github.com/lestrrat-go/server-starter` | v0.0.0-20210101230921 | http-framework | Graceful listener management (go-server-starter integration) |
| `golang.org/x/sync` | v0.12.0 | scheduling | Semaphore-based concurrency control for push workers |
| `gopkg.in/natefinch/lumberjack.v2` | v2.2.1 | logging | Rolling log file management for send/failed log shipping |
| `github.com/client9/reopen` | v1.0.0 | logging | Log file reopening on SIGHUP signal |
| `github.com/stretchr/testify` | v1.9.0 | testing | Unit test assertions |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See `go.mod` for a full list.
