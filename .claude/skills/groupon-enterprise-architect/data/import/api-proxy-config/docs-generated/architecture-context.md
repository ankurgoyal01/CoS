---
service: "api-proxy-config"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumApiProxyConfigBundle", "continuumApiProxyConfigTools"]
---

# Architecture Context

## System Context

`api-proxy-config` lives within the `continuumSystem` (Continuum Platform) as a configuration-first service. It does not serve live traffic directly; instead, it acts as the authoritative source of routing truth for the `apiProxy` runtime. Operators and CI pipelines use the `continuumApiProxyConfigTools` CLI to read and mutate JSON configuration files stored in the repository. The `continuumApiProxyConfigBundle` packages those files into a versioned artifact that is copied into the `apiProxy` container image at deploy time. The `apiProxy` loads the bundle on startup and uses it to route inbound HTTP/HTTPS traffic to registered backend destination services.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| API Proxy Config Bundle | `continuumApiProxyConfigBundle` | Configuration | JSON Configuration, Maven Assembly | cmf-java-api 3.92.0 | Versioned configuration bundle (proxyConf, routingConf, clientConf, mainConf) packaged and copied into the API Proxy runtime image |
| API Proxy Config Tools CLI | `continuumApiProxyConfigTools` | Tooling | Node.js | LTS | Node.js command-line scripts used by operators and CI to inspect and mutate routing configuration files |

## Components by Container

### API Proxy Config Bundle (`continuumApiProxyConfigBundle`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Routing Configuration Artifacts (`routingConfigArtifacts`) | Environment-scoped `routingConf.json`, `proxyConf.json`, `clientConf.json`, and `mainConf.json` files under `src/main/conf/` | JSON |
| Java Routing Config Model (`javaRoutingConfigModel`) | Typed Java model classes for route groups, routes, destinations, experiments, and realms | Java |
| JSON Utility Layer (`configJsonUtils`) | Shared JSON parsing and helper utilities used by tests and config model handling | Java |
| Assembly Packaging Descriptor (`configAssemblyDescriptor`) | Maven assembly descriptor that packages `src/main/conf/` into a distributable config artifact | Maven Assembly |

### API Proxy Config Tools CLI (`continuumApiProxyConfigTools`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Region and Environment Option Parser (`regionEnvOptionParser`) | CLI option parser resolving `--region`, `--env`, and `--isCloud` inputs for config_tools scripts | Node.js |
| Routing Config File Resolver (`routingConfigFileResolver`) | Builds concrete `routingConf.json` file paths across regions, environments, and zones; resolves previous-environment paths for promotion | Node.js |
| Route Read Scripts (`routeReadScripts`) | Read-only scripts that enumerate routes, route groups, destinations, and experiments from `routingConf.json` | Node.js |
| Route Mutation Scripts (`routeMutationScripts`) | Scripts that add, remove, clean, and promote routes by mutating `routingConf.json` files | Node.js |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumApiProxyConfigTools` | `continuumApiProxyConfigBundle` | Reads and updates configuration artifacts via config_tools scripts | File I/O (JSON) |
| `continuumApiProxyConfigBundle` | `apiProxy` | Provides runtime configuration files copied into `/app/conf` | File artifact copy |
| `continuumApiProxyConfigBundle` | `apiProxyRedisMemorystore_2f3a9c` | Defines Redis host/port used for rate-limit counters (stub — not in central model) | Configuration reference |
| `continuumApiProxyConfigBundle` | `clientIdService_94c1e2` | Defines `clientServiceConfig`/`clientServiceConfigV3` endpoints (stub — not in central model) | Configuration reference |
| `continuumApiProxyConfigBundle` | `bassService_1d8b77` | Defines `bemodConfig` upstream endpoint (stub — not in central model) | Configuration reference |
| `continuumApiProxyConfigBundle` | `apiProxyTelegraf_6a41f0` | Defines InfluxDB telemetry endpoint via `influxDbOptions` (stub — not in central model) | Configuration reference |
| `continuumApiProxyConfigBundle` | `apiProxyRouteDestinations_7b2d11` | Defines destination hosts and route-group mappings (stub — not in central model) | Configuration reference |

## Architecture Diagram References

- System context: `contexts-continuumSystem`
- Container: `containers-continuumApiProxyConfig`
- Component (bundle): `components-api-proxy-config-bundle`
- Component (tools): `components-api-proxy-config-tools`
- Dynamic view (promote route flow): `dynamic-promote-route-request-flow`
