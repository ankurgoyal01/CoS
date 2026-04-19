---
service: "groupon-monorepo"
title: "Deal Creation and Publishing"
generated: "2026-03-03"
type: flow
flow_name: "deal-creation-publishing"
flow_type: synchronous
trigger: "User creates or publishes a deal via admin UI"
participants:
  - "adminReactFe"
  - "encoreTs"
  - "continuumDealManagementApi"
  - "salesForce"
architecture_ref: "dynamic-deal-creation-publishing"
---

# Deal Creation and Publishing

## Summary

This flow covers the end-to-end deal lifecycle in the Encore Platform. An administrator creates a deal through the Admin React frontend, which calls the Encore TypeScript backend deal service. The deal goes through a version-controlled lifecycle with draft, review, and approval stages. When approved, the deal is published by syncing to the Continuum Deal Management API (DMAPI) and optionally updating Salesforce CRM records.

## Trigger

- **Type**: user-action
- **Source**: Administrator creates or updates a deal in the Admin React frontend
- **Frequency**: on-demand, multiple times per day

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Admin React Frontend | UI for deal creation, editing, approval | `adminReactFe` |
| Deal Service (B2B) | Deal lifecycle management, versioning, validation | `encoreTs` (_tribe_b2b/deal) |
| Deal Sync Service | Synchronization state tracking | `encoreTs` (_tribe_b2b/deal_sync) |
| DMAPI Wrapper | Proxy to Continuum Deal Management API | `encoreTs` (_tribe_b2b/dmapi) |
| Continuum DMAPI | Legacy deal management backend | `continuumDealManagementApi` |
| Salesforce Service | CRM update for deal metadata | `encoreTs` (_tribe_b2b/salesforce) |
| Salesforce | External CRM platform | `salesForce` |

## Steps

1. **Create Deal Draft**: Administrator fills deal form in admin UI and submits
   - From: `adminReactFe`
   - To: `encoreTs` (deal service)
   - Protocol: REST (generated client)

2. **Validate and Persist**: Deal service validates input, creates deal record and initial version
   - From: `encoreTs` (deal service)
   - To: `deal` PostgreSQL database
   - Protocol: SQL (Drizzle ORM)

3. **Edit and Iterate**: Administrator edits deal options, pricing, redemption details (creates new versions)
   - From: `adminReactFe`
   - To: `encoreTs` (deal service)
   - Protocol: REST (generated client)

4. **Submit for Approval**: Deal version submitted for review
   - From: `adminReactFe`
   - To: `encoreTs` (deal service)
   - Protocol: REST (generated client)

5. **Approve and Trigger Publish**: Approver reviews and approves; publishes approval event
   - From: `encoreTs` (deal service)
   - To: Pub/Sub topic `deal-version-approval-publish`
   - Protocol: Encore Pub/Sub

6. **Sync to Continuum DMAPI**: Deal sync service pushes deal data to legacy platform
   - From: `encoreTs` (deal_sync service)
   - To: `encoreTs` (dmapi wrapper)
   - Protocol: Internal service call

7. **Call Continuum DMAPI**: DMAPI wrapper sends deal to Continuum
   - From: `encoreTs` (dmapi wrapper)
   - To: `continuumDealManagementApi`
   - Protocol: REST

8. **Update Salesforce (optional)**: If deal has Salesforce metadata, update CRM
   - From: `encoreTs` (salesforce service)
   - To: `salesForce`
   - Protocol: REST (jsforce)

9. **Record Sync State**: Deal sync service records successful sync
   - From: `encoreTs` (deal_sync service)
   - To: `deal_sync` PostgreSQL database
   - Protocol: SQL (Drizzle ORM)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Validation failure | Return validation errors to UI | Deal not created; user corrects input |
| DMAPI sync failure | Log error; record failed state in deal_sync DB | Deal remains in "pending sync" state; manual retry from admin UI |
| Salesforce update failure | Log warning; deal still published to Continuum | Deal published without CRM update; retry via scheduled sync |
| Database write failure | Transaction rollback | Operation fails atomically; user retries |
| Stuck versions | Cron job cleans up versions stuck in approval for too long | Versions auto-cancelled after timeout |

## Sequence Diagram

```
Administrator -> Admin React FE: Create/edit deal
Admin React FE -> Deal Service: POST /deal.create
Deal Service -> Deal DB: INSERT deal + version
Deal Service --> Admin React FE: Deal created (ID)
Administrator -> Admin React FE: Submit for approval
Admin React FE -> Deal Service: POST /deal.submitForApproval
Approver -> Admin React FE: Approve version
Admin React FE -> Deal Service: POST /deal.approve
Deal Service -> PubSub: publish deal-version-approval-publish
Deal Sync Service -> DMAPI Wrapper: Sync deal data
DMAPI Wrapper -> Continuum DMAPI: POST deal
Continuum DMAPI --> DMAPI Wrapper: Success
Deal Sync Service -> Deal Sync DB: Record sync state
Salesforce Service -> Salesforce: Update deal record
```

## Related

- Architecture dynamic view: `dynamic-deal-creation-publishing`
- Related flows: [Salesforce Account Sync](salesforce-account-sync.md), [AI Deal Content Generation](ai-deal-content-generation.md)
