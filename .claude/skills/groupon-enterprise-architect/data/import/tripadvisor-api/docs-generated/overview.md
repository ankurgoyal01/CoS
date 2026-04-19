---
service: "tripadvisor-api"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Getaways Affiliates / Travel"
platform: "Continuum"
team: "Getaways Engineering"
status: active
tech_stack:
  language: "Java"
  language_version: "1.8"
  framework: "Spring MVC"
  framework_version: "4.1.6.RELEASE"
  runtime: "Apache Tomcat"
  runtime_version: "9.x (Jetty 9.4 for integration tests)"
  build_tool: "Maven"
  package_manager: "Maven"
---

# Getaways Affiliate API Overview

## Purpose

The Getaways Affiliate API (also known internally as the TripAdvisor API) is a Spring MVC WAR application that acts as an integration gateway between Groupon Getaways hotel inventory and external Cost-Per-Click (CPC) partner platforms. It exposes hotel availability, pricing, and feed endpoints tailored to the specific protocol requirements of TripAdvisor, Trivago, and Google Hotel Ads. The service translates partner-facing requests into calls to internal Getaways search and content APIs, then transforms and returns the responses in the format each partner expects.

## Scope

### In scope

- Serving hotel availability and pricing responses to TripAdvisor and Trivago partners via a partner-keyed REST endpoint
- Serving Google Hotel Ads integration endpoints: transaction query, query control message, and hotel list feed
- Translating internal Getaways availability data into partner-specific response schemas
- XSD validation of XML payloads exchanged with Google Hotel Ads
- Heartbeat and status endpoint management for load-balancer health checking
- Exposing an external URL at `http://api.groupon.com/getaways/v2/affiliates` for partner integrations

### Out of scope

- Hotel search and availability computation (delegated to `getaways-search` and `getaways-availability-api`)
- Hotel content management (delegated to `getaways-content`)
- Booking and checkout workflows
- Bidding logic for CPC campaigns (handled by the `ms-bids-api` subservice in this same repository)
- User authentication and session management

## Domain Context

- **Business domain**: Getaways Affiliates / Travel
- **Platform**: Continuum
- **Upstream consumers**: TripAdvisor partner (HTTPS), Trivago partner (HTTPS), Google Hotel Ads (`continuumGoogleHotelAds` via HTTPS)
- **Downstream dependencies**: `getaways-search` (availability queries), `getaways-content` (product sets and hotel detail), `trackingRedirectService` (URL construction — stub only in federated model)

## Stakeholders

| Role | Description |
|------|-------------|
| Getaways Engineering | Owning team (getaways-eng@groupon.com); responsible for feature development and on-call |
| SRE / Production Operations | Monitors service health via Nagios, Wavefront dashboards, and PagerDuty (getaways-svc-affiliate-alert@groupon.com) |
| External Partners | TripAdvisor, Trivago, and Google — consume the affiliate API endpoints |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 1.8 | `ta-api-v1/pom.xml` — `maven.compiler.source=1.8` |
| Framework | Spring MVC | 4.1.6.RELEASE | `ta-api-v1/pom.xml` — `spring.framework.version` |
| Security | Spring Security | 3.2.5.RELEASE | `ta-api-v1/pom.xml` |
| Runtime | Apache Tomcat | 9.x (Jetty 9.4 for integration test) | `.ci/Dockerfile`, `ta-api-v1/pom.xml` |
| Build tool | Maven | 3.x | `pom.xml`, `Jenkinsfile` |
| Container image | docker.groupondev.com/jtier/dev-java8-maven | 2020-09-22 | `.ci/Dockerfile` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| spring-webmvc | 4.1.6.RELEASE | http-framework | REST controller routing and MVC dispatch |
| spring-security | 3.2.5.RELEASE | auth | Basic auth for management endpoints (heartbeat) |
| jackson-databind | 2.4.3 | serialization | JSON serialization of availability responses |
| jaxb2-maven-plugin | 2.2 | serialization | XSD-to-Java code generation for Google XML schemas |
| ehcache-core | 2.4.7 | state-management | In-process caching (configured but not used per owner docs) |
| guava | 18.0 | validation | Collection utilities and preconditions |
| apache httpasyncclient | 4.1 | http-framework | Async HTTP client for upstream Getaways API calls |
| joda-time | 2.5 | serialization | Date/time handling for availability date ranges |
| logback-classic | 1.0.13 | logging | Structured application logging |
| steno / logback-steno | 0.1.1-fork | logging | Groupon structured log format |
| gpn-heartbeat | 4.0.4 | metrics | Groupon heartbeat/health check framework |
| gpn-commons (common-utils) | 2.0.28 | http-framework | Groupon platform utilities |
| super-csv | 2.4.0 | serialization | CSV parsing for Google hotel list feed |
| hibernate-validator | 4.3.1 | validation | Bean Validation for request forms |
| commons-vfs2 | 2.0 | scheduling | Virtual file system for resource loading |
| testng | 6.8 | testing | Unit test framework |
| spock-core | 0.7-groovy-2.0 | testing | BDD-style unit tests |
| cucumber | 1.2.2 | testing | Integration/acceptance test stories |

> Only the most important libraries are listed here. See `ta-api-v1/pom.xml` for the full dependency list.
