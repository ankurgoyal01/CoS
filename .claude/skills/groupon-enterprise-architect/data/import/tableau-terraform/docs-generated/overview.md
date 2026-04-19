---
service: "tableau-terraform"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Analytics / DnD Tools"
platform: "GCP"
team: "analytics@groupon.com"
status: active
tech_stack:
  language: "HCL"
  language_version: "Terraform 0.15.5"
  framework: "Terragrunt"
  framework_version: "0.30.7"
  runtime: "Terraform"
  runtime_version: "0.15.5"
  build_tool: "Make + Terragrunt"
  package_manager: "Terragrunt module-ref"
---

# Tableau Server Infrastructure Overview

## Purpose

`tableau-terraform` provisions and manages the full Tableau Server cluster on Google Cloud Platform. It deploys a primary-plus-worker GCE instance group, an internal TCP load balancer, a GCS storage bucket for backups and logs, and TLS certificates across three environments (dev, stable, prod). The repository enables the DnD Tools / Analytics team to version-control, plan, and apply all Tableau infrastructure changes through standard Terraform workflows.

## Scope

### In scope

- Provisioning GCE VM instances (primary node and one or more worker nodes) running Rocky Linux 9
- Configuring Tableau Server installation and cluster initialisation via metadata startup scripts
- Creating and managing a GCP Internal TCP Load Balancer with regional health checks and forwarding rules on ports 80 and 443
- Managing a GCS bucket (`grpn-<env_short_name>-<env_stage>-bucket`) for Tableau backups and log files with lifecycle retention policies
- Uploading and managing self-managed TLS certificates via GCP Certificate Manager
- Writing DNS A-records in the environment-scoped Cloud DNS managed zone
- Managing remote Terraform state in GCS via Terragrunt
- Providing operational scripts for process-status checks, server restarts, and email alerting
- Configuring LDAP/Active Directory identity store integration on Tableau startup

### Out of scope

- Tableau Server software licensing (license key must be provided separately)
- Tableau content publishing (workbooks, dashboards) — handled by Tableau end-users
- GCP Shared VPC and subnet creation — consumed from pre-existing shared VPC projects
- Cloud DNS zone creation — DNS zones are pre-existing; only records are managed here
- LDAP / Active Directory server management
- Monitoring dashboards and alerting infrastructure beyond the cron-based process check scripts

## Domain Context

- **Business domain**: Analytics — internal business intelligence and reporting platform
- **Platform**: GCP (Google Cloud Platform), `us-central1` region
- **Upstream consumers**: Internal analytics users and BI consumers who connect to `analytics.groupondev.com`
- **Downstream dependencies**: GCP Compute Engine, GCS, GCP Certificate Manager, Cloud DNS, GCP Shared VPC, LDAP/Active Directory (`use2-ldap-vip.group.on:389`), Tableau software download server (`downloads.tableau.com`)

## Stakeholders

| Role | Description |
|------|-------------|
| Owner team | DnD Tools (`analytics@groupon.com`, `dnd-tools@groupon.com`) |
| Cloud infrastructure | CloudCore team (supplies GCP service accounts and Shared VPC) |
| Analytics users | Internal Groupon employees who consume Tableau dashboards |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | HCL | — | `modules/**/*.tf`, `envs/**/*.hcl` |
| Framework | Terragrunt | 0.30.7 | `envs/Makefile` (`TERRAGRUNT_VERSION`) |
| Runtime | Terraform | 0.15.5 | `envs/dev/.terraform-version` |
| Build tool | Make | — | `envs/Makefile`, `envs/.terraform-tooling/Makefile` |
| Package manager | Terragrunt module-ref | — | `envs/.terraform-tooling/bin/module-ref` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| google Terraform provider | — | infrastructure | Manages all GCP resources (Compute, GCS, DNS, Certificate Manager) |
| google-beta Terraform provider | — | infrastructure | Access to beta GCP features (Certificate Manager) |
| Terragrunt | 0.30.7 | orchestration | DRY wrapper for Terraform; manages remote state and module sourcing |
| Rocky Linux 9 (optimized GCP) | `v20250709` | os | Base OS image for all Tableau GCE VMs |
| Tableau Server RPM | 2025.1.4 | application | Tableau Server application binary installed on VMs |
| TSM (Tableau Services Manager) | bundled | application | CLI tool used to configure and initialise Tableau Server |
| tabcmd | bundled | application | CLI used to create the initial Tableau REST API user |
| Python 3 (stdlib) | — | scripting | Operational scripts: process status checks and email alerting |
| pre-commit (check-jira hook) | v0.0.2 | dev-tooling | Enforces JIRA ticket reference (`ED` project key) in commit messages |
