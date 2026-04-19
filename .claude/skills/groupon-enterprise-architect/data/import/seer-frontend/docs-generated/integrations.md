---
service: "seer-frontend"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 0
internal_count: 1
---

# Integrations

## Overview

Seer Frontend has one internal dependency: the `seer-service` backend API. All external system integrations (SonarQube, OpsGenie, Jira, Jenkins, Deploybot) are mediated by the backend. The frontend has no direct network connections to any external systems — it communicates only with the backend via the `/api` path prefix.

## External Dependencies

> No evidence found in codebase. The frontend does not call any external systems directly.

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| seer-service (backend) | REST/HTTPS JSON | Provides all aggregated metric data: SonarQube code quality, OpsGenie alerts, Jira sprint and incidents, Jenkins build times, PR merge times, Deploybot deployment times | `seerBackendApi_unk_7b2f` |

### seer-service (backend) Detail

- **Protocol**: HTTPS/JSON REST
- **Base URL**: `/api` (relative path; proxied to `http://seer-service.staging.service.us-central1.gcp.groupondev.com` in development via `vite.config.js`)
- **Auth**: No authentication headers are added by the frontend. Backend auth mechanism, if any, is not visible from this repository.
- **Purpose**: Single aggregation backend that exposes pre-processed metric data from SonarQube, OpsGenie, Jira, Jenkins, and Deploybot to the SPA.
- **Failure mode**: Fetch errors are caught and logged to browser console only. No user-facing error state, retry logic, or fallback is rendered.
- **Circuit breaker**: No evidence found in codebase.

## Consumed By

> Upstream consumers are tracked in the central architecture model. Seer Frontend is a browser SPA accessed by human users; it is not called by other services.

## Dependency Health

No programmatic health-check, retry, or circuit-breaker patterns are implemented in the frontend. Each metric view issues independent `fetch` calls on component mount and on filter change. A failed fetch silently leaves chart data empty (no error displayed to the user).
