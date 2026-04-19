---
service: "s2s"
title: "Facebook Automatization ROI"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "facebook-automatization-roi"
flow_type: scheduled
trigger: "Quartz scheduler fires the Google Ads automation/ROI job or manual /jobs/bau/display-run trigger"
participants:
  - "continuumS2sService"
  - "continuumS2sBigQuery"
  - "continuumGoogleAdsApi"
  - "continuumDataBreakerApi"
  - "continuumTraskService"
architecture_ref: "dynamic-s2s-event-dispatch"
---

# Facebook Automatization ROI

## Summary

This scheduled batch flow computes booster campaign ROI metrics and generates Google Ads automation proposals. It reads financial performance data from BigQuery, computes ROI figures using booster history and financial metrics, queries DataBreaker for booster recommendation status per deal, exports proposals to Google Sheets for SEM team review, and delivers results via SMTP email notifications. The Trask Service receives booster and partner data updates as part of this workflow. The `/jobs/bau/display-run` HTTP endpoint enables manual execution.

## Trigger

- **Type**: schedule (also: manual HTTP trigger via `/jobs/bau/display-run`)
- **Source**: Quartz Scheduler within `continuumS2sService`; `/jobs/bau/display-run` POST for manual runs
- **Frequency**: Scheduled (BAU — business as usual; interval configured in Quartz)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| S2S Service — Quartz Scheduler | Fires the scheduled automation job | `continuumS2sService_quartzScheduler` |
| S2S Service — Job Resource | Accepts manual job trigger via HTTP | `continuumS2sService_jobResource` |
| S2S Service — Service Factory | Provides domain services for job execution | `continuumS2sService_serviceFactory` |
| S2S Service — ROI Data Service | Reads BigQuery financial tables | `continuumS2sService_roiDataService` |
| BigQuery Financial Tables | Source of ROI, financial metrics, and BI extracts | `continuumS2sBigQuery` |
| S2S Service — Booster Recommendation Service | Queries DataBreaker for deal recommendation status | `continuumS2sService_boosterRecommendationService` |
| S2S Service — DataBreaker Send Event Service | Obtains DataBreaker token; submits events | `continuumS2sService_dataBreakerSendEventService` |
| DataBreaker API | Provides booster recommendation results | `continuumDataBreakerApi` |
| S2S Service — Google Ads & Sheets Service | Generates proposals and exports to Google Sheets | `continuumS2sService_googleAdsSheetsService` |
| Google Ads / Enhanced Conversions | Receives Google Ads automation data | `continuumGoogleAdsApi` |
| S2S Service — Email Service | Delivers automation outputs and notifications | `continuumS2sService_emailService` |
| Trask Service | Receives booster and tracking updates | `continuumTraskService` |

## Steps

1. **Fire scheduled trigger**: Quartz Scheduler fires the BAU display run job. The `/jobs/bau/display-run` Job Resource endpoint also accepts manual POST triggers.
   - From: `continuumS2sService_quartzScheduler` (or `continuumS2sService_jobResource`)
   - To: Job execution context via `continuumS2sService_serviceFactory`
   - Protocol: Quartz internal / HTTP

2. **Read financial data from BigQuery**: ROI Data Service queries BigQuery Financial Tables to retrieve booster ROI data, campaign financial metrics, and BI extract data required for proposal computation.
   - From: `continuumS2sService_roiDataService`
   - To: `continuumS2sBigQuery`
   - Protocol: BigQuery API (BigQuery 26.58.0)

3. **Obtain DataBreaker authentication token**: Booster Recommendation Service calls DataBreaker Send Event Service to retrieve a valid DataBreaker API token before querying recommendations.
   - From: `continuumS2sService_boosterRecommendationService`
   - To: `continuumS2sService_dataBreakerSendEventService` → `continuumDataBreakerApi`
   - Protocol: HTTP/JSON

4. **Query booster recommendation status per deal**: Booster Recommendation Service queries DataBreaker items API to determine recommendation status for each deal being evaluated in the automation run.
   - From: `continuumS2sService_boosterRecommendationService`
   - To: `continuumDataBreakerApi`
   - Protocol: HTTP/JSON

