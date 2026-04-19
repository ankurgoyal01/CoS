---
service: "hybrid-boundary"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumHybridBoundary"
  containers:
    - "continuumHybridBoundaryEdgeProxy"
    - "continuumHybridBoundaryAgent"
    - "continuumHybridBoundaryLambdaApi"
    - "continuumHybridBoundaryLambdaRrdns"
    - "continuumHybridBoundaryLambdaIterator"
    - "continuumHybridBoundaryApiGateway"
    - "continuumHybridBoundaryServiceRegistryTable"
    - "continuumHybridBoundaryStepFunctions"
    - "continuumHybridBoundaryDns"
---

# Architecture Context

## System Context

Hybrid Boundary sits at the network edge of Groupon's AWS infrastructure, bridging on-prem and cloud environments. Platform teams interact with it through an administrative REST API to register services and manage traffic routing. Envoy proxy instances running on EC2 subscribe to the Go-based xDS control plane to receive up-to-date routing configuration. DNS records in Route53 direct traffic to the appropriate proxy instances. External CDN traffic from Akamai is allow-listed at the proxy level via periodically refreshed IP sets. The system depends on AWS DynamoDB as its configuration state store and AWS Step Functions to orchestrate incremental traffic shifts.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Edge Proxy Fleet | `continuumHybridBoundaryEdgeProxy` | Runtime/Proxy | EC2, Envoy, OpenResty | — | Envoy and OpenResty instances handling edge ingress and service-to-service proxying |
| Hybrid Boundary Agent | `continuumHybridBoundaryAgent` | Runtime/ControlPlane | Go, gRPC, HTTP | Go 1.18 | Go control-plane process that builds and serves Envoy xDS config and telemetry |
| Registry Lambda | `continuumHybridBoundaryLambda` | Serverless/ControlPlane | AWS Lambda (Go) | — | Processes registry stream updates and coordinates DNS and target updates |
| Iterator Lambda | `continuumHybridBoundaryLambdaIterator` | Serverless/Workflow | AWS Lambda (Go) | — | Executes iterative shift and rollout workflows across service endpoints |
| API Lambda | `continuumHybridBoundaryLambdaApi` | Serverless/API | AWS Lambda (Go) | Go 1.18 | Administrative API for service registration, endpoint policy, and shift controls |
| RRDNS Lambda | `continuumHybridBoundaryLambdaRrdns` | Serverless/DNS | AWS Lambda (Go) | — | Handles scaling lifecycle events and updates Route53 weighted records |
| API Gateway | `continuumHybridBoundaryApiGateway` | Gateway/API | AWS API Gateway | — | Public/internal API front door for administrative Hybrid Boundary APIs |
| Service Registry | `continuumHybridBoundaryServiceRegistryTable` | Database/StateStore | AWS DynamoDB | — | Configuration and service registration state store for edge routing |
| Shift Workflow | `continuumHybridBoundaryStepFunctions` | Workflow | AWS Step Functions | — | State machine orchestrating traffic shift operations |
| DNS Zone | `continuumHybridBoundaryDns` | DNS | AWS Route53 | — | Hosted zones and records for edge target discovery and failover |

## Components by Container

### Hybrid Boundary Agent (`continuumHybridBoundaryAgent`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Service Registry Client (`serviceRegistryClient`) | Queries service registration and endpoint state from DynamoDB | Go package: `agent/service` |
| xDS Config Builder (`xdsConfigBuilder`) | Builds Envoy clusters/listeners/routes and snapshot versions per namespace | Go package: `agent/envoy` |
| Envoy gRPC Server (`envoyConfigPublisher`) | Serves xDS resources to Envoy and handles stream lifecycle | Go package: `agent/envoy` |
| Metrics and Admin Endpoint (`telemetryExporter`) | Exposes Prometheus metrics/config and manages periodic update loops | Go package: `cmd/agent` |

