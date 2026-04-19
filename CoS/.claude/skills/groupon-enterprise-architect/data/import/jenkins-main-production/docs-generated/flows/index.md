---
service: "cloud-jenkins-main"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 5
---

# Flows

Process and flow documentation for Cloud Jenkins Main.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Controller Startup and Configuration Load](controller-startup.md) | scheduled | EC2 instance start / deployment | JCasC and Groovy init hooks configure the controller; Wavefront startup event is posted |
| [Pipeline Job Execution](pipeline-job-execution.md) | event-driven | GitHub Enterprise push webhook via `/ghe-seed/` | A repository push triggers job seeding; the controller provisions an EC2 agent and runs pipeline stages |
| [EC2 Agent Lifecycle](ec2-agent-lifecycle.md) | event-driven | Build queue demand / idle timer | Controller provisions an ephemeral EC2 agent, runs a build, and terminates the instance after use |
| [Dangling Agent Cleanup](dangling-agent-cleanup.md) | scheduled | AWS EventBridge cron | Lambda queries controller state, identifies stale EC2 agents, and terminates them |
| [Self-Deploy Pipeline](self-deploy-pipeline.md) | event-driven | Push to master branch of this repository | Jenkins pipeline validates, plans, and applies Terraform changes to redeploy its own infrastructure |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 0 |
| Asynchronous (event-driven) | 3 |
| Batch / Scheduled | 2 |

## Cross-Service Flows

- **Dangling Agent Cleanup** spans `continuumJenkinsAgentCleanupLambda` and `continuumJenkinsController`; see the architecture dynamic view `dynamic-jenkins-agent-cleanup-runtime-flow`.
- **Pipeline Job Execution** spans `continuumJenkinsController`, `githubEnterprise`, `artifactory`, `cloudPlatform`, `loggingStack`, and `metricsStack`.
