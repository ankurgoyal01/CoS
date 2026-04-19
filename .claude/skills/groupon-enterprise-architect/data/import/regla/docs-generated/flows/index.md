---
service: "regla"
title: Flows
generated: "2026-03-03T00:00:00Z"
type: flows-index
flow_count: 6
---

# Flows

Process and flow documentation for regla (Rules Engine and Deal Purchase Decision Platform).

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Rule Management CRUD](rule-management-crud.md) | synchronous | Admin creates, updates, approves, or deactivates a rule via REST API | Full lifecycle management of rule definitions through `POST /rule`, `PUT /rule`, `GET /rule` |
| [Rule Instance Registration](rule-instance-registration.md) | synchronous | External system registers event triggers against a rule instance | Event bindings for rule instances registered via `POST /ruleInstance/registerRuleEvents` |
| [Rule Evaluation Query](rule-evaluation-query.md) | synchronous | Downstream service queries whether a user satisfies a rule condition | Real-time purchase-based decision via `/userHasDealPurchaseSince` and `/userHasAnyPurchaseEver` backed by Redis and PostgreSQL |
| [Stream Processing](stream-processing.md) | event-driven | Kafka deal-purchase or browse event arrives on a consumed topic | `reglaStreamJob` evaluates active rules at scale; publishes results to `im_push_regla_delayed_instances_spark` and `janus-tier2` |
| [Rule Action Execution](rule-action-execution.md) | asynchronous | A rule fires for a user (via stream job or API evaluation) | Deferred actions dispatched to Rocketman v2 (push), Email Campaign (email), or Incentive Service (coupon/credit) |
| [Category Taxonomy Resolution](category-taxonomy-resolution.md) | synchronous | Rule condition evaluation requires category hierarchy check | Category membership resolved via Taxonomy Service v2 and Redis cache through `GET /categoryInCategoryTree` |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 3 |
| Asynchronous (event-driven) | 2 |
| Batch / Scheduled | 1 |

## Cross-Service Flows

regla participates in several cross-service flows that span the Continuum Emerging Channels domain:

- The [Stream Processing](stream-processing.md) flow is the highest-volume cross-service flow, consuming from Kafka and publishing to `im_push_regla_delayed_instances_spark` (consumed by inbox push scheduling) and `janus-tier2` (consumed by Janus inbox delivery).
- The [Rule Action Execution](rule-action-execution.md) flow fans out to three downstream services — Rocketman v2, Email Campaign, and Incentive Service — after rule evaluation. Failures in any action service are isolated and do not affect other action types.
- The [Rule Evaluation Query](rule-evaluation-query.md) flow is called synchronously by inbox management orchestration and campaign management systems as part of real-time purchase decisions.
- The [Category Taxonomy Resolution](category-taxonomy-resolution.md) flow depends on Taxonomy Service v2 for authoritative category hierarchy data, with Redis providing a cache layer to reduce repeated remote calls.
