---
service: "aws-external"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Cloud Infrastructure / AWS Operations"
platform: "Continuum"
team: "Cloud SRE"
status: active
tech_stack:
  language: "N/A"
  language_version: "N/A"
  framework: "N/A"
  framework_version: "N/A"
  runtime: "N/A"
  runtime_version: "N/A"
  build_tool: "N/A"
  package_manager: "N/A"
---

# aws-external Overview

## Purpose

`aws-external` is a placeholder service metadata repository whose sole purpose is to provide a named owner for AWS third-party alerts and incident reports within Groupon's internal tooling. It exists so that alerts and IRs arising from AWS (Amazon Web Services) activity can be routed and assigned to the Cloud SRE team rather than remaining unowned. This repository contains no application code; its value is entirely in its service identity, ownership metadata, and operational runbook references.

## Scope

### In scope

- Defining the ownership mapping that routes AWS-originated alerts to the Cloud SRE team.
- Storing runbook references covering AWS onboarding, FAQs, incident response procedures, adding capacity via service quotas, and troubleshooting guidance.
- Acting as the named service for AWS-related incident tickets so that on-call routing tools can assign them correctly.

### Out of scope

- Actual AWS infrastructure management — that is performed by individual projects such as CloudCore and Conveyor.
- Infrastructure-as-code (Terraform/CDK) — owned by the projects that provision AWS resources.
- Code-level monitoring or instrumentation — AWS publishes its own SLAs per service.
- Multi-region failover logic — responsibility lies with the services that run on AWS.

## Domain Context

- **Business domain**: Cloud Infrastructure / AWS Operations
- **Platform**: Continuum
- **Upstream consumers**: `continuumAwsControlPlane` — emits alerts and incidents tracked by this repository (stub-only relationship in the central model)
- **Downstream dependencies**: `continuumCloudSreOperations` — receives ownership and response context routed from this repository (stub-only relationship in the central model)

## Stakeholders

| Role | Description |
|------|-------------|
| Cloud SRE | Primary owner; responds to AWS alerts and incidents assigned via this repository's routing metadata |
| IMOC (Incident Manager On-Call) | Contacted during production incidents in the #production Slack room |
| AWS Technical Account Managers (TAMs) | External escalation point for confirmed AWS platform issues; contacted via #grpn-and-aws-guests Slack channel |
| NETOPS | Escalation point for network-level throttling incidents across AZs or regions |

## Tech Stack

### Core

> Not applicable. This repository contains no runnable application code. It is a service metadata and documentation repository only.

### Key Libraries

> Not applicable. No code dependencies are present in this repository.
