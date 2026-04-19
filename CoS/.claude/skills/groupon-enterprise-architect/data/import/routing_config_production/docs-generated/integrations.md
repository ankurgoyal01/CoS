---
service: "routing_config_production"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 2
internal_count: 14
---

# Integrations

## Overview

`routing_config_production` itself does not make runtime service calls. Its integrations are CI/CD-time and deployment-time: the Jenkins pipeline pulls from GitHub Enterprise, publishes to an internal Docker registry, and commits to a deployment Git repository. At deploy time, Gradle SSH tasks push config bundles to on-premises app nodes and trigger a hot-reload call. The Flexi DSL config it produces references ~14 distinct internal Groupon application services as routing destinations. These are not runtime dependencies of this repo but are the downstream recipients of traffic routed by the config it generates.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| `github.groupondev.com` (GitHub Enterprise) | HTTPS / Git | Source control, PR comments posted after deploy | yes | — |
| `nexus-dev.snc1` (Nexus artifact registry) | HTTP (Maven) | Resolves Gradle build dependencies (`grout-tools-gradle`, `gradle-ssh-plugin`) | yes | — |

### GitHub Enterprise Detail

- **Protocol**: HTTPS (Git clone, REST API for PR comments)
- **Base URL / SDK**: `https://github.snc1/api/v3/repos/routing/routing-config-production/issues/<pr_id>/comments`
- **Auth**: OAuth token (routing-deploy GHE user, token embedded in `build.gradle`)
- **Purpose**: Source repository; also receives automated deploy-confirmation comments on merged pull requests
- **Failure mode**: PR comment step fails silently (non-blocking); source access failure would prevent CI from running
- **Circuit breaker**: No

### Nexus Maven Repository Detail

- **Protocol**: HTTP (Maven)
- **Base URL / SDK**: `http://nexus-dev.snc1/content/groups/public` and `http://nexus-dev.snc1/content/groups/public-snapshots`
- **Auth**: None (internal network access)
- **Purpose**: Provides `com.groupon.grout:grout-tools-gradle:1.4.2` and `org.hidetake:gradle-ssh-plugin:1.1.2` during Gradle build
- **Failure mode**: Gradle build fails; CI pipeline halts
- **Circuit breaker**: No

## Internal Dependencies

These are the upstream application services registered as routing destinations in the Flexi DSL. They receive production traffic when the routing rules match. They are not called by this repository at CI time; they are called by the routing service runtime using the config this repo produces.

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| `checkout-itier.production.service:443` | HTTPS | Handles `/cart`, `/checkout/*`, `/receipt/:order_id`, `/deals/:id/confirmation` routes | — |
| `pull.production.service:443` | HTTPS | Handles homepage (`/`), `/search`, `/gift`, `/local`, `/goods`, `/landing`, browse routes | — |
| `deal.production.service:443` | HTTPS | Handles `/deals/:deal_permalink`, `/deals/*` (deal page), `/wishlist` routes | — |
| `next-pwa-app.production.service:443` | HTTPS | Handles MBNXT routes: `/_next`, `/api/graphql`, `/api/auth`, `/mobilenextapi/*`, `/llm`, `/filters/:filter_id` | — |
| `user-sessions.production.service:443` | HTTPS | Handles `/login`, `/signup`, `/logout`, `/user_sessions`, `/password_reset`, `/register`, OAuth callbacks | — |
| `mygroupons.production.service:443` | HTTPS | Handles `/mygroupons`, `/mystuff`, `/myaccount`, `/myprofile`, `/mybucks`, `/track_order/*` | — |
| `merchant-center-auth.production.service:443` | HTTPS | Handles `/merchant/center/login`, `/merchant/center/logout`, password reset, and account routes | — |
| `mx-merchant-api.production.service:443` | HTTPS | Handles `/merchant/admin/api/*` (with separate 1s timeout for metrics/traces/logs) | — |
| `merchant-center-web--bucket.production.service` | HTTP | Handles `/merchant/admin` (NA and EMEA; GCP load balancer backend) | — |
| `raf-ita.production.service:80` | HTTP | Handles `/visitor_referral/*`, refer-a-friend assets, and deal referral routes | — |
| `seo-local-proxy--nginx.production.service:443` | HTTPS | Handles `/sitemaps`, `/sitemap.xml`, `/robots.txt` | — |
| `pwa.production.service:80` | HTTP | Handles legacy PWA routes (Facebook session, static assets, legacy `/deals/*` admin paths) | — |
| `tls_conveyor_customer_support_itier` | HTTPS | Handles `/faq/*` (help center, FAQ, dynamic support routes) | — |
| `docker-conveyor.groupondev.com` | HTTPS (Docker) | Container registry target for publishing versioned routing config images | — |

## Consumed By

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| Routing service nodes (`routing-app[1-10].snc1`, `routing-app[1-10].sac1`, `routing-app[1-10].dub1`) | SSH (deploy) / Docker (runtime) | Load compiled routing config bundle or Docker image to apply URL routing rules |
| Kubernetes routing deployments (`routing-service-production-us-west-1`, `routing-service-production-eu-west-1`, `routing-service-production-us-central1`, `routing-service-production-europe-west1`) | Docker / Kustomize | Reference versioned Docker image for cloud-based routing service pods |

> Upstream consumers are tracked in the central architecture model.

## Dependency Health

The CI pipeline performs a `./gradlew validate` step (via `grout`) that fails fast if any Flexi DSL syntax is invalid. The `bin/check-routes` script allows manual evaluation of specific URLs against the compiled config before merging. There are no runtime circuit breakers; the routing config is static once deployed and relies on the routing service's own health checks for availability.
