---
service: "api-proxy-config"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "routingConfigArtifacts"
    type: "json-files"
    purpose: "Environment-scoped routing configuration files versioned in Git"
---

# Data Stores

## Overview

`api-proxy-config` is stateless at runtime — it owns no databases, caches, or external storage systems. Its entire data store is the Git repository itself: environment-scoped JSON configuration files under `src/main/conf/` serve as the authoritative source of routing state. These files are read and mutated by `config_tools/` CLI scripts and are packaged by the Maven assembly descriptor into a versioned artifact consumed by the `apiProxy` runtime.

## Stores

### Routing Configuration Artifacts (`routingConfigArtifacts`)

| Property | Value |
|----------|-------|
| Type | JSON files (Git-versioned) |
| Architecture ref | `routingConfigArtifacts` (component of `continuumApiProxyConfigBundle`) |
| Purpose | Environment- and region-scoped routing rules: realms, route groups, destinations, and A/B experiment layers |
| Ownership | owned |
| Migrations path | `src/main/conf/` |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `realms` | Named groupings of route groups defining internal vs. external API surfaces | `name` (e.g., `us_api`, `us_api_internal`, `api_groupon_de`, `api_groupon_de_internal`), `routeGroups[]` |
| `routeGroups` | Named sets of URL path patterns routed to a single destination | `id`, `name`, `destination`, `routes[]` |
| `routes` | Individual URL path pattern entries within a route group | `path`, `methods[]` (e.g., `GET`, `POST`), `exact` (boolean) |
| `destinations` | Backend service endpoint definitions consumed by the API Proxy | `name`, `type` (`static` or `dynamicClientId`), `host`, `port`, `ssl`, `connectTimeout`, `requestTimeout`, `timeoutStatus`, `maxConnections`, `heartbeatUri`, `heartbeatCheck`, `allowAuthHeaders`, `forcedHeaders`, `metricName`, `servicePortalId` |
| `layers` | A/B experiment container layers | `id`, `experiments[]` |
| `experiments` | Traffic-splitting experiment definitions within a layer | `id`, `type` (`rollout`), `startBucket`, `endBucket`, `variants[]` |

#### Access Patterns

- **Read**: `config_tools/` read scripts (`getRoutes.js`, `getRouteGroups.js`, `getDestinations.js`, `getExperiments.js`) parse JSON files using `fs.readFileSync` and filter with `lodash`/`underscore`. The `apiProxy` runtime reads `mainConf.json` on startup via the `CONFIG` environment variable.
- **Write**: `config_tools/` mutation scripts (`removeRoutes.js`, `promoteRouteRequest.js`, `addNewRouteRequest.js`, `cleanExperiments.js`) parse the file, mutate the in-memory object, and write back to disk with `fs.writeFileSync` using 4-space JSON indentation.
- **Indexes**: No database indexes — files are small enough that linear scan via `_.filter`/`_.find` is sufficient for all operations.

#### File Path Resolution

The `routingConfigFileResolver` component (`configUtils.js:getRoutingConfigFiles`) resolves the correct file path based on region, environment, and cloud mode:

| Region | Environment | Cloud Mode | Resolved Zones |
|--------|-------------|------------|----------------|
| `na` | any | cloud | `us-west-1`, `us-central1` |
| `emea` | `production` | cloud | `eu-west-1`, `europe-west1` |
| `emea` | `staging` | cloud | `us-west-2`, `europe-west1` |
| `na` | `production` | data center | `snc1`, `sac1` |
| `na` | `staging`/`uat` | data center | `snc1` |
| `emea` | `production` | data center | `dub1` |
| `emea` | `staging` | data center | `emea_snc1` |

## Caches

> Not applicable. This service uses no caches. Redis is referenced in routing configuration as a destination for the `apiProxy` runtime's rate-limiting feature, but `api-proxy-config` does not interact with Redis directly.

## Data Flows

Configuration files are authored and mutated in Git. When a PR is merged to the main branch, DeployBot triggers a build that packages the files into a versioned Docker image (`docker-conveyor.groupondev.com/groupon-api/api-proxy-config`) and deploys it to Kubernetes. The `apiProxy` runtime container reads the mounted configuration artifact from `/app/conf/` at startup. There is no CDC, ETL, or replication pattern — the Git repository is the single source of truth.
