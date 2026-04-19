---
service: "marketing"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 0
internal_count: 3
---

# Integrations

## Overview

The Marketing & Delivery Platform has a focused integration footprint. It is primarily an internal platform consumed by other Continuum services. It publishes events to the shared Message Bus and receives inbound calls from the Orders Service (for notification triggers) and the Marketing Deal Service (for deal data updates). An Administrator persona interacts with the platform directly via HTTPS. No external third-party system integrations are modeled for this service.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|

> No external (third-party) system dependencies are modeled for this service. All integrations are internal to the Continuum Platform.

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Message Bus | Async | Pub/Sub for campaign events, subscription changes, and delivery logs | `messageBus` |
| Marketing Platform Database | JDBC (inferred) | Persistence of campaign, subscription, inbox, and delivery data | `continuumMarketingPlatformDb` |

## Consumed By

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| Orders Service (`continuumOrdersService`) | JSON/HTTPS | Triggers marketing notifications (e.g., order confirmation) |
| Marketing Deal Service (`continuumMarketingDealService`) | HTTP + Events | Serves deal data and publishes updates consumed by marketing systems |
| Administrator | HTTPS | Creates and manages marketing campaigns |

> Additional upstream consumers may be tracked in the central architecture model.

## Dependency Health

> No evidence found in codebase. Health check, retry, and circuit breaker patterns for dependencies are not discoverable from the architecture model.
