---
service: "contract_service"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Deal Management"
platform: "Continuum"
team: "Deal Management Services"
status: active
tech_stack:
  language: "Ruby"
  language_version: "2.2.3"
  framework: "Rails"
  framework_version: "3.2.22.5"
  runtime: "Unicorn"
  runtime_version: "4.3.1"
  build_tool: "Rake 0.9.2.2"
  package_manager: "Bundler"
---

# Contract Service (Cicero) Overview

## Purpose

Contract Service (also known as Cicero) stores versioned document templates and manages the full lifecycle of merchant contracts for Groupon's Deal Builder and merchant self-service workflows. It enables creation, versioning, rendering, and signing of contracts by accepting merchant data, validating it against an XSD schema, and rendering output in HTML, PDF, or plain text via XSLT templates. The service is SOX/PCI-scoped and is the canonical system of record for all merchant contract agreements.

## Scope

### In scope

- Storing and versioning contract definition templates (XSD schemas, XSLT render templates)
- Creating, reading, updating, and deleting merchant contract instances
- Validating merchant-supplied `user_data` against the contract definition schema before persisting
- Rendering contract instances as HTML, PDF (via PDFKit/wkhtmltopdf), and plain text
- Recording electronic or acceptance-based contract signatures with IP address capture
- Tracking contract version history on every data change
- Providing a sample/example contract rendering endpoint per definition

### Out of scope

- Merchant authentication and identity management (handled upstream)
- Deal creation, pricing, or publishing workflows (handled by Deal Builder and Deal Management Services)
- Uploading and managing contract definition assets — this is driven from the merchant-self-service-engine via a Rake task
- Email delivery of signed contracts

## Domain Context

- **Business domain**: Deal Management
- **Platform**: Continuum
- **Upstream consumers**: `continuumMerchantSelfService` (merchant self-service engine), `clo-campaign` service
- **Downstream dependencies**: MySQL via DaaS (contract and definition storage), metrics stack (Wavefront/Telegraf)

## Stakeholders

| Role | Description |
|------|-------------|
| Deal Management Services team | Service owners (dms-dev@groupon.com), responsible for development and operations |
| Merchant Self-Service Engine team | Primary API consumer; drives contract definition uploads and contract creation |
| SOX/PCI Compliance | Service handles class-4 personal data (merchant signatures, user data) and is in SOX scope |
| Production Operations (IMOC) | Escalation for P1/P2 incidents via PagerDuty (PXM5GIL) |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Ruby | 2.2.3 | `.ruby-version` |
| Framework | Rails | 3.2.22.5 | `Gemfile` |
| Runtime | Unicorn | 4.3.1 | `Gemfile` |
| Build tool | Rake | 0.9.2.2 | `Gemfile` |
| Package manager | Bundler | — | `Gemfile` / `Gemfile.lock` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `mysql2` | 0.3.14 | db-client | MySQL adapter for ActiveRecord |
| `activerecord` | 3.2.22.5 | orm | ORM for contract, definition, identity, and version models |
| `pdfkit` | 0.8.4.3.2 | serialization | Converts rendered HTML contract to PDF via wkhtmltopdf |
| `wkhtmltopdf-binary` | 0.12.3 | serialization | Binary for PDF generation from HTML |
| `nokogiri` | 1.6.1 | serialization | HTML parsing for plain-text rendering of contracts |
| `uuidtools` | 2.1.3 | serialization | UUID generation for contract and definition primary keys |
| `uuid-support` | 1.1.6 | serialization | UUID column support for ActiveRecord models |
| `sonoma-metrics` | — | metrics | Groupon internal metrics emission (Wavefront) |
| `sonoma-logger` | — | logging | Groupon internal structured logging (Steno) |
| `sonoma-request-id` | — | logging | Propagates request IDs across service calls |
| `rspec` | 2.14.1 | testing | Unit and integration test framework |
| `factory_girl_rails` | 4.3.0 | testing | Test data factories |
| `capistrano` | 2.12.0 | deployment | Legacy on-prem deployment tooling |
