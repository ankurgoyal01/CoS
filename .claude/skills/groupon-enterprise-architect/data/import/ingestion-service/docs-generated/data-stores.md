---
service: "ingestion-service"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumIngestionServiceMysql"
    type: "mysql"
    purpose: "Operational datastore for auth client IDs, Salesforce OAuth token state, failed SF ticket job records, and merchant-approved refund audit data"
---

# Data Stores

## Overview

The ingestion-service owns a single MySQL database provisioned via Groupon's DaaS (Database-as-a-Service) platform. This database serves four distinct functions: authenticating API callers, caching Salesforce OAuth tokens, persisting failed Salesforce ticket creation requests for retry, and recording merchant-approved refund audit entries. Schema migrations are managed via `jtier-migrations` with Quartz tables also managed via `jtier-quartz-mysql-migrations`.

## Stores

### Ingestion Service MySQL (`continuumIngestionServiceMysql`)

| Property | Value |
|----------|-------|
| Type | MySQL |
| Architecture ref | `continuumIngestionServiceMysql` |
| Purpose | Auth client credential store, Salesforce token cache, failed ticket job queue, merchant refund audit trail |
| Ownership | owned |
| Migrations path | Managed via `jtier-migrations` (standard JTier migrations directory) |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Auth client credentials | Stores registered `client_id` + secret pairs for API authentication | `client_id`, hashed secret, grant type |
| SF OAuth token store (`SfTokenDBI`) | Caches Salesforce OAuth access tokens to avoid re-authentication on every request | token value, expiry, Salesforce instance URL |
| SF ticket creation job queue (`SfTicketCreationJobDBI`) | Persists failed Salesforce ticket creation requests for async retry by `SfCreateTicketFailuresJob` | `requestData` (JSON payload), status, retry count, timestamps |
| Merchant-approved refunds audit (`MerchantApprovedRefundsAuditDBI`) | Records each refund processed as part of the merchant-approved refund flow for auditability | refund identifier, order reference, status, processed timestamp |
| Quartz job tables | Quartz scheduler state for `SfCreateTicketFailuresJob` and `RefundMerchantApprovedOrdersJob` | job name, trigger, state, next fire time |

#### Access Patterns

- **Read**: Auth client lookup on every authenticated API request; SF token fetch before each Salesforce API call; failed job queue polling on each Quartz job execution; merchant-approved refunds fetched from Salesforce then audited after processing
- **Write**: SF token upsert after Salesforce OAuth flow; failed ticket request insertion when Salesforce case creation returns 500; audit record insertion after each merchant-approved refund attempt; job state updates by Quartz framework
- **Indexes**: Not directly visible from source — standard JTier JDBI patterns suggest primary key and status indexes on job queue table

## Caches

> No evidence found in codebase. No Redis or in-memory cache layer is used; Salesforce OAuth tokens are cached in MySQL rather than a dedicated cache.

## Data Flows

1. On each authenticated API call, the Auth component reads client credentials from MySQL via `JdbiClientIdDao`.
2. Before calling Salesforce, the Integration Client reads the cached OAuth token from MySQL via `SfTokenDBI`; if absent or expired, it performs the OAuth flow and writes the new token back.
3. When a `POST /odis/api/v1/salesforce/escalate/ticket/create` call fails at Salesforce, the service writes the full request payload to the job queue table via `SfTicketCreationJobDBI`.
4. The `SfCreateTicketFailuresJob` reads one failed request at a time from MySQL, attempts Salesforce ticket creation, and removes or updates the record on success.
5. The `RefundMerchantApprovedOrdersJob` reads merchant-approved refund orders from Salesforce, processes them through CAAP, and writes an audit record to MySQL via `MerchantApprovedRefundsAuditDBI`.
