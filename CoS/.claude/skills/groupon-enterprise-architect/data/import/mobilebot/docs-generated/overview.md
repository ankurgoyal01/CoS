---
service: "mobilebot"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Mobile Release Automation"
platform: "Continuum"
team: "Mobile Consumer"
status: active
tech_stack:
  language: "JavaScript"
  language_version: "Node.js 18"
  framework: "Hubot"
  framework_version: "3.3.2"
  runtime: "Node.js"
  runtime_version: "18.14.2"
  build_tool: "npm"
  package_manager: "npm 9"
---

# Mobilebot Overview

## Purpose

Mobilebot is a Hubot-based chat bot that automates mobile release operations for the Groupon Mobile Consumer team. It listens for commands in Slack and Google Chat and orchestrates release workflows including triggering Jenkins builds, querying App Store Connect and Google Play Developer API for app status, creating Jira release tickets, and surfacing PagerDuty on-call schedules. It exists to reduce manual toil and coordinate release processes through chat-driven commands.

## Scope

### In scope

- Triggering iOS and Android app upload builds via Jenkins CI
- Querying iOS App Store Connect status (via Ruby/Spaceship bridge)
- Querying Google Play Store release status (via Ruby/Supply bridge)
- Creating GPROD (production release) Jira tickets for iOS and Android releases
- Filing MOBTOOL project Jira tickets interactively
- Fetching current mobile iOS/Android on-call engineer from PagerDuty
- Reading and caching the current iOS release branch from GitHub Enterprise
- Creating patch branches from existing release branches via Jenkins
- Room-permission-gated command execution (iOS vs Android release rooms)
- Heartbeat HTTP endpoint for health-check polling

### Out of scope

- Publishing apps directly to app stores (delegated to Jenkins jobs)
- Managing app store metadata, screenshots, or descriptions
- Running test suites or quality gates
- Provisioning infrastructure or cloud resources

## Domain Context

- **Business domain**: Mobile Release Automation
- **Platform**: Continuum
- **Upstream consumers**: Mobile engineers interacting via Slack (`#mobile-ios-release`, `#mobile-and-release`) and Google Chat
- **Downstream dependencies**: Jenkins CI, Jira (Atlassian Cloud), GitHub Enterprise, PagerDuty, App Store Connect (via Ruby Spaceship), Google Play Developer API (via Ruby Supply), Redis

## Stakeholders

| Role | Description |
|------|-------------|
| Mobile Consumer Team | Primary users — iOS and Android engineers executing release commands |
| SRE / Mobile Platform | Service owners responsible for mobilebot uptime |
| Release Manager | Uses `gprod` and `upload` commands to coordinate app releases |
| On-call Engineer | Uses `oncall` command to identify current responders |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | JavaScript | Node.js 18 | `package.json` engines |
| Framework | Hubot | 3.3.2 | `package.json` dependencies |
| Runtime | Node.js | 18.14.2 | `Dockerfile` base image `node:18.14.2-alpine3.17` |
| Runtime (Ruby bridge) | Ruby | 2.7.7 | `Dockerfile` COPY from `ruby:2.7.7-alpine3.16` |
| Build tool | npm | 9 | `package.json` engines |
| Package manager | npm | 9 | `package.json` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `hubot` | 3.3.2 | http-framework | Core bot framework — command dispatch, chat adapter integration |
| `hubot-gchat` (`@grpn/hubot-gchat-adapter`) | 1.0.7 | http-framework | Google Chat adapter for Hubot |
| `hubot-conversation` | 1.1.1 | state-management | Multi-turn interactive dialog support for Hubot |
| `@octokit/rest` | 18.0.9 | http-client | GitHub REST API client for reading release branch refs |
| `@mapbox/pagerduty` | 4.0.0 | http-client | PagerDuty API client for on-call schedule lookups |
| `axios` | 0.21.0 | http-client | HTTP client for Jenkins and other REST calls |
| `redis` | 3.0.2 | db-client | Redis client for conversation state and release branch cache |
| `groupon-steno` | 3.6.0 | logging | Groupon structured event logging library |
| `dotenv` | 6.0.0 | configuration | Loads `.env` files for local development |
| `lodash` | 4.17.20 | utility | Data manipulation helpers across all scripts |
| `moment` | 2.29.1 | utility | Date/time formatting for PagerDuty schedule queries |
| `semver` | 6.2.0 | utility | Semantic version parsing and comparison for release branches |
| `coffee-script` | 1.12.7 | language | CoffeeScript transpiler (legacy Hubot ecosystem support) |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
