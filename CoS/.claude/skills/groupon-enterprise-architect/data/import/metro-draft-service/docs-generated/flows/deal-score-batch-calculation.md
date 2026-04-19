---
service: "metro-draft-service"
title: "Deal Score Batch Calculation"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "deal-score-batch-calculation"
flow_type: scheduled
trigger: "Quartz scheduler — Deal Score Calculator Job fires on configured interval"
participants:
  - "continuumMetroDraftService_dealScoreCalculatorJob"
  - "continuumMetroDraftService_dealScoreToSalesforceJob"
  - "continuumMetroDraftService_dealService"
  - "continuumMetroDraftService_dealDao"
  - "continuumMetroDraftService_searchAnalyticsClient"
  - "continuumMetroDraftService_salesforceClient"
  - "continuumMetroDraftDb"
  - "elasticSearch"
  - "salesForce"
architecture_ref: "dynamic-continuum-metro-draft-continuumMetroDraftService_dealService-deal-scoring"
---

# Deal Score Batch Calculation

## Summary

Metro Draft Service runs two coordinated Quartz batch jobs to calculate deal quality scores and sync them externally. The Deal Score Calculator Job fetches current deal data, computes scores, persists updated scores to the primary database, and pushes search/scoring signals to ElasticSearch. The Deal Score to Salesforce Job then reads the latest persisted scores and writes them to Salesforce for commercial tracking and reporting. These jobs run on a scheduled interval managed by the Quartz scheduler.

## Trigger

- **Type**: schedule
- **Source**: Quartz scheduler within `continuumMetroDraftService` — Deal Score Calculator Job and Deal Score to Salesforce Job
- **Frequency**: Scheduled interval (job-specific; confirm exact schedule with Metro Team)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Deal Score Calculator Job | Scheduled job that calculates deal scores and persists results | `continuumMetroDraftService_dealScoreCalculatorJob` |
| Deal Score to Salesforce Job | Scheduled job that syncs latest scores to Salesforce | `continuumMetroDraftService_dealScoreToSalesforceJob` |
| Deal Service | Provides deal data and scoring computation logic | `continuumMetroDraftService_dealService` |
| Deal DAO | Reads current scores and persists score updates | `continuumMetroDraftService_dealDao` |
| Search & Analytics Client | Pushes scoring and search signals to ElasticSearch | `continuumMetroDraftService_searchAnalyticsClient` |
| Salesforce Client | Writes deal scores to Salesforce | `continuumMetroDraftService_salesforceClient` |
| Metro Draft DB | Primary storage for deal data and score records | `continuumMetroDraftDb` |
| ElasticSearch | Receives search indexing and scoring signals | `elasticSearch` |
| Salesforce | Receives deal scores for commercial reporting | `salesForce` |

## Steps

### Phase 1 — Score Calculation (Deal Score Calculator Job)

1. **Job fires on schedule**: Quartz triggers Deal Score Calculator Job.
   - From: Quartz scheduler (internal)
   - To: `continuumMetroDraftService_dealScoreCalculatorJob`
   - Protocol: Quartz

2. **Fetch deal data**: Deal Score Calculator Job calls Deal Service to retrieve deal data for scoring.
   - From: `continuumMetroDraftService_dealScoreCalculatorJob`
   - To: `continuumMetroDraftService_dealService`
   - Protocol: Internal call

3. **Read current scores**: Deal Score Calculator Job reads current score values from Deal DAO to determine which deals need recalculation.
   - From: `continuumMetroDraftService_dealScoreCalculatorJob` -> `continuumMetroDraftService_dealDao`
   - To: `continuumMetroDraftDb`
   - Protocol: JDBI

4. **Compute scores**: Deal Score Calculator Job computes updated quality scores from deal attributes (pricing, completeness, merchant data, taxonomy).
   - From: `continuumMetroDraftService_dealScoreCalculatorJob` (internal computation)
   - To: `continuumMetroDraftService_dealService` (computation support)
   - Protocol: Internal call

