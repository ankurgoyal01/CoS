---
service: "api-proxy-config"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 5
---

# Flows

Process and flow documentation for API Proxy Config.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Promote Route Request](promote-route-request.md) | batch | Manual operator invocation or CI pipeline | Promotes a route configuration from a previous environment into the target environment's `routingConf.json` using the `promoteRouteRequest.js` script |
| [Add New Route](add-new-route.md) | batch | Manual operator invocation | Adds a new destination and route group into a target environment's `routingConf.json` using `addNewRouteRequest.js` |
| [Remove Routes](remove-routes.md) | batch | Manual operator invocation | Removes one or more routes from a route group in the target environment's `routingConf.json` using `removeRoutesCli.js` |
| [Clean Experiments](clean-experiments.md) | batch | Manual operator invocation after experiment rollout | Removes fully-rolled-out A/B experiment entries and their associated unused destinations from `routingConf.json` |
| [Configuration Bundle Deploy](config-bundle-deploy.md) | batch | DeployBot Git tag trigger | Packages the environment-scoped JSON configuration files into a versioned Docker image and deploys it to the target Kubernetes environment |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 0 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 5 |

## Cross-Service Flows

The `promote-route-request` flow is documented as a dynamic architecture view in the Structurizr model:
- Architecture dynamic view: `dynamic-promote-route-request-flow` (defined in `architecture/views/dynamics/promote-route-request.dsl`)

The `config-bundle-deploy` flow spans `continuumApiProxyConfigBundle` and the `apiProxy` runtime — the configuration artifact produced by this repository is the direct runtime input to the API Proxy container.
