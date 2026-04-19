---
service: "regla"
title: "Rule Instance Registration"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "rule-instance-registration"
flow_type: synchronous
trigger: "External system registers one or more event triggers against a rule instance"
participants:
  - "reglaService"
  - "reglaPostgresDb"
architecture_ref: "dynamic-containers-regla"
---

# Rule Instance Registration

## Summary

This flow describes how external systems bind event triggers to rule instances in regla. A rule instance represents the association between an active rule definition and a specific event type (e.g., deal-purchase, browse event) that should trigger evaluation. Callers register event bindings by calling `POST /ruleInstance/registerRuleEvents`. The registration is persisted in `reglaPostgresDb`, and the `reglaStreamJob` uses registered instances to determine which rules to evaluate for each incoming Kafka event.

## Trigger

- **Type**: api-call
- **Source**: External system (inbox management orchestration or campaign tooling) calls `POST /ruleInstance/registerRuleEvents`
- **Frequency**: On-demand; typically called when a new rule is activated or when event routing configuration changes

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| External System (Inbox Management / Campaign Tool) | Initiates registration call | — |
| regla Service | Accepts registration request; persists rule instance event bindings | `reglaService` |
| regla PostgreSQL | Stores rule instance records and event-type associations | `reglaPostgresDb` |
| regla Stream Job | Reads rule instance bindings from PostgreSQL to route event evaluations | `reglaStreamJob` |

## Steps

1. **External system calls registration endpoint**: Caller sends `POST /ruleInstance/registerRuleEvents` with a payload containing the rule ID, instance metadata, and the list of event types to bind.
   - From: External System
   - To: `reglaService`
   - Protocol: REST/HTTP POST `Content-Type: application/json`, API key auth

2. **reglaService validates request**: Service validates that the referenced rule exists and is in an `active` or `approved` state, and that the supplied event types are valid.
   - From: `reglaService`
   - To: `reglaPostgresDb`
   - Protocol: JDBC SELECT (rule existence check)

3. **reglaService persists rule instance bindings**: Inserts `rule_instances` records for each event type binding; associates the rule ID with the event type.
   - From: `reglaService`
   - To: `reglaPostgresDb`
   - Protocol: JDBC INSERT into `rule_instances`

4. **reglaService returns registration confirmation**: Returns 201 Created with the created rule instance record(s).
   - From: `reglaService`
   - To: External System
   - Protocol: REST/HTTP JSON

5. **Stream job incorporates new bindings**: On the next `RULE_CACHE_SYNC_INTERVAL_SECONDS` tick, `reglaStreamJob` reloads rule instances from `reglaPostgresDb` and begins routing matching Kafka events to the newly registered rule.
   - From: `reglaStreamJob`
   - To: `reglaPostgresDb`
   - Protocol: JDBC SELECT from `rule_instances`

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Referenced rule does not exist or is not active | `reglaService` returns 404 or 422 | Instance not registered; caller must ensure rule is active before registering |
| Duplicate event binding (same rule + event type) | `reglaService` returns 409 or silently deduplicates | No duplicate record created |
| PostgreSQL unavailable | `reglaService` returns 500 | Instance not registered; caller must retry |
| Stream job sync not yet elapsed | New instance not yet active in stream routing | Events not routed to this rule until next sync tick (max 300s) |

## Sequence Diagram

```
ExternalSystem -> reglaService: POST /ruleInstance/registerRuleEvents {rule_id, event_types}
reglaService -> reglaPostgresDb: SELECT rule WHERE id=rule_id (validate rule exists)
reglaPostgresDb --> reglaService: rule record
reglaService -> reglaPostgresDb: INSERT rule_instances (rule_id, event_type)
reglaPostgresDb --> reglaService: OK
reglaService --> ExternalSystem: 201 Created, rule instance records

reglaStreamJob -> reglaPostgresDb: SELECT rule_instances (sync tick)
reglaPostgresDb --> reglaStreamJob: Updated rule instance bindings
```

## Related

- Related flows: [Rule Management CRUD](rule-management-crud.md), [Stream Processing](stream-processing.md)
