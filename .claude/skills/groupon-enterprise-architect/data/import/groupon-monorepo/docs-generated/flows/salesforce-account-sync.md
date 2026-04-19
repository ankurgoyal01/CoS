---
service: "groupon-monorepo"
title: "Salesforce Account Sync"
generated: "2026-03-03"
type: flow
flow_name: "salesforce-account-sync"
flow_type: asynchronous
trigger: "Scheduled cron job or on-demand user action"
participants:
  - "encoreTs"
  - "salesForce"
architecture_ref: "dynamic-salesforce-account-sync"
---

# Salesforce Account Sync

## Summary

This flow synchronizes merchant account data bidirectionally between the Encore Platform and Salesforce CRM. It runs on a scheduled basis (cron) and can also be triggered manually from the admin UI. Account updates from Salesforce are pulled into the local accounts database, and local account changes are pushed to Salesforce. Events are published on Pub/Sub to notify downstream services of changes.

## Trigger

- **Type**: schedule + user-action
- **Source**: Scheduled cron job (`salesforce-sync`, `update-deals-structured-data`, `calculate-account-metrics`) and manual sync from admin UI
- **Frequency**: Daily (cron), on-demand (manual)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Accounts Service (B2B) | Manages local account records and sync logic | `encoreTs` (_tribe_b2b/accounts) |
| Salesforce Service (B2B) | Salesforce API client wrapper | `encoreTs` (_tribe_b2b/salesforce) |
| Salesforce | External CRM platform | `salesForce` |
| AIDG Service | Consumes account data for AI deal generation | `encoreTs` (aidg) |

## Steps

1. **Trigger Sync**: Cron fires or admin user initiates manual sync
   - From: Cron scheduler / `adminReactFe`
   - To: `encoreTs` (accounts service)
   - Protocol: Internal / REST

2. **Query Salesforce**: Accounts service calls Salesforce API for updated records
   - From: `encoreTs` (salesforce service)
   - To: `salesForce`
   - Protocol: REST (jsforce)

3. **Upsert Local Records**: Updated account data persisted to accounts database
   - From: `encoreTs` (accounts service)
   - To: `accounts` PostgreSQL database
   - Protocol: SQL (Drizzle ORM)

4. **Publish Sync Event**: Notify downstream services of account changes
   - From: `encoreTs` (accounts service)
   - To: Pub/Sub topic `account-updated-in-salesforce`
   - Protocol: Encore Pub/Sub

5. **Push Local Changes**: If local changes exist, push updates back to Salesforce
   - From: `encoreTs` (salesforce service)
   - To: `salesForce`
   - Protocol: REST (jsforce)

6. **Publish Internal Event**: Notify of internally-originated updates
   - From: `encoreTs` (accounts service)
   - To: Pub/Sub topic `account-updated-internal`
   - Protocol: Encore Pub/Sub

7. **Recalculate Metrics**: Cron triggers account metrics recalculation
   - From: Cron scheduler (`calculate-account-metrics`)
   - To: `encoreTs` (accounts service)
   - Protocol: Internal

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Salesforce API timeout | Retry with backoff; log error | Sync incomplete; retried on next cron cycle |
| Salesforce OAuth expired | Log error; alert team | Manual credential refresh required |
| Salesforce rate limit | Back off; retry on next cycle | Sync delayed but data eventually consistent |
| Database write failure | Transaction rollback | Account not updated; retried on next sync |

## Sequence Diagram

```
Cron/Admin -> Accounts Service: Trigger sync
Accounts Service -> Salesforce Service: Fetch updated accounts
Salesforce Service -> Salesforce: SOQL query
Salesforce --> Salesforce Service: Account records
Salesforce Service --> Accounts Service: Parsed accounts
Accounts Service -> Accounts DB: Upsert records
Accounts Service -> PubSub: account-updated-in-salesforce
AIDG Service -> PubSub: Subscribe to account events
Accounts Service -> Salesforce Service: Push local changes
Salesforce Service -> Salesforce: Update records
```

## Related

- Architecture dynamic view: `dynamic-salesforce-account-sync`
- Related flows: [Deal Creation and Publishing](deal-creation-publishing.md), [AI Deal Content Generation](ai-deal-content-generation.md)
