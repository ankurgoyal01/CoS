---
service: "scs-jtier"
title: "Abandoned Cart Detection"
generated: "2026-03-03"
type: flow
flow_name: "abandoned-cart-detection"
flow_type: scheduled
trigger: "Quartz scheduler — every 30 minutes on worker pods; IS_CRON_ENABLED=true"
participants:
  - "abandonedCartsJob"
  - "abandonedCartsWorker"
  - "cartService"
  - "shoppingCartReadDao"
  - "scsJtier_messageBusPublisher"
  - "continuumScsJtierReadMysql"
architecture_ref: "dynamic-scsJtier"
---

# Abandoned Cart Detection

## Summary

The Abandoned Cart Detection flow is a scheduled background job that runs every 30 minutes on `worker` pods. It scans the MySQL read replica for active carts belonging to authenticated users (with `consumer_id`) that have not been updated within a configured time window (typically 4 hours), indicating the user has abandoned their shopping session. For each qualifying cart, an `abandoned_cart` event is published to the `abandoned.carts` Mbus destination, which is consumed downstream by the Regla push marketing team to send re-engagement emails.

## Trigger

- **Type**: schedule
- **Source**: Quartz scheduler configured in `quartzConfiguration`; only active when `IS_CRON_ENABLED=true` (worker component)
- **Frequency**: Every 30 minutes (half-hourly); window for qualifying carts is controlled by `abandonedCartTimes.period` and `abandonedCartTimes.interval` config values — typically detects carts inactive for 4 hours

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| `abandonedCartsJob` | Quartz job entry point — reads context and initiates the flow | `abandonedCartsJob` |
| `abandonedCartsWorker` | Worker class that queries carts and sends Mbus notifications | `abandonedCartsWorker` |
| `cartService` | Provides `findAbandonedCarts` lookup via DAO | `cartService` |
| `shoppingCartReadDao` | Executes `findAbandonedCarts` query on the read replica | `shoppingCartReadDao` |
| `scsJtier_messageBusPublisher` | Mbus writer that serializes and publishes `AbandonedCartPublishMessage` | `scsJtier_messageBusPublisher` |
| `continuumScsJtierReadMysql` | MySQL read replica scanned for abandoned carts | `continuumScsJtierReadMysql` |

## Steps

1. **Quartz triggers job**: The Quartz scheduler fires `AbandonedCartsJob` every 30 minutes on worker pods (controlled by `@DisallowConcurrentExecution` — only one execution at a time).
   - From: Quartz scheduler
   - To: `abandonedCartsJob`
   - Protocol: JVM scheduler

2. **Compute time window**: `AbandonedCartsJob` calculates the `startTimeToQuery` and `endTimeToQuery` by subtracting `abandonedCartTimes.period` and `abandonedCartTimes.period + abandonedCartTimes.interval` minutes from the current time, respectively. This defines the window of carts considered abandoned.
   - From: `abandonedCartsJob`
   - To: `abandonedCartsWorker`
   - Protocol: direct

3. **Scan for abandoned carts per country**: `AbandonedCarts` worker iterates over supported country codes and calls `CartService`, which queries `ShoppingCartReadDAO.findAbandonedCarts(countryCode, startTime, endTime)`. This executes: `SELECT * FROM shopping_carts WHERE country_code = ? AND active=true AND size>0 AND consumer_id IS NOT NULL AND updated_at BETWEEN ? AND ?`.
   - From: `abandonedCartsWorker` → `cartService`
   - To: `shoppingCartReadDao` → `continuumScsJtierReadMysql`
   - Protocol: JDBC

4. **Publish abandoned_cart events**: For each abandoned cart found, `AbandonedCarts` creates an `AbandonedCartPublishMessage` (containing `event = "abandoned_cart"`, `consumer_id`, `b_cookie`, `updated_at`, `items`, `country_code`) and writes it to the `abandoned.carts` Mbus destination.
   - From: `abandonedCartsWorker`
   - To: `scsJtier_messageBusPublisher` → Mbus `abandoned.carts` destination
   - Protocol: Mbus

5. **Close writer and emit metric**: After all events are published, the Mbus writer is closed and a `shopping.cart.service.custom` counter metric is emitted with `type=abandoned.cart.publish.success` (or `abandoned.cart.publish.failure` on error).
   - From: `abandonedCartsJob`
   - To: Metrics submitter (SMA)
   - Protocol: direct

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Quartz context load failure | Error logged; job exits early | No carts processed; no events published; `abandoned.cart.publish.failure` not incremented |
| Database read failure | Exception propagates; job fails | No events published for that country; job completes for other countries if possible |
| Mbus write failure | `MessageException` caught in `finishAbandonedCartsJob` | Writer closed; individual message failures logged; metric not incremented as success |
| Concurrent execution attempted | Blocked by `@DisallowConcurrentExecution` annotation | Second execution skipped until first completes |

## Sequence Diagram

```
QuartzScheduler -> abandonedCartsJob: execute() [every 30 min]
abandonedCartsJob -> abandonedCartsJob: compute startTimeToQuery, endTimeToQuery
abandonedCartsJob -> abandonedCartsWorker: new AbandonedCarts(cartService, writer, startTime, endTime)
abandonedCartsWorker -> cartService: findAbandonedCarts(countryCode, startTime, endTime)
cartService -> shoppingCartReadDao: findAbandonedCarts(countryCode, startTime, endTime)
shoppingCartReadDao -> continuumScsJtierReadMysql: SELECT * FROM shopping_carts WHERE active=1 AND size>0 AND consumer_id IS NOT NULL AND updated_at BETWEEN ? AND ?
continuumScsJtierReadMysql --> shoppingCartReadDao: List<ShoppingCartModel>
shoppingCartReadDao --> cartService: List<ShoppingCartModel>
cartService --> abandonedCartsWorker: List<ShoppingCartModel>
abandonedCartsWorker -> scsJtier_messageBusPublisher: write(AbandonedCartPublishMessage) [for each cart]
scsJtier_messageBusPublisher --> abandonedCartsWorker: OK
abandonedCartsJob -> abandonedCartsJob: writer.close()
abandonedCartsJob -> MetricsSubmitter: submitCustomCounterMetric(ABANDONED_CART_PUBLISH_SUCCESS)
```

## Related

- Architecture dynamic view: `dynamic-scsJtier`
- Related flows: [Get Cart](get-cart.md)
- Downstream consumer: Regla (Push Marketing) team — processes `abandoned.carts` Mbus events to send re-engagement emails
