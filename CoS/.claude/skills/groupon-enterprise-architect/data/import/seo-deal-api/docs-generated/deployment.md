---
service: "seo-deal-api"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [staging, production]
---

# Deployment

## Overview

SEO Deal API is deployed as a JVM-based Dropwizard service within Groupon's Continuum Platform on GCP. The service is registered under the internal service discovery hostnames `seo-deal-api.staging.service` (staging) and `seo-deal-api.production.service` (production), which resolve to GCP-internal endpoints. Logs are shipped to Elasticsearch via Logstash using the `seo_deal_api` sourcetype. The service is present in both US and EU logging clusters, indicating multi-region deployment.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker (inferred from JTier conventions) | Not specified in available source evidence |
| Orchestration | Kubernetes (inferred from GCP/JTier deployment pattern) | Not specified in available source evidence |
| Load balancer | Internal GCP load balancer | Accessed via `seo-deal-api.production.service` DNS |
| CDN | Not applicable | Internal service; not fronted by CDN |
| Logging | Elasticsearch / Logstash | Sourcetype: `seo_deal_api`; JSON log format (ISO8601 timestamps) |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| Staging | Pre-production testing and integration | us-central1 (GCP) | `http://seo-deal-api.staging.service` |
| Production (NA) | Live production traffic — North America | us-central1 (GCP) | `http://seo-deal-api.production.service` |
| Production (EU) | Live production traffic — Europe | EU GCP region | Evidenced by EU logging cluster inventory (`logging-prod-eu-data01`) |

## CI/CD Pipeline

- **Tool**: Not specified in available source evidence (Jenkins or GitHub Actions inferred from JTier/Groupon conventions)
- **Config**: Not specified in available source evidence
- **Trigger**: Not specified in available source evidence

### Pipeline Stages

> Deployment configuration managed externally. The following are inferred from the Groupon JTier deployment pattern.

1. Build: Compile Java source, run unit tests, package JAR
2. Test: Integration and contract tests against staging dependencies
3. Publish: Push Docker image or artifact to registry
4. Deploy staging: Roll out to `seo-deal-api.staging.service`
5. Deploy production: Roll out to `seo-deal-api.production.service` (NA and EU)

## Scaling

> No evidence found in codebase.

Scaling configuration is managed externally and not discoverable from the available source archive.

## Resource Requirements

> No evidence found in codebase.

Resource requests and limits are managed externally and not discoverable from the available source archive.
