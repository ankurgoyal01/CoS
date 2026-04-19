---
service: "glive-gia"
title: "Uninvoiced Deal Detection"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "uninvoiced-deal-detection"
flow_type: scheduled
trigger: "Resque-scheduler cron job fires on configured schedule"
participants:
  - "continuumGliveGiaWorker"
  - "continuumGliveGiaRedisCache"
  - "continuumGliveGiaMysqlDatabase"
architecture_ref: "dynamic-glive-gia-uninvoiced-detection"
---

# Uninvoiced Deal Detection

## Summary

GIA runs a scheduled background job that scans the MySQL database for deals that have reached an invoiceable state (e.g., completed events) but do not yet have a corresponding invoice record. The job compiles a report of these uninvoiced deals and either generates an internal report for operations review or triggers an alert so that the GrouponLive supply team can take action. This prevents merchant payment delays caused by deals slipping through without invoice creation.

## Trigger

- **Type**: schedule
- **Source**: resque-scheduler fires the uninvoiced deal detection job on a configured cron schedule
- **Frequency**: Periodic (exact schedule managed in deployment configuration; typically daily)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| GIA Redis (Scheduler) | Triggers the detection job | `continuumGliveGiaRedisCache` |
| GIA Background Worker | Queries MySQL for uninvoiced deals; compiles report | `continuumGliveGiaWorker` |
| GIA MySQL Database | Source of deal and invoice records for detection query | `continuumGliveGiaMysqlDatabase` |

## Steps

1. **Scheduler fires detection job**: resque-scheduler enqueues the uninvoiced deal detection job
   - From: resque-scheduler (within `continuumGliveGiaRedisCache`)
   - To: `continuumGliveGiaRedisCache`
   - Protocol: Resque / Redis

2. **Worker dequeues job**: `resqueWorkers_GliGia` picks up the job
   - From: `continuumGliveGiaWorker`
   - To: `continuumGliveGiaRedisCache`
   - Protocol: Resque / Redis

3. **Query for eligible deals without invoices**: `jobServices_GliGia` queries MySQL via `workerDomainModels` for deals in invoiceable states (e.g., `completed`, `events_settled`) that have no associated invoice record or have an invoice in `draft` state beyond an acceptable age threshold
   - From: `continuumGliveGiaWorker` (`jobServices_GliGia` -> `workerDomainModels`)
   - To: `continuumGliveGiaMysqlDatabase`
   - Protocol: ActiveRecord / MySQL

4. **Compile uninvoiced deals list**: `jobServices_GliGia` assembles the list of matching deal IDs, deal names, event dates, and responsible admin information

5. **Generate report or trigger alert**: The job either persists a report record to MySQL for display in the GIA admin UI or sends a notification to the operations team (e.g., via internal alerting)
   - From: `continuumGliveGiaWorker` (`jobServices_GliGia`)
   - To: `continuumGliveGiaMysqlDatabase` (report record) and/or alert channel
   - Protocol: ActiveRecord / MySQL; internal alert mechanism

6. **Report available for review**: Operations admins review the uninvoiced deals via the GIA admin UI or alert notification and take action to create missing invoices
   - From: Admin browser
   - To: `continuumGliveGiaWebApp`
   - Protocol: REST (HTTP GET `/merchant_report` or deal list with filter)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| MySQL query failure | ActiveRecord exception; Resque job fails and is retried | Detection skipped for that cycle; retried on next run |
| No uninvoiced deals found | Job completes normally with empty result | No report generated; no alert sent |
| Alert delivery failure | Alert error logged; job still completes | Detection completed but team may not be notified; check alerting system |

## Sequence Diagram

```
resque-scheduler -> GIA Redis: RPUSH uninvoiced_deal_detection job
GIA Background Worker -> GIA Redis: LPOP job
GIA Background Worker -> GIA MySQL Database: SELECT deals LEFT JOIN invoices WHERE deals.state IN ('completed', ...) AND invoices.id IS NULL
GIA MySQL Database --> GIA Background Worker: uninvoiced deals list
GIA Background Worker -> GIA MySQL Database: INSERT report record (if report-based approach)
Admin -> GIA Web App: GET /merchant_report (review)
GIA Web App -> GIA MySQL Database: SELECT report
GIA MySQL Database --> GIA Web App: uninvoiced deals data
GIA Web App --> Admin: Render uninvoiced deals report
```

## Related

- Architecture dynamic view: `dynamic-glive-gia-uninvoiced-detection`
- Related flows: [Invoice Creation and Payment](invoice-creation-and-payment.md), [Salesforce Deal Sync](salesforce-deal-sync.md)
