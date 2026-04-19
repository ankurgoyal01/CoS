---
service: "regla"
title: "Rule Action Execution"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "rule-action-execution"
flow_type: asynchronous
trigger: "A rule fires for a user, triggering one or more deferred action dispatches"
participants:
  - "reglaService"
  - "reglaPostgresDb"
architecture_ref: "dynamic-containers-regla"
---

# Rule Action Execution

## Summary

This flow describes how regla dispatches rule-triggered actions to downstream delivery services after a rule condition has been met. When a rule fires (either via the stream job or a synchronous evaluation), the associated `rule_actions` records specify what action to take: a push notification (Rocketman v2), an email campaign (Email Campaign service), or an incentive grant (Incentive Service). `reglaService` dispatches these actions via HTTP using `commons-httpclient` 3.1. The outcome of each dispatch is recorded in the `executions` table in `reglaPostgresDb`. Failures in one action type do not prevent other action types from being dispatched.

## Trigger

- **Type**: event
- **Source**: Rule fires for a user — either from `reglaStreamJob` stream evaluation or from a synchronous evaluation in `reglaService`
- **Frequency**: Per rule firing event; rate proportional to stream processing volume during campaign windows

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| regla Service | Reads rule_actions; dispatches HTTP action calls; records outcomes | `reglaService` |
| regla PostgreSQL | Stores rule_actions definitions and execution outcome records | `reglaPostgresDb` |
| Rocketman v2 | Receives and delivers push notification actions | — |
| Email Campaign | Receives and delivers email campaign actions | — |
| Incentive Service | Receives and grants incentive (coupon/credit) actions | — |

## Steps

1. **Rule fires**: A rule evaluation determines that a user satisfies the rule conditions. `reglaService` retrieves the associated `rule_actions` records for the fired rule from `reglaPostgresDb`.
   - From: `reglaService`
   - To: `reglaPostgresDb`
   - Protocol: JDBC SELECT from `rule_actions` WHERE `rule_id = ?`

2. **Dispatch push notification action** (if action_type = push): `reglaService` calls Rocketman v2 via HTTP with the push notification payload generated from the Freemarker template in the action definition.
   - From: `reglaService`
   - To: Rocketman v2
   - Protocol: HTTP POST (commons-httpclient 3.1)

3. **Dispatch email campaign action** (if action_type = email): `reglaService` calls the Email Campaign service via HTTP with the email campaign parameters.
   - From: `reglaService`
   - To: Email Campaign
   - Protocol: HTTP POST (commons-httpclient 3.1)

4. **Dispatch incentive action** (if action_type = incentive): `reglaService` calls the Incentive Service via HTTP to grant a coupon or credit to the user.
   - From: `reglaService`
   - To: Incentive Service
   - Protocol: HTTP POST (commons-httpclient 3.1)

5. **Record dispatch outcome**: For each action dispatched, `reglaService` writes or updates the `executions` record in `reglaPostgresDb` with the outcome (`action_dispatched=true|false`, HTTP status code, and timestamp).
   - From: `reglaService`
   - To: `reglaPostgresDb`
   - Protocol: JDBC UPDATE/INSERT into `executions`

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Rocketman v2 returns 500 or is unreachable | HTTP error logged; `executions` record written with `action_dispatched=false` | Push not delivered; no retry at application level |
| Email Campaign returns 500 or is unreachable | HTTP error logged; `executions` record written with failed status | Email not sent; no retry at application level |
| Incentive Service returns 500 or is unreachable | HTTP error logged; `executions` record written with failed status | Incentive not granted; no retry at application level |
| One action fails; others pending | Failure is isolated to the failed action type | Other action types dispatched independently; partial delivery possible |
| PostgreSQL unavailable when writing execution record | Execution outcome not persisted | Action may have been dispatched but no record exists; creates audit gap |

## Sequence Diagram

```
reglaService -> reglaPostgresDb: SELECT rule_actions WHERE rule_id=X
reglaPostgresDb --> reglaService: action list [{type: push, payload}, {type: email, payload}]

reglaService -> RocketmanV2: POST /push {user_id, notification_payload}
RocketmanV2 --> reglaService: 200 OK
reglaService -> reglaPostgresDb: UPDATE executions SET action_dispatched=true (push)

reglaService -> EmailCampaign: POST /send {user_id, campaign_params}
EmailCampaign --> reglaService: 200 OK
reglaService -> reglaPostgresDb: UPDATE executions SET action_dispatched=true (email)

reglaService -> IncentiveService: POST /grant {user_id, incentive_params}
IncentiveService --> reglaService: 200 OK
reglaService -> reglaPostgresDb: UPDATE executions SET action_dispatched=true (incentive)
```

## Related

- Related flows: [Stream Processing](stream-processing.md), [Rule Management CRUD](rule-management-crud.md)
