---
service: "regla"
title: "Rule Management CRUD"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "rule-management-crud"
flow_type: synchronous
trigger: "Admin or campaign operator creates, updates, approves, rejects, or deactivates a rule via the REST API"
participants:
  - "reglaService"
  - "reglaPostgresDb"
  - "reglaRedisCache"
architecture_ref: "dynamic-containers-regla"
---

# Rule Management CRUD

## Summary

This flow covers the full lifecycle of a rule definition in regla: creation (draft), approval, activation, and deactivation. Campaign operators and admins interact with `reglaService` via `POST /rule` (create), `PUT /rule` (update including approve/reject/deactivate), and `GET /rule` (list). Rule definitions are persisted in `reglaPostgresDb`. When a rule is activated, the `reglaStreamJob` picks up the new rule on its next cache sync cycle (`RULE_CACHE_SYNC_INTERVAL_SECONDS`, default 300 seconds). An approval workflow enforces that rules transition through draft -> approved -> active -> inactive states.

## Trigger

- **Type**: api-call
- **Source**: Campaign operator or admin system calls the rule management REST API
- **Frequency**: On-demand; per rule authoring or status-change action

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Campaign Operator / Admin System | Initiates rule create, update, or status change | — |
| regla Service | Accepts and validates API requests; persists rule state | `reglaService` |
| regla PostgreSQL | Stores rule definitions, instances, and status history | `reglaPostgresDb` |
| regla Redis Cache | Cache invalidated or updated when rule state changes | `reglaRedisCache` |
| regla Stream Job | Reloads active rules from PostgreSQL on sync interval | `reglaStreamJob` |

## Steps

1. **Create rule (draft)**: Caller sends `POST /rule` with rule definition payload (name, conditions, action configuration).
   - From: Campaign Operator / Admin System
   - To: `reglaService`
   - Protocol: REST/HTTP POST `Content-Type: application/json`, API key auth

2. **reglaService validates and persists draft**: Service validates the rule payload, assigns `status=draft`, and inserts the record into `reglaPostgresDb`.
   - From: `reglaService`
   - To: `reglaPostgresDb`
   - Protocol: JDBC / PostgreSQL

3. **reglaService returns created rule**: Returns 201 Created with the new rule definition including assigned `id` and `status=draft`.
   - From: `reglaService`
   - To: Campaign Operator / Admin System
   - Protocol: REST/HTTP JSON

4. **Approve rule**: Caller sends `PUT /rule` with `{id: <rule_id>, status: "approved"}`.
   - From: Campaign Operator / Admin System
   - To: `reglaService`
   - Protocol: REST/HTTP PUT `Content-Type: application/json`, API key auth

5. **reglaService validates status transition and updates record**: Service validates the draft -> approved transition and updates the rule record in `reglaPostgresDb`.
   - From: `reglaService`
   - To: `reglaPostgresDb`
   - Protocol: JDBC UPDATE

6. **Activate rule**: Caller sends `PUT /rule` with `{id: <rule_id>, status: "active"}` after approval.
   - From: Campaign Operator / Admin System
   - To: `reglaService`
   - Protocol: REST/HTTP PUT JSON

7. **reglaService persists active status**: Updates rule record in `reglaPostgresDb` to `status=active`; this rule is now eligible for stream evaluation.
   - From: `reglaService`
   - To: `reglaPostgresDb`
   - Protocol: JDBC UPDATE

8. **Stream job reloads active rules**: On the next `RULE_CACHE_SYNC_INTERVAL_SECONDS` tick, `reglaStreamJob` queries `reglaPostgresDb` for all `status=active` rules and loads them into its in-memory rule set.
   - From: `reglaStreamJob`
   - To: `reglaPostgresDb`
   - Protocol: JDBC SELECT

9. **Deactivate rule**: Caller sends `PUT /rule` with `{id: <rule_id>, status: "inactive"}`.
   - From: Campaign Operator / Admin System
   - To: `reglaService`
   - Protocol: REST/HTTP PUT JSON

10. **reglaService persists inactive status**: Updates rule to `status=inactive`; stream job excludes this rule on the next sync cycle.
    - From: `reglaService`
    - To: `reglaPostgresDb`
    - Protocol: JDBC UPDATE

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Invalid rule payload on POST | `reglaService` returns 400/422 | Rule not created; caller receives validation error |
| Invalid status transition (e.g., inactive -> approved) | `reglaService` returns 422 | Status unchanged; caller receives error |
| PostgreSQL unavailable during write | `reglaService` returns 500 | Rule not persisted; caller must retry |
| Stream job sync interval not yet elapsed | New active rule not yet visible to stream processing | Rule will be evaluated after next `RULE_CACHE_SYNC_INTERVAL_SECONDS` tick (max 300s delay) |

## Sequence Diagram

```
CampaignOperator -> reglaService: POST /rule {name, conditions, action}
reglaService -> reglaPostgresDb: INSERT rule (status=draft)
reglaPostgresDb --> reglaService: 201 Created, rule record
reglaService --> CampaignOperator: 201 Created, rule JSON

CampaignOperator -> reglaService: PUT /rule {id, status: "approved"}
reglaService -> reglaPostgresDb: UPDATE rule SET status=approved
reglaPostgresDb --> reglaService: OK
reglaService --> CampaignOperator: 200 OK, updated rule JSON

CampaignOperator -> reglaService: PUT /rule {id, status: "active"}
reglaService -> reglaPostgresDb: UPDATE rule SET status=active
reglaPostgresDb --> reglaService: OK
reglaService --> CampaignOperator: 200 OK, updated rule JSON

reglaStreamJob -> reglaPostgresDb: SELECT * FROM rules WHERE status='active' (sync tick)
reglaPostgresDb --> reglaStreamJob: Active rule list including new rule
```

## Related

- Related flows: [Rule Instance Registration](rule-instance-registration.md), [Stream Processing](stream-processing.md)
