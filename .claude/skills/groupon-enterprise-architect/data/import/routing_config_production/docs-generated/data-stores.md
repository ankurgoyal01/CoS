---
service: "routing_config_production"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores: []
---

# Data Stores

## Overview

> No evidence found in codebase.

`routing_config_production` is a stateless configuration repository. It does not own or interact with any database, cache, or persistent data store. The routing rules are expressed as static Flexi DSL files, compiled into a tarball and Docker image, and distributed to routing service nodes via CI/CD. There is no runtime state written or read from any data store by this config repository itself.

## Stores

> This service is stateless and does not own any data stores.

## Caches

> Not applicable — no caches are used.

## Data Flows

> Not applicable — no data flows between stores exist for this configuration repository.
