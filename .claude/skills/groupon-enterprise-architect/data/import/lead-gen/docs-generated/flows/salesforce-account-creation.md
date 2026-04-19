---
service: "lead-gen"
title: "Salesforce Account Creation"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "salesforce-account-creation"
flow_type: batch
trigger: "n8n trigger after outreach engagement detected or manual API call to /api/leads/sync-crm"
participants:
  - "leadGenWorkflows"
  - "leadGenService"
  - "salesForce"
  - "leadGenDb"
architecture_ref: "components-continuum-leadgen-service"
---

# Salesforce Account Creation

## Summary

The Salesforce Account Creation flow is the final stage of the lead generation pipeline. It takes leads that have demonstrated engagement through outreach (e.g., opened email, replied) and creates corresponding Account and Contact records in Salesforce, handing them off to the Sales team for follow-up. The service handles Salesforce API authentication, duplicate detection, record creation, and sync status tracking. This is the primary handoff point between automated lead generation and human-driven sales activity.

## Trigger

- **Type**: schedule or api-call
- **Source**: n8n workflow triggered when outreach engagement metrics qualify leads for CRM sync, or manual `POST /api/leads/sync-crm` with lead filters
- **Frequency**: After outreach campaign results are processed (daily) plus on-demand via API

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| LeadGen Workflows | Triggers CRM sync job for engaged leads | `leadGenWorkflows` |
| LeadGen Service | Authenticates with Salesforce, creates Accounts/Contacts, tracks sync status | `leadGenService` |
| Salesforce | Target CRM system where Accounts and Contacts are created | `salesForce` |
| LeadGen DB | Stores CRM sync status and Salesforce record references | `leadGenDb` |

## Steps

1. **Workflow triggers CRM sync**: n8n workflow detects leads with positive outreach engagement (opened, replied) and calls the LeadGen Service CRM sync endpoint
   - From: `leadGenWorkflows`
   - To: `leadGenService`
   - Protocol: Internal (HTTP)

2. **Service loads sync-eligible leads**: LeadGen Service queries the database for leads that have outreach engagement and have not yet been synced to Salesforce
   - From: `leadGenService`
   - To: `leadGenDb`
   - Protocol: JDBC (SELECT)

3. **Service authenticates with Salesforce**: LeadGen Service obtains or refreshes an OAuth 2.0 access token for the Salesforce REST API
   - From: `leadGenService`
   - To: `salesForce`
   - Protocol: REST (OAuth 2.0 token endpoint)

4. **Service checks for existing Salesforce records**: For each lead, the service queries Salesforce to check if an Account already exists with the same business name and address to prevent duplicates
   - From: `leadGenService`
   - To: `salesForce`
   - Protocol: REST (SOQL query)

5. **Service creates Account**: If no existing Account is found, the service creates a new Account record in Salesforce with business details from the enriched lead data
   - From: `leadGenService`
   - To: `salesForce`
   - Protocol: REST (POST /services/data/vXX.0/sobjects/Account)

6. **Service creates Contact**: The service creates a Contact record in Salesforce attached to the Account, using the lead's best contact information
   - From: `leadGenService`
   - To: `salesForce`
   - Protocol: REST (POST /services/data/vXX.0/sobjects/Contact)

7. **Service records sync status**: The Salesforce Account ID and Contact ID are recorded in the `crm_sync_log` table with status "synced"; the lead status is updated to "synced"
   - From: `leadGenService`
   - To: `leadGenDb`
   - Protocol: JDBC (INSERT/UPDATE)

8. **Workflow logs completion**: n8n workflow records sync batch metrics and execution status
   - From: `leadGenWorkflows`
   - To: `leadGenDb`
   - Protocol: SQL

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Salesforce OAuth token expired | Automatic token refresh; retry request | Transparent to the flow; minor latency increase |
| Salesforce daily API limit exceeded | Pause sync batch; alert triggered; resume when limits reset (midnight UTC) | Remaining leads queued for next day; sync status set to "pending" |
| Duplicate Account detected in Salesforce | Link existing Account instead of creating new; create Contact only | Lead associated with existing Account; no duplicate created |
| Account creation fails (validation error) | Log error with Salesforce error payload; skip lead; continue batch | Individual lead marked as "sync_failed"; retried in next batch |
| Contact creation fails after Account created | Log error; Account exists without Contact | Account orphaned; retry creates Contact on next run |
| Network connectivity failure | Retry with backoff; fail batch if persistent | Batch deferred to next scheduled run |
| Database write failure for sync log | Transaction rolled back; batch retried | Sync status not recorded; Salesforce records may exist without local tracking |

## Sequence Diagram

```
leadGenWorkflows -> leadGenService: POST /api/leads/sync-crm (filter params)
leadGenService -> leadGenDb: Load sync-eligible leads (SELECT)
leadGenDb --> leadGenService: Engaged lead records
leadGenService -> salesForce: OAuth 2.0 token request (REST)
salesForce --> leadGenService: Access token
leadGenService -> salesForce: Check existing Account (SOQL query)
salesForce --> leadGenService: Query results (existing or none)
leadGenService -> salesForce: Create Account (POST, if new)
salesForce --> leadGenService: Account ID
leadGenService -> salesForce: Create Contact (POST)
salesForce --> leadGenService: Contact ID
leadGenService -> leadGenDb: Record sync status (INSERT crm_sync_log)
leadGenDb --> leadGenService: Confirmation
leadGenService --> leadGenWorkflows: Sync result (count, status)
leadGenWorkflows -> leadGenDb: Log workflow completion (SQL)
```

## Related

- Architecture dynamic view: not yet defined -- see `components-continuum-leadgen-service`
- Related flows: [Outreach Campaign](outreach-campaign.md) (upstream -- provides engaged leads)
- See [Integrations](../integrations.md) for Salesforce integration details
- See [Data Stores](../data-stores.md) for `crm_sync_log` table schema
