---
service: "lead-gen"
title: "Outreach Campaign"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "outreach-campaign"
flow_type: batch
trigger: "n8n trigger after enrichment qualifies leads or manual API call to /api/leads/outreach"
participants:
  - "leadGenWorkflows"
  - "leadGenService"
  - "mailgun"
  - "leadGenDb"
architecture_ref: "components-continuum-leadgen-service"
---

# Outreach Campaign

## Summary

The Outreach Campaign flow sends templated email outreach to leads that have been enriched and qualified above the score threshold. LeadGen Service selects qualified leads, resolves contact information, renders email templates with lead-specific data, and sends outreach emails via the Mailgun API. The service tracks delivery status (sent, opened, bounced, replied) per message and enforces daily sending limits and inbox warmup sequences to maintain sender reputation.

## Trigger

- **Type**: schedule or api-call
- **Source**: n8n workflow triggered after enrichment qualifies new leads, or manual `POST /api/leads/outreach` with campaign parameters
- **Frequency**: After each enrichment batch completes (daily) plus on-demand via API

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| LeadGen Workflows | Triggers outreach campaign execution | `leadGenWorkflows` |
| LeadGen Service | Selects qualified leads, renders templates, sends emails, tracks delivery | `leadGenService` |
| Mailgun | Delivers outreach emails and provides delivery status callbacks | `mailgun` |
| LeadGen DB | Stores outreach campaign state, message status, and delivery tracking | `leadGenDb` |

## Steps

1. **Workflow triggers outreach**: n8n workflow detects newly qualified leads after enrichment and calls the LeadGen Service outreach endpoint with campaign configuration
   - From: `leadGenWorkflows`
   - To: `leadGenService`
   - Protocol: Internal (HTTP)

2. **Service loads qualified leads**: LeadGen Service queries the database for leads with status "qualified" that have not yet been contacted in the current campaign
   - From: `leadGenService`
   - To: `leadGenDb`
   - Protocol: JDBC (SELECT)

3. **Service resolves contacts**: For each qualified lead, the service retrieves or infers the best contact email from the `lead_contacts` table
   - From: `leadGenService`
   - To: `leadGenDb`
   - Protocol: JDBC (SELECT)

4. **Service checks daily sending limits**: Before sending, the service verifies the daily outreach limit has not been exceeded and the sender domain has completed inbox warmup
   - From: `leadGenService`
   - To: `leadGenDb`
   - Protocol: JDBC (SELECT count of sent messages today)

5. **Service renders and sends emails**: For each contact within the daily limit, the service renders the email template with lead-specific data and sends via the Mailgun API
   - From: `leadGenService`
   - To: `mailgun`
   - Protocol: API (REST)

6. **Service records message status**: Each sent message is recorded in the `outreach_messages` table with the Mailgun message ID and initial "sent" status
   - From: `leadGenService`
   - To: `leadGenDb`
   - Protocol: JDBC (INSERT)

7. **Mailgun delivers and reports status**: Mailgun delivers emails and sends webhook callbacks for delivery events (delivered, opened, bounced, complained)
   - From: `mailgun`
   - To: `leadGenService`
   - Protocol: Webhook (HTTP POST)

8. **Service updates delivery status**: LeadGen Service receives Mailgun webhooks and updates `outreach_messages` status accordingly
   - From: `leadGenService`
   - To: `leadGenDb`
   - Protocol: JDBC (UPDATE)

9. **Workflow logs completion**: n8n workflow records campaign execution metrics
   - From: `leadGenWorkflows`
   - To: `leadGenDb`
   - Protocol: SQL

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Mailgun API unavailable | Retry individual messages with backoff; pause campaign if persistent | Unsent messages queued for retry; campaign paused if provider is down |
| Mailgun rate limit exceeded | Pause sending; resume after rate limit window resets | Remaining messages deferred to next batch |
| Daily sending limit reached | Stop sending for the day; remaining leads deferred | Deferred leads picked up in next daily run |
| High bounce rate detected (> 10%) | Pause campaign automatically; alert triggered | Campaign halted to protect sender reputation; manual review required |
| Webhook delivery failure | Mailgun retries webhooks; missed events reconciled via Mailgun events API | Delivery status may be stale until reconciliation runs |
| Invalid contact email | Mailgun returns hard bounce; lead contact flagged as invalid | Lead excluded from future campaigns until contact updated |
| Template rendering failure | Message skipped; error logged | Individual lead skipped; batch continues |

## Sequence Diagram

```
leadGenWorkflows -> leadGenService: POST /api/leads/outreach (campaign config)
leadGenService -> leadGenDb: Load qualified leads (SELECT)
leadGenDb --> leadGenService: Qualified lead records
leadGenService -> leadGenDb: Load contacts for leads (SELECT)
leadGenDb --> leadGenService: Contact records
leadGenService -> leadGenDb: Check daily send count (SELECT)
leadGenDb --> leadGenService: Current send count
leadGenService -> mailgun: Send outreach email (API, per contact)
mailgun --> leadGenService: Message ID and acceptance confirmation
leadGenService -> leadGenDb: Record outreach message (INSERT)
mailgun -> leadGenService: Delivery webhook (delivered/opened/bounced)
leadGenService -> leadGenDb: Update message status (UPDATE)
leadGenService --> leadGenWorkflows: Campaign result (sent count, status)
leadGenWorkflows -> leadGenDb: Log workflow completion (SQL)
```

## Related

- Architecture dynamic view: not yet defined -- see `components-continuum-leadgen-service`
- Related flows: [Lead Enrichment](lead-enrichment.md) (upstream -- provides qualified leads), [Salesforce Account Creation](salesforce-account-creation.md) (downstream for engaged leads)
- See [Integrations](../integrations.md) for Mailgun integration details
- See [Data Stores](../data-stores.md) for `outreach_campaigns` and `outreach_messages` table schemas
