---
service: "cloud-jenkins-main"
title: "EC2 Agent Lifecycle"
generated: "2026-03-03"
type: flow
flow_name: "ec2-agent-lifecycle"
flow_type: event-driven
trigger: "Build queue demand / idle termination timer"
participants:
  - "continuumJenkinsController"
  - "jenkinsPipelineOrchestrator"
  - "cloudPlatform"
architecture_ref: "components-continuumJenkinsController"
---

# EC2 Agent Lifecycle

## Summary

Cloud Jenkins Main provisions ephemeral EC2 instances as Jenkins agents on demand. When a build is queued with a label that matches an EC2 template (e.g. `ec2`, `dind_2gb_2cpu`, `graviton-default`, `M52xlarge`), the Amazon EC2 plugin launches a matching instance, registers it as a Jenkins node, runs exactly one build (or more if `maxTotalUses > 1` for multitenant templates), and terminates the instance after the idle timeout expires. Each agent template enforces `deleteRootOnTermination: true` and ephemeral EBS devices (where applicable) to ensure clean isolation between builds.

## Trigger

- **Type**: event (build queue demand)
- **Source**: Build enqueued with a label matching a configured EC2 template; also triggered proactively for templates with `minimumNumberOfSpareInstances > 0`
- **Frequency**: On demand; continuously throughout the day

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Jenkins Main Controller | Monitors build queue; instructs EC2 plugin to provision agents | `continuumJenkinsController` |
| Pipeline Orchestrator | Executes build stages on the provisioned agent | `jenkinsPipelineOrchestrator` |
| AWS (cloudPlatform) | Provisions EC2 instances; terminates them after use | `cloudPlatform` |

## Steps

1. **Detect build demand**: The `jenkinsPipelineOrchestrator` detects a queued build whose label matches an EC2 cloud template (e.g. `ec2 jenkins-agent-main-production`).
   - From: `jenkinsPipelineOrchestrator`
   - To: Amazon EC2 plugin (in-process)
   - Protocol: direct

2. **Select agent template**: The Amazon EC2 plugin matches the job label to the correct EC2 template (instance type, AMI, subnet, security group, IAM profile).
   - From: `continuumJenkinsController` (EC2 plugin)
   - To: `cloudPlatform` (EC2 DescribeInstances / RunInstances)
   - Protocol: AWS SDK

3. **Launch EC2 instance**: An EC2 instance is launched using the resolved AMI, instance type, IAM instance profile (`AGENT_INSTANCE_PROFILE_ARN`), security group (`AGENT_SG_NAME`), and subnet (`AWS_SUBNETS`). Spot instances are attempted first for applicable templates (`fallbackToOndemand: true`).
   - From: `continuumJenkinsController` (EC2 plugin)
   - To: `cloudPlatform` (EC2 RunInstances)
   - Protocol: AWS SDK

4. **Register agent node**: Once the instance is running, the controller registers it as a Jenkins node. The agent connects back using JNLP4-connect on port 50001 (SSH for templates with `connectionStrategy: PRIVATE_IP`). Launch timeout is 120–900 seconds depending on template.
   - From: `cloudPlatform` (EC2 instance)
   - To: `continuumJenkinsController` (port 50001)
   - Protocol: JNLP4 / SSH

5. **Execute build**: The queued build is dispatched to the agent. The `jenkinsPipelineOrchestrator` runs all pipeline stages on this node.
   - From: `jenkinsPipelineOrchestrator`
   - To: EC2 agent executor
   - Protocol: JNLP / SSH remoting

6. **Build completes**: The build finishes (SUCCESS, FAILURE, or ABORTED). The agent is marked idle.
   - From: EC2 agent
   - To: `continuumJenkinsController`
   - Protocol: JNLP / SSH

7. **Idle timeout and termination**: After the template's `idleTerminationMinutes` elapses (0–60 minutes depending on template), the Amazon EC2 plugin terminates the EC2 instance. `deleteRootOnTermination: true` ensures the root volume is deleted. Ephemeral EBS devices are also removed.
   - From: `continuumJenkinsController` (EC2 plugin)
   - To: `cloudPlatform` (EC2 TerminateInstances)
   - Protocol: AWS SDK

## Agent Template Summary

| Label | Instance Type | Max Instances | Max Uses | Idle Timeout | Notes |
|-------|--------------|--------------|----------|-------------|-------|
| `ec2`, `dind_*`, `m5.xlarge` | m5a.xlarge | 200 | 1 | 60 min | Default x86 agent; spot with on-demand fallback |
| `graviton-default`, `m6g.xlarge` | m6g.xlarge | 100 | 1 | 60 min | ARM64 Graviton agent |
| `agent-docker-v19` | m5.xlarge | 100 | 1 | 60 min | Pinned Docker v19 engine (AMI: ami-0c6727d45f2629385) |
| `multitenant` | m5.large | 10 | 40 | 15 min | 4 executors; 40 GB EBS; reused across builds |
| `itier-multitenant` | m5.large | 50 | 40 | 15 min | 4 executors; I-tier service builds |
| `api_lazlo_sox`, `M58xlarge` | m5.8xlarge | 10 | 1 | 0 min | CPU/memory intensive; immediate idle termination |
| `M52xlarge`, `m5.2xlarge` | m5.2xlarge | 200 | 1 | 60 min | High-memory workloads; spot with fallback |
| `C5D.4xlarge`, `merchant` | c5d.4xlarge | 12 | 1 | 1 min | Mobile Flutter/merchant builds |
| `mobile-android-bare-metal` | m5.metal | 10 | 1 | 5 min | Bare metal for Android nested virtualisation; 250 GB EBS; 900s launch timeout |
| `ocq` | m5.xlarge | 1 | 1 | 60 min | OCQ worker; custom AMI by owner 787676117833 |

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| EC2 launch failure (capacity, quota) | Plugin logs error; build remains queued | Build delays until capacity is available |
| Launch timeout exceeded | Agent registration fails; build requeued | Build delayed; alert operator if persistent |
| Spot instance interrupted | `fallbackToOndemand: true` — on-demand launched | Transparent to build; slight delay |
| Agent disconnects mid-build | Build marked ABORTED; instance may persist as dangling agent | Cleanup Lambda terminates the orphaned instance on next run |
| Instance not terminated after build | Dangling Agent Terminator (Lambda) detects and terminates it | See [Dangling Agent Cleanup](dangling-agent-cleanup.md) |

## Sequence Diagram

```
Controller         EC2Plugin          AWS EC2         Agent
    |                  |                 |               |
    |--queue demand--->|                 |               |
    |                  |--select AMI---->|               |
    |                  |--RunInstances-->|               |
    |                  |                 |--start EC2--->|
    |                  |<--instance ID---|               |
    |                  |                 |               |--JNLP connect-->|
    |<-agent registered-                 |               |
    |--dispatch build-->                 |               |
    |                                    |               |--run stages-----|
    |<--build result----|                |               |
    |--idle timeout---->|                |               |
    |                  |--TerminateInstances-->|          |
```

## Related

- Architecture dynamic view: `dynamic-jenkins-agent-cleanup-runtime-flow`
- Related flows: [Pipeline Job Execution](pipeline-job-execution.md), [Dangling Agent Cleanup](dangling-agent-cleanup.md)
