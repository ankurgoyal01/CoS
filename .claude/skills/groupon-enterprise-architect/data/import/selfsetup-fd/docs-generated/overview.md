---
service: "selfsetup-fd"
title: Overview
generated: "2026-03-02T00:00:00Z"
type: overview
domain: "Merchant Onboarding / Booking Tool Self-Setup"
platform: "Continuum (EMEA)"
team: "International Booking-tool (ssamantara)"
status: active
tech_stack:
  language: "PHP"
  language_version: "5.6"
  framework: "Zend Framework"
  framework_version: "1.11.6"
  runtime: "Apache"
  runtime_version: "php:5.6-apache"
  build_tool: "Composer"
  package_manager: "Composer"
---

# EMEA BT Self-Setup (Food & Drinks) Overview

## Purpose

selfsetup-fd is a Groupon-internal web application that allows EMEA employees to self-onboard Food & Drinks merchants onto the Groupon Booking Tool. It retrieves deal and merchant opportunity data from Salesforce, validates eligibility and capping rules, and then orchestrates the creation and configuration of Booking Tool instances via an async MySQL-backed job queue.

## Scope

### In scope

- Presenting a wizard-style UI for employees to initiate Booking Tool setup for F&D merchants
- Querying Salesforce for opportunity and merchant details (`/api/getopportunity`)
- Validating deal eligibility and capping rules before BT creation
- Enqueuing setup jobs and processing them asynchronously via cron
- Creating and configuring Booking Tool instances via the Booking Tool API
- Tracking queue and session state in MySQL

### Out of scope

- Booking Tool platform itself (managed by `bookingToolSystem_7f1d`)
- Salesforce data ownership (managed by Salesforce CRM)
- Merchant-facing interfaces (this tool is employee-only)
- Non-Food-&-Drinks verticals (separate self-setup services handle those)

## Domain Context

- **Business domain**: Merchant Onboarding / Booking Tool Self-Setup
- **Platform**: Continuum (EMEA)
- **Upstream consumers**: Groupon EMEA employees (`grouponEmployee_51c9`) accessing the setup wizard via browser
- **Downstream dependencies**: Salesforce (opportunity/merchant data via HTTPS), Booking Tool System (`bookingToolSystem_7f1d` via HTTPS), MySQL queue database (`continuumEmeaBtSelfSetupFdDb`), Telegraf metrics gateway (`telegrafGateway_6a2b` via HTTP)

## Stakeholders

| Role | Description |
|------|-------------|
| EMEA Booking-tool Team (ssamantara) | Owns and maintains the service |
| EMEA Merchant Operations / Sales | Primary end-users initiating merchant setups |
| Booking Tool Platform Team | Downstream — receives setup requests from this service |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | PHP | 5.6 | `Dockerfile` (`php:5.6-apache`) |
| Framework | Zend Framework | 1.11.6 | `composer.json` |
| Runtime | Apache | php:5.6-apache | `Dockerfile` / `APACHE_LISTEN_PORT=8080` |
| Build tool | Composer | — | `composer.json` / `composer.lock` |
| Deployment tool | Capistrano | 3.6.1 (Ruby 2.3.3) | `Gemfile` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| monolog/monolog | ^1.21 | logging | Structured application logging |
| influxdb-php | ^1.15 | metrics | Emits metrics to InfluxDB via Telegraf gateway |
| Zend_Controller | 1.11.6 | http-framework | MVC routing and front-controller dispatch |
| capistrano | 3.6.1 | scheduling | Ruby-based deployment automation |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
