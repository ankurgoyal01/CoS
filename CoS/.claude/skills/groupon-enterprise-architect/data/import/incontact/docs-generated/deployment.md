---
service: "incontact"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: false
orchestration: "N/A (SaaS)"
environments: []
---

# Deployment

## Overview

> No evidence found in codebase.

InContact is a vendor-managed SaaS platform. There are no Dockerfiles, Kubernetes manifests, Helm charts, Terraform configurations, CI/CD pipeline definitions, or any other deployment artifacts in this repository. The InContact contact centre infrastructure is deployed, scaled, and operated entirely by NICE inContact under a SaaS agreement with Groupon. Groupon's GSS team is responsible for configuring and administering the platform through InContact's admin interface, not through code deployments.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | None | No Dockerfile present |
| Orchestration | None (SaaS) | Vendor-managed |
| Load balancer | None (SaaS) | Vendor-managed |
| CDN | None (SaaS) | Vendor-managed |

## Environments

> No evidence found in codebase.

Environment configuration for the InContact SaaS platform is managed by NICE inContact and the GSS team. Refer to the Owners Manual: https://confluence.groupondev.com/display/GSS/Owners+Manual+-+InContact

## CI/CD Pipeline

> No evidence found in codebase.

No CI/CD pipeline definitions are present in this repository.

## Scaling

> Not applicable — SaaS platform scaled by vendor.

## Resource Requirements

> Not applicable — SaaS platform; resources managed by vendor.

> Deployment configuration managed externally by NICE inContact (vendor SaaS). Internal deployment and operational procedures are documented in the GSS Owners Manual and the ORR linked in `.service.yml`.
