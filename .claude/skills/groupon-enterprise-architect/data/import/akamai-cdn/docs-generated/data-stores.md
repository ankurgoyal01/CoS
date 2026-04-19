---
service: "akamai-cdn"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores: []
---

# Data Stores

## Overview

This service is stateless and does not own any data stores. Akamai CDN is a managed SaaS platform; all configuration state is persisted in Akamai's own infrastructure (property configurations, rule trees, cache policies) and is managed through the Akamai Control Center (`https://control.akamai.com`). Groupon's DSL and configuration-as-code files stored in this repository serve as the source-of-truth for intended configuration, but there is no Groupon-owned database, cache, or storage layer.

## Stores

> Not applicable — this service owns no data stores.

## Caches

> Not applicable — the Akamai edge cache is managed by Akamai as a platform capability, not as a Groupon-owned cache resource. Cache TTLs and invalidation rules are defined through CDN property configurations.

## Data Flows

> Not applicable — no data movement between owned stores. CDN configuration state flows outward from Groupon's architecture DSL definitions to the Akamai Control Center via the configuration management process described in [Flows](flows/index.md).
