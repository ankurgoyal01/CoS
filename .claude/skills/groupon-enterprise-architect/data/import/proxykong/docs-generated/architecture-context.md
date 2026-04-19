---
service: "proxykong"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuum"
  containers: ["continuumProxykongService"]
---

# Architecture Context

## System Context

ProxyKong sits within the Continuum platform as an internal tooling service. It is accessed exclusively by authenticated Groupon engineers who need to manage API proxy routing configuration. The service acts as an orchestration layer: it reads existing route data from the locally cloned `api-proxy-config` repository, validates proposed changes against live infrastructure (Hybrid Boundary, Service Portal), and then automates the creation of Jira issues and GitHub pull requests to formally track and apply each change. ProxyKong does not sit in the customer-facing request path.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| ProxyKong Service | `continuumProxykongService` | Application | Node.js, iTier, Preact | Node.js 14.20.0 | Node.js iTier application serving UI and APIs for route-change workflows and reporting |
| API Proxy Config Bundle | `continuumApiProxyConfigBundle` | External Config | Git repository / filesystem | — | Stores API routing configuration and config_tools scripts; cloned into the container at `/api-proxy-config` |
| Jira Service | `continuumJiraService` | External | HTTPS REST | — | Atlassian Jira for tracking route change request issues |
| GitHub Enterprise | `githubEnterprise` | External | HTTPS REST | — | Source control for `api-proxy-config`; pull requests created here |
| Service Portal | `servicePortal` | External | HTTP REST | — | Service metadata registry used to validate service names |
| Hybrid Boundary Edge Proxy | `continuumHybridBoundaryEdgeProxy` | External | HTTP | — | Edge proxy used to validate destination VIP existence |
| Robin Reporting Service | `continuumRobinReportingService` | External | Service API | — | Argus performance reporting and email generation |

## Components by Container

### ProxyKong Service (`continuumProxykongService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| ProxyKong UI Module (`proxykongWebUi`) | Preact-based UI forms for route requests, promotions, deletions, and reporting | JavaScript/TypeScript, Preact |
| Route Management Controller (`routeManagementController`) | API handlers in `proxyroutes/actions.js` orchestrating route and experiment read/write operations | Node.js |
| Pull Request Automation (`pullRequestAutomation`) | `pullRequestBuilder` / `prHelper` / `jiraHelper` workflow creating Jira issues and GitHub pull requests | Node.js/TypeScript |
| Authentication Bridge (`authBridge`) | Request-scoped authenticator reading Okta headers and cookies; enforces authentication on all mutation endpoints | Node.js |
| Issue Tracker Gateway (`issueTrackerGateway`) | Jira client integration for issue creation in project `11500` with issue type `10700` | Node.js |
| Source Control Gateway (`scmGateway`) | GitHub client integration for branch, commit, and pull request lifecycle against `groupon-api/api-proxy-config` | Node.js |
| Reporting Controller (`reportingController`) | Reporting actions for generating and emailing Argus performance reports | Node.js |
| Reporting Gateway (`reportingGateway`) | Robin library integration for `PerformanceReport` retrieval and `EmailGenerator` dispatch | Node.js |
| Route Config Gateway (`routeConfigGateway`) | Wrappers around `api-proxy-config/config_tools` scripts for routes, destinations, experiments, and validation | Node.js |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumProxykongService` | `continuumApiProxyConfigBundle` | Loads and mutates route configuration using shared config scripts | Filesystem/Git |
| `continuumProxykongService` | `githubEnterprise` | Creates pull requests for route changes | HTTPS |
| `continuumProxykongService` | `continuumJiraService` | Creates route request tickets | HTTPS |
| `continuumProxykongService` | `servicePortal` | Fetches service metadata for validation and enrichment | HTTP |
| `continuumProxykongService` | `continuumHybridBoundaryEdgeProxy` | Validates service reachability by host probe | HTTP |
| `continuumProxykongService` | `continuumRobinReportingService` | Queries metrics and sends reporting emails | Service API |
| `routeManagementController` | `routeConfigGateway` | Reads route groups, routes, destinations, and experiment metadata | direct |
| `routeManagementController` | `authBridge` | Uses request authentication context and caller identity | direct |
| `routeManagementController` | `pullRequestAutomation` | Builds and executes configuration pull-request workflows | direct |
| `pullRequestAutomation` | `issueTrackerGateway` | Creates and links Jira tickets to route-change workflows | direct |
| `pullRequestAutomation` | `scmGateway` | Creates branches, commits, and pull requests in GitHub Enterprise | direct |
| `scmGateway` | `githubEnterprise` | Creates branches, commits, and pull requests | HTTPS |
| `issueTrackerGateway` | `continuumJiraService` | Creates and updates route request issues | HTTPS |
| `routeConfigGateway` | `continuumApiProxyConfigBundle` | Reads and writes API routing configuration artifacts | Filesystem |

## Architecture Diagram References

- Component: `components-proxykong-service`
- Dynamic flow: `dynamic-route-change-request-flow`
