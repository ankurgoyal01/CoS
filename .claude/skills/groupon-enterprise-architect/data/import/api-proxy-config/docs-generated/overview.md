---
service: "api-proxy-config"
title: Overview
generated: "2026-03-03"
type: overview
domain: "API Gateway / Traffic Routing"
platform: "Continuum"
team: "groupon-api/api-platform-internal"
status: active
tech_stack:
  language: "Java / Node.js"
  language_version: "Java 21 (bundle) / Node.js LTS (tools)"
  framework: "Maven Assembly"
  framework_version: "cmf-java-api Helm chart 3.92.0"
  runtime: "JVM / Node.js"
  runtime_version: "Java 21 / Node.js LTS"
  build_tool: "Maven (bundle) / npm (tools)"
  package_manager: "Maven (bundle) / npm (tools)"
---

# API Proxy Config Overview

## Purpose

`api-proxy-config` is the versioned configuration bundle and operator tooling repository for the Groupon API Proxy. It packages environment-scoped JSON configuration files — `mainConf.json`, `routingConf.json`, `proxyConf.json`, and `clientConf.json` — that are copied into the API Proxy runtime image at deploy time, defining how inbound API traffic is routed to backend service destinations. A companion set of Node.js CLI scripts (`config_tools/`) allows operators and CI pipelines to inspect and mutate routing configuration across regions and environments without manual JSON editing.

## Scope

### In scope

- Authoring and versioning of `routingConf.json`, `mainConf.json`, `proxyConf.json`, and `clientConf.json` per region and environment under `src/main/conf/`
- Maven assembly packaging of configuration files into a distributable artifact consumed by the API Proxy runtime image
- Typed Java model classes for route groups, routes, destinations, experiments, and realms
- Node.js CLI scripts (`config_tools/`) for reading routing state (routes, route groups, destinations, experiments)
- Node.js CLI scripts for mutating routing state (add route, remove route, promote route, clean experiments)
- Region and environment option parsing for NA (us-west-1, us-central1) and EMEA (eu-west-1, europe-west1) cloud zones
- Experiment lifecycle management within routing configuration (clean fully-rolled-out experiments)

### Out of scope

- Runtime API Proxy request processing (owned by `apiProxy`)
- Redis rate-limit counter storage (owned by `apiProxyRedisMemorystore`)
- Client ID service integration runtime calls (owned by `clientIdService`)
- InfluxDB / Telegraf telemetry endpoint runtime calls (owned by `apiProxyTelegraf`)
- Destination VIP infrastructure provisioning

## Domain Context

- **Business domain**: API Gateway / Traffic Routing
- **Platform**: Continuum
- **Upstream consumers**: The `apiProxy` runtime container — configuration files are copied into its image and loaded at startup via the `CONFIG` environment variable pointing to `conf/<env>-<region>/mainConf.json`
- **Downstream dependencies**: Backend service destination hosts referenced in `routingConf.json` (e.g., Redis Memorystore for rate limiting, Client ID Service, BASS service, upstream route destinations)

## Stakeholders

| Role | Description |
|------|-------------|
| API Platform Team (`groupon-api/api-platform-internal`) | Owns routing configuration, reviews all PRs, maintains config_tools scripts |
| Service-owning teams | Submit PRs to add or remove routes for their services in routingConf |
| SRE / Cloud Operations | Deploys configuration artifacts via DeployBot across cloud environments |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language (bundle) | Java | 21 | `.meta/.raptor.yml` archetype: java |
| Language (tools) | Node.js | LTS | `config_tools/package.json` |
| Framework (bundle) | Maven Assembly | via `cmf-java-api` Helm chart 3.92.0 | `.deploy_bot.yml` |
| Framework (tools) | Node.js CLI | — | `config_tools/*.js` |
| Build tool (bundle) | Maven | — | `configAssemblyDescriptor` component |
| Build tool (tools) | npm / Jest | 26.6.3 | `config_tools/package.json` devDependencies |
| Container orchestration | Kubernetes via Helm | cmf-java-api 3.92.0 | `.deploy_bot.yml`, `deploy.sh` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `lodash` | ^4.17.11 | utility | Deep clone, find, filter operations on routing config objects in mutation scripts |
| `underscore` | ^1.9.1 | utility | Filter and pluck route groups and destinations in read scripts |
| `node-getopt` | ^0.3.2 | cli | CLI option parsing for `--region`, `--env`, `--isCloud` arguments |
| `assert` | ^1.4.1 | validation | Input validation guards in mutation scripts |
| `jest` | ^26.6.3 | testing | Unit tests for all config_tools scripts |
| `babel-cli` | ^6.18.0 | build | ES6 transpilation for config_tools scripts |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See `config_tools/package.json` for a full list.
