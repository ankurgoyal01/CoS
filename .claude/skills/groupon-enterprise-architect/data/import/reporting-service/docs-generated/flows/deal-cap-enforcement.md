---
service: "reporting-service"
title: "Deal Cap Enforcement"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "deal-cap-enforcement"
flow_type: scheduled
trigger: "Daily scheduler — dealCapScheduler (Spring Scheduler + ShedLock)"
participants:
  - "dealCapScheduler"
  - "reportingService_persistenceDaos"
  - "reportingService_externalApiClients"
  - "continuumDealCapDb"
  - "dcApi"
  - "m3Api"
architecture_ref: "Reporting-API-Components"
---

# Deal Cap Enforcement

## Summary

The deal cap enforcement flow runs on a daily schedule via the `dealCapScheduler` component. It queries the Deal Cap Database for all active deal cap configurations, fetches current deal and merchant status from external APIs, evaluates whether caps have been reached or exceeded, updates cap state, and records enforcement actions to the deal cap audit trail. The results are accessible via `GET /dealcap/v1/audit`.

## Trigger

- **Type**: schedule
- **Source**: `dealCapScheduler` component (Spring Scheduler with ShedLock 1.2.0 distributed lock)
- **Frequency**: Daily

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Deal Cap Scheduler | Initiates the daily enforcement job; holds ShedLock to prevent duplicate runs | `dealCapScheduler` |
| Persistence Layer | Reads active cap configurations; writes updated cap state and audit entries | `reportingService_persistenceDaos` |
| External API Clients | Fetches current deal status and merchant information | `reportingService_externalApiClients` |
| Deal Cap Database | Stores cap configurations, current state, and audit log | `continuumDealCapDb` |
| Deal Catalog API | Provides current deal redemption counts and deal status | `dcApi` |
| M3 Merchant API | Provides merchant account status relevant to cap decisions | `m3Api` |

## Steps

1. **Acquire distributed lock**: `dealCapScheduler` acquires a ShedLock on the deal cap enforcement job to prevent concurrent execution across multiple service instances.
   - From: `dealCapScheduler`
   - To: `continuumDealCapDb` (ShedLock table)
   - Protocol: JDBC

2. **Load active deal caps**: Scheduler reads all active deal cap configurations from the Deal Cap Database.
   - From: `dealCapScheduler`
   - To: `reportingService_persistenceDaos` → `continuumDealCapDb`
   - Protocol: direct / JDBC

3. **Fetch current deal status**: External API Clients query the Deal Catalog API for current redemption counts per deal.
   - From: `dealCapScheduler`
   - To: `reportingService_externalApiClients` → `dcApi`
   - Protocol: REST

4. **Fetch merchant status**: External API Clients query M3 Merchant API for merchant account status relevant to cap enforcement.
   - From: `dealCapScheduler`
   - To: `reportingService_externalApiClients` → `m3Api`
   - Protocol: REST

5. **Evaluate caps**: Scheduler compares current redemption counts against configured limits to identify deals at or over cap.
   - From: `dealCapScheduler`
   - To: internal evaluation logic
   - Protocol: direct

6. **Update cap state**: Scheduler writes updated cap state (current count, cap status) for each deal back to the Deal Cap Database.
   - From: `dealCapScheduler`
   - To: `reportingService_persistenceDaos` → `continuumDealCapDb`
   - Protocol: direct / JDBC

7. **Write audit entries**: Scheduler records enforcement actions (cap reached, cap cleared, no action) to the audit log in the Deal Cap Database.
   - From: `dealCapScheduler`
   - To: `reportingService_persistenceDaos` → `continuumDealCapDb`
   - Protocol: direct / JDBC

8. **Release distributed lock**: ShedLock releases the enforcement job lock.
   - From: `dealCapScheduler`
   - To: `continuumDealCapDb` (ShedLock table)
   - Protocol: JDBC

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| ShedLock already held (duplicate instance) | Lock not acquired; job skipped | No enforcement run; cap state not updated until next schedule |
| Deal Catalog API unavailable | External API Clients exception | Cap evaluation cannot proceed for affected deals; scheduler may log error and skip |
| M3 Merchant API unavailable | External API Clients exception | Merchant-status-dependent cap decisions skipped |
| Database write failure | Hibernate exception | Cap state or audit log update fails; inconsistent state until next run |

## Sequence Diagram

```
dealCapScheduler -> continuumDealCapDb: ACQUIRE ShedLock
dealCapScheduler -> continuumDealCapDb: SELECT active deal caps
dealCapScheduler -> reportingService_externalApiClients: fetch deal status
reportingService_externalApiClients -> dcApi: GET deal redemption counts
reportingService_externalApiClients -> m3Api: GET merchant status
dealCapScheduler -> dealCapScheduler: evaluate caps (current vs limit)
dealCapScheduler -> continuumDealCapDb: UPDATE cap state per deal
dealCapScheduler -> continuumDealCapDb: INSERT audit log entries
dealCapScheduler -> continuumDealCapDb: RELEASE ShedLock
```

## Related

- Architecture dynamic view: `Reporting-API-Components`
- Related flows: [Report Generation](report-generation.md), [Weekly Campaign Summary](weekly-campaign-summary.md)
- Audit trail accessible via: [API Surface](../api-surface.md) — `GET /dealcap/v1/audit`
