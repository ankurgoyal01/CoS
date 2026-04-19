---
service: "aws-external"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumAwsExternal"]
---

# Architecture Context

## System Context

`aws-external` lives inside the `continuumSystem` (Continuum Platform) in the Groupon architecture model. It is not a running service but a named container within the C4 model that provides ownership identity for AWS-originated alerts and incident reports. The control plane that generates AWS signals (`continuumAwsControlPlane`) feeds ownership context into this container, which in turn routes response responsibility to the Cloud SRE operations function (`continuumCloudSreOperations`). Both upstream and downstream relationships are currently modelled as stub-only in the central workspace because the external dependencies are not fully federated.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| aws-external | `continuumAwsExternal` | Service Metadata Repository | Service Metadata Repository | N/A | Placeholder service metadata repository used to assign AWS third-party alerts and incident response ownership to Cloud SRE. |

## Components by Container

### aws-external (`continuumAwsExternal`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Alert Routing Metadata (`continuumAlertRoutingMetadata`) | Defines ownership mappings that route AWS third-party alerts to Cloud SRE. | Service Metadata |
| Runbook Reference Index (`continuumRunbookReferenceIndex`) | Stores links to onboarding, FAQ, and troubleshooting guidance used during incident response. | Documentation Index |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumRunbookReferenceIndex` | `continuumAlertRoutingMetadata` | Provides operational context for routing definitions | Internal reference |
| `continuumAwsControlPlane` | `continuumAwsExternal` | Emits alerts and incidents tracked by (stub-only) | Internal signal |
| `continuumAwsExternal` | `continuumCloudSreOperations` | Routes ownership and response context to (stub-only) | Internal routing |

## Architecture Diagram References

- Component: `components-aws-external`
- Dynamic view (disabled in federation — references stub-only elements): `awsAlertRoutingFlow`
