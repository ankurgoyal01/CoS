---
service: "selfsetup-hbw"
title: Overview
generated: "2026-03-02T00:00:00Z"
type: overview
domain: "Merchant Onboarding / Booking Tool"
platform: "Continuum (EMEA)"
team: "International Booking-tool (booking-tool-engineers@groupon.com)"
status: active
tech_stack:
  language: "PHP"
  language_version: "5.6"
  framework: "Zend Framework"
  framework_version: "1.11.6"
  runtime: "Apache"
  runtime_version: "2.4"
  build_tool: "Composer / Capistrano"
  package_manager: "Composer"
---

# EMEA Booking Tool Self Setup — Health & Beauty Overview

## Purpose

selfsetup-hbw (internal: `emea_bt_self_setup_hb`) is a web application that enables Health & Beauty merchants in EMEA markets to self-configure their Groupon booking profiles — including availability windows, capacity capping, and service catalog — without requiring Groupon agent assistance. It acts as the integration bridge between the merchant-facing setup UI, Salesforce (authoritative CRM), and the BookingTool API (live booking engine).

## Scope

### In scope

- Presenting a setup wizard UI to merchants who follow a Salesforce-generated invitation link
- Resolving merchant opportunity and account data from Salesforce via SOQL
- Accepting and validating merchant availability schedule submissions (`/week`)
- Accepting and validating capacity/capping settings (`/capping`)
- Pushing finalised configuration to Salesforce and the BookingTool API (`/sf`)
- Persisting in-progress setup state in a MySQL database
- Running scheduled cron jobs for merchant reminder emails and DWH reconciliation
- Emitting structured logs to Splunk and metrics to Telegraf/InfluxDB
- Supporting eight locales: `en_GB`, `de_DE`, `es_ES`, `fr_FR`, `it_IT`, `nl_NL`, `pl_PL`, `ja_JP`

### Out of scope

- Live booking / appointment scheduling (handled by BookingTool API)
- CRM record creation or account management (owned by Salesforce / Salesforce team)
- Payment processing
- Consumer-facing Groupon deal pages
- Non-Health & Beauty merchant onboarding (separate SSU variants)

## Domain Context

- **Business domain**: Merchant Onboarding / Booking Tool
- **Platform**: Continuum (EMEA)
- **Upstream consumers**: Merchants access directly via browser; Salesforce triggers the invitation link
- **Downstream dependencies**: Salesforce (opportunity/account data, final configuration push), BookingTool API (per-country endpoints, availability/capacity updates)

## Stakeholders

| Role | Description |
|------|-------------|
| EMEA Health & Beauty merchant | End user who completes the self-setup wizard |
| International Booking-tool team | Owns and operates the service (ssamantara, booking-tool-engineers@groupon.com) |
| Salesforce / CRM team | Provides authoritative merchant opportunity data and receives final configuration |
| BookingTool platform team | Receives availability and capacity configuration via API |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | PHP | 5.6 | Dockerfile (`php:5.6-apache`) |
| Framework | Zend Framework | 1.11.6 | composer.json |
| Runtime | Apache | 2.4 | Dockerfile (`php:5.6-apache`) |
| Build tool | Composer | — | composer.json / composer.lock |
| Deployment tool | Capistrano | 3.17.0 | Capfile |
| Package manager | Composer | — | composer.json |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `monolog/monolog` | ^1.21 | logging | PSR-3 structured application logging |
| `vube/monolog-splunk-formatter` | ^1.0 | logging | Formats log records for Splunk ingestion |
| `influxdb/influxdb-php` | ^1.15 | metrics | Writes HTTP and business metrics to InfluxDB/Telegraf |
| `Zend_Translate` | 1.11.6 | ui-framework | Locale-aware i18n for 8 EMEA/APAC locales |
| `Zend_Db` | 1.11.6 | db-client | MySQL database access layer |
| `Zend_Controller` | 1.11.6 | http-framework | MVC request routing and dispatch |
| `ext-curl` | — | http-client | HTTP communication with Salesforce and BookingTool APIs |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
