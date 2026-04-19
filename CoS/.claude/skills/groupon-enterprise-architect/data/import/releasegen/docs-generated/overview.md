---
service: "releasegen"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Release Engineering"
platform: "Continuum"
team: "release-engineering"
status: active
tech_stack:
  language: "Java"
  language_version: "17"
  framework: "Dropwizard"
  framework_version: "managed via jtier-service-pom 5.14.0"
  runtime: "JVM"
  runtime_version: "17 (Eclipse Temurin)"
  build_tool: "Maven"
  package_manager: "Maven"
---

# Releasegen Overview

## Purpose

Releasegen is a Dropwizard service that automatically synchronizes deployment state across Deploybot, GitHub Releases, and JIRA. When a production deployment occurs for any Releasebot-enrolled repository, Releasegen creates or updates a GitHub release tagged to the deployed SHA, generates release notes from the PR history since the last release, and links all referenced JIRA tickets to that release. For non-production deployments, it records GitHub Deployment statuses on the relevant branch or PR without creating a full release.

## Scope

### In scope

- Detecting production and non-production deployments via Deploybot polling and direct API calls
- Creating and updating GitHub releases for production-deployed SHAs
- Auto-generating release notes from GitHub PR history between the previous release and the current SHA
- Rewriting JIRA ticket references in release notes as hyperlinks
- Creating GitHub Deployment and DeploymentStatus records to populate the Releases and Environments tabs
- Annotating GitHub release bodies with per-environment deployment status
- Labeling JIRA RE-project tickets with `releasegen` to track processing
- Adding remote links from JIRA tickets to the associated GitHub release
- Providing an admin UI and API to manually reprocess historical deployments
- Running a background worker that polls JIRA for unprocessed RE-project tickets and publishes the corresponding deployments

### Out of scope

- Initiating or authorizing deployments (owned by Deploybot / Conveyor)
- Creating JIRA RE tickets (owned by Deploybot)
- Managing the CI/CD pipeline itself (owned by Jenkins / jtier pipeline)
- Merge gating or approval workflows (owned by mergebot)

## Domain Context

- **Business domain**: Release Engineering
- **Platform**: Continuum
- **Upstream consumers**: Deploybot (triggers deployment events); operators via the admin UI; any service that has installed the Releasebot GitHub App
- **Downstream dependencies**: Deploybot REST API, GitHub REST API (via `github-api` library and direct REST calls), JIRA REST API

## Stakeholders

| Role | Description |
|------|-------------|
| Release Engineering team | Service owners; receive Slack notifications on deployment events |
| Service developers | Install the Releasebot GitHub App in their repos to opt in to automated release notes |
| Product managers | Consume JIRA-linked release notes to understand what shipped to production |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 17 | `pom.xml` — `project.build.targetJdk = 17`; `.envrc` — `sdk use java 17.0.14-tem` |
| Framework | Dropwizard (via jtier-service-pom) | 5.14.0 parent | `pom.xml` — `jtier-service-pom:5.14.0` |
| Runtime | JVM (Eclipse Temurin) | 17 | `.ci/Dockerfile` — `jtier/dev-java17-maven:2023-12-19-609aedb` |
| Build tool | Maven | managed by wrapper | `.mvn/maven.config`, `mvnvm.properties` |
| Package manager | Maven | | `pom.xml` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `io.dropwizard:dropwizard-views-mustache` | managed by jtier BOM | ui-framework | Server-side HTML rendering for the admin UI |
| `io.dropwizard:dropwizard-assets` | managed by jtier BOM | http-framework | Static asset serving |
| `com.groupon.jtier.http:jtier-retrofit` | managed by jtier BOM | http-framework | Retrofit HTTP client integration with jtier configuration |
| `org.kohsuke:github-api` | 1.314 | http-framework | High-level Java client for GitHub REST API |
| `com.groupon:github-app` | 0.1.0 | auth | GitHub App authentication (JWT + installation token) |
| `org.yaml:snakeyaml` | 1.33 | serialization | YAML configuration parsing |
| `com.fasterxml.jackson` | managed via `.mvn/maven.config` | serialization | JSON serialization for REST responses |
| `org.immutables:value` | managed by jtier BOM | validation | Immutable value objects for configuration and data models |
| `retrofit2` | managed by jtier BOM | http-framework | Type-safe HTTP client for Deploybot and JIRA REST APIs |
| `com.arpnetworking.steno` | managed by jtier BOM | logging | Structured event logging |
| `org.assertj:assertj-core` | managed by jtier BOM | testing | Fluent assertion library |
| `org.awaitility:awaitility` | managed by jtier BOM | testing | Async condition waiting in tests |
| `org.ow2.asm:asm` | 9.4 | testing | Bytecode manipulation for GitHub API mocking in tests |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See `pom.xml` for a full list.
