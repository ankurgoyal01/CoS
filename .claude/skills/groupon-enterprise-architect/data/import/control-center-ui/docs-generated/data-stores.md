---
service: "control-center-ui"
title: Data Stores
generated: "2026-03-03T00:00:00Z"
type: data-stores
stores:
  - id: "ember-data-store"
    type: "in-memory"
    purpose: "In-memory Ember Data model store for client-side state management"
---

# Data Stores

## Overview

Control Center UI does not own or operate any server-side data stores. All persistent sale and pricing data is stored and managed by the DPCC Service backend. The application uses Ember Data's in-memory store as a client-side cache of model records fetched from the backend during a session. The bulk sale uploader feature leverages AWS S3 (via aws-sdk) for file staging, but the bucket is owned and managed by backend infrastructure, not this SPA.

## Stores

### Ember Data In-Memory Store (`ember-data-store`)

| Property | Value |
|----------|-------|
| Type | in-memory |
| Architecture ref | `continuumControlCenterUiWeb` |
| Purpose | Client-side cache of sale and pricing model records fetched from DPCC Service and PCCJT Service |
| Ownership | owned (client-side, per-session) |
| Migrations path | Not applicable |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Sale | Represents a sale event in the Sale Builder | sale ID, name, start/end dates, deals, status |
| Deal | Represents a deal/product assigned to a sale | deal ID, title, price, division |
| Division | Represents a geographic or business division for deal scoping | division ID, name, region |
| Price | Represents a price configuration for Price Changer | deal ID, price value, effective date |

#### Access Patterns

- **Read**: Ember Data adapter fetches records from DPCC / PCCJT REST endpoints on model query; results cached in store for the session.
- **Write**: Ember Data adapter pushes model changes (create/update/delete) to DPCC REST endpoints; store updated optimistically or on confirmation.
- **Indexes**: Not applicable — in-memory Ember Data identity map (keyed by record ID).

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| Ember Data identity map | in-memory | Avoids redundant API calls within a browser session | Session lifetime (no explicit TTL) |

## Data Flows

All persistent data flows through the SPA to the DPCC Service backend via HTTPS proxy. The bulk sale uploader parses CSV files client-side using papaparse, then uploads file content to AWS S3 via the aws-sdk, after which the backend processes the upload. No ETL, CDC, or replication patterns exist at this layer.

> This service is stateless server-side and does not own any server-side data stores.
