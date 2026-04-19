---
service: "mobilebot"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 7
internal_count: 1
---

# Integrations

## Overview

Mobilebot integrates with 7 external systems and 1 internal Continuum service. All integrations are outbound HTTP or adapter-based calls initiated by mobilebot in response to chat commands. There are no inbound webhook integrations. External system credentials are injected via environment variables and Kubernetes secrets.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Slack | Hubot Adapter | Primary chat interface for command receipt and reply | yes | `slack` |
| Google Chat | Hubot Adapter (`hubot-gchat`) | Secondary chat interface for command receipt and reply | yes | `googleChat` |
| Jenkins CI | REST (HTTP POST) | Triggers iOS and Android build/upload jobs | yes | `jenkinsController` |
| PagerDuty | REST (`@mapbox/pagerduty`) | Fetches iOS and Android on-call schedules | no | `pagerDuty` |
| GitHub Enterprise | REST (`@octokit/rest`) | Lists release branch refs from `mobile/ios-consumer` | no | `githubEnterprise` |
| App Store Connect | Ruby subprocess (Spaceship gem) | Queries iOS app version and review status | no | `appStoreConnect` |
| Google Play Developer API | Ruby subprocess (Supply gem) | Queries Android app version and rollout status | no | `googlePlayDeveloperApi` |

### Slack Detail

- **Protocol**: Hubot Adapter (WebSocket / Events API)
- **Base URL / SDK**: Configured via `HUBOT_SLACK_TOKEN` (injected as secret); uses `hubot-slack` adapter
- **Auth**: Bot OAuth token
- **Purpose**: Receives all `@mobilebot` commands and sends replies, threaded messages, and status updates
- **Failure mode**: Bot goes offline; commands silently fail
- **Circuit breaker**: No

### Google Chat Detail

- **Protocol**: Hubot Adapter (`@grpn/hubot-gchat-adapter` 1.0.7)
- **Base URL / SDK**: GChat Spaces API via adapter
- **Auth**: Service account credentials (injected as secret)
- **Purpose**: Alternative chat interface; sends service notifications to configured spaces
- **Failure mode**: GChat commands fail silently; Slack remains functional
- **Circuit breaker**: No

### Jenkins CI Detail

- **Protocol**: HTTP POST (Axios, 7-second timeout)
- **Base URL / SDK**: `https://cloud-jenkins.groupondev.com/job/mobile/job/ios-consumer/buildWithParameters` (iOS); `https://cloud-jenkins.groupondev.com/job/mobile/job/android-consumer/buildWithParameters` (Android); patch branch job: `http://jenkins-main-production.prod-internal.us-west-2.aws.groupondev.com/job/mobile/job/release-branch-cut-job-ios/buildWithParameters`
- **Auth**: Job token parameter (`token: 'test'` in query params)
- **Purpose**: Triggers parameterised build jobs to upload iOS/Android apps to stores and to create patch release branches
- **Failure mode**: Bot replies with error message distinguishing bad status, no response, or configuration error
- **Circuit breaker**: No; single Axios POST with timeout

### PagerDuty Detail

- **Protocol**: REST (`@mapbox/pagerduty` SDK)
- **Base URL / SDK**: PagerDuty API (`schedules/{scheduleId}`)
- **Auth**: `PAGERDUTY_TOKEN` environment variable
- **Purpose**: Queries schedule IDs `PQOLK3I` (iOS primary) and `PXD8WTR` (Android primary) for current on-call engineer
- **Failure mode**: Bot replies "Could not get on call user"
- **Circuit breaker**: No

### GitHub Enterprise Detail

- **Protocol**: REST (`@octokit/rest` 18.0.9, 20-second timeout)
- **Base URL / SDK**: `https://${GITHUB_BASE_URL}/api/v3`
- **Auth**: `GITHUB_API_TOKEN` environment variable
- **Purpose**: Paginates `git.listMatchingRefs` for `mobile/ios-consumer` repo to find the latest `release/` branch; used when cache is empty or reset
- **Failure mode**: Bot replies with generic error and falls back to cached value if available
- **Circuit breaker**: No

### App Store Connect Detail

- **Protocol**: Ruby subprocess (`child_process.exec` invoking Spaceship gem)
- **Base URL / SDK**: Spaceship `ConnectAPI::App.find(app_bundle_id)` — credentials via `ITC_USERNAME`, `ITC_PASSWORD` env vars
- **Auth**: Apple Developer account credentials (secrets); `SPACESHIP_SKIP_2FA_UPGRADE=1` workaround set
- **Purpose**: Retrieves latest iOS app version string and `app_store_state` for Groupon and LivingSocial brands
- **Failure mode**: Bot replies "Could not query app status at this time"
- **Circuit breaker**: No; process-level isolation via child_process

### Google Play Developer API Detail

- **Protocol**: Ruby subprocess (`child_process.exec` invoking Supply gem)
- **Base URL / SDK**: Supply `Client.new(service_account_json:...)` reading from `.meta/deployment/cloud/secrets/ci-groupon-playstore.json`
- **Auth**: Google service account JSON key (k8s secret mounted at secrets path)
- **Purpose**: Queries `com.groupon` production track for latest version, status, and rollout percentage
- **Failure mode**: Bot replies "Could not query app status at this time"
- **Circuit breaker**: No; process-level isolation via child_process

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Mobilebot Redis | Redis (TCP) | Conversation state and release branch cache | `continuumMobilebotRedis` |
| Jira (Continuum Jira Service) | REST (HTTP POST/GET) | Creates GPROD and MOBTOOL Jira issues; queries project versions and user account IDs | `continuumJiraService` |

> Note: Jira is accessed via `JIRA_BASE_URL` (internal DNS) for MOBTOOL tickets and via `https://groupondev.atlassian.net/rest/api/latest/` for GPROD tickets. Auth uses `ATLASSIAN_API_EMAIL` and `ATLASSIAN_API_TOKEN`.

## Consumed By

> Mobilebot exposes no service-to-service API. It is consumed exclusively by human engineers via Slack and Google Chat. Upstream consumers are tracked in the central architecture model.

## Dependency Health

- **Jenkins**: Axios HTTP timeout of 7 seconds (upload) / 5 seconds (patch branch); error logged via `groupon-steno` with `app.error` event
- **PagerDuty**: No explicit timeout or retry configured; failures return user-facing error message
- **GitHub Enterprise**: Octokit timeout of 20 seconds; paginated requests
- **Jira (Atlassian)**: No explicit timeout configured; failures return user-facing error message
- **App Store Connect / Play Store**: Ruby subprocess with no explicit timeout; subprocess exit code and stdout checked
- **Redis**: Connection established at startup; `error` and `ready` events registered but error handling is not yet fully implemented (noted as TODODB in `store.js`)
