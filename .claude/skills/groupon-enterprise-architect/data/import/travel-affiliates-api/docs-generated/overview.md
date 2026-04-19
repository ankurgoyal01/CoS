---
service: "travel-affiliates-api"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Travel / Getaways Affiliates"
platform: "Continuum"
team: "Getaways Engineering"
status: active
tech_stack:
  language: "Java"
  language_version: "11"
  framework: "Spring MVC"
  framework_version: "4.1.6.RELEASE"
  runtime: "Apache Tomcat"
  runtime_version: "8.5.73-jre11-temurin"
  build_tool: "Maven"
  package_manager: "Maven (Nexus)"
---

# Travel Affiliates API Overview

## Purpose

The Travel Affiliates API (also known internally as the AFL TripAdvisor API or Getaways Affiliates API) is an integration layer that exposes Groupon Getaways hotel inventory and pricing to external cost-per-click (CPC) affiliate partners. It translates partner-specific availability query formats into internal Getaways API calls and returns partner-compatible responses. The service also generates and publishes periodic hotel feed XML files to AWS S3 for consumption by Google Hotel Ads and other partners.

## Scope

### In scope
- Serving real-time hotel availability requests from Google Hotel Ads, Skyscanner, and TripAdvisor via partner-specific endpoints
- Processing Google Hotel Ads Live Query (transaction and query control) requests, returning XML responses conforming to Google's Transaction and QueryControl XSD schemas
- Generating hotel list feeds (CSV/JSON) for Google Hotel Ads via on-demand and scheduled cron jobs
- Uploading generated hotel feed XML artifacts to an AWS S3 bucket
- Resolving affiliate partner SEO identifiers to internal partner definitions
- Transforming partner user-country codes and point-of-sale values to internal locale and region mappings

### Out of scope
- Hotel booking and checkout flows (handled by Getaways checkout services)
- Hotel content management and inventory storage (owned by Getaways API and Deal Catalog)
- User authentication and session management
- Affiliate billing and commission tracking

## Domain Context

- **Business domain**: Travel / Getaways Affiliates
- **Platform**: Continuum
- **Upstream consumers**: Google Hotel Ads (`continuumGoogleHotelAds`), Skyscanner (`continuumSkyscanner`), TripAdvisor (`continuumTripAdvisor`)
- **Downstream dependencies**: Getaways API (`continuumGetawaysApi`), SEO Name Service (`continuumSeoNameService`), AWS S3 Feed Bucket (`continuumTravelAffiliatesFeedBucket`), Travel Affiliates DB (`continuumTravelAffiliatesDb`)

## Stakeholders

| Role | Description |
|------|-------------|
| Getaways Engineering | Primary owning team; contact getaways-eng@groupon.com for general questions |
| GPN Alerts | Emergency support and outage notification; gpn-alerts@groupon.com triggers PagerDuty 24/7 |
| GPN Support | Regular support during office hours; gpn-support@groupon.com |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 11 | `pom.xml` `maven.compiler.source=11` |
| Framework | Spring MVC | 4.1.6.RELEASE | `pom.xml` `spring.framework.version` |
| Runtime | Apache Tomcat | 8.5.73-jre11-temurin | `src/main/docker/Dockerfile` base image |
| Build tool | Maven | 3.x | `pom.xml` |
| Package manager | Maven (Nexus) | | `pom.xml` repository config |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| spring-webmvc | 4.1.6.RELEASE | http-framework | Spring MVC web layer and REST controllers |
| spring-security-web | 3.2.5.RELEASE | auth | Servlet-level security filters |
| jackson-databind | 2.9.4 | serialization | JSON marshalling for API requests and responses |
| jaxb-api / jaxb-impl | 2.2.6 | serialization | XML marshalling for Google Transaction and QueryControl XSD-generated types |
| httpasyncclient | 4.1 | http-framework | Async HTTP client for outbound Getaways API calls |
| ehcache-core | 2.4.7 | state-management | In-process caching layer |
| guava | 18.0 | validation | General utility; immutable collections |
| joda-time | 2.5 | scheduling | Date/time calculations for check-in/check-out and length-of-stay |
| gpn-heartbeat | 4.0.4 | metrics | Groupon heartbeat health-check mechanism |
| logback-classic + logback-steno | 1.0.13 / 1.0.2 | logging | Structured JSON logging (steno format) |
| software.amazon.awssdk:s3 | 2.20.102 | db-client | AWS SDK v2 for S3 feed file uploads |
| super-csv | 2.4.0 | serialization | CSV generation for hotel list feeds |
| lombok | 1.18.30 | validation | Boilerplate reduction via compile-time annotation processing |
| hibernate-validator | 4.3.1.Final | validation | Bean Validation (JSR-303) for request objects |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See `pom.xml` for a full list.
