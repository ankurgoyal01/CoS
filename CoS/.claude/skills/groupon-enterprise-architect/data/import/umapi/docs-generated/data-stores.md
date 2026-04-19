---
service: "umapi"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores: []
---

# Data Stores

## Overview

> No evidence found in codebase. The architecture DSL does not define any database containers or data store relationships for UMAPI. Given the service's role as the centralized merchant data API (supporting onboarding, profile CRUD, search, and reporting), it almost certainly owns or accesses one or more persistent data stores, but these are not yet modeled in the architecture.

## Stores

> No database containers, caches, or storage references are defined in the UMAPI architecture module. The service likely uses a relational database (e.g., MySQL or PostgreSQL, consistent with Continuum conventions) for merchant and place data, but this needs to be confirmed by the service owner and added to `models/containers.dsl`.

## Caches

> No evidence found in codebase.

## Data Flows

> No evidence found in codebase. Data flow patterns between stores (CDC, ETL, replication) are not documented in the architecture model.
