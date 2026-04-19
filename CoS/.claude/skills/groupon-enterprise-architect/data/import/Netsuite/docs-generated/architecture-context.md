---
service: "Netsuite"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers:
    - "continuumNetsuiteGoodsCustomizations"
    - "continuumNetsuiteNamCustomizations"
    - "continuumNetsuiteIntlCustomizations"
---

# Architecture Context

## System Context

The NetSuite customizations sit within the `continuumSystem` as three distinct containers, one per regional ERP tenant. Each container holds SuiteScript code deployed directly into its NetSuite instance's File Cabinet. The three instances (GOODS/NS2, NAM/NS3, INTL/NS1) are federated through shared integration patterns: all three communicate outbound to SnapLogic as an integration broker, all synchronize AP/procurement records with Coupa, and all push reconciliation updates to BlackLine. NAM and GOODS additionally initiate JPMorgan Chase payment transfers. INTL publishes FX and planning data to Anaplan. All three use Kyriba for treasury payment file exchange.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| NetSuite GOODS Customizations | `continuumNetsuiteGoodsCustomizations` | Container | SuiteScript 1.x/2.x | current | Customizations deployed to the Goods marketplace NetSuite instance (NS2) |
| NetSuite NAM Customizations | `continuumNetsuiteNamCustomizations` | Container | SuiteScript 1.x/2.x | current | Customizations deployed to the North America NetSuite instance (NS3) |
| NetSuite INTL Customizations | `continuumNetsuiteIntlCustomizations` | Container | SuiteScript 1.x/2.x | current | Customizations deployed to the International NetSuite instance (NS1) |

## Components by Container

### NetSuite GOODS Customizations (`continuumNetsuiteGoodsCustomizations`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `goodsScheduledScripts` | Batch automations for AP, reconciliation, and goods-specific period processes | SuiteScript Scheduled Script |
| `goodsRestlets` | HTTP endpoints for vendor, invoice, and integration data exchange | SuiteScript RESTlet |
| `goodsUserEventScripts` | Record lifecycle extensions for policy checks, defaults, and workflow actions | SuiteScript User Event |
| `goodsSharedLibraries` | Reusable helper modules (lookups, utilities, shared business logic) | SuiteScript Library |

### NetSuite NAM Customizations (`continuumNetsuiteNamCustomizations`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `namScheduledScripts` | Batch automations, reconciliations, and timed back-office jobs | SuiteScript Scheduled Script |
| `namRestlets` | HTTP endpoints for integration and data import/export workloads | SuiteScript RESTlet |
| `namUserEventScripts` | Record lifecycle extensions for validation, enrichment, and workflow actions | SuiteScript User Event |
| `namSharedLibraries` | Reusable helper modules (lookups, SFTP, formatting, utility logic) | SuiteScript Library |

### NetSuite INTL Customizations (`continuumNetsuiteIntlCustomizations`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `intlScheduledScripts` | Batch automations, country-specific processing, and timed accounting jobs | SuiteScript Scheduled Script |
| `intlRestlets` | HTTP endpoints for integration and data import/export workloads | SuiteScript RESTlet |
| `intlUserEventScripts` | Record lifecycle extensions for approvals, controls, and validations | SuiteScript User Event |
| `intlSharedLibraries` | Reusable helper modules (lookups, utilities, shared business logic) | SuiteScript Library |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumNetsuiteNamCustomizations` | `snapLogic` | Triggers and exchanges integration payloads | HTTPS/REST |
| `continuumNetsuiteNamCustomizations` | `coupa` | Synchronizes AP/procurement data | HTTPS/REST |
| `continuumNetsuiteNamCustomizations` | `kyriba` | Sends and receives treasury payment files | HTTPS/REST via SnapLogic |
| `continuumNetsuiteNamCustomizations` | `jpmPayments` | Initiates payment transfer workflows | HTTPS/REST via SnapLogic |
| `continuumNetsuiteNamCustomizations` | `blackLine` | Pushes reconciliation and close process updates | HTTPS/REST via SnapLogic |
| `continuumNetsuiteIntlCustomizations` | `snapLogic` | Triggers and exchanges integration payloads | HTTPS/REST |
| `continuumNetsuiteIntlCustomizations` | `coupa` | Synchronizes AP/procurement data | HTTPS/REST |
| `continuumNetsuiteIntlCustomizations` | `kyriba` | Sends and receives treasury payment files | HTTPS/REST via SnapLogic |
| `continuumNetsuiteIntlCustomizations` | `anaplan` | Publishes FX and planning data exports | HTTPS/REST via SnapLogic |
| `continuumNetsuiteIntlCustomizations` | `blackLine` | Pushes reconciliation and close process updates | HTTPS/REST via SnapLogic |
| `continuumNetsuiteGoodsCustomizations` | `snapLogic` | Triggers and exchanges integration payloads | HTTPS/REST |
| `continuumNetsuiteGoodsCustomizations` | `coupa` | Synchronizes AP/procurement data | HTTPS/REST |
| `continuumNetsuiteGoodsCustomizations` | `kyriba` | Sends and receives treasury payment files | HTTPS/REST via SnapLogic |
| `continuumNetsuiteGoodsCustomizations` | `jpmPayments` | Initiates payment transfer workflows | HTTPS/REST via SnapLogic |
| `continuumNetsuiteGoodsCustomizations` | `blackLine` | Pushes reconciliation and close process updates | HTTPS/REST via SnapLogic |

## Architecture Diagram References

- Dynamic integration view: `dynamic-netsuite-integration-flows`
- Component view (GOODS): `components-continuum-netsuite-goods`
- Component view (NAM): `components-continuum-netsuite-nam`
- Component view (INTL): `components-continuum-netsuite-intl`
