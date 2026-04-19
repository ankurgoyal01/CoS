---
service: "api-proxy"
title: Overview
generated: "2026-03-03T00:00:00Z"
type: overview
domain: "API Gateway / Edge"
platform: "Continuum"
team: "Groupon API (GAPI)"
status: active
tech_stack:
  language: "Java"
  language_version: "1.8"
  framework: "Vert.x"
  framework_version: "3.5.4"
  runtime: "JVM"
  runtime_version: "1.8"
  build_tool: "Maven"
  package_manager: "Maven"
---

# API Proxy Overview

## Purpose

API Proxy is the edge gateway for the Groupon Continuum platform. It receives all inbound HTTP requests from consumer clients (web, iOS, Android) and merchant-facing applications, applies routing rules, enforces authentication and rate-limiting policies, and forwards allowed requests to the appropriate backend destination services. It exists to provide a single, consistent entry point for API traffic across all Groupon client applications.

## Scope

### In scope

- Accepting and routing inbound HTTP requests from all Groupon client applications
- Executing an ordered filter chain covering routing resolution, auth validation, redirect enforcement, and policy evaluation
- Enforcing global and client-level rate limits using distributed Redis counters
- Validating Google reCAPTCHA tokens on protected request paths
- Dynamically loading and refreshing route configuration from external config endpoints
- Synchronising BEMOD (behaviour-modification) data from BASS for routing overlays
- Publishing request metrics, logs, and distributed traces to the metrics stack
- Health and status reporting via dedicated endpoints

### Out of scope

- Business logic processing (handled by backend destination services)
- Authentication token issuance (handled by upstream identity services)
- Client identity management (handled by `continuumClientIdService`)
- API configuration bundle management (handled by `api-proxy-config`)
- Static asset serving

## Domain Context

- **Business domain**: API Gateway / Edge
- **Platform**: Continuum
- **Upstream consumers**: Legacy Android app, legacy iOS app, legacy web frontend, Merchant Center — all send `JSON/HTTPS` requests
- **Downstream dependencies**: Backend destination services (dynamic via route config), `continuumClientIdService`, `continuumApiProxyRedis` (Redis), BASS Service, Google reCAPTCHA API, Metrics Stack

## Stakeholders

| Role | Description |
|------|-------------|
| Groupon API (GAPI) team | Service owner; responsible for routing policy, rate-limiting config, and BEMOD sync rules |
| Consumer client teams | Rely on API Proxy as the stable entry point for all API calls |
| Backend service teams | Register destination routes consumed by API Proxy's route config |
| Platform / SRE | Operate and monitor the gateway; escalation point for P1 incidents |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 1.8 | summary (pom.xml) |
| Framework | Vert.x | 3.5.4 | summary (pom.xml: vertx-core, vertx-web, vertx-rx-java2) |
| Runtime | JVM | 1.8 | summary (pom.xml) |
| Build tool | Maven | — | pom.xml |
| Package manager | Maven | — | pom.xml |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| vertx-core | 3.5.4 | http-framework | Reactive HTTP server and event loop |
| vertx-web | 3.5.4 | http-framework | HTTP routing and handler composition |
| vertx-rx-java2 | 3.5.4 | http-framework | RxJava2 integration for Vert.x async flows |
| netty-all | 4.1.19 | http-framework | Underlying network I/O via Vert.x |
| jedis | 2.1.0 | db-client | Redis client for rate-limit counter operations |
| jackson-databind | 2.9.6 | serialization | JSON serialisation and deserialisation |
| logback-steno | 1.17.0 | logging | Structured JSON log output |
| metrics-vertx | 2.0.6 | metrics | Vert.x metrics bridge to the metrics stack |
| tracing | 3.0.0 | metrics | Distributed tracing integration |
| flexiconf | 0.1.0 | scheduling | Flexible runtime configuration loading |
| bass-client | 0.1.24 | http-framework | Client for BASS Service BEMOD data retrieval |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
