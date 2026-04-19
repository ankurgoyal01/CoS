---
service: "selfsetup-hbw"
title: Integrations
generated: "2026-03-02T00:00:00Z"
type: integrations
external_count: 4
internal_count: 1
---

# Integrations

## Overview

selfsetup-hbw has four external dependencies and one internal data store. All integrations are synchronous. Salesforce is both a data source and a configuration sink. The BookingTool API is the live booking engine that receives the merchant's finalised schedule and capacity settings. Metrics and logs flow to Telegraf and a log aggregation service respectively. There are no message-bus or gRPC dependencies.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Salesforce | REST / HTTPS | Fetch merchant opportunity and account data; push finalised setup configuration | yes | `salesForce` |
| BookingTool API | REST / HTTPS | Push availability schedule and capacity caps per feature country | yes | `bookingToolApi` |
| Telegraf Agent | UDP/TCP (InfluxDB line protocol) | Receive HTTP and business metrics from `ssuMetricsReporter` | no | `telegrafAgent` |
| Log Aggregation (Splunk) | TCP / Splunk HEC | Ingest Splunk-formatted structured logs from `ssuLogger` | no | `logAggregation` |

### Salesforce Detail

- **Protocol**: REST / HTTPS + OAuth 2.0
- **Auth**: OAuth 2.0 — client credentials grant using `SALESFORCE_CLIENT_ID`, `SALESFORCE_CLIENT_SECRET`, `SALESFORCE_USERNAME`, `SALESFORCE_PASSWORD`
- **Purpose**: Resolves the merchant opportunity and account record at session start (`/api/opportunity`); receives the finalised self-setup configuration on wizard completion (`/sf`)
- **Failure mode**: If Salesforce is unavailable at session start the merchant cannot proceed with setup; if unavailable at submission, the configuration push fails and the merchant must retry
- **Circuit breaker**: > No evidence found of a circuit breaker implementation

### BookingTool API Detail

- **Protocol**: REST / HTTPS
- **Auth**: BasicAuth — credentials supplied via `BOOKINGTOOL_CREDENTIALS` (per-country endpoints)
- **Purpose**: Accepts availability windows (`/week` flow) and capacity caps (`/capping` flow) per feature country after Salesforce configuration is confirmed
- **Failure mode**: If BookingTool API is unavailable, the configuration push step fails; the merchant's data is retained in MySQL for retry
- **Circuit breaker**: > No evidence found of a circuit breaker implementation

### Telegraf Agent Detail

- **Protocol**: InfluxDB line protocol (UDP or TCP)
- **Auth**: None (internal network)
- **Purpose**: Receives application and business metrics from `ssuMetricsReporter` for dashboarding in InfluxDB/Grafana
- **Failure mode**: Metrics are fire-and-forget; loss of Telegraf does not affect merchant-facing flows
- **Circuit breaker**: Not applicable

### Log Aggregation (Splunk) Detail

- **Protocol**: TCP / Splunk HEC
- **Auth**: Internal network trust / HEC token (managed by `ssuLogger` configuration)
- **Purpose**: Centralised log ingestion formatted by `vube/monolog-splunk-formatter`
- **Failure mode**: Log loss if aggregation service is unavailable; no impact on merchant-facing flows
- **Circuit breaker**: Not applicable

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| SSU HBW Database | TCP / MySQL | Persist and retrieve self-setup configuration and job queue state | `continuumSsuDatabase` |

## Consumed By

> Upstream consumers are tracked in the central architecture model. Merchants access selfsetup-hbw directly via browser using Salesforce-generated invitation URLs. There are no known programmatic API consumers.

## Dependency Health

- The `/heartbeat.txt` endpoint confirms the Apache/PHP process is alive but does not probe downstream dependencies.
- No active health checks or readiness probes against Salesforce or BookingTool API are evidenced in the inventory.
- Operational procedures for dependency failures should be defined by the service owner team (booking-tool-engineers@groupon.com).
