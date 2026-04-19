---
service: "cloud-jenkins-main"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumJenkinsController", "continuumJenkinsAgentCleanupLambda"]
---

# Architecture Context

## System Context

Cloud Jenkins Main lives inside the `continuumSystem` (Continuum Platform) as a CI/CD infrastructure service. It is consumed by every engineering team at Groupon via GitHub Enterprise webhooks and direct web-browser access. It depends on GitHub Enterprise for source code, Artifactory for artifact storage, AWS for compute and infrastructure, and the central logging and metrics stacks for observability. The controller is not directly user-facing in a product sense — it is an internal engineering platform.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Jenkins Main Controller | `continuumJenkinsController` | CI/CD Controller | Jenkins (JCasC + Groovy) | — | Production Jenkins controller; runs pipeline stages and manages EC2 agent lifecycle |
| Jenkins Agent Cleanup Lambda | `continuumJenkinsAgentCleanupLambda` | Serverless | AWS Lambda | — | Scheduled cleanup function; terminates dangling EC2 agents and reconciles ASG/SG state |

## Components by Container

### Jenkins Main Controller (`continuumJenkinsController`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Pipeline Orchestrator (`jenkinsPipelineOrchestrator`) | Runs repository pipeline stages (Prepare, Validate, Integration Tests, Plan, Deploy) and enforces deployment gating for master-only pushes | Jenkins Pipeline (Declarative DSL) |
| Configuration Loader (`jenkinsConfigLoader`) | Loads JCasC YAML files and Groovy hook scripts from the configuration Docker image during controller startup | Jenkins Configuration as Code |
| Observability Emitter (`jenkinsObservabilityEmitter`) | Exports controller metrics, build logs, and Slack alerts; posts startup/shutdown events to Wavefront | Metrics/Logging sidecars + Jenkins plugins |

### Jenkins Agent Cleanup Lambda (`continuumJenkinsAgentCleanupLambda`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Cleanup Scheduler (`agentCleanupScheduler`) | Invokes the cleanup workflow on a fixed cron schedule | AWS EventBridge Schedule |
| Dangling Agent Terminator (`danglingAgentTerminator`) | Queries controller/agent state, identifies stale EC2 instances, and terminates them via the AWS API | AWS Lambda Handler |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumJenkinsController` | `githubEnterprise` | Clones source repositories and reads pull-request metadata | HTTPS / Git |
| `continuumJenkinsController` | `artifactory` | Pulls and pushes build artifacts and Docker images | HTTPS |
| `continuumJenkinsController` | `cloudPlatform` | Provisions and manages AWS infrastructure via Terraform/Terragrunt | AWS SDK / CLI |
| `continuumJenkinsController` | `loggingStack` | Ships controller and build logs | Filebeat / HTTPS |
| `continuumJenkinsController` | `metricsStack` | Publishes controller and pipeline metrics (Telegraf/Wavefront) | HTTP (Telegraf port 8186) |
| `continuumJenkinsController` | `slack` | Sends deployment/pipeline failure alerts | Slack API (HTTPS) |
| `continuumJenkinsAgentCleanupLambda` | `cloudPlatform` | Terminates stale EC2 agents and reconciles ASG/SG state | AWS SDK |
| `continuumJenkinsAgentCleanupLambda` | `continuumJenkinsController` | Reads controller outputs to identify dangling agents | HTTPS (Jenkins API) |
| `continuumJenkinsAgentCleanupLambda` | `loggingStack` | Emits cleanup execution logs | Logging sidecar |
| `continuumJenkinsAgentCleanupLambda` | `metricsStack` | Emits cleanup execution metrics | Metrics sidecar |

## Architecture Diagram References

- System context: `contexts-continuumSystem`
- Container: `containers-continuumSystem`
- Component (controller): `components-continuumJenkinsController`
- Component (cleanup lambda): `components-continuumJenkinsAgentCleanupLambda`
- Dynamic view (agent cleanup): `dynamic-jenkins-agent-cleanup-runtime-flow`
