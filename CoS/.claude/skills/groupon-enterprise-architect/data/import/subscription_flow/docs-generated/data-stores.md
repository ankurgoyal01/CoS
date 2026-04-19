---
service: "subscription_flow"
title: Data Stores
generated: "2026-03-03T00:00:00Z"
type: data-stores
stores: []
---

# Data Stores

## Overview

This service is stateless and does not own any data stores. Subscription Flow is an i-tier rendering service — it holds no persistent state, owns no database, and uses no cache. All data required for rendering is fetched at request time from GConfig (configuration/experiments), Lazlo API (legacy subscription data), and the Groupon V2 API (user context).

## Stores

> Not applicable

## Caches

> Not applicable

## Data Flows

> Not applicable — no data store ownership. All data is fetched on demand from upstream services per request.
