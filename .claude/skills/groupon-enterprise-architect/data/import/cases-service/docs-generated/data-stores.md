---
service: "cases-service"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumMerchantCaseRedis"
    type: "redis"
    purpose: "Transient cache for unread case counts and knowledge management session data"
  - id: "salesForce"
    type: "external-crm"
    purpose: "Primary record of truth for all merchant support cases"
---

# Data Stores

## Overview

MCS does not own a relational database. All durable case data is stored in and retrieved from Salesforce CRM via the Salesforce REST API. A Redis instance (`continuumMerchantCaseRedis`) provides a transient cache for unread case/refund counts and knowledge management data to reduce Salesforce API call volume. The OWNERS_MANUAL.md historically noted "MCS does not use any caching", but the active codebase (`CasesServiceConfiguration` with `JedisFactory`, `ownerCacheEnabled`, configuration key `casesConfig.ownerCacheEnabled: true`) confirms Redis is actively used.

## Stores

### Salesforce CRM (external, authoritative case record)

| Property | Value |
|----------|-------|
| Type | External CRM / REST API (Salesforce) |
| Architecture ref | `salesForce` |
| Purpose | Primary record of truth for all merchant support case data — standard cases, refund cases, deal-edit cases, callback cases, DAC7/RRDP cases, email messages, attachments |
| Ownership | external |
| Migrations path | Not applicable — schema managed by Salesforce administrators |

#### Key Entities

| Entity / Object | Purpose | Key Fields |
|----------------|---------|-----------|
| `Case` (SF Object) | Core support case record | `Id`, `CaseNumber`, `Status`, `Subject`, `Description`, `RecordTypeId`, `Web2Case_Origin__c`, `Issue_Category__c`, `Issue_Details__c`, `Case_Raised_by__c` |
| `EmailMessage` (SF Object) | Email thread entries within a case | `Id`, `ParentId`, `TextBody`, `HtmlBody`, `FromAddress`, `ToAddress` |
| `Attachment` (SF Object) | Files attached to case emails | `Id`, `ParentId`, `Name`, `ContentType`, `Body` |
| `Contact` (SF Object) | Merchant contact record linked to cases | `Id`, `AccountId`, `Email` |
| `Account` (SF Object) | Salesforce account representing a merchant | `Id`, `Name` |
| `Opportunity` (SF Object) | Deal/opportunity records consumed from message bus | `Id`, `StageName`, `AccountId` |

#### Access Patterns

- **Read**: SOQL queries via Salesforce REST API for case lists (filtered by `AccountId`, date range, status, `RecordTypeId`), single case retrieval, email message retrieval, attachment download, banking/payment status
- **Write**: Salesforce Case object creation (multiple record types), case status update (`Status=Closed`), case reply (EmailMessage creation), attachment upload
- **Indexes**: Managed by Salesforce; MCS queries primarily by Salesforce `AccountId` linked to merchant UUID

### Merchant Cases Redis (`continuumMerchantCaseRedis`)

| Property | Value |
|----------|-------|
| Type | Redis |
| Architecture ref | `continuumMerchantCaseRedis` |
| Purpose | Transient cache for unread case counts, unread refund counts, and knowledge management / support-tree lookups |
| Ownership | owned |
| Migrations path | Not applicable — schema-less key-value store |

#### Key Entities

| Entity / Key Pattern | Purpose | Key Fields |
|---------------------|---------|-----------|
| Unread case count | Count of unread cases per merchant, refreshed on case create/update events | Keyed by merchant UUID |
| Unread refund count | Count of unread refund cases per merchant | Keyed by merchant UUID |
| Owner cache entries | Cached Salesforce owner/contact data | Enabled via `casesConfig.ownerCacheEnabled=true` |

#### Access Patterns

- **Read**: Count lookups on `GET /v1/merchants/{merchantuuid}/case_counts/unread` and `GET /v1/merchants/{merchantuuid}/refund_counts/unread`; knowledge management session state
- **Write**: Count refresh triggered by message bus consumers on case create/update events; owner cache writes on first resolution
- **Indexes**: Not applicable — Redis key-value; keys are merchant UUID scoped

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| `continuumMerchantCaseRedis` | Redis | Unread case/refund counts, owner data, knowledge management state | No evidence of explicit TTL configuration found in codebase |

## Data Flows

- Salesforce CRM is the system of record; MCS writes cases to Salesforce synchronously on HTTP requests from the Merchant Center.
- Salesforce publishes case lifecycle events to the message bus (`jms.topic.salesforce.case.*`); MCS consumes these to refresh Redis counts and trigger merchant notifications.
- Redis stores are populated by message bus consumers and invalidated/updated on each relevant event; no ETL or CDC pipeline is used.
