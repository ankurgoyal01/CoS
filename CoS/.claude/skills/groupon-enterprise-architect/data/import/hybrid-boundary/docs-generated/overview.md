---
service: "hybrid-boundary"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Cloud Routing / Service Mesh"
platform: "Continuum (AWS)"
team: "Cloud Routing"
status: active
tech_stack:
  language: "Go, Python"
  language_version: "Go 1.18, Python 3.9"
  framework: "Envoy xDS (go-control-plane)"
  framework_version: "v0.11.1"
  runtime: "AWS Lambda, EC2 (Alpine Linux)"
  runtime_version: "Lambda (Go runtime), EC2"
  build_tool: "Make, Jenkins, Packer, Terraform"
  package_manager: "Go modules, Pipenv"
---

# Hybrid Boundary Overview

## Purpose

Hybrid Boundary is a network of edge proxies managing service-to-service and edge communication between on-prem and AWS environments. It provides a centralized service registry, a Go-based xDS control plane that programs Envoy proxy instances, and administrative APIs for managing service endpoints, traffic shifting, and authorization policies. The system enables teams to register services, route traffic across AWS clusters, and execute controlled traffic shifts without manual proxy reconfiguration.

## Scope

### In scope

- Envoy xDS control-plane serving cluster, listener, and route configurations to edge proxy instances
- Service and endpoint registration via a REST administrative API (AWS API Gateway + Lambda)
- Traffic shift orchestration using AWS Step Functions (incremental weight changes between endpoints)
- DNS lifecycle management for edge proxy targets via Route53 weighted records
- Akamai IP range allow-list maintenance on edge proxy instances
- JWT-based authentication and group-based authorization for all administrative operations
- Change history and revert capability for service configurations
- Conveyor maintenance-window enforcement and ProdCat approval gating for production changes

### Out of scope

- Application-layer business logic (no business domain services hosted here)
- Ingress configuration for services not registered in the Hybrid Boundary registry
- SSL/TLS termination configuration beyond what is provided to Envoy via xDS
- Monitoring and metrics collection beyond Prometheus metrics emitted by the agent

## Domain Context

- **Business domain**: Cloud Routing / Service Mesh
- **Platform**: Continuum (AWS)
- **Upstream consumers**: Platform teams and service teams that register services and manage edge routing via the API; Envoy proxy instances that subscribe to the xDS control-plane
- **Downstream dependencies**: AWS DynamoDB (service registry), AWS Route53 (DNS records), AWS Step Functions (shift workflows), AWS API Gateway (API front door), Akamai (IP range allow-lists), Conveyor (maintenance-window checks), ProdCat (production change approval), Service Portal (service name validation)

## Stakeholders

| Role | Description |
|------|-------------|
| Cloud Routing Team | Service owner; operates and maintains Hybrid Boundary infrastructure (cloud-routing@groupon.com) |
| SRE / Platform Teams | Consumer of the administrative API; registers services and manages traffic shifts |
| Service Teams | Register their services in the Hybrid Boundary registry to participate in edge routing |
| On-call SRE | Responds to PagerDuty alerts for the hybrid-boundary service (PAXBCM9) |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language (agent) | Go | 1.18 | `go.mod` |
| Language (tooling) | Python | 3.9 | `Pipfile`, `.python-version` |
| Framework | go-control-plane (Envoy xDS) | v0.11.1 | `go.mod` |
| Transport (control plane) | gRPC | v1.55.0 | `go.mod` |
| Runtime (agent) | AWS Lambda (Go), EC2 | — | `agent/Dockerfile`, `.service.yml` |
| Build tool | Make + Jenkins + Packer + Terraform | — | `Makefile`, `Jenkinsfile` |
| Package manager (Go) | Go modules | — | `go.mod` |
| Package manager (Python) | Pipenv | — | `Pipfile` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `github.com/envoyproxy/go-control-plane` | v0.11.1 | http-framework | Builds and serves Envoy xDS resources (clusters, listeners, routes, endpoints) |
| `github.com/aws/aws-sdk-go` | v1.36.22 | sdk | AWS SDK for DynamoDB, S3, ELB, Step Functions, and Route53 access |
| `github.com/aws/aws-lambda-go` | v1.13.3 | http-framework | AWS Lambda handler runtime for the API Lambda |
| `github.com/prometheus/client_golang` | v1.12.2 | metrics | Prometheus metrics exposure on the agent admin endpoint |
| `github.com/sirupsen/logrus` | v1.6.0 | logging | Structured JSON logging across all agent components |
| `gopkg.in/square/go-jose.v2` | v2.4.1 | auth | JWT parsing and validation using JWKS for API authentication |
| `google.golang.org/grpc` | v1.55.0 | http-framework | gRPC server serving xDS configuration to Envoy |
| `github.com/grpc-ecosystem/go-grpc-prometheus` | v1.2.0 | metrics | Prometheus interceptors for gRPC server instrumentation |
| `github.com/thoas/go-funk` | v0.9.2 | validation | Utility functions including slice deduplication |
| `github.com/google/uuid` | v1.3.0 | serialization | UUID generation for xDS snapshot versioning |
| `cerberus` (Python) | * | validation | Config YAML validation in Python tooling |
| `ansible` (Python) | * | scheduling | Infrastructure automation in the tooling layer |
| `boto3` (Python) | * | sdk | Python-side AWS API access |
