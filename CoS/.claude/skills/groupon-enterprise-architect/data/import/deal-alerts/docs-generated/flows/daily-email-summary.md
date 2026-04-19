---
service: "deal-alerts"
title: "Daily Email Summary"
generated: "2026-03-03"
type: flow
flow_name: "daily-email-summary"
flow_type: scheduled
trigger: "Daily schedule in n8n"
participants:
  - "continuumDealAlertsWorkflows_emailSummary"
  - "continuumDealAlertsDb_summaryEmails"
  - "continuumDealAlertsDb_actionMapping"
architecture_ref: "dynamic-deal-alerts-continuumDealAlertsDb_alertLifecycle"
---

# Daily Email Summary

## Summary

The Email Summary workflow generates daily summary emails for stakeholders about alert-related task outcomes. It aggregates action results (Salesforce tasks created, chat messages sent, errors) across the previous day, generates per-recipient email content, and records execution state in the summary email tables. Recipients can be excluded via summary_email_exclusions and configure preferences via summary_email_preferences.

## Trigger

- **Type**: schedule
- **Source**: n8n daily timer
- **Frequency**: Daily

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Email Summary | Aggregates action outcomes and generates per-recipient summary emails | `continuumDealAlertsWorkflows_emailSummary` |
| Summary Email Tables | Stores email run records, per-recipient results, exclusions, and preferences | `continuumDealAlertsDb_summaryEmails` |
| Action & Attribution Tables | Source of action outcomes for aggregation | `continuumDealAlertsDb_actionMapping` |

## Steps

1. **Create summary run**: Insert a `summary_email_runs` record to track this execution.
   - From: `continuumDealAlertsWorkflows_emailSummary`
   - To: `continuumDealAlertsDb_summaryEmails`
   - Protocol: SQL

2. **Aggregate action outcomes**: Query actions completed since the last run, grouping by type, status, and associated alert metrics.
   - From: `continuumDealAlertsWorkflows_emailSummary`
   - To: `continuumDealAlertsDb_actionMapping`
   - Protocol: SQL

3. **Determine recipients**: Build recipient list, filtering out entries in `summary_email_exclusions` and applying `summary_email_preferences`.
   - From: `continuumDealAlertsWorkflows_emailSummary`
   - To: `continuumDealAlertsDb_summaryEmails`
   - Protocol: SQL

4. **Generate and send emails**: Create email content per recipient with summary statistics and send via email provider.
   - From: `continuumDealAlertsWorkflows_emailSummary`
   - To: External email provider

5. **Record results**: Insert `summary_emails` records per recipient with success/error status.
   - From: `continuumDealAlertsWorkflows_emailSummary`
   - To: `continuumDealAlertsDb_summaryEmails`
   - Protocol: SQL

6. **Complete run**: Update the `summary_email_runs` record with final status.
   - From: `continuumDealAlertsWorkflows_emailSummary`
   - To: `continuumDealAlertsDb_summaryEmails`
   - Protocol: SQL

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Email delivery failure for a recipient | Error recorded in `summary_emails.error_message` | Other recipients still receive emails; errors visible in Logs API |
| No actions to summarize | Run completes with empty summary | Run recorded with zero-count status |

## Sequence Diagram

```
EmailSummary -> SummaryEmails: Create summary_email_runs record
EmailSummary -> ActionMapping: Aggregate action outcomes
EmailSummary -> SummaryEmails: Filter recipients (exclusions, preferences)
EmailSummary -> EmailProvider: Send summary emails
EmailSummary -> SummaryEmails: Record per-recipient results
EmailSummary -> SummaryEmails: Complete run with final status
```

## Related

- Architecture dynamic view: `dynamic-deal-alerts-continuumDealAlertsDb_alertLifecycle`
- Related flows: [Action Orchestration](action-orchestration.md)
