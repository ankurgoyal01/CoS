---
service: "elit-github-app"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumElitGithubAppService"]
---

# Architecture Context

## System Context

The ELIT GitHub App is a container within the `continuumSystem` (Continuum Platform). It sits at the intersection of Groupon's internal engineering tooling and GitHub Enterprise. GitHub Enterprise is the sole upstream caller — it sends webhook events for check suite and check run lifecycle actions. The service in turn calls back into GitHub Enterprise via the GitHub API to create check runs, fetch PR diffs, and read rule files from repositories. There are no other Groupon services that this service calls or that call it directly.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| ELIT GitHub App Service | `continuumElitGithubAppService` | Service | Java, JTier/Dropwizard | jtier-service-pom 5.14.1 | Receives GitHub App webhooks, scans pull request diffs for ELIT violations, and creates GitHub checks/annotations |

## Components by Container

### ELIT GitHub App Service (`continuumElitGithubAppService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| GitHub Webhook Resource | Receives POST webhook events for check suites and check runs at `/elit-github-app/webhook` | JAX-RS Resource |
| Webhook Signature Filter | Validates GitHub webhook HMAC-SHA256 signatures before allowing requests to proceed | JAX-RS Filter |
| Check Action Handler | Routes incoming check suite and check run events to the appropriate create or start handler | Handler |
| Pull Request Check Function | Fetches PR diff URLs and orchestrates the ELIT scan, determining check conclusion | Service |
| ELIT Scanner Factory | Builds a `ContentScanner` from the merged default and per-repo rule configurations | Factory |
| Rule File Reader | Loads and merges ELIT YAML rule files from repositories, following `ruleFiles` references recursively | Service |
| Diff Reader | Reads raw diff content from GitHub API responses | Service |
| Diff Parser | Parses unified diff lines into structured `DiffItem` objects (INSERT, DELETE, CONTEXT types) | Service |
| Content Scanner | Evaluates inserted diff lines against ELIT regex replacement rules and produces `ContentAnnotation` objects | Service |
| GitHub App Client | Authenticates as GitHub App installations using JWT/installation-token exchange and calls GitHub APIs | Client |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `githubEnterprise` | `continuumElitGithubAppService` | Sends webhook events for check suites and check runs | HTTPS POST / webhook |
| `continuumElitGithubAppService` | `githubEnterprise` | Creates check runs and fetches PR data, diffs, and rule files via API | HTTPS REST |
| `messageAuthFilter` | `webhookResource` | Allows verified webhook requests to pass through | JAX-RS filter chain |
| `webhookResource` | `actionHandler` | Dispatches parsed GitHub webhook events | Direct (in-process) |
| `actionHandler` | `githubClient` | Creates and updates check runs | Direct (in-process) |
| `actionHandler` | `checkFunction` | Runs ELIT scan for check run events | Direct (in-process) |
| `checkFunction` | `scannerFactory` | Builds scanners for the check request | Direct (in-process) |
| `scannerFactory` | `contentScanner` | Creates scanners from rule config | Direct (in-process) |
| `checkFunction` | `ruleFileReader` | Loads ELIT rule files | Direct (in-process) |
| `checkFunction` | `diffReader` | Reads PR diff content | Direct (in-process) |
| `diffReader` | `diffParser` | Parses diff content | Direct (in-process) |
| `checkFunction` | `contentScanner` | Scans diff lines for violations | Direct (in-process) |
| `ruleFileReader` | `githubClient` | Reads rule files from repositories | Direct (in-process) |
| `checkFunction` | `githubClient` | Fetches PR metadata and diffs | Direct (in-process) |

## Architecture Diagram References

- System context: `contexts-elitGithubApp`
- Container: `containers-elitGithubApp`
- Component: `components-elitGithubAppService`
