---
service: "booster"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores: []
---

# Data Stores

## Overview

Booster is an external SaaS operated entirely by Data Breakers. Groupon does not own or access any data stores associated with the Booster service directly. The `continuumBoosterService` integration boundary is stateless on the Groupon side — it passes requests to the Booster external API and returns ranked results to `continuumRelevanceApi`.

## Stores

> Not applicable. This service is stateless on the Groupon side and does not own any data stores. All data persistence for the Booster relevance engine is managed internally by the vendor (Data Breakers).

## Caches

> No evidence found in codebase. No Groupon-owned caching layer for Booster responses is described in the architecture model.

## Data Flows

> No evidence found in codebase. Data flows between Groupon and Booster are synchronous HTTPS request/response interactions. No CDC, ETL, or replication patterns are documented for this integration.
