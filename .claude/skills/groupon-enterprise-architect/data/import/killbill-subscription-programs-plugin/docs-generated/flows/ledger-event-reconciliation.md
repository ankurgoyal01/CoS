---
service: "killbill-subscription-programs-plugin"
title: "Ledger Event Payment Reconciliation"
generated: "2026-03-03"
type: flow
flow_name: "ledger-event-reconciliation"
flow_type: asynchronous
trigger: "jms.topic.Orders.TransactionalLedgerEvents MBus message"
participants:
  - "continuumSubscriptionProgramsPlugin"
  - "messageBus"
  - "continuumOrdersService"
  - "continuumSubscriptionProgramsPluginDb"
architecture_ref: "dynamic-sp-plugin-order-processing"
---

# Ledger Event Payment Reconciliation

## Summary

When payment outcomes occur in the Groupon commerce system (payments, refunds, chargebacks), the Orders system publishes `TransactionalLedgerEvent` messages to the `jms.topic.Orders.TransactionalLedgerEvents` MBus topic. The plugin subscribes to these events via a per-tenant pool of MBus listener threads and uses the event data to locate the corresponding Kill Bill invoice, then calls the Orders service to get current order/payment status, and updates the Kill Bill invoice accordingly (marking as paid, recording refunds, or recording chargebacks).

## Trigger

- **Type**: event (external MBus JMS/STOMP)
- **Source**: Groupon Orders system publishes `TransactionalLedgerEvent` to `jms.topic.Orders.TransactionalLedgerEvents`
- **Frequency**: Per payment transaction — on demand, as payment events occur

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Orders System | Publishes `TransactionalLedgerEvent` to MBus | External (Groupon commerce) |
| MBus Listener (`spMbusListener`) | Subscribes to topic and receives messages | `continuumSubscriptionProgramsPlugin` |
| Retry Processor (`spRetryProcessor`) | Schedules retry jobs for failed reconciliation | `continuumSubscriptionProgramsPlugin` |
| Orders Gateway (`spOrdersGateway`) | Calls Orders service to read current order/payment status | `continuumSubscriptionProgramsPlugin` |
| Orders Service | Provides order and payment status | `continuumOrdersService` |
| Notification Queue | Stores retry records for deferred reconciliation | `continuumSubscriptionProgramsPluginDb` |

## Steps

1. **Receive MBus Message**: `MBusListener` thread (one of `nbMBusListenerThreadsPerTenant` per tenant) receives a `TransactionalLedgerEvent` message from `jms.topic.Orders.TransactionalLedgerEvents` via JMS/STOMP.
   - From: `messageBus`
   - To: `MBusListener`
   - Protocol: JMS/STOMP

2. **Identify Relevant Invoice**: `MBusListener` inspects the ledger event to determine which Kill Bill invoice is affected. Matches by order ID or consumer/account correlation.
   - From: `MBusListener`
   - To: Kill Bill API (in-process)
   - Protocol: direct

3. **Dispatch to Worker Pool**: The message processing is dispatched to one of `mbusWorkers` per-tenant worker threads.
   - From: `MBusListener`
   - To: `MessageProcessor` (thread pool)
   - Protocol: direct (in-process)

4. **Call Orders Service**: `OrdersClient` (Retrofit2) calls the Orders service to retrieve the current order and payment status for the affected account.
   - From: `spOrdersGateway`
   - To: `continuumOrdersService`
   - Protocol: HTTPS/JSON

5. **Reconcile Invoice State**: Based on the Orders response, updates the Kill Bill invoice:
   - Marks invoice as paid (triggers Kill Bill payment recording)
   - Records a refund on the invoice
   - Records a chargeback on the invoice
   - From: `MBusRetries` / `MessageProcessor`
   - To: Kill Bill Invoice / Payment API (in-process)
   - Protocol: direct

6. **Schedule Retry on Failure**: If reconciliation fails, `MBusRetries` inserts a retry record into the `sp_notifications` table for later processing.
   - From: `MBusRetries`
   - To: `continuumSubscriptionProgramsPluginDb`
   - Protocol: JDBC/MySQL

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Orders service unavailable | Logs `step='syncOrder.callOrders.failure'`; schedules retry via notification queue | Retry deferred; eventual consistency |
| Kill Bill API error during reconciliation | Schedules retry via notification queue | Retry deferred |
| MBus listener thread dies | Healthcheck reports unhealthy; pod restart required | Events queue on MBus broker until listener reconnects |
| Message not relevant to any Kill Bill invoice | Message discarded | No action |

## Sequence Diagram

```
OrdersSystem -> messageBus: TransactionalLedgerEvent (orderId, consumerId, eventType)
messageBus -> MBusListener: JMS/STOMP message delivery
MBusListener -> MBusListener: identify relevant Kill Bill invoice
MBusListener -> MessageProcessor: dispatch to worker thread
MessageProcessor -> continuumOrdersService: GET orders for account
continuumOrdersService --> MessageProcessor: OrdersResponse (payment status)
MessageProcessor -> KillBillPaymentAPI: record payment/refund/chargeback
MessageProcessor -> continuumSubscriptionProgramsPluginDb: insert retry record (on failure)
```

## Related

- Architecture dynamic view: `dynamic-sp-plugin-order-processing`
- Related flows: [Invoice-Driven Order Creation](invoice-order-creation.md), [Manual Order Trigger and Refresh](manual-order-trigger.md)
