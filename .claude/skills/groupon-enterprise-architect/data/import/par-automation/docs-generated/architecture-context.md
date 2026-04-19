---
service: "par-automation"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumParAutomationApi"]
---

# Architecture Context

## System Context

PAR Automation sits within the `continuumSystem` and serves as the backend automation engine for Hybrid Boundary access control. An administrator submits a PAR request in the `continuumHybridBoundaryUi`; the UI posts the request to this service, which then coordinates across Service Portal, Okta, Hybrid Boundary Lambda API, Jira, and GCP Secret Manager to evaluate the request, record it as a Jira ticket, and — if automatically approvable — apply the policy change directly to Hybrid Boundary. It has no persistent database of its own; all state is stored in Jira issues and in the Hybrid Boundary policy store.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| PAR Automation API | `continuumParAutomationApi` | Backend API | Go, net/http | 1.20 | Validates PAR requests, checks policy duplication, and applies/records approvals. |

## Components by Container

### PAR Automation API (`continuumParAutomationApi`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| PAR Request Handler | HTTP endpoints and orchestration for `/release/par` and `/release/healthcheck` | Go, net/http |
| Policy Automation Rules Engine | Classification policy rules used to auto-approve or deny requests based on C1/C2/C3/SOX/PCI attributes | Go |
| Hybrid Boundary Client | HTTP client for policy read/write operations against the Hybrid Boundary Lambda API | Go, net/http |
| Service Portal Client | HTTP client for fetching service metadata and regulatory classifications from Service Portal | Go, net/http |
| Jira Client | Creates PAR and GPROD Jira issues and manages ticket status transitions | go-jira v1.13.0 |
| Okta Client | Obtains OAuth2 bearer tokens for authenticating calls to the Hybrid Boundary API | Go, net/http |
| Config Provider | Resolves environment-driven configuration from env vars and GCP Secret Manager via Viper | viper v1.7.1 |
| HTTP Logger | Sanitized request logging for inbound and outbound HTTP operations (masks Authorization header) | Go, log |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `administrator` | `continuumHybridBoundaryUi` | Submits PAR request via UI | HTTPS / browser |
| `continuumHybridBoundaryUi` | `continuumParAutomationApi` | POST /release/par | REST/HTTP |
| `continuumParAutomationApi` | `servicePortal` | Reads service classification metadata | REST/HTTP |
| `continuumParAutomationApi` | `continuumHybridBoundaryLambdaApi` | Reads and writes authorization policies | REST/HTTP |
| `continuumParAutomationApi` | `oktaIdp` | Obtains OAuth token for Hybrid Boundary API calls | OAuth2 password grant / HTTPS |
| `continuumParAutomationApi` | `continuumJiraService` | Creates and updates PAR/GPROD issues | REST/HTTPS (Jira API) |
| `continuumParAutomationApi` | `cloudPlatform` | Reads service credentials and secrets | GCP Secret Manager SDK |

## Architecture Diagram References

- System context: `contexts-continuumSystem`
- Container: `containers-continuumSystem`
- Component: `components-continuumParAutomationApi`
- Dynamic flow: `dynamic-par-request-automation-flow`
