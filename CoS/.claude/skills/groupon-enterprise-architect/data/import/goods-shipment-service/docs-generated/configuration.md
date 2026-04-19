---
service: "goods-shipment-service"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars, config-files, helm-values]
---

# Configuration

## Overview

The service is configured primarily through a YAML config file supplied at runtime via the `JTIER_RUN_CONFIG` environment variable (e.g., `/var/groupon/jtier/config/cloud/production-us-central1.yml`). The YAML config file is mapped into `GoodsShipmentServiceConfiguration` on startup. Non-secret values are set directly in Helm values files under `.meta/deployment/cloud/components/`. Secret values (credentials, API keys) are injected from a secrets YAML file at `.meta/deployment/cloud/secrets/cloud/<env>.yml`.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `JTIER_RUN_CONFIG` | Path to the runtime YAML config file for this environment/region | yes | — | helm |
| `ELASTIC_APM_VERIFY_SERVER_CERT` | Whether to verify the APM server TLS certificate | no | `true` | helm |
| `MALLOC_ARENA_MAX` | Caps glibc memory arena count to prevent JVM OOM under GCP | no | `4` | helm |

> IMPORTANT: Never document actual secret values. Only document variable names and purposes.

## Feature Flags

These flags are controlled in the runtime YAML config under the `featureFlags` block and enable or disable individual Quartz scheduled jobs at startup.

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| `featureFlags.shipmentRefreshJob` | Enables the Shipment Refresh Job (carrier status polling) | false (must be explicitly enabled) | per-deployment |
| `featureFlags.aftershipCreateShipmentJob` | Enables the Aftership Create Shipments Job | false | per-deployment |
| `featureFlags.untrackedShipmentUpdaterJob` | Enables the Untracked Shipment Updater Job | false | per-deployment |
| `featureFlags.shipmentRejectJob` | Enables the Shipment Reject Job | false | per-deployment |
| `featureFlags.emailNotificationJob` | Enables the Email Notification Job | false | per-deployment |
| `featureFlags.shipmentUpdateMobileNotificationJob` | Enables the Shipment Update Mobile Notification Job | false | per-deployment |
| `featureFlags.authTokenRefreshJob` | Enables the Auth Token Refresh Job | false | per-deployment |

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `.meta/deployment/cloud/components/app/common.yml` | YAML | Helm values for the `app` component — image, ports, logging, HPA, env vars |
| `.meta/deployment/cloud/components/app/production-us-central1.yml` | YAML | Production US Central 1 overrides — replicas (4–15), CPU/memory, APM endpoint |
| `.meta/deployment/cloud/components/app/production-europe-west1.yml` | YAML | Production EU West 1 overrides — replicas (4–15), CPU/memory, APM endpoint |
| `.meta/deployment/cloud/components/app/staging-us-central1.yml` | YAML | Staging US Central 1 overrides — replicas (1–5), CPU/memory |
| `.meta/deployment/cloud/components/worker/common.yml` | YAML | Helm values for the `worker` component — image, JMX port, HPA, logging |
| `.meta/deployment/cloud/components/public/common.yml` | YAML | Helm values for the `public` component |
| `doc/swagger/swagger.yaml` | YAML (Swagger 2.0) | OpenAPI specification |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| Aftership API key (`aftership.apiKey`) | Authenticates requests to the Aftership API | secrets YAML (`.meta/deployment/cloud/secrets/cloud/<env>.yml`) |
| Aftership webhook secret (`aftership.webhookSecret`) | Validates HMAC-SHA256 signatures on inbound Aftership webhooks | secrets YAML |
| Aftership auth token (`aftership.webhookAuthToken`) | Secondary `auth_token` validation for inbound webhooks | secrets YAML |
| UPS API key (`upsApiKey`) | Authenticates legacy UPS API calls | secrets YAML |
| UPS API account (`upsApiAccount`) | UPS account identifier | secrets YAML |
| UPS API password (`upsApiPassword`) | UPS API credential | secrets YAML |
| UPS OAuth client credentials (`ups.*`) | OAuth2 client ID/secret for UPS token API | secrets YAML |
| DHL OAuth client credentials (`dhl.*`) | OAuth2 client ID/secret for DHL token API | secrets YAML |
| FedEx OAuth client credentials (`fedex.*`) | OAuth2 client ID/secret for FedEx token API | secrets YAML |
| Rocketman client ID (`rocketman.clientId`) | API key for Rocketman email service | secrets YAML |
| Event Delivery Service client ID (`eventDeliveryService.clientId`) | API key for mobile push notification service | secrets YAML |
| Allowed client IDs (`allowedClientIds`) | Set of permitted `clientId` values for API auth | secrets YAML |
| MySQL credentials (`mysql.*`) | Database username/password | secrets YAML |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

- **Staging** (`staging-us-central1`, `staging-europe-west1`): 1–5 replicas; CPU request 100m; memory 3Gi–9Gi; APM enabled pointing to the staging Elastic APM endpoint; JTIER_RUN_CONFIG points to staging YAML.
- **Production** (`production-us-central1`, `production-europe-west1`): 4–15 replicas; CPU request 500m; memory 3Gi–9Gi; APM enabled pointing to production Elastic APM endpoint; filebeat volume type `medium`; SOX namespace (`goods-shipment-service-production-sox`).
- All environments set `MALLOC_ARENA_MAX=4` to prevent container OOM kills under GCP.
