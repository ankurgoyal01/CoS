---
service: "mobilebot"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: [continuumMobilebotService, continuumMobilebotRedis]
---

# Architecture Context

## System Context

Mobilebot is a container within the **Continuum Platform** software system (`continuumSystem`). It sits at the intersection of the Mobile Consumer team's engineering tooling and external third-party platforms. Engineers interact with it through chat systems (Slack and Google Chat); it then orchestrates calls to CI infrastructure (Jenkins), release tracking (Jira, GitHub Enterprise), app store APIs (App Store Connect, Google Play), and on-call tooling (PagerDuty). State is persisted in a dedicated Redis cache. Mobilebot has no external-facing HTTP API surface; all interaction is chat-driven.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Mobilebot Service | `continuumMobilebotService` | Backend | Node.js | 18.14.2 | Hubot-based mobile operations bot that responds in chat and automates release workflows |
| Mobilebot Redis Cache | `continuumMobilebotRedis` | Database | Redis | 3.x (client) | External Redis store for conversation state and temporary pairing cache |

## Components by Container

### Mobilebot Service (`continuumMobilebotService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `mobilebot_commandHandlers` | Hubot listeners and responders implementing all chat commands (`upload`, `gprod`, `oncall`, `appstore_status`, `playstore_status`, `release_branch`, `create_patch_from_branch`, `mobtool`, `pick`, `help`) | JavaScript (Hubot Scripts) |
| `mobilebot_integrationClients` | HTTP and SDK clients for Jenkins (Axios), Jira (request/Axios), GitHub Enterprise (Octokit), PagerDuty (`@mapbox/pagerduty`), and chat systems (Hubot adapters) | JavaScript (Axios/SDKs) |
| `mobilebot_rubyAutomationBridge` | Local Ruby script runner for App Store Connect and Google Play Store status queries via `child_process.exec` | Node child_process + Ruby |
| `mobilebot_conversationStateStore` | Redis-backed key-value store for release branch caching (key: `mobilebot:internal:ios:current_release_branch`) and multi-turn conversation context | Redis Client |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumMobilebotService` | `slack` | Responds to bot commands and posts threaded messages | Hubot Adapter |
| `continuumMobilebotService` | `googleChat` | Sends service notifications to configured chat spaces | Hubot Adapter |
| `continuumMobilebotService` | `pagerDuty` | Fetches mobile on-call schedules | PagerDuty API |
| `continuumMobilebotService` | `continuumJiraService` | Creates release (GPROD) and deployment (MOBTOOL) issues | Jira REST API |
| `continuumMobilebotService` | `githubEnterprise` | Reads release branch refs from `mobile/ios-consumer` repository | GitHub REST API |
| `continuumMobilebotService` | `jenkinsController` | Triggers iOS (`ios-consumer`) and Android (`android-consumer`) build/upload jobs | Jenkins HTTP API |
| `continuumMobilebotService` | `appStoreConnect` | Queries iOS app release status via Ruby Spaceship scripts | App Store Connect API |
| `continuumMobilebotService` | `googlePlayDeveloperApi` | Queries Android release status via Ruby Supply scripts | Google Play Developer API |
| `continuumMobilebotService` | `continuumMobilebotRedis` | Reads/writes conversation cache and release branch pairing data | Redis |
| `mobilebot_commandHandlers` | `mobilebot_integrationClients` | Routes command execution to integration APIs | Internal |
| `mobilebot_commandHandlers` | `mobilebot_conversationStateStore` | Reads and updates command/session state | Internal |
| `mobilebot_integrationClients` | `mobilebot_rubyAutomationBridge` | Delegates App Store and Play Store status operations to Ruby scripts | Internal |
| `mobilebot_integrationClients` | `mobilebot_conversationStateStore` | Stores and reads workflow context | Internal |

## Architecture Diagram References

- System context: `contexts-continuum-mobilebot`
- Container: `containers-continuum-mobilebot`
- Component: `components-continuum-mobilebot-service`
