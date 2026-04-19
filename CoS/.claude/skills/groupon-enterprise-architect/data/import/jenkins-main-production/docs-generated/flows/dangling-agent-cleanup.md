---
service: "cloud-jenkins-main"
title: "Dangling Agent Cleanup"
generated: "2026-03-03"
type: flow
flow_name: "dangling-agent-cleanup"
flow_type: scheduled
trigger: "AWS EventBridge cron schedule"
participants:
  - "continuumJenkinsAgentCleanupLambda"
  - "agentCleanupScheduler"
  - "danglingAgentTerminator"
  - "continuumJenkinsController"
  - "cloudPlatform"
  - "loggingStack"
  - "metricsStack"
architecture_ref: "dynamic-jenkins-agent-cleanup-runtime-flow"
---

# Dangling Agent Cleanup

## Summary

When Jenkins EC2 agents fail to deregister cleanly — typically due to a controller restart, network disruption, or spot instance interruption — EC2 instances can remain running in AWS without a corresponding node record in Jenkins. The Jenkins Agent Cleanup Lambda detects these dangling agents by reading current agent/computer state from the Jenkins controller and comparing it against live EC2 instances tagged as Jenkins agents. Stale instances are terminated via the AWS EC2 API, and cleanup metrics and logs are emitted to the observability stack.

## Trigger

- **Type**: schedule
- **Source**: AWS EventBridge cron schedule (cron expression defined in Terraform modules under `terraform/environments/`)
- **Frequency**: Periodic (scheduled interval; exact cron expression not exposed in this repository)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Cleanup Scheduler | Receives EventBridge invocation; triggers cleanup workflow | `agentCleanupScheduler` |
| Dangling Agent Terminator | Queries controller state; identifies and terminates stale EC2 agents | `danglingAgentTerminator` |
| Jenkins Main Controller | Provides current agent/node state via Jenkins API | `continuumJenkinsController` |
| AWS (cloudPlatform) | Target for EC2 instance termination; also source of running instance list | `cloudPlatform` |
| Logging Stack | Receives cleanup execution logs | `loggingStack` |
| Metrics Stack | Receives cleanup execution metrics | `metricsStack` |

## Steps

1. **EventBridge fires cron trigger**: AWS EventBridge fires the scheduled invocation, calling the Lambda function entry point.
   - From: `cloudPlatform` (EventBridge)
   - To: `continuumJenkinsAgentCleanupLambda`
   - Protocol: AWS Lambda invocation (direct)

2. **Cleanup Scheduler triggers Dangling Agent Terminator**: The `agentCleanupScheduler` component invokes the `danglingAgentTerminator` handler to begin the cleanup run.
   - From: `agentCleanupScheduler`
   - To: `danglingAgentTerminator`
   - Protocol: direct (in-process Lambda)

3. **Query Jenkins controller for agent/node state**: The `danglingAgentTerminator` calls the Jenkins REST API to retrieve the current list of registered computers (agents), including their name, status, and associated EC2 instance metadata.
   - From: `danglingAgentTerminator`
   - To: `continuumJenkinsController` (Jenkins REST API)
   - Protocol: HTTPS

4. **Enumerate live EC2 instances tagged as Jenkins agents**: The terminator queries the AWS EC2 API for all running instances tagged with the Jenkins agent tag (e.g. `Name=cj-agent-production-main-*`).
   - From: `danglingAgentTerminator`
   - To: `cloudPlatform` (EC2 DescribeInstances)
   - Protocol: AWS SDK

5. **Identify dangling agents**: Instances that are running in EC2 but have no corresponding active node entry in the Jenkins controller are classified as dangling agents.
   - From: `danglingAgentTerminator` (reconciliation logic)
   - To: Internal comparison (in-process)
   - Protocol: direct

6. **Terminate stale EC2 instances**: Each dangling agent's EC2 instance is terminated via the AWS EC2 API. Termination removes the instance and (due to `deleteRootOnTermination: true`) the associated root EBS volume.
   - From: `danglingAgentTerminator`
   - To: `cloudPlatform` (EC2 TerminateInstances)
   - Protocol: AWS SDK

7. **Emit cleanup execution logs**: Log entries covering the cleanup run (instances evaluated, instances terminated, errors encountered) are emitted to the logging stack.
   - From: `danglingAgentTerminator`
   - To: `loggingStack`
   - Protocol: Logging sidecar / Filebeat

8. **Emit cleanup execution metrics**: Metrics (count of dangling agents found, terminated, errors) are emitted to the metrics stack.
   - From: `danglingAgentTerminator`
   - To: `metricsStack`
   - Protocol: Metrics sidecar

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Jenkins controller unreachable | Lambda logs error; cleanup run aborted | Dangling agents persist until next scheduled run |
| EC2 DescribeInstances failure | Lambda logs error; cleanup run aborted | Dangling agents persist until next scheduled run |
| EC2 TerminateInstances failure (single instance) | Error logged per instance; cleanup continues for remaining instances | Partial cleanup; failed instance retried on next run |
| Lambda execution timeout | EventBridge will retry on next schedule; no manual intervention needed | Stale agents persist until next run |

## Sequence Diagram

```
EventBridge       CleanupLambda       Controller       AWS EC2
    |                  |                   |               |
    |--cron trigger--->|                   |               |
    |                  |--GET /computer--->|               |
    |                  |<--agent list------|               |
    |                  |--DescribeInstances--------------->|
    |                  |<--running instances---------------|
    |                  |--reconcile (in-process)           |
    |                  |--TerminateInstances (dangling)--->|
    |                  |--emit logs/metrics (async)        |
```

## Related

- Architecture dynamic view: `dynamic-jenkins-agent-cleanup-runtime-flow`
- Related flows: [EC2 Agent Lifecycle](ec2-agent-lifecycle.md)
