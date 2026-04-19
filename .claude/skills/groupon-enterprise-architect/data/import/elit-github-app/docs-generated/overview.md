---
service: "elit-github-app"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Developer Tooling / Engineering Effectiveness"
platform: "Continuum"
team: "alasdair@groupon.com"
status: active
tech_stack:
  language: "Java"
  language_version: "17"
  framework: "JTier / Dropwizard"
  framework_version: "jtier-service-pom 5.14.1"
  runtime: "JVM 17"
  runtime_version: "Eclipse Temurin / Alpine"
  build_tool: "Maven"
  package_manager: "Maven"
---

# ELIT GitHub App Overview

## Purpose

The ELIT GitHub App is a JTier-based microservice that acts as a GitHub App to enforce Equitable Language in Tech (ELIT) standards across Groupon's repositories. It listens for GitHub webhook events triggered by pull request activity, scans the changed lines in each PR diff against a configurable set of problematic language rules, and reports findings directly as GitHub Checks with inline file annotations. This enables engineering teams to identify and remediate non-inclusive terminology before code is merged.

## Scope

### In scope

- Receiving and authenticating GitHub App webhook events (check suite and check run events)
- Verifying webhook payload signatures using HMAC-SHA256
- Creating GitHub Check runs on new or re-requested check suites
- Fetching PR diffs from GitHub Enterprise via the GitHub API
- Reading ELIT rule files from repositories (default `default-elit.yml` and per-repo `.elit.yml`)
- Scanning inserted diff lines against regex-based replacement rules
- Creating GitHub Check annotations at the file and line level for each violation
- Reporting check conclusions (`success` or `failure`) based on violation count
- Supporting per-repository ELIT rule extension via `.elit.yml` files
- Supporting shared rule files referenced by `ruleFiles` in scanner configuration

### Out of scope

- Scanning files outside of pull request diffs (no full-repo scans)
- Enforcing branch protection rules directly (that is configured by repo owners in GitHub)
- Managing ELIT rule content centrally (rules live in `default-elit.yml` and per-repo `.elit.yml`)
- Storing scan results persistently (stateless — results are written back to GitHub only)
- Any consumer-facing or end-user-facing features

## Domain Context

- **Business domain**: Developer Tooling / Engineering Effectiveness
- **Platform**: Continuum
- **Upstream consumers**: GitHub Enterprise (sends webhook events for check suite and check run actions)
- **Downstream dependencies**: GitHub Enterprise API (creates/updates check runs, fetches PR diffs and rule files)

## Stakeholders

| Role | Description |
|------|-------------|
| Service owner | alasdair@groupon.com — primary developer and operator |
| Engineering teams | Any Groupon team that installs the GitHub App on their repositories becomes a consumer of ELIT scan results |
| SRE / On-call | ellit-github-app@groupon.pagerduty.com for incident notifications |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 17 | `pom.xml` — `project.build.targetJdk=17`, `maven.compiler.source=17` |
| Framework | JTier / Dropwizard | jtier-service-pom 5.14.1 | `pom.xml` — `<parent>` block |
| Runtime | JVM 17 (Alpine Docker) | prod-java17-alpine-jtier:3 | `src/main/docker/Dockerfile` |
| Build tool | Maven | 3.6.3 | `mvnvm.properties` — `mvn_version=3.6.3` |
| Package manager | Maven | — | `pom.xml` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `com.groupon:github-app` | 0.1.0 | http-framework | Groupon internal GitHub App SDK — JWT auth, installation tokens, webhook helpers |
| `org.kohsuke:github-api` | 1.314 | http-client | GitHub REST API client — repository access, check run creation and update |
| `io.jsonwebtoken:jjwt-api` | 0.11.2 | auth | JWT generation for GitHub App authentication |
| `io.jsonwebtoken:jjwt-impl` | 0.11.2 | auth | JWT implementation (runtime) |
| `io.jsonwebtoken:jjwt-jackson` | 0.11.2 | serialization | JWT Jackson serialization (runtime) |
| `io.swagger.codegen.v3:swagger-codegen-maven-plugin` | 3.0.25 | validation | OpenAPI model code generation from `openapi3.yml` |
| `com.fasterxml.jackson.dataformat:jackson-dataformat-yaml` | managed by parent | serialization | YAML parsing for scanner rule configuration files |
| `com.fasterxml.jackson.datatype:jackson-datatype-guava` | managed by parent | serialization | Guava type support for Jackson |
| `com.arpnetworking.steno:steno` | managed by parent | logging | Structured JSON logging |
| `org.immutables:value` | managed by parent | validation | Immutable value object generation for configuration types |
| `org.jacoco:jacoco-maven-plugin` | managed by parent | testing | Code coverage measurement |
| `org.junit.jupiter:junit-jupiter-params` | managed by parent | testing | Parameterised unit tests |
