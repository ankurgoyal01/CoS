---
service: "service-portal"
title: "Operational Readiness Review"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "operational-readiness-review"
flow_type: event-driven
trigger: "API action to initiate ORR; subsequent check result changes drive progression"
participants:
  - "continuumServicePortalWeb"
  - "continuumServicePortalWorker"
  - "continuumServicePortalDb"
  - "Google Chat"
  - "Jira Cloud"
---

# Operational Readiness Review

## Summary

The Operational Readiness Review (ORR) flow guides an engineering team through the governance gates required before a service reaches production. An ORR is initiated via the API, which creates a review record in MySQL and optionally creates a tracking issue in Jira Cloud. As scheduled governance checks pass, the ORR status progresses. Google Chat notifications inform the team of status changes and blockers. The Jira integration is currently a stub.

## Trigger

- **Type**: api-call (initiation); event-driven (progression based on check results)
- **Source**: Engineering team initiates via API; Sidekiq check workers drive subsequent state changes
- **Frequency**: Per-service, on-demand at service pre-production stage

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Engineering team | Initiates ORR; responds to blockers | external caller |
| Rails Web App | Handles ORR initiation API request; returns ORR status queries | `continuumServicePortalWeb` |
| Sidekiq Worker | Evaluates checks; updates ORR status on check result changes | `continuumServicePortalWorker` |
| MySQL Database | Persists ORR workflow state and check results | `continuumServicePortalDb` |
| Google Chat | Receives ORR status and blocker notifications | external system |
| Jira Cloud | Tracks ORR as a Jira issue (stub — not fully integrated) | external system (stub) |

## Steps

1. **Initiate ORR**: Engineering team sends an API request to initiate an ORR for their service.
   - From: Engineering team
   - To: `continuumServicePortalWeb`
   - Protocol: HTTPS REST

2. **Create ORR record**: Web app creates an `orr_reviews` record in MySQL with status `in_progress`.
   - From: `continuumServicePortalWeb`
   - To: `continuumServicePortalDb`
   - Protocol: MySQL (ActiveRecord)

3. **Create Jira issue (stub)**: Web app or worker attempts to create a tracking issue in Jira Cloud. Currently stubbed — no issue is created in practice.
   - From: `continuumServicePortalWeb` (or `continuumServicePortalWorker`)
   - To: Jira Cloud
   - Protocol: HTTPS REST via Faraday (stub)

4. **Notify team via Google Chat**: Worker sends a Google Chat notification to the owning team's space confirming ORR has been initiated and listing required checks.
   - From: `continuumServicePortalWorker`
   - To: Google Chat
   - Protocol: HTTPS REST via `google-apis-chat_v1`

5. **Scheduled checks evaluate ORR criteria**: On each scheduled check run, the check runner evaluates ORR-relevant checks for the service (e.g., documentation completeness, runbook present, dependency graph declared, alert thresholds configured).
   - From: `continuumServicePortalWorker`
   - To: `continuumServicePortalDb`
   - Protocol: MySQL (ActiveRecord)

6. **Update ORR status on check changes**: When all ORR-required checks pass, the worker updates the `orr_reviews` record status to `passed`. If blocking checks remain failed, status stays `in_progress`.
   - From: `continuumServicePortalWorker`
   - To: `continuumServicePortalDb`
   - Protocol: MySQL (ActiveRecord)

7. **Notify team of status change**: Worker sends a Google Chat notification when ORR status changes (new blockers identified or all checks passing).
   - From: `continuumServicePortalWorker`
   - To: Google Chat
   - Protocol: HTTPS REST via `google-apis-chat_v1`

8. **ORR completion**: When all required checks pass and the ORR record is marked `passed`, the team is notified and the service is considered production-ready.
   - From: `continuumServicePortalWorker`
   - To: Google Chat
   - Protocol: HTTPS REST

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Jira issue creation failure | Stub — failure is logged; ORR proceeds without Jira issue | ORR continues; manual Jira tracking required |
| Check evaluation failure during ORR run | Per-check exception handling; other checks continue | Affected check result missing; worker retried |
| MySQL write failure on ORR status update | Sidekiq job fails; retried | Status update delayed; eventual consistency |
| Google Chat notification failure | Sidekiq notification job retried | Notification delayed; ORR state in DB remains accurate |

## Sequence Diagram

```
Engineering Team -> continuumServicePortalWeb: POST initiate ORR
continuumServicePortalWeb -> continuumServicePortalDb: INSERT orr_reviews (status: in_progress)
continuumServicePortalDb --> continuumServicePortalWeb: ORR record created
continuumServicePortalWeb -> Jira Cloud: POST create issue (stub — no-op)
continuumServicePortalWeb --> Engineering Team: 201 Created (ORR record JSON)
continuumServicePortalWorker -> continuumServicePortalDb: evaluate ORR checks (scheduled)
continuumServicePortalDb --> continuumServicePortalWorker: check results
continuumServicePortalWorker -> continuumServicePortalDb: UPDATE orr_reviews status
continuumServicePortalWorker -> Google Chat: POST status notification
Google Chat --> continuumServicePortalWorker: 200 OK
```

## Related

- Architecture dynamic view: `dynamic-orr-flow`
- Related flows: [Scheduled Service Checks Execution](scheduled-service-checks-execution.md), [Service Registration and Metadata Sync](service-registration-and-metadata-sync.md)
