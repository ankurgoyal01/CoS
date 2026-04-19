---
service: "regla"
title: "Stream Processing"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "stream-processing"
flow_type: event-driven
trigger: "A deal-purchase or browse event arrives on a Kafka topic consumed by the reglaStreamJob"
participants:
  - "reglaStreamJob"
  - "reglaRedisCache"
  - "reglaPostgresDb"
architecture_ref: "dynamic-containers-regla"
---

# Stream Processing

## Summary

This flow describes how `reglaStreamJob` continuously processes deal-purchase and browse events from Kafka at scale using Kafka Streams 2.8.2. For each incoming event, the stream job evaluates all active rules against the event's user, deal, and category context. Purchase history is read from and written to `reglaRedisCache` for low-latency access, with `reglaPostgresDb` as the durable store. When a rule condition is satisfied, the stream job publishes evaluation results to either the `janus-tier2` Kafka topic (immediate actions) or the `im_push_regla_delayed_instances_spark` topic (time-delayed actions). Active rules are reloaded from `reglaPostgresDb` every `RULE_CACHE_SYNC_INTERVAL_SECONDS` (default 300 seconds).

## Trigger

- **Type**: event
- **Source**: Kafka deal-purchase topic or Kafka browse events topic; events partitioned by `user_id`
- **Frequency**: Continuous; high-volume during peak purchase windows

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Kafka (deal-purchase topic) | Source of DealPurchased events | — |
| Kafka (browse events topic) | Source of BrowseEvent events | — |
| regla Stream Job | Consumes events; evaluates rules; publishes results | `reglaStreamJob` |
| regla Redis Cache | Provides and receives purchase history and rule state | `reglaRedisCache` |
| regla PostgreSQL | Durable store for execution records and purchase records; source of active rule definitions | `reglaPostgresDb` |
| Kafka (`im_push_regla_delayed_instances_spark`) | Receives delayed rule instance results | — |
| Kafka (`janus-tier2`) | Receives immediate rule evaluation results for Janus inbox delivery | — |

## Steps

1. **Stream job initialises active rule set**: On startup and on each `RULE_CACHE_SYNC_INTERVAL_SECONDS` tick, `reglaStreamJob` queries `reglaPostgresDb` for all `status=active` rules and loads them into memory.
   - From: `reglaStreamJob`
   - To: `reglaPostgresDb`
   - Protocol: JDBC SELECT from `rules` WHERE `status='active'`

2. **Kafka event arrives**: A `DealPurchased` or `BrowseEvent` message is consumed from the respective Kafka topic by the Kafka Streams topology.
   - From: Kafka topic
   - To: `reglaStreamJob`
   - Protocol: Kafka (SSL, at-least-once delivery)

3. **Stream job reads purchase history from Redis**: For `DealPurchased` events, the stream job looks up the user's purchase history cache in `reglaRedisCache` using the `user_id` + `deal_id` key.
   - From: `reglaStreamJob`
   - To: `reglaRedisCache`
   - Protocol: Redis GET (jedis 2.8.0)

4. **Stream job evaluates active rules**: Each active rule's conditions are evaluated against the event data (user_id, deal_id, category_id, purchased_at) and the purchase history state.
   - From: `reglaStreamJob` (internal evaluation)
   - To: `reglaStreamJob`
   - Protocol: In-memory Kafka Streams processing

5. **Stream job updates purchase history cache**: For `DealPurchased` events, the stream job writes the new purchase record to `reglaRedisCache` with TTL `REDIS_TTL_SECONDS` (403200s).
   - From: `reglaStreamJob`
   - To: `reglaRedisCache`
   - Protocol: Redis SET with TTL

6. **Stream job writes execution record to PostgreSQL**: Inserts an `executions` record capturing the evaluation outcome (rule_id, user_id, triggered_at, outcome).
   - From: `reglaStreamJob`
   - To: `reglaPostgresDb`
   - Protocol: JDBC INSERT into `executions`

7. **Stream job writes purchase record to PostgreSQL** (DealPurchased events only): Inserts a `purchases` record for durable storage.
   - From: `reglaStreamJob`
   - To: `reglaPostgresDb`
   - Protocol: JDBC INSERT into `purchases`

8a. **Publish immediate result to `janus-tier2`**: If the rule fires and the action is immediate, the stream job publishes a `RuleEvaluationResult` message to the `janus-tier2` Kafka topic.
   - From: `reglaStreamJob`
   - To: Kafka `janus-tier2` topic
   - Protocol: Kafka (kafka-0.8-thin-client 2.0.16)

8b. **Publish delayed instance to `im_push_regla_delayed_instances_spark`**: If the rule fires with a time-delayed action, the stream job publishes a `DelayedRuleInstance` message to the `im_push_regla_delayed_instances_spark` topic.
   - From: `reglaStreamJob`
   - To: Kafka `im_push_regla_delayed_instances_spark` topic
   - Protocol: Kafka (kafka-0.8-thin-client 2.0.16)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Kafka consumer deserialisation failure | Kafka offset not committed; message retried | Stream job retries the message; persistent failures cause consumer lag to grow |
| Redis write failure on purchase history update | Logged; execution continues | Redis cache misses on subsequent queries; PostgreSQL fallback used |
| PostgreSQL write failure on execution record | Logged; Kafka offset not committed | Message retried; potential duplicate execution record on retry |
| Rule evaluation produces no match | No output published | Kafka offset committed; event processed with no action |
| `janus-tier2` publish failure | Logged; no retry at application level | Rule fires but Janus does not receive the event; message may be lost |
| Active rule set stale (sync interval not yet elapsed) | Stream job uses previously loaded rules | New rules are not evaluated until next sync tick (max 300s delay) |

## Sequence Diagram

```
Kafka(deal-purchase) -> reglaStreamJob: DealPurchased event (user_id, deal_id, category_id)
reglaStreamJob -> reglaRedisCache: GET purchase:<user_id>:<deal_id>
reglaRedisCache --> reglaStreamJob: purchase history (or nil)
reglaStreamJob -> reglaStreamJob: Evaluate active rules against event context
reglaStreamJob -> reglaRedisCache: SET purchase:<user_id>:<deal_id> TTL=403200
reglaStreamJob -> reglaPostgresDb: INSERT executions (rule_id, user_id, outcome)
reglaStreamJob -> reglaPostgresDb: INSERT purchases (user_id, deal_id, purchased_at)
alt Immediate action rule fired
  reglaStreamJob -> Kafka(janus-tier2): Publish RuleEvaluationResult
else Delayed action rule fired
  reglaStreamJob -> Kafka(im_push_regla_delayed_instances_spark): Publish DelayedRuleInstance
end
```

## Related

- Related flows: [Rule Management CRUD](rule-management-crud.md), [Rule Instance Registration](rule-instance-registration.md), [Rule Action Execution](rule-action-execution.md)
