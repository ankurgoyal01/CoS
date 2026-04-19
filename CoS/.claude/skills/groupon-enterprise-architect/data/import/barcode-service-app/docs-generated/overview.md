---
service: "barcode-service-app"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Redemption"
platform: "Continuum"
team: "Redemption"
status: active
tech_stack:
  language: "Java"
  language_version: "11"
  framework: "Dropwizard"
  framework_version: "JTier 5.14.1"
  runtime: "JVM"
  runtime_version: "11"
  build_tool: "Maven"
  package_manager: "Maven"
---

# Barcode Service Overview

## Purpose

Barcode Service (`citydeals_barcode_app`) is a stateless, synchronous HTTP service that generates barcode and QR code images for Groupon's voucher redemption flows. It accepts a code type, payload encoding type, and data payload via URL path parameters, then returns a rendered image (PNG or GIF) or structured metadata. The service exists to decouple barcode rendering logic from downstream consumers such as voucher print flows, mobile redemption screens, and merchant-facing redemption portals.

## Scope

### In scope

- Generating 1D barcode images: Code128, Code128A, Code128B, Code128C, Code25, Code25 Interleaved, Code39, Code39 Extended, EAN-13, EAN-8, GS1, ITF, UPC, PDF417
- Generating 2D QR code images
- Serving images in PNG and GIF formats
- Accepting payloads encoded as `plain`, `base64`, or `base64url`
- Accepting optional image dimension constraints (width, height) and rotation angle
- Reporting available code types and output formats via discovery endpoints
- Computing rendered barcode pixel width for a given code type and base64 payload

### Out of scope

- Storing barcode data or voucher records (service is fully stateless)
- Caching generated images
- Voucher creation or redemption state management (handled by separate redemption services)
- Authentication or authorization of callers

## Domain Context

- **Business domain**: Redemption
- **Platform**: Continuum
- **Upstream consumers**: Voucher print services, mobile redemption clients, merchant center redemption portals, and any internal service needing on-demand barcode rendering
- **Downstream dependencies**: None — the service performs all barcode rendering in-process using embedded libraries (ZXing, Barbecue)

## Stakeholders

| Role | Description |
|------|-------------|
| Service owner | Redemption team (owner: imaya) |
| On-call | barcode-service@groupon.pagerduty.com |
| Mailing list | shawshank@groupon.com |
| Slack channel | post-purchase-notification |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 11 | `.ci/Dockerfile`, `src/main/docker/Dockerfile` |
| Framework | Dropwizard (JTier) | jtier-service-pom 5.14.1 | `pom.xml` parent POM |
| Runtime | JVM | 11 | `docker.groupondev.com/jtier/prod-java11-jtier` base image |
| Build tool | Maven | 3.5.4 | `mvnvm.properties` |
| Package manager | Maven | 3.5.4 | `mvnvm.properties` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `com.google.zxing:core` | 3.3.3 | barcode-rendering | Core ZXing barcode encoding engine |
| `com.google.zxing:javase` | 3.3.3 | barcode-rendering | Java SE image output for ZXing (PNG/GIF) |
| `net.sourceforge.barbecue:barbecue` | 1.5-beta1 | barcode-rendering | Legacy Barbecue barcode renderer (Code128, Code39, etc.) |
| `ru.vyarus:dropwizard-guicey` | 5.4.2 | http-framework | Guice dependency injection integration for Dropwizard |
| `javax.inject:javax.inject` | 1 | http-framework | Standard DI annotations (JSR-330) |
| `io.swagger.codegen.v3:swagger-codegen-maven-plugin` | 3.0.8 | api-generation | Generates JAX-RS server stubs from OpenAPI spec at build time |
| `com.groupon.jtier.codegen:jtier-api-codegen` | 1.2.0 | api-generation | Groupon-specific JTier codegen templates |
| `io.swagger.parser.v3:swagger-parser-v3` | 2.0.12 | api-generation | OpenAPI 3 spec parsing used by codegen |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
