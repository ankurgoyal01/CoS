---
service: "routing_config_production"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Routing / Infrastructure"
platform: "Continuum"
team: "Routing Service Devs"
status: active
tech_stack:
  language: "Groovy / Python"
  language_version: "Groovy (Gradle 2.2.1) / Python 2.7"
  framework: "Grout"
  framework_version: "1.4.2"
  runtime: "JVM"
  runtime_version: "1.8.0_31"
  build_tool: "Gradle 2.2.1"
  package_manager: "Pipenv (Python deps)"
---

# Routing Config Production Overview

## Purpose

`routing_config_production` is the version-controlled, production routing configuration for Groupon's global routing infrastructure. It defines, in the Flexi DSL, every URL pattern-to-backend-service mapping served by Groupon's routing layer across all supported countries and application domains. The repository is validated on every CI run and deployed as a Docker image that is consumed by the routing service nodes in US and EU data-center regions.

## Scope

### In scope

- All production URL path-to-destination routing rules expressed in Flexi DSL files under `src/applications/`
- Jinja2 template rendering of per-application Flexi files to support on-premises vs. cloud environment differences
- Validation of compiled routing config via the `grout` Gradle plugin and `check-routes` CLI tool
- Docker image packaging of the compiled config (`/var/conf`) for consumption by the routing service
- CI/CD pipeline orchestration via Jenkins: render templates, validate, build image, publish to container registry, and trigger deployment-repo tagging
- Deployment coordination via SSH-based Gradle tasks to routing app nodes in `snc1`, `sac1`, and `dub1` data centers (legacy on-prem path) and Kustomize-based overlay updates for Kubernetes in `us-west-1`, `eu-west-1`, `us-central1`, and `europe-west1` (cloud path)
- Per-country and per-region route group definitions covering ~65 distinct application domains

### Out of scope

- The routing service runtime itself (handled by a separate service)
- Staging/preview routing rules (managed in a companion `routing-config-staging` repository)
- Per-service application logic or backend implementation
- DNS configuration and TLS certificate management

## Domain Context

- **Business domain**: Routing / Infrastructure
- **Platform**: Continuum
- **Upstream consumers**: Groupon's routing service nodes (load balancers / reverse-proxies) that load this config at startup or via hot-reload (`POST localhost:9001/config/routes/reload`)
- **Downstream dependencies**: All upstream application services referenced as routing destinations (e.g., `checkout-itier.production.service`, `pull.production.service`, `deal.production.service`, `next-pwa-app.production.service`, `user-sessions.production.service`, `mygroupons.production.service`, `merchant-center-auth.production.service`, `mx-merchant-api.production.service`, `raf-ita.production.service`, `seo-local-proxy--nginx.production.service`, `pwa.production.service`)

## Stakeholders

| Role | Description |
|------|-------------|
| Routing Service Devs | Team that owns and maintains this repository; contact: routing-service-devs@groupon.com |
| Application teams | Teams whose services are registered as routing destinations; must request routing changes via PR |
| Platform / SRE | Relies on correct routing config for production traffic management across all Groupon regions |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language (build) | Groovy (Gradle DSL) | Gradle 2.2.1 | `gradle/wrapper/gradle-wrapper.properties` |
| Language (template rendering) | Python | 2.7 | `Pipfile` |
| Framework (DSL validation) | Grout (`com.groupon.grout:grout-tools-gradle`) | 1.4.2 | `build.gradle` |
| Framework (templating) | Jinja2 | 2.10 | `Pipfile` |
| Runtime (build) | JVM | 1.8.0_31 | `.ci.yml` |
| Build tool | Gradle | 2.2.1 | `gradle/wrapper/gradle-wrapper.properties` |
| Package manager (Python) | Pipenv | — | `Pipfile` / `Pipfile.lock` |
| Container base (config artifact) | BusyBox | 1.29.1 | `Dockerfile` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `com.groupon.grout:grout-tools-gradle` | 1.4.2 | validation | Compiles and validates Flexi DSL routing config |
| `org.hidetake:gradle-ssh-plugin` | 1.1.2 | deployment | SSH-based deployment of routing config bundles to on-prem app nodes |
| `jinja2` | 2.10 | templating | Renders `.flexi` templates to environment-specific config files before validation |
| `groupon-api/api-proxy-cli` | latest | validation | Docker-based CLI tool used by `bin/check-routes` to evaluate routing rules against test URLs |
| `bitlayer/kustomize` | v1.0.11 | deployment | Updates Kubernetes overlay image tags in the deployment repository |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
