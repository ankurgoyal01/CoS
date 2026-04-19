---
service: "optimize-suite"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: false
orchestration: "npm-package"
environments: [staging, uat, production]
---

# Deployment

## Overview

Optimize Suite is not deployed as a server-side service. It is an npm library published to Groupon's internal npm registry (`https://npm.groupondev.com`) and delivered to browsers through the Layout Service. Releasing a new version requires publishing to npm via the `nlm` release tool on the `main` branch, then opening a pull request to Layout Service to bump the `optimize-suite` dependency version. There is no Docker container, Kubernetes deployment, or server infrastructure owned by this library.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | None | Browser-side JavaScript library; no Docker container |
| Build | Webpack 5 via `@grpn/itier-webpack` | Produces `build/optimize-suite.js`, `build/optimize-suite-standalone.js`, `build/inspector.js` |
| Registry | npm (internal Groupon) | Published to `https://npm.groupondev.com` |
| Delivery | Layout Service | Layout Service bundles `optimize-suite.js` into the I-Tier page layout script |
| CDN | Managed by Layout Service / Akamai | optimize-suite reaches browsers as part of the Layout Service asset bundle |
| CI | Cloud Jenkins | `https://cloud-jenkins.groupondev.com/job/optimize/job/optimize-suite/` |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| staging | Pre-production validation | snc1 | `http://birdcage-staging.snc1.` (Birdcage config endpoint) |
| uat | User acceptance testing | snc1 | `http://birdcage-uat.snc1.` |
| production | Live traffic | snc1, dub1 | `http://birdcage.snc1.` / `http://birdcage.dub1.` |

> Optimize Suite itself does not have dedicated deployed URLs. It runs in browsers as part of host applications. The URLs above are for the Birdcage experiment configuration service that Optimize Suite depends on indirectly.

## CI/CD Pipeline

- **Tool**: Jenkins (Cloud Jenkins `conveyor@latest-5` library)
- **Config**: `Jenkinsfile`
- **Trigger**: Pull requests to `main`; push to `main`

### Pipeline Stages

1. **tests (parallel)**: Runs `npm cit` (install + test) inside Docker containers for both Node.js 14 (`alpine-node14.16.1-test`) and Node.js 16 (`alpine-node16.1.0-test`) to validate cross-version compatibility
2. **publish**: Runs only on `main` branch; executes `npm ci` + `npx nlm release --commit` inside `alpine-node16.1.0-build` Docker image to bump version, tag, and publish to internal npm registry

### Release Process

1. Merge changes to `main` branch following conventional commit format (enforced by `nlm`)
2. Jenkins pipeline runs `nlm release --commit`, which: computes the next semver from commit messages, updates `package.json` version, generates `CHANGELOG.md` entry, creates a GitHub tag, and publishes to `https://npm.groupondev.com`
3. Open a pull request to [Layout Service](https://github.groupondev.com/front-end/layout-service) bumping `optimize-suite` in its `package.json`
4. Layout Service deploys the updated bundle through its own pipeline

## Scaling

> Not applicable. Optimize Suite is a browser-side JavaScript bundle. Scaling is handled by the CDN and Layout Service infrastructure.

## Resource Requirements

> Not applicable. No server-side resources are allocated for this library.
