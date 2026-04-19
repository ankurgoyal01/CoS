---
service: "HotzoneGenerator"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: ["cli-args", "properties-files", "classpath-resource"]
---

# Configuration

## Overview

HotzoneGenerator is configured through three mechanisms: (1) CLI arguments passed at invocation specifying environment and run mode, (2) environment-scoped `.properties` files loaded by the `app-config` library based on the `ACTIVE_ENV` system property, and (3) a classpath-bundled JSON resource (`gconfig/`) containing per-region division coefficients. There are no runtime calls to a live GConfig service; coefficient data is baked into the jar.

Per-environment properties files are located at `src/main/resources/props/project.<env>.properties` and selected automatically based on the `ACTIVE_ENV` value set from the first CLI argument. The global properties file `skeletor.global.properties` is always loaded in addition.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `ACTIVE_ENV` | Selects the active environment (`development`, `staging`, `production`, `production-emea`) | yes | none | Set programmatically from CLI arg 1 via `System.setProperty("ACTIVE_ENV", env)` |
| `LANG` | Locale for the run script (`en_US.UTF-8`) | yes (cron) | none | cron job env export |
| `custom.logpath` | Directory path for log file output | yes | none | JVM `-D` flag |

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| `proximity.enabled` | When `true`, hotzones are submitted to the Proximity API; when `false`, output is written to a local file | `true` in all non-dev environments | per-environment properties file |

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `src/main/resources/props/project.production.properties` | properties | NA production service URLs, client IDs, country codes, audience IDs |
| `src/main/resources/props/project.production-emea.properties` | properties | EMEA production service URLs, client IDs, country codes, audience IDs |
| `src/main/resources/props/project.staging.properties` | properties | NA staging service URLs and settings |
| `src/main/resources/props/project.staging-emea.properties` | properties | EMEA staging service URLs and settings |
| `src/main/resources/props/project.development.properties` | properties | NA development settings |
| `src/main/resources/props/project.development-emea.properties` | properties | EMEA development settings |
| `src/main/resources/props/project.uat.properties` | properties | UAT environment settings |
| `src/main/resources/props/skeletor.global.properties` | properties | Per-category UUIDs, radii (metres), time-range JSON strings, and deny-list category GUIDs — loaded in all environments |
| `src/main/resources/props/app_config.properties` | properties | AppConfig library bootstrap: declares property file prefix paths |
| `src/main/resources/gconfig/production.txt` | JSON | Division population-density coefficients for NA (baked into jar) |
| `src/main/resources/gconfig/production-emea.txt` | JSON | Division coefficients for EMEA |
| `src/main/resources/gconfig/staging.txt` | JSON | Division coefficients for NA staging |
| `src/main/resources/log4j2.xml` | XML | Log4j2 logging configuration |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `postgres.app.pass` | PostgreSQL password for Proximity DB (weekly email mode) | Properties file (`/secrets/project.<env>.properties`) |
| `postgres.app.user` | PostgreSQL username for Proximity DB | Properties file (`/secrets/project.<env>.properties`) |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

The following properties differ between environments:

| Property | NA Production | EMEA Production | NA Staging |
|----------|---------------|-----------------|------------|
| `proximity.url` | `http://proximity-notifications.production.service/v1/proximity/location/hotzone` | Same | `http://proximity-notifications.staging.service/v1/proximity/location/hotzone` |
| `mds.url` | `http://marketing-deal-service.production.service/` | Same | `http://marketing-deal-service.staging.service/` |
| `mds.channel` | `g1` | `local` | `g1` |
| `dealClusters.url` | `http://api-proxy--internal-us.production.service/wh/v2/clusters/` | `http://api-proxy--internal-eu.production.service/wh/v2/clusters/` | `http://api-proxy--internal-us.staging.service/wh/v2/clusters/` |
| `gapi.url` | `http://api-proxy--internal-us.production.service` | `http://api-proxy--internal-eu.production.service` | `http://api-proxy--internal-us.staging.service` |
| `CountryCode` | `US,CA` | `GB,FR,DE,IT,ES,AU,IE,BE,NL,PL` | `US,CA` |
| `gconfig.resourceLocation` | `gconfig/production.txt` | `gconfig/production-emea.txt` | `gconfig/staging.txt` |
| `hotzoneGenerator.country` | `us` | `emea` | `us` |

### Notable global config properties (from `skeletor.global.properties`)

| Property | Value | Purpose |
|----------|-------|---------|
| `radius.things-to-do` | `3200` | Geofence radius (metres) for Things-to-Do category |
| `radius.massage` | `3000` | Geofence radius (metres) for Massage |
| `radius.food-and-drink` | `1500` | Geofence radius (metres) for Food & Drink |
| `denyListCategories` | 14 GUIDs | Level-3 taxonomy category GUIDs excluded from auto-campaign generation |
| `timeRange.things-to-do` | `{"storeHours":{"4":["11:00-17:00"],...}}` | Default time window for Things-to-Do hotzones (Thu–Sun 11AM–5PM) |
| `timeRange.food-and-drink` | `{"storeHours":{"1":["11:00-17:00"],...}}` | Default time window for Food & Drink hotzones (every day 11AM–5PM) |
