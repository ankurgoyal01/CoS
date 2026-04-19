---
service: "lavatoryRunner"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumLavatoryRunnerService"]
---

# Architecture Context

## System Context

Lavatory Runner lives inside the `continuumSystem` (Continuum Platform) as a batch/scheduled service. It has no inbound API surface — it is triggered exclusively by host cron jobs on `artifactory-utility` machines. Outbound, it connects to Groupon's internal Artifactory instance via HTTPS/REST to execute AQL queries and delete stale Docker image tags. Cleanup logs are forwarded to the centralized logging stack (Splunk). Metrics are published to Wavefront.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Lavatory Runner Service | `continuumLavatoryRunnerService` | Service, Batch | Python (Lavatory policy runner) | 2019.05.08 base | Runs retention policies and purges stale Artifactory Docker artifacts on a schedule |

## Components by Container

### Lavatory Runner Service (`continuumLavatoryRunnerService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Policy Loader | Loads repository-specific retention policy modules from `/opt/lavatory/policies` | Python |
| Retention Evaluator | Applies policy rules to determine purge candidates and retention exceptions | Python |
| Artifactory Client | Executes AQL queries and delete operations against Artifactory REST APIs | HTTP client |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumLavatoryRunnerService` | `artifactory` | Queries metadata and deletes stale artifacts | HTTPS/REST |
| `continuumLavatoryRunnerService` | `loggingStack` | Writes cleanup and performance logs | File / Splunk forwarder |
| `policyLoader` | `retentionEvaluator` | Supplies policy definitions and thresholds | In-process Python |
| `retentionEvaluator` | `artifactoryClient` | Requests artifact metadata and purge operations | In-process Python |

## Architecture Diagram References

- System context: `contexts-continuumLavatoryRunnerService`
- Container: `containers-continuumLavatoryRunnerService`
- Component: `components-continuum-lavatory-runner-service`
