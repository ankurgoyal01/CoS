---
service: "breakage-reduction-service"
title: "Notification Backfill"
generated: "2026-03-03"
type: flow
flow_name: "notification-backfill"
flow_type: batch
trigger: "Internal backfill API call (per-voucher or batch)"
participants:
  - "continuumBreakageReductionService"
  - "riseApi"
architecture_ref: "components-continuum-breakage-reduction-service-components"
---

# Notification Backfill

## Summary

The notification backfill flow allows internal operators or automation tools to schedule or re-schedule notification workflow jobs in bulk or for individual vouchers. This is used when vouchers miss their initial scheduling window — for example, after a system outage, a config change, or a new workflow feature rollout. BRS routes backfill requests through the Backfill Handler, which calls the RISE scheduler's ad-hoc job API to enqueue the required notification commands. Both per-voucher and batch variants are supported.

## Trigger

- **Type**: api-call (internal / manual)
- **Source**: Internal operations tooling, deployment automation, or a Groupon ops engineer
- **Frequency**: On demand or batch (typically post-outage or post-deploy remediation)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| BRS API Routes | Receives and routes backfill requests | `brsApiRoutes` |
| Backfill Handler | Processes per-voucher or batch backfill logic and schedules jobs | `backfillHandler` |
| Service Client Adapters (RISE) | Submits backfill job commands to RISE | `serviceClientAdapters` |
| RISE Scheduler | Receives and enqueues the backfill notification jobs | `riseApi` |

## Steps

1. **Receive backfill request**: An authorized internal caller sends a backfill request (single voucher or batch) to the BRS backfill endpoint.
   - From: internal tooling or operator
   - To: `brsApiRoutes`
   - Protocol: HTTPS/JSON

2. **Route to Backfill Handler**: API Routes dispatches the request to the Backfill Handler.
   - From: `brsApiRoutes`
   - To: `backfillHandler`
   - Protocol: direct

3. **Resolve vouchers to backfill**: For batch requests, the handler iterates over the supplied voucher list. For per-voucher requests, it processes the single supplied voucher.

4. **Schedule backfill jobs in RISE**: For each voucher, the Backfill Handler uses the RISE Service Client Adapter to POST an ad-hoc scheduled job to RISE, specifying the notification type, voucher context, and target delivery parameters.
   - From: `serviceClientAdapters` (RISE client)
   - To: `riseApi`
   - Protocol: HTTPS/JSON (`POST /rise/v1/adhoc?clientId=breakage-reduction-service`)

5. **Return result**: BRS returns a summary of the scheduled backfill jobs (success/failure counts) to the caller.
   - From: `backfillHandler`
   - To: caller
   - Protocol: HTTPS/JSON

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| RISE scheduling failure for one voucher | Error logged; batch continues for remaining vouchers | Partial success reported |
| RISE service unavailable | All scheduling calls fail; error propagated | Caller receives 5xx; retry required |
| Invalid voucher ID in batch | Skipped or error logged per item | Caller receives summary with error details |

## Sequence Diagram

```
InternalCaller -> brsApiRoutes: POST /backfill or /backfill/batch
brsApiRoutes -> backfillHandler: dispatch
backfillHandler -> serviceClientAdapters: schedule(risePayload) [per voucher]
serviceClientAdapters -> riseApi: POST /rise/v1/adhoc?clientId=breakage-reduction-service
riseApi --> serviceClientAdapters: 200 OK (job queued)
backfillHandler --> InternalCaller: 200 OK (backfill result summary)
```

## Related

- Related flows: [Reminder Scheduling](reminder-scheduling.md), [Voucher Next-Actions Computation](voucher-next-actions.md)