### API Lambda (`continuumHybridBoundaryLambdaApi`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Authenticator (`apiAuthHandler`) | Validates JWTs and caller authorization for API operations | Go package: `agent/lambda-api/authenticator` |
| Service Handler (`serviceCrudHandler`) | Manages service-level API operations and validation | Go package: `agent/lambda-api/service` |
| Endpoint Handler (`endpointCrudHandler`) | Handles endpoint create/update/delete semantics | Go package: `agent/lambda-api/endpoint` |
| Policy Handler (`policyHandler`) | Applies and validates authorization policy changes | Go package: `agent/lambda-api/policy` |
| Shift Handler (`shiftHandler`) | Starts and controls traffic shift operations | Go package: `agent/lambda-api/shift` |
| History Handler (`historyHandler`) | Returns historical change records for audits and troubleshooting | Go package: `agent/lambda-api/history` |
| Step Functions Client (`sfnClient`) | Calls Step Functions APIs to execute shift workflows | Go package: `agent/lambda-api/sfn` |

### RRDNS Lambda (`continuumHybridBoundaryLambdaRrdns`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Lifecycle Event Handler (`rrdnsLifecycleHandler`) | Processes scaling lifecycle events from Auto Scaling | Go package: `agent/lambda-rrdns` |
| Autoscaling Client (`rrdnsAutoscalingClient`) | Reads and acknowledges lifecycle transitions for proxy instances | Go package: `agent/lambda-rrdns/autoscaling` |
| Route53 Client (`rrdnsRoute53Client`) | Publishes weighted DNS updates for active proxy targets | Go package: `agent/route53` |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumHybridBoundaryEdgeProxy` | `continuumHybridBoundaryAgent` | Subscribes to xDS configuration | gRPC |
| `continuumHybridBoundaryAgent` | `continuumHybridBoundaryServiceRegistryTable` | Reads service registrations and endpoint metadata | AWS SDK (DynamoDB) |
| `continuumHybridBoundaryAgent` | `akamai` | Retrieves Akamai IP ranges for allow-list updates | HTTPS (S3 / Akamai API) |
| `continuumHybridBoundaryLambda` | `continuumHybridBoundaryServiceRegistryTable` | Processes registry stream and updates records | AWS SDK (DynamoDB) |
| `continuumHybridBoundaryLambda` | `continuumHybridBoundaryDns` | Manages service DNS records | AWS SDK (Route53) |
| `continuumHybridBoundaryApiGateway` | `continuumHybridBoundaryLambdaApi` | Invokes administrative APIs | AWS Lambda invocation |
| `continuumHybridBoundaryLambdaApi` | `continuumHybridBoundaryServiceRegistryTable` | Creates/reads/updates/deletes service and endpoint configuration | AWS SDK (DynamoDB) |
| `continuumHybridBoundaryLambdaApi` | `continuumHybridBoundaryStepFunctions` | Starts shift workflows | AWS SDK (Step Functions) |
| `continuumHybridBoundaryLambdaIterator` | `continuumHybridBoundaryServiceRegistryTable` | Applies stepwise traffic changes | AWS SDK (DynamoDB) |
| `continuumHybridBoundaryLambdaIterator` | `continuumHybridBoundaryStepFunctions` | Reports workflow progress | AWS SDK (Step Functions) |
| `continuumHybridBoundaryLambdaRrdns` | `continuumHybridBoundaryDns` | Updates Route53 weighted records | AWS SDK (Route53) |
| `continuumHybridBoundaryStepFunctions` | `continuumHybridBoundaryLambdaIterator` | Invokes iterator tasks for shift execution | AWS Step Functions |
| `continuumHybridBoundaryStepFunctions` | `continuumHybridBoundaryLambdaRrdns` | Invokes DNS sync on lifecycle events | AWS Step Functions |

## Architecture Diagram References

- Component (agent): `components-hb-agent`
- Component (api lambda): `components-hb-lambda-api`
- Component (rrdns lambda): `components-hb-lambda-rrdns`
- Dynamic (config update): `dynamic-hb-config-update-flow`
- Dynamic (shift workflow): `dynamic-hb-shift-workflow-flow`
