---
service: "subscription-programs-app"
title: Data Stores
generated: "2026-03-03T00:00:00Z"
type: data-stores
stores:
  - id: "continuumSubscriptionProgramsDb"
    type: "mysql"
    purpose: "Primary store for all subscription, membership, and incentive data"
---

# Data Stores

## Overview

Subscription Programs App owns a single MySQL database (`mm_programs`) accessed via the `jtier-daas-mysql` library. This is the authoritative data store for all membership, subscription plan, and incentive records. An in-memory cache layer (cache2k) is used to reduce database reads for frequently accessed, low-churn data such as the plan catalog.

## Stores

### Subscription Programs DB (`continuumSubscriptionProgramsDb`)

| Property | Value |
|----------|-------|
| Type | MySQL |
| Architecture ref | `continuumSubscriptionProgramsDb` |
| Purpose | Primary store for consumer memberships, subscription plans, incentive enrollment, and billing state |
| Ownership | owned |
| Migrations path | > No evidence found — migration tooling path not present in architecture inventory |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| membership | Tracks each consumer's Select membership record and current status | consumerId, planId, status, startDate, endDate, billingAccountId |
| subscription_plan | Catalog of available Select subscription plans | planId, name, price, billingPeriod, features |
| incentive_enrollment | Records incentive benefits enrolled for active members | consumerId, incentiveId, enrolledAt, status |
| payment_history | Billing event log per consumer | consumerId, paymentDate, amount, status, killbillTransactionId |

#### Access Patterns

- **Read**: Membership status lookups by `consumerId` (high-frequency, per API request); plan catalog reads (low-frequency, served from cache2k); payment history queries by `consumerId`
- **Write**: Membership state transitions (create, cancel, suspend, reactivate) on API calls and KillBill webhook receipt; incentive enrollment records on membership activation
- **Indexes**: Primary key on `consumerId` for membership and incentive tables expected; `killbillTransactionId` index on payment_history for idempotent webhook handling

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| Plan catalog cache | in-memory (cache2k 1.0.2) | Caches `GET /select/plans` results to avoid repeated DB reads for stable, low-churn plan data | Not specified in inventory |
| Eligibility cache | in-memory (cache2k 1.0.2) | Caches eligibility check results per consumer to reduce repeated evaluation overhead | Not specified in inventory |

## Data Flows

All reads and writes route through the `subscriptionRepository` component within `continuumSubscriptionProgramsApp`. KillBill webhook events cause synchronous writes to `continuumSubscriptionProgramsDb` followed by async `MembershipUpdate` event publishing to MBus. Background Quartz jobs perform periodic reads to identify memberships requiring maintenance actions (e.g., expiry cleanup, incentive reconciliation) and write the resulting state changes back to the database.
