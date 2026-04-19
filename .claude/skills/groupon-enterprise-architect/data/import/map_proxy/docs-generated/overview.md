---
service: "map_proxy"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Geo Services"
platform: "Continuum"
team: "Geo Services"
status: active
tech_stack:
  language: "Java"
  language_version: "1.8 (source/target); Java 11 runtime in Docker"
  framework: "Jetty"
  framework_version: "8.0.4.v20111024"
  runtime: "JVM"
  runtime_version: "Java 11 (prod-java11:3 base image)"
  build_tool: "Maven"
  package_manager: "Maven / npm (build-time JS bundling only)"
---

# MapProxy Overview

## Purpose

MapProxy (codename MapTrotsky) is Groupon's centralized gateway for static and dynamic map requests. It decouples Groupon's web, mobile, and email platforms from their upstream maps provider, currently Google Maps for Business (with Yandex Maps for select CIS geographies). The service applies HMAC-SHA1 cryptographic URL signing to outbound Google Maps requests and selects the correct provider based on the caller's geography, ensuring that provider API keys are never exposed to client-side callers.

## Scope

### In scope

- Serving static map image requests by redirecting to the upstream provider (Google or Yandex) with a signed URL.
- Serving dynamic map JavaScript loader requests by redirecting to the upstream provider with a signed URL.
- Serving a dynamically assembled JavaScript payload (v2 dynamic endpoint) that embeds provider JS libraries using classpath templates.
- Provider selection by country: country query parameter, `X-Country` HTTP header, Referer TLD, and Host header fallback.
- HMAC-SHA1 URL signing for Google Maps for Business requests.
- Tracking all map requests via structured log output (method, URI, status, latency, request ID, referer, user-agent).
- Health and heartbeat endpoints for load balancer and Kubernetes probes.

### Out of scope

- Geocoding or address resolution (not implemented).
- Tile caching or image buffering (all responses are HTTP 302 redirects to upstream).
- Authentication of incoming Groupon callers (no auth on inbound requests).
- Map analytics or quota enforcement (usage is tracked by Google via the `client` param and logged by MapProxy; enforcement is upstream).

## Domain Context

- **Business domain**: Geo Services
- **Platform**: Continuum
- **Upstream consumers**: Groupon web platform (www.groupon.com), mobile apps, email platform, layout-service, and other internal services that render maps for deal/merchant pages, vouchers, and checkout flows.
- **Downstream dependencies**: Google Maps Static API, Google Maps JavaScript API (maps.googleapis.com), Yandex Static Maps API (static-maps.yandex.ru).

## Stakeholders

| Role | Description |
|------|-------------|
| Service Owner | Geo Services team (geo-team@groupon.com), owner: khsingh |
| On-call | geo-alerts@groupon.com, PagerDuty P7FZQE4 |
| Consumers | Groupon web, mobile, email, and layout-service teams |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 1.8 (source/target); Java 11 runtime | `pom.xml` jdk.version, `Dockerfile` base image |
| Framework | Jetty embedded servlet | 8.0.4.v20111024 | `pom.xml` jetty-servlet dependency |
| Runtime | JVM | Java 11 (prod-java11:3) | `Dockerfile` FROM line |
| Build tool | Maven | 3.x | `pom.xml` |
| JS bundling | Gulp | 3.6.0 (build-time only) | `package.json` |
| Package manager | Maven (Java), npm 2.5.1 (build-time JS) | — | `pom.xml` eirslett plugin |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| jetty-servlet | 8.0.4.v20111024 | http-framework | Embedded HTTP server and servlet container |
| javax.servlet-api | 3.0.1 | http-framework | Servlet API contract for request/response handling |
| commons-configuration | 1.7 | config | Reads `MapProxy.properties` configuration file |
| snakeyaml | 1.10 | serialization | YAML config file parsing |
| slf4j-log4j12 | 1.6.4 | logging | SLF4J bridge to Log4j for structured request logging |
| json-simple | 1.1 | serialization | Lightweight JSON construction for responses |
| net.iharder base64 | 2.3.8 | auth | Base64 encode/decode for HMAC-SHA1 URL signing |
| app-config (groupon-common) | 1.4 | config | Groupon internal AppConfig property loader |
| commons-io | 1.3.2 | utilities | I/O utilities for classpath JS template loading |
| dockerfile-maven-plugin (spotify) | 1.4.10 | build | Builds and pushes Docker image to docker-conveyor.groupondev.com |
| mockito-all | 1.9.0 | testing | Unit test mocking |
| powermock-api-mockito | 1.4.10 | testing | PowerMock extension for static method mocking |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
