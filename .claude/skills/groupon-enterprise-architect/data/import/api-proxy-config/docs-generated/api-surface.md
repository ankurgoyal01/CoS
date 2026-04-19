---
service: "api-proxy-config"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: ["cli", "file-artifact"]
auth_mechanisms: []
---

# API Surface

## Overview

`api-proxy-config` does not expose any HTTP API endpoints. Its interface is the set of Node.js CLI scripts in `config_tools/` invoked by operators and CI pipelines, and the JSON artifact files under `src/main/conf/` consumed by the `apiProxy` runtime at startup. All CLI scripts accept `--region`, `--env`, and optionally `--isCloud` arguments to target the correct environment-scoped `routingConf.json` file.

## CLI Interface (config_tools)

Each operation comes in two forms: a core module (`script.js`) and a CLI wrapper (`scriptCli.js`) that parses command-line arguments via `node-getopt` and calls the core module.

### Read Operations

| Script | Purpose | Required Arguments |
|--------|---------|-------------------|
| `getRoutesCli.js` | List all routes in a route group for a given destination | `--env`, `--region`, `--destination`, `--routeGroup`, `[--isCloud]` |
| `getRouteGroupsCli.js` | List all route group IDs for a given destination | `--env`, `--region`, `--destination`, `[--isCloud]` |
| `getDestinationsCli.js` | List all destination names and hosts | `--env`, `--region`, `[--isCloud]` |
| `getExperimentsCli.js` | List all active experiments in a routing config | `--env`, `--region`, `[--isCloud]` |
| `getRouteGroupDestinationsCli.js` | Get destinations for a specific route group | `--env`, `--region`, `--routeGroup`, `[--isCloud]` |
| `doesDestinationVipExistCli.js` | Check if a destination VIP exists in the config | `--env`, `--region`, `--vip`, `[--isCloud]` |
| `getDestinationPreviewCli.js` | Preview a destination entry from routing config | `--env`, `--region`, `--destination`, `[--isCloud]` |

### Mutation Operations

| Script | Purpose | Required Arguments |
|--------|---------|-------------------|
| `removeRoutesCli.js` | Remove one or more routes from a route group | `--env`, `--region`, `--routeGroup`, route paths/methods, `[--isCloud]` |
| `cleanExperimentsCli.js` | Remove fully-rolled-out experiments from routing config | `--env`, `--region`, `--exp=<experimentId\|All>`, `[--isCloud]` |
| `addNewRouteRequest.js` | Add a new route and destination to routing config | JSON request object (programmatic — no CLI wrapper yet) |
| `promoteRouteRequest.js` | Promote a route from a previous environment to the target environment | JSON request object (programmatic — no CLI wrapper yet) |

### CLI Argument Conventions

| Argument | Values | Description |
|----------|--------|-------------|
| `--env` | `production`, `staging`, `uat` | Target environment |
| `--region` | `na`, `emea` | Geographic region (North America or EMEA) |
| `--isCloud` | `true` / `false` | Selects cloud zone paths (e.g., `production-us-west-1/`) vs. data center paths (e.g., `production_snc1/`) |
| `--exp` | `<experimentId>` or `All` | Experiment ID to clean; `All` cleans all fully-rolled-out (`startBucket=0`, `endBucket=999`, `type=rollout`) experiments |

### Example Invocations

```bash
# List all routes for a route group in NA production
node ./getRoutesCli.js --env=production --region=na --isCloud=true

# Remove a specific route
node ./removeRoutesCli.js --env=production --region=na --isCloud=true

# Clean all fully-rolled-out experiments in EMEA production
node ./cleanExperimentsCli.js --env=production --region=emea --exp=All --isCloud=true
```

## Configuration Artifact Files

These JSON files are the primary output consumed by the `apiProxy` runtime. They are not HTTP endpoints but are listed here as the definitive interface surface between this repository and downstream consumers.

| File Path Pattern | Purpose |
|-------------------|---------|
| `src/main/conf/<env>-<cloudRegion>/mainConf.json` | Top-level API Proxy configuration; selected at startup via `CONFIG` env var |
| `src/main/conf/<env>-<cloudRegion>/routingConf.json` | Routing rules: realms, route groups, routes, destinations, experiment layers |
| `src/main/conf/<env>-<cloudRegion>/proxyConf.json` | Proxy-level configuration |
| `src/main/conf/<env>-<cloudRegion>/clientConf.json` | Client service endpoint configuration |

### routingConf.json Schema (key fields)

```json
{
  "realms": [{ "name": "us_api", "routeGroups": ["externalGroup"] }],
  "routeGroups": [{ "name": "...", "id": "...", "destination": "...", "routes": [...] }],
  "destinations": [{ "name": "...", "type": "static", "host": "...", "port": 80, ... }],
  "layers": [{ "id": "...", "experiments": [...] }]
}
```

## Request/Response Patterns

### Common headers

> Not applicable. This service exposes no HTTP endpoints. CLI scripts operate on local JSON files.

### Error format

CLI scripts use Node.js `assert` for input validation and throw descriptive error strings. Examples:
- `"Existing route(s): [...] found"` — thrown when a route being added already exists
- `"Couldn't find the route promoter case: ..."` — thrown for unknown promote case values
- `"Two routes with same path: ... and different exact values found"` — thrown during method consolidation

### Pagination

> Not applicable.

## Rate Limits

> No rate limiting configured. This is a CLI tooling and configuration repository, not a live HTTP service.

## Versioning

Configuration artifacts are versioned via Git tags. The `apiProxy` runtime image is built referencing a specific artifact version. There is no URL-based API versioning.

## OpenAPI / Schema References

No OpenAPI spec or proto files exist. The routing configuration schema is implicitly defined by:
- Java model classes in `continuumApiProxyConfigBundle` (`javaRoutingConfigModel` component)
- Shape of `routingConf.json` files under `config_tools/test/conf/` (test fixtures)
