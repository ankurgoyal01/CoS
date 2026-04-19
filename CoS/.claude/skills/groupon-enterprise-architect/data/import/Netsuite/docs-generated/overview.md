---
service: "Netsuite"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Finance / ERP"
platform: "Continuum"
team: "FS - NetSuite"
status: active
tech_stack:
  language: "JavaScript (SuiteScript)"
  language_version: "1.x / 2.x"
  framework: "Oracle NetSuite SuiteScript"
  framework_version: "1.x / 2.x"
  runtime: "Oracle NetSuite Cloud Platform"
  runtime_version: "current"
  build_tool: "SuiteCloud CLI"
  package_manager: "npm (dev tooling only)"
---

# NetSuite Overview

## Purpose

NetSuite is Groupon's Oracle cloud ERP system. This repository contains the SuiteScript customizations deployed across three regional NetSuite instances: GOODS (NS2, the Goods marketplace entity), NAM (NS3, North America), and INTL (NS1, International). The scripts automate accounts-payable lifecycle management, treasury payment initiation, OTP purchase-order exports, procurement data exchange with Coupa, and accounting close/reconciliation processes.

## Scope

### In scope

- Vendor bill and vendor credit creation via RESTlet endpoints (GOODS instance)
- Vendor bill transaction numbering, duplicate invoice detection, and AP account auto-assignment
- OTP (Order-to-Pay) purchase-order export to GLS (Drop-Ship) and to PO Manager (EMEA)
- JPM (JPMorgan Chase) ACH payment batch initiation via SnapLogic triggers
- Kyriba treasury outbound and inbound file synchronization via SnapLogic pipelines
- Balance pull and reconciliation trigger to SnapLogic (BlackLine close support)
- Coupa header tax/shipping line distribution on vendor bills
- Intercompany sales order, invoice, and bill creation
- Three-way match (PO/receipt/bill) automation
- FX reclassification journal entries
- Audit trail deletion tracking
- ESA (Electronic Signature Agreement) status checks
- Script deployment lifecycle management (approval, promotion)

### Out of scope

- NetSuite core ERP configuration (chart of accounts, subsidiaries, roles) — managed directly in NetSuite
- Coupa platform administration — owned by the Coupa team
- Kyriba treasury platform configuration — owned by the Treasury team
- BlackLine reconciliation workspace setup — owned by the Accounting team
- Anaplan planning model maintenance — owned by the FP&A team
- SnapLogic pipeline logic — owned by the Integration/SnapLogic team

## Domain Context

- **Business domain**: Finance / ERP — Accounts Payable, Treasury, Procurement, Close & Reconciliation
- **Platform**: Continuum
- **Upstream consumers**: SnapLogic integration pipelines, Coupa AP system, GLS invoicing service, PO Manager (EMEA)
- **Downstream dependencies**: SnapLogic (orchestration), JPMorgan Chase payments, Kyriba treasury, BlackLine reconciliation, Anaplan (INTL FX planning)

## Stakeholders

| Role | Description |
|------|-------------|
| FS - NetSuite Team | Script development, deployment, and support (team owner: dcancelado) |
| Finance / AP Operations | Primary consumers of vendor bill automation and payment batching |
| Treasury | Owners of Kyriba integration and payment file workflows |
| Accounting Close | Owners of BlackLine reconciliation and period-end processes |
| FP&A | Owners of Anaplan FX/planning data exports (INTL instance) |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | JavaScript (SuiteScript) | 1.x / 2.x | `GOODS/src/FileCabinet/SuiteScripts/*.js` |
| Framework | Oracle NetSuite SuiteScript | 1.x / 2.x | All `.js` files use `nlapiCreateRecord`, `nlapiRequestURL`, etc. |
| Runtime | Oracle NetSuite Cloud Platform | current | `.service.yml` — hosted on NetSuite SaaS |
| Build tool | SuiteCloud CLI | current | `GOODS/package.json` (`@oracle/suitecloud-unit-testing`) |
| Package manager | npm | current | `GOODS/package.json` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `@oracle/suitecloud-unit-testing` | 1.1.3 | testing | Unit test harness for SuiteScript |
| `jest` | 26.6.3 | testing | JavaScript test runner |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
