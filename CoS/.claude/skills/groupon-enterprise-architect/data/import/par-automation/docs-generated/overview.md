---
service: "par-automation"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Service Mesh / Access Control"
platform: "GCP Kubernetes (Conveyor)"
team: "cloud-routing@groupon.com"
status: active
tech_stack:
  language: "Go"
  language_version: "1.20"
  framework: "net/http"
  framework_version: "stdlib"
  runtime: "Alpine Linux"
  runtime_version: "latest"
  build_tool: "Go toolchain / Docker multi-stage build"
  package_manager: "Go modules (go.mod)"
---

# PAR Automation Overview

## Purpose

PAR Automation is a Go HTTP service that automates Policy Access Request (PAR) processing for Groupon's Hybrid Boundary service mesh. When a developer submits a PAR request through the Hybrid Boundary UI, this service evaluates the data-classification and regulatory attributes of both the requesting service and the target domain, then automatically approves or denies the request according to a fixed rule set. For approved requests in production, it creates the required Jira PAR and GPROD tickets and directly updates the Hybrid Boundary authorization policy configuration.

## Scope

### In scope

- Receiving PAR requests via `POST /release/par` from the Hybrid Boundary UI
- Looking up service metadata and regulatory classifications (C1/C2/C3/SOX/PCI) from the Service Portal
- Evaluating PAR eligibility according to the data-classification policy rules
- Detecting and rejecting duplicate PAR requests
- Creating PAR and GPROD Jira tickets (production environment only)
- Updating Hybrid Boundary authorization policies via the Hybrid Boundary Lambda API
- Exposing a health check endpoint at `GET /release/healthcheck`

### Out of scope

- Maintaining the Service Portal service registry (owned by the service-portal service)
- Hybrid Boundary UI rendering and form submission (owned by `continuumHybridBoundaryUi`)
- Long-term storage of PAR request history (delegated to Jira)
- Custom PAR approval workflows beyond the automated classification rules
- Human-in-the-loop approval flows (handled externally via Jira)

## Domain Context

- **Business domain**: Service Mesh / Access Control
- **Platform**: GCP Kubernetes via Conveyor (CMF Helm charts)
- **Upstream consumers**: Hybrid Boundary UI (`continuumHybridBoundaryUi`) — calls `POST /release/par` on PAR form submission
- **Downstream dependencies**: Service Portal (service metadata), Hybrid Boundary Lambda API (policy writes), Okta IdP (OAuth token for Hybrid Boundary calls), Jira (`continuumJiraService`), GCP Secret Manager (`cloudPlatform`)

## Stakeholders

| Role | Description |
|------|-------------|
| Service owners / developers | Submit PAR requests via the Hybrid Boundary UI to gain inter-service access |
| Cloud Routing team (cloud-routing@groupon.com) | Own and operate this service; approve BAST classification rule changes |
| Security / BAST | Define the classification rules that govern automated approval |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Go | 1.20 | `Dockerfile` |
| Framework | net/http | stdlib | `agent/par-automation/main.go` |
| Runtime | Alpine Linux | latest | `Dockerfile` |
| Build tool | Docker multi-stage build | — | `Dockerfile` |
| Package manager | Go modules | — | `go.mod` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `cloud.google.com/go/secretmanager` | v1.11.5 | secrets | Reads credentials from GCP Secret Manager |
| `github.com/andygrunwald/go-jira` | v1.13.0 | http-client | Creates and transitions Jira PAR/GPROD issues |
| `github.com/spf13/viper` | v1.7.1 | configuration | Environment-driven config loading with defaults |
| `github.com/pkg/errors` | v0.9.1 | logging | Structured error wrapping for Jira API responses |
| `github.com/trivago/tgo` | v1.0.1 | serialization | Jira custom-field `MarshalMap` support |
| `gopkg.in/yaml.v2` | v2.3.0 | serialization | YAML support (indirect, used by Viper) |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See `go.mod` for the full list.
