---
service: "routing_config_production"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 5
---

# Flows

Process and flow documentation for Routing Config Production.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Config Change and Deployment](config-change-deployment.md) | synchronous | Pull request merged to `master` | Full lifecycle from Flexi rule authoring through CI validation, Docker image build, registry publish, and Kubernetes/on-prem deployment |
| [Route Validation (Pre-Merge)](route-validation-pre-merge.md) | synchronous | Developer runs `bin/check-routes` or CI runs `./gradlew validate` | Manual and automated verification of routing rules before a config change reaches production |
| [Consumer Traffic Routing — Browse and Homepage](consumer-traffic-routing-browse.md) | synchronous | Inbound HTTP/HTTPS request to `/`, `/search`, `/gift`, `/local`, `/goods`, `/landing` | Routing layer applies config to direct browse and homepage traffic to the `pull.production.service` destination |
| [Consumer Traffic Routing — Checkout](consumer-traffic-routing-checkout.md) | synchronous | Inbound HTTPS request to `/cart`, `/checkout/*`, `/receipt/*`, `/deals/:id/confirmation` | Routing layer applies config to direct checkout and cart traffic to `checkout-itier.production.service` |
| [Emergency Deploy](emergency-deploy.md) | synchronous | Manual `./gradlew emergency_deploy` invocation | Bypass of normal safety checks to push a routing config fix directly to on-prem nodes and place a deployment lock |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 5 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

The [Config Change and Deployment](config-change-deployment.md) flow spans this repository, the Jenkins CI system, the `docker-conveyor.groupondev.com` container registry, the `routing-deployment` Kustomize repository, and the Kubernetes routing-service pods in four production regions. It also involves on-premises routing app nodes in `snc1`, `sac1`, and `dub1` data centers for the legacy deploy path.

The consumer traffic routing flows ([Browse](consumer-traffic-routing-browse.md), [Checkout](consumer-traffic-routing-checkout.md)) span the routing service runtime (which reads the config this repo produces) and the downstream application services registered as destinations.
