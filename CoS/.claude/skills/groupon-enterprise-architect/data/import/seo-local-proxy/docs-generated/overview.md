---
service: "seo-local-proxy"
title: Overview
generated: "2026-03-03"
type: overview
domain: "SEO"
platform: "Continuum"
team: "SEO (computational-seo@groupon.com)"
status: active
tech_stack:
  language: "Node.js"
  language_version: "12.6"
  framework: "groupon-site-maps"
  framework_version: ""
  runtime: "Kubernetes CronJob / Nginx"
  runtime_version: ""
  build_tool: "Jenkins / Helm 3 / krane"
  package_manager: "npm"
---

# SEO Local Proxy Overview

## Purpose

SEO Local Proxy generates XML sitemaps and robots.txt files for all Groupon brands and country TLDs, publishes those files to AWS S3, and serves them via an Nginx reverse proxy. It exists to ensure that search engine crawlers receive up-to-date, correctly structured sitemaps and crawl directives for every Groupon storefront. Traffic is routed to this service from the `routing-service` whenever `/robots.txt`, `/sitemap.xml`, or `/sitemaps/*` URLs are requested.

## Scope

### In scope

- Scheduled daily generation of XML sitemaps (index and per-channel `.xml.gz` files) for US, Canada, EMEA, and APAC countries.
- Scheduled daily generation of `robots.txt` files per country and brand.
- Upload of generated artefacts to regional AWS S3 buckets.
- Nginx-based serving of sitemaps and robots.txt by resolving the correct S3 path from the `X-Forwarded-Host` header.
- Brand-aware routing: `https` (Groupon), `livingsocial`, `speedgroupon`.
- Country-aware path construction for 20+ supported country codes.
- EMEA CityDeals Archive URL redirects to SEO Platform ITA URLs.
- Manual one-off cron job execution for emergency re-generation.

### Out of scope

- Generation of product or deal page content (handled by upstream commerce services).
- Routing of non-SEO traffic (handled by `routing-service`).
- Sitemap generator library internals (owned by the `groupon-site-maps` and `site-mapper-internal` repositories).
- Schema validation of API requests/responses (schema: disabled per `.service.yml`).

## Domain Context

- **Business domain**: SEO
- **Platform**: Continuum
- **Upstream consumers**: `routing-service` (routes `/robots.txt`, `/sitemap.xml`, `/sitemaps/*` to `continuumSeoLocalProxyNginx`)
- **Downstream dependencies**: AWS S3 (file storage), `groupon-site-maps` Node.js scripts (sitemap generation), Apache Hive / Hadoop (data source for sitemap content), GCP Cloud Storage (alternative bucket in GCP regions)

## Stakeholders

| Role | Description |
|------|-------------|
| Team | SEO team (computational-seo@groupon.com), owner: vpande |
| Members | jahill, rlynch, sutekar, joeliu |
| On-call | seo-local-proxy@groupon.pagerduty.com (PagerDuty: POQLFLJ) |
| Slack/GChat | Space ID: AAAANlivtII |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language (cron job) | Node.js | 12.6 | `.ci/Dockerfile` FROM node:12.6 |
| Language (deploy tooling) | Ruby | 2.3.3 | `.ruby-version` |
| Runtime (serving) | Nginx + nginx-mod-http-lua | alpine-based | `docker/nginx/Dockerfile` |
| Container image (nginx) | docker-conveyor.groupondev.com/seo/seo-local-proxy-nginx | 0.0.03 | `.meta/deployment/cloud/components/nginx/common.yml` |
| Container image (cron job) | docker-conveyor.groupondev.com/seo/seo-local-proxy | DEPLOYBOT_PARSED_VERSION | `.meta/deployment/cloud/components/cron-job/common.yml` |
| Build tool | Jenkins (cloud-jenkins) + Helm 3 + krane | Helm chart v3.89.0 | `Jenkinsfile`, `.meta/deployment/cloud/scripts/deploy.sh` |
| Deploy tool | Deploybot | v2.8.5 | `.deploy_bot.yml` deployment_image |
| Package manager (Node.js) | npm | — | `.ci/Dockerfile` npm config |
| Package manager (Ruby) | Bundler / Capistrano | capistrano >=3.0.0 | `Gemfile` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| groupon-site-maps | (git-cloned at build) | scheduling | Generates sitemaps and robots.txt; orchestrates upload scripts |
| site-mapper-internal | (npm dependency of groupon-site-maps) | serialization | Core sitemap XML generation library used by groupon-site-maps |
| capistrano | >=3.0.0 | scheduling | Legacy deployment automation (on-prem) |
| capistrano-multiconfig | >=3.0.3 | scheduling | Multi-environment Capistrano configuration |
| rspec | (test group) | testing | Ruby test framework for proxy and sitemap validation scripts |
| nokogiri | (test group) | testing | XML parsing for sitemap validation specs |
| addressable | (test group) | testing | URL parsing in verification scripts |
| AWS CLI v2 | (installed in Dockerfile) | db-client | S3 bucket upload and inspection |
| Google Cloud SDK | (installed in Dockerfile) | db-client | GCP bucket operations in GCP-hosted environments |
| Apache Hadoop | 2.7.4 | db-client | Data sourcing for sitemap content generation |
| Apache Hive | 1.2.2 | db-client | Query layer over Hadoop data for sitemap sources |
| OpenJDK | 11.0.2 | runtime | JVM required by Hadoop and Hive |
| nginx-mod-http-lua | alpine | http-framework | Lua scripting support in Nginx for dynamic header handling |