5. **Enrich DataBreaker datapoints with financial metrics**: DataBreaker Datapoint Processor enriches booster events with ROI financial data from BigQuery before posting datapoints to DataBreaker.
   - From: `continuumS2sService_dataBreakerDatapointProcessor`
   - To: `continuumS2sService_roiDataService` → `continuumS2sBigQuery`; `continuumS2sService_dataBreakerSendEventService` → `continuumDataBreakerApi`
   - Protocol: BigQuery API; HTTP/JSON

6. **Generate Google Ads automation proposals**: Google Ads & Sheets Service combines ROI metrics and recommendation results to generate Google Ads automation proposals for deals.
   - From: `continuumS2sService_googleAdsSheetsService`
   - To: `continuumS2sService_roiDataService` (ROI data pull)
   - Protocol: internal

7. **Export proposals to Google Sheets**: Google Ads & Sheets Service writes the computed proposals to a Google Sheets document for SEM team review.
   - From: `continuumS2sService_googleAdsSheetsService`
   - To: Google Sheets API (external)
   - Protocol: HTTP/SDK (Google Sheets API)

8. **Send Google Ads automation data**: Google Ads & Sheets Service submits automation results directly to the Google Ads API.
   - From: `continuumS2sService_googleAdsSheetsService`
   - To: `continuumGoogleAdsApi`
   - Protocol: HTTP/JSON (Google Ads API 38.0.0)

9. **Notify SEM team via email**: Email Service sends SMTP notifications containing automation outputs and booster recommendations to the SEM/Display Engineering team.
   - From: `continuumS2sService_googleAdsSheetsService`
   - To: `continuumS2sService_emailService` → SMTP
   - Protocol: SMTP

10. **Update Trask Service**: Booster and partner data updates are sent to Trask Service as part of the automation workflow completion.
    - From: `continuumS2sService`
    - To: `continuumTraskService`
    - Protocol: HTTP/JSON

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| BigQuery unavailable | Job fails at ROI data read step; logged | Automation run skipped; retried on next schedule or manual trigger |
| DataBreaker API unavailable | Failsafe retry; recommendation status unavailable | Proposals generated without recommendation enrichment; DataBreaker token fetch fails first |
| Google Ads API unavailable | Failsafe retry via Google Ads client | Automation submission deferred; Sheets export may still succeed |
| Google Sheets API unavailable | Exception logged; email notification still attempted | Report not exported; email contains partial results |
| SMTP failure | Exception logged; non-critical | No email notification delivered; automation results still written to Sheets |
| Trask Service unavailable | Failsafe retry; non-critical update | Trask update deferred; booster state may be briefly stale |

## Sequence Diagram

```
continuumS2sService_quartzScheduler        -> continuumS2sService_serviceFactory         : Fire BAU display run
continuumS2sService_serviceFactory         -> continuumS2sService_roiDataService          : Initialize ROI service
continuumS2sService_roiDataService         -> continuumS2sBigQuery                        : BigQuery financial data query
continuumS2sBigQuery                      --> continuumS2sService_roiDataService           : ROI + financial metrics
continuumS2sService_boosterRecommendationService -> continuumS2sService_dataBreakerSendEventService : Get DataBreaker token
continuumS2sService_dataBreakerSendEventService  -> continuumDataBreakerApi                : HTTP token request
continuumDataBreakerApi                   --> continuumS2sService_dataBreakerSendEventService : Auth token
continuumS2sService_boosterRecommendationService -> continuumDataBreakerApi                : HTTP GET recommendations per deal
continuumDataBreakerApi                   --> continuumS2sService_boosterRecommendationService : Recommendation results
continuumS2sService_googleAdsSheetsService -> continuumS2sService_roiDataService          : Pull ROI metrics for proposals
continuumS2sService_googleAdsSheetsService -> continuumGoogleAdsApi                       : POST automation data
continuumGoogleAdsApi                     --> continuumS2sService_googleAdsSheetsService   : 200 OK / error
continuumS2sService_googleAdsSheetsService -> Google Sheets API                           : Export proposals
continuumS2sService_googleAdsSheetsService -> continuumS2sService_emailService             : Trigger notification
continuumS2sService_emailService           -> SMTP                                         : Send email to SEM team
continuumS2sService                        -> continuumTraskService                        : HTTP POST booster updates
```

## Related

- Architecture dynamic view: `dynamic-s2s-event-dispatch`
- Related flows: [MBus Booster DataBreaker Ingestion](mbus-booster-databreaker.md), [Teradata Customer Info Job](teradata-customer-info-job.md)