5. **Persist score updates**: Deal Score Calculator Job writes updated scores back to the primary database via Deal DAO.
   - From: `continuumMetroDraftService_dealScoreCalculatorJob` -> `continuumMetroDraftService_dealDao`
   - To: `continuumMetroDraftDb`
   - Protocol: JDBI

6. **Push search/scoring signals**: Deal Score Calculator Job sends scoring signals to ElasticSearch via Search & Analytics Client.
   - From: `continuumMetroDraftService_dealScoreCalculatorJob` -> `continuumMetroDraftService_searchAnalyticsClient`
   - To: `elasticSearch`
   - Protocol: HTTP

### Phase 2 — Salesforce Sync (Deal Score to Salesforce Job)

7. **Job fires on schedule**: Quartz triggers Deal Score to Salesforce Job (runs after or in coordination with Deal Score Calculator Job).
   - From: Quartz scheduler (internal)
   - To: `continuumMetroDraftService_dealScoreToSalesforceJob`
   - Protocol: Quartz

8. **Load latest scores**: Deal Score to Salesforce Job calls Deal Service to fetch the most recently persisted scores.
   - From: `continuumMetroDraftService_dealScoreToSalesforceJob`
   - To: `continuumMetroDraftService_dealService`
   - Protocol: Internal call

9. **Push scores to Salesforce**: Deal Score to Salesforce Job calls Salesforce Client to write deal scores to Salesforce.
   - From: `continuumMetroDraftService_dealScoreToSalesforceJob` -> `continuumMetroDraftService_salesforceClient`
   - To: `salesForce`
   - Protocol: HTTP (Salesforce SOAP client)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Deal Service unavailable during scoring | Job logs error and aborts current execution cycle | Scores not updated for this cycle; Quartz retries on next scheduled firing |
| Database write failure (score persist) | JDBI exception logged; job may partially complete for processed deals | Some scores updated; inconsistent state until next full cycle |
| ElasticSearch unavailable | Search & Analytics Client logs error; job continues | Search signals not pushed for this cycle; search index may be stale |
| Salesforce unavailable or auth failure | Salesforce Client logs error; job fails | Scores not synced to Salesforce for this cycle; next job execution retries |
| Quartz job stuck / not firing | Stuck Deal Retry Job may not cover batch jobs; alert on job-not-running metrics | Manual trigger or restart required |

## Sequence Diagram

```
QuartzScheduler -> DealScoreCalculatorJob: fire (scheduled)
DealScoreCalculatorJob -> DealService: fetchDealData(batch)
DealService --> DealScoreCalculatorJob: deal records
DealScoreCalculatorJob -> DealDao: readCurrentScores(dealIds)
DealDao -> MetroDraftDb: SELECT scores
MetroDraftDb --> DealDao: current scores
DealScoreCalculatorJob -> DealService: computeScore(deal)
DealService --> DealScoreCalculatorJob: computed score
DealScoreCalculatorJob -> DealDao: persistScoreUpdates(scores)
DealDao -> MetroDraftDb: UPDATE scores
DealScoreCalculatorJob -> SearchAnalyticsClient: pushScoringSignals(signals)
SearchAnalyticsClient -> ElasticSearch: index scoring data

QuartzScheduler -> DealScoreToSalesforceJob: fire (scheduled)
DealScoreToSalesforceJob -> DealService: loadLatestScores(batch)
DealService --> DealScoreToSalesforceJob: score records
DealScoreToSalesforceJob -> SalesforceClient: writeScores(scores)
SalesforceClient -> Salesforce: SOAP API call (upsert scores)
Salesforce --> SalesforceClient: ok
```

## Related

- Architecture dynamic view: `dynamic-continuum-metro-draft-continuumMetroDraftService_dealService-deal-scoring`
- Related flows: [Merchant Deal Draft Creation](merchant-deal-draft-creation.md), [Deal Publishing Orchestration](deal-publishing-orchestration.md)
