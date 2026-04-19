---
service: "aws-external"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 1
internal_count: 2
---

# Integrations

## Overview

`aws-external` has one external dependency (Amazon Web Services itself) and two internal dependencies modelled in the Continuum architecture: the AWS Control Plane that emits signals into this service, and the Cloud SRE Operations function that receives routed ownership context. Both internal relationships are currently stub-only in the central federation model because the external container stubs are not fully resolved.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Amazon Web Services (AWS) | N/A (3rd-party platform) | Cloud infrastructure platform on which Groupon's services run; this repo exists to track AWS-related incidents | yes | `continuumAwsExternal` |

### Amazon Web Services Detail

- **Protocol**: N/A — AWS is the underlying platform, not a service this repo calls programmatically.
- **Base URL / SDK**: See [AWS Architecture documentation](https://aws.amazon.com/architecture/well-architected/)
- **Auth**: AWS IAM (managed per account/project by Cloud SRE; onboarding instructions at Groupon Confluence EE space)
- **Purpose**: Groupon runs its infrastructure on AWS across multiple accounts and regions (us-west-1, us-west-2, eu-west-1 primary; us-east-1, eu-west-2, ap-southeast-1 legacy/niche). This repository exists as a named owner so that AWS platform-level alerts and incidents can be assigned to Cloud SRE.
- **Failure mode**: AWS service degradation is experienced as quota exhaustion, API throttling, EC2 node failures, or regional/AZ network disruptions. See [Runbook](runbook.md) for response procedures.
- **Circuit breaker**: Not applicable — no programmatic calls are made from this repository.

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| `continuumAwsControlPlane` | Internal signal (stub-only) | Generates AWS alerts and incidents that are tracked and owned by this service's metadata | `continuumAwsControlPlane` |

## Consumed By

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| `continuumCloudSreOperations` | Internal routing (stub-only) | Receives owner assignment and runbook context routed from this service's alert routing metadata |

> Upstream consumers are tracked in the central architecture model. The stub-only relationships indicate that `continuumAwsControlPlane` and `continuumCloudSreOperations` are defined in separate federated repositories not yet fully resolved in this workspace.

## Dependency Health

Not applicable. This service exposes no runtime component and makes no active calls to dependencies.
