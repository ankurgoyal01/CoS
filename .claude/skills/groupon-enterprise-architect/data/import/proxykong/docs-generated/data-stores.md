---
service: "proxykong"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumApiProxyConfigBundle"
    type: "git-repository"
    purpose: "Route and destination configuration storage"
---

# Data Stores

## Overview

ProxyKong does not own any traditional databases or caches. Its primary data store is the `api-proxy-config` Git repository, which is cloned into the container filesystem at `/api-proxy-config` at build time and kept current by a cron job. All routing configuration is read from and written to this repository via the config_tools scripts it provides.

## Stores

### API Proxy Config Repository (`continuumApiProxyConfigBundle`)

| Property | Value |
|----------|-------|
| Type | Git repository (filesystem-mounted clone) |
| Architecture ref | `continuumApiProxyConfigBundle` |
| Purpose | Stores API routing configuration (routes, route groups, destinations, experiments) and provides `config_tools` scripts for querying and mutating that configuration |
| Ownership | external — owned by the `groupon-api/api-proxy-config` repository |
| Mount path | `/api-proxy-config` (inside the container) |

#### Key Entities

| Entity / Directory | Purpose | Key Fields |
|--------------------|---------|-----------|
| Routes configuration | Defines HTTP routes mapped to destinations | `env`, `region`, `destination`, `routeGroup`, `routing_path`, `http_methods`, `namespace` |
| Destinations configuration | Defines destination VIPs and connection parameters | `destinationName`, `destination_vips`, `destinationPort`, `connectionTimeout`, `requestTimeout` |
| Route groups | Groups of related routes under a destination | `routeGroupId`, `destination`, `env`, `region` |
| Experiments | Routing experiment configurations | `env`, `region` |

#### Access Patterns

- **Read**: `config_tools` scripts (`getRouteGroups`, `getRoutes`, `getDestinations`, `getExperiments`, `getDestinationPreview`, `doesDestinationExist`, `doesDestinationVipExist`, `doesRouteGroupExist`, `doRoutesExist`) are called synchronously on each API request.
- **Write**: Changes are never applied directly to `/api-proxy-config`. The `pullRequestAutomation` component copies the directory to a temporary folder, applies mutations via `addNewRouteRequest`, `promoteRouteRequest`, or `removeRoutes` scripts, commits the changes, and pushes a new branch for pull request review.
- **Refresh**: A cron job runs every 10 minutes (`*/10 * * * *`) executing `cron/gitRefreshMaster.sh` to pull the latest `master` branch into `/api-proxy-config`.

## Caches

> Not applicable. No in-memory or external caches are used.

## Data Flows

Configuration data flows one way through the system:
1. The `api-proxy-config` master branch is pulled into the container at build time via `Dockerfile` `git clone`.
2. A cron job refreshes master every 10 minutes to keep read queries current.
3. Mutation requests copy the working directory to a temp folder, apply changes, and push a branch — the actual config store is only updated after an authorized engineer merges the resulting pull request.
