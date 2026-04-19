---
service: "tripadvisor-api"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [config-files, jndi, spring-profiles]
---

# Configuration

## Overview

The Getaways Affiliate API is configured via a layered Java `.properties` file system managed by Spring. A base `settings.properties` file defines defaults and build-time properties. Per-environment override files (e.g., `live-US-settings.properties`, `staging-US-settings.properties`) are selected by Spring profile. The active Spring profile is set at deployment time via the system property `spring.profiles.active`. Database connectivity uses JNDI.

All properties files are located under `ta-api-v1/src/main/resources/`.

## Environment Variables

> No evidence found in codebase. Configuration is driven by Spring `.properties` files and system properties rather than OS-level environment variables.

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| `getaways.api.forceOff` | When `true`, bypasses all downstream Getaways API calls and returns empty responses | `false` | global |
| `availability.shortcut.enabled` | Enables a shortcut path that bypasses the full availability pipeline | `true` (dev), `false` (production) | per-environment |

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `ta-api-v1/src/main/resources/settings.properties` | properties | Base defaults: heartbeat credentials, JNDI datasource path, Hibernate dialect, Getaways API defaults, build metadata |
| `ta-api-v1/src/main/resources/live-US-settings.properties` | properties | Production (US) overrides: Getaways API URLs, client ID, heartbeat file path |
| `ta-api-v1/src/main/resources/staging-US-settings.properties` | properties | Staging (US) overrides: Getaways staging API URLs, client ID, heartbeat file path |
| `ta-api-v1/src/main/resources/dev-US-settings.properties` | properties | Development (US) overrides |
| `ta-api-v1/src/main/resources/qa-US-settings.properties` | properties | QA overrides |
| `ta-api-v1/src/main/resources/integration-tests-settings.properties` | properties | Integration test settings |
| `ta-api-v1/src/main/resources/seoname.properties` | properties | Partner SEO name mappings (TripAdvisor, Trivago, Google) |
| `ta-api-v1/src/main/resources/xsd/Query.xsd` | XSD | Google Hotel Ads query XML schema |
| `ta-api-v1/src/main/resources/xsd/Transaction.xsd` | XSD | Google Hotel Ads transaction XML schema |
| `ta-api-v1/src/main/resources/xsd/query_control.xsd` | XSD | Google Hotel Ads query control XML schema |
| `google/google-query-control-message.xml` | XML | Static Google query control message response (`google.queryControlMessage.location`) |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `heartbeat.passwd` | HTTP Basic auth password for heartbeat management endpoints | properties file (value present in `settings.properties`; should be rotated) |
| `getaways.api.client.id` | Client ID for authenticating calls to the Getaways search and content APIs | properties file (`live-US-settings.properties`) |
| `getaways.api.content.productsets.authorization` | `X-GRPN-Groups` authorization header value for Getaways Content API | properties file |

> Secret values are not documented here. See the properties files in the repository for current values (note: storing secrets in properties files is a known security concern; rotation policy is not documented).

## Per-Environment Overrides

| Property | Development | Staging | Production (US) |
|----------|-------------|---------|-----------------|
| `spring.profiles.active` | `development` | `staging` | `live` |
| `getaways.api.search.url` | (not set — uses shortcut) | `http://getaways-search-app-staging-vip/getaways/v2/search` | `http://getaways-search-app-vip/getaways/v2/search` |
| `getaways.api.content.productsets.url` | (not set) | `http://getaways-travel-content-staging-vip/v2/getaways/content/product_sets` | `http://getaways-content-app-vip/v2/getaways/content/product_sets` |
| `getaways.api.content.batchhoteldetail.url` | (not set) | `http://getaways-travel-content-staging-vip/v2/getaways/content/hotelDetailBatch` | `http://getaways-content-app-vip/v2/getaways/content/hotelDetailBatch` |
| `heartbeat.location` | `heartbeat.txt` (relative) | `/var/groupon/run/ta-api/heartbeat.txt` | `/var/groupon/run/ta-api/heartbeat.txt` |
| `availability.shortcut.enabled` | `true` | not set | `false` |

### Fixed configuration properties

| Property | Value | Purpose |
|----------|-------|---------|
| `getaways.api.connection.timeout.seconds` | `5` | HTTP connection timeout to Getaways APIs |
| `getaways.api.content.productsets.limit` | `100` | Max product sets per page |
| `getaways.api.content.productsets.dealstatus` | `live` | Only fetch live deals |
| `getaways.api.content.batchhoteldetail.batchsize` | `100` | Hotel detail batch size |
| `marketrate.minimum.los.min.days` | `2` | Minimum length of stay for market rate |
| `marketrate.minimum.nearby.deals` | `3` | Minimum nearby deals for market rate |
| `marketrate.minimum.nearby.radius` | `10` | Nearby radius in miles for market rate |
| `jndi.datasource.path` | `java:comp/env/jdbc/GpnDataDb` | JNDI datasource name |
| `hibernate.dialect` | `org.hibernate.dialect.MySQLDialect` | Hibernate SQL dialect |
