---
service: "pact-broker"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Quality Assurance / Contract Testing"
platform: "Continuum / GCP"
team: "QA Tribe"
status: active
tech_stack:
  language: "Ruby"
  language_version: ""
  framework: "pact-foundation/pact-broker"
  framework_version: "2.117.1"
  runtime: "Alpine Linux"
  runtime_version: "latest"
  build_tool: "Jenkins"
  package_manager: "Docker image (pact-foundation/pact-broker)"
---

# Pact Broker Overview

## Purpose

Pact Broker is Groupon's centralized contract registry for consumer-driven contract testing. It stores pact files (contracts) published by consumer services, records verification results from provider services, and coordinates webhook callbacks to CI systems to gate deployments. The service enables Groupon engineering teams to safely evolve service APIs by proving compatibility before deployment.

## Scope

### In scope

- Hosting and persisting pact contract documents published by consumer services
- Recording and exposing provider verification results against stored pacts
- Serving the Pact Broker web UI and REST API on port 9292
- Executing configurable outbound webhooks triggered by pact lifecycle events (publish, verify, etc.)
- Managing pacticipant (consumer/provider) registrations and version metadata
- Enforcing webhook host allow-listing (`PACT_BROKER_WEBHOOK_HOST_WHITELIST`)

### Out of scope

- Running consumer or provider test suites (handled by individual service CI pipelines)
- Generating pact contract files (responsibility of consumer services)
- Storing secrets beyond what is injected via environment variables
- Contract testing for non-Groupon external APIs

## Domain Context

- **Business domain**: Quality Assurance / Contract Testing
- **Platform**: Continuum (GCP/Kubernetes)
- **Upstream consumers**: Consumer and provider services across Groupon that publish pacts or post verification results via the Pact Broker HTTP API; CI/CD pipelines using `can-i-deploy`
- **Downstream dependencies**: PostgreSQL database (`continuumPactBrokerPostgres`), GitHub Enterprise (`githubEnterprise`) for internal webhook callbacks, GitHub.com (`githubDotCom`) for public webhook callbacks

## Stakeholders

| Role | Description |
|------|-------------|
| QA Tribe | Owns and operates the Pact Broker infrastructure |
| Service teams | Publish pacts and verification results via the API |
| Platform/DevOps | Manages GCP/Kubernetes deployment and secrets |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Ruby | Bundled with pact-broker image | `Dockerfile` (FROM alpine:latest + pact-foundation image) |
| Framework | pact-foundation/pact-broker | 2.117.1 | `.meta/deployment/cloud/components/app/staging-us-central1.yml` (`appVersion: 2.135.0-pactbroker2.117.1`) |
| Runtime | Alpine Linux | latest | `Dockerfile` |
| Container image | docker-conveyor.groupondev.com/pact-foundation/pact-broker | 2.135.0-pactbroker2.117.1 | `staging-us-central1.yml` |
| Build tool | Jenkins | java-pipeline-dsl@latest-2 | `Jenkinsfile` |
| Orchestration | Kubernetes (GCP) | Helm 3 chart: cmf-generic-api 3.95.1 | `.meta/deployment/cloud/scripts/deploy.sh` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| pact-foundation/pact-broker | 2.117.1 | http-framework | Core contract registry application (Rack/Sinatra) |
| Rack / Sinatra | Bundled | http-framework | HTTP layer serving API and web UI endpoints |
| ActiveRecord | Bundled | orm | Database access layer for PostgreSQL |
| PostgreSQL adapter | Bundled | db-client | Connection to `PACT_BROKER_DATABASE_*` |
| Pact Broker Webhooks | Bundled | scheduling | Outbound webhook execution engine |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. The upstream pact-foundation/pact-broker image bundles all Ruby gems.
