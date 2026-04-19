---
service: "PizzaNG"
title: Deployment
generated: "2026-03-03T00:00:00Z"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [development, staging, production]
---

# Deployment

## Overview

PizzaNG is a Continuum-platform I-Tier application deployed as a containerized Node.js service. The service delivers both the BFF (`continuumPizzaNgService`) and the client-side React/Chrome extension assets (`continuumPizzaNgUi`). Deployment follows the standard Continuum I-Tier pattern with Docker containerization and Kubernetes orchestration. Specific manifest paths and pipeline configuration are managed externally to this architecture repository.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | Deployment configuration managed externally |
| Orchestration | Kubernetes | Manifest paths managed externally |
| Load balancer | Internal LB / Akamai | Standard Continuum I-Tier routing |
| CDN | Akamai | Static asset delivery for React/extension bundles |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| development | Local development and feature testing | local | localhost |
| staging | Pre-production validation | US | Internal staging URL |
| production | Live CS agent traffic | US | Internal production URL |

## CI/CD Pipeline

- **Tool**: No evidence found in codebase. Standard Continuum CI/CD pipeline expected.
- **Config**: Deployment configuration managed externally.
- **Trigger**: No evidence found in codebase.

### Pipeline Stages

> No evidence found in codebase. Deployment procedures to be defined by service owner.

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | No evidence found in codebase | — |
| Memory | No evidence found in codebase | — |
| CPU | No evidence found in codebase | — |

## Resource Requirements

> Deployment configuration managed externally. Resource requests and limits are not discoverable from this repository.
