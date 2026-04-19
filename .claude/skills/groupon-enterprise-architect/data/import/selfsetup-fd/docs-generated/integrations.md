---
service: "selfsetup-fd"
title: Integrations
generated: "2026-03-02T00:00:00Z"
type: integrations
external_count: 3
internal_count: 1
---

# Integrations

## Overview

selfsetup-fd has three external dependencies and one internal dependency. Salesforce is the critical upstream data source for merchant opportunity data. The Booking Tool System is the critical downstream target where BT instances are created. Telegraf is used for metrics emission. The owned MySQL database is the sole internal dependency for queue and state.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Salesforce | HTTPS | Opportunity and merchant identifier lookups via SOQL/REST | yes | `salesForce` |
| Booking Tool System | HTTPS | Creates and configures Booking Tool instances for merchants | yes | `bookingToolSystem_7f1d` |
| Telegraf Gateway | HTTP | Emits application metrics (influxdb-php) | no | `telegrafGateway_6a2b` |

### Salesforce Detail

- **Protocol**: HTTPS (REST API / SOQL)
- **Base URL / SDK**: Configured at runtime; accessed via `selfsetupFd_ssuSalesforceClient` component using Salesforce OAuth
- **Auth**: Salesforce OAuth (credentials managed via application config)
- **Purpose**: Provides opportunity data for the setup wizard (`/api/getopportunity`) and merchant identifier resolution for cron-driven queue processing
- **Failure mode**: Opportunity lookup fails; setup wizard cannot proceed without valid opportunity data. Cron jobs cannot resolve merchant IDs, leaving queued jobs unprocessed.
- **Circuit breaker**: No evidence found

### Booking Tool System Detail

- **Protocol**: HTTPS
- **Base URL / SDK**: Accessed via `selfsetupFd_ssuBookingToolClient` component
- **Auth**: No evidence found of specific auth mechanism in the inventory
- **Purpose**: Receives create/configure requests for merchant Booking Tool instances, invoked both synchronously (web layer) and asynchronously (cron jobs)
- **Failure mode**: BT instance creation fails; queued jobs remain unprocessed or must be retried on next cron cycle
- **Circuit breaker**: No evidence found

### Telegraf Gateway Detail

- **Protocol**: HTTP
- **Base URL / SDK**: Configured via `TELEGRAF_URL` environment variable; accessed via `influxdb-php` library
- **Auth**: No evidence found
- **Purpose**: Application metrics emission to InfluxDB via the Telegraf proxy
- **Failure mode**: Metrics stop flowing to InfluxDB; application continues to operate normally (non-critical path)
- **Circuit breaker**: No evidence found

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| SSU FD Database | MySQL | Queue persistence and setup state reads/writes | `continuumEmeaBtSelfSetupFdDb` |

## Consumed By

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| Groupon EMEA Employees | HTTPS (browser) | Access setup wizard to onboard Food & Drinks merchants onto Booking Tool |

> Upstream consumers are tracked in the central architecture model.

## Dependency Health

> No evidence found of health check endpoints, retry policies, or circuit breaker implementations for external dependencies. Operational procedures to be defined by service owner.
