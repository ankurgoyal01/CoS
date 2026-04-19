---
service: "orders-rails3"
title: "Order Creation and Collection"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "order-creation-and-collection"
flow_type: synchronous
trigger: "POST /orders/v1/orders from storefront or mobile client"
participants:
  - "continuumOrdersService"
  - "continuumOrdersWorkers"
  - "continuumUsersService"
  - "continuumDealCatalogService"
  - "continuumVoucherInventoryService"
  - "continuumFraudArbiterService"
  - "continuumIncentivesService"
  - "continuumPaymentsService"
  - "paymentGateways"
  - "continuumOrdersDb"
  - "continuumRedis"
  - "messageBus"
architecture_ref: "dynamic-continuum-orders-creation"
---

# Order Creation and Collection

## Summary

The order creation and collection flow is the core commerce transaction in Groupon's Continuum platform. A client submits an order via the REST API; the Orders Service validates the request against deal catalog and user data, applies incentives, authorizes payment, and persists the order. Payment collection (charge capture) is then completed asynchronously by the Orders Workers, with the fraud screening path running in parallel.

## Trigger

- **Type**: api-call
- **Source**: Storefront web application or mobile client calling `POST /orders/v1/orders`
- **Frequency**: On-demand, per purchase

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Orders REST Controllers | Receives and validates order request; coordinates downstream calls | `continuumOrdersApi_ordersControllers` |
| External Service Clients | Executes HTTP calls to downstream services | `continuumOrdersApi_serviceClientsGateway` |
| Message Bus Publishers | Publishes OrderSnapshots event at order creation | `continuumOrdersApi_messageBusPublishers` |
| Users Service | Provides account validation and billing record lookup | `continuumUsersService` |
| Deal Catalog Service | Validates deal availability and pricing | `continuumDealCatalogService` |
| Voucher Inventory Service | Reserves voucher inventory for line items | `continuumVoucherInventoryService` |
| Fraud Arbiter Service | Provides initial fraud signal | `continuumFraudArbiterService` |
| Incentives Service | Applies credits and promotional incentives | `continuumIncentivesService` |
| Payments Service | Manages billing record and payment authorization | `continuumPaymentsService` |
| Payment Gateways | Processes payment authorization (GlobalPayments/Killbill/Adyen) | `paymentGateways` |
| Order Collection Workers | Executes async payment capture / collection | `continuumOrdersWorkers_orderCollectionWorkers` |
| Orders DB | Persists order, line items, payment records | `continuumOrdersDb` |
| Redis Cache/Queue | Queues collection jobs; provides distributed locks | `continuumRedis` |
| Message Bus | Receives OrderSnapshots and Transactions events | `messageBus` |

## Steps

1. **Receives order request**: Client submits `POST /orders/v1/orders` with deal IDs, quantity, billing reference, and address.
   - From: `client`
   - To: `continuumOrdersApi_ordersControllers`
   - Protocol: REST

2. **Validates user account**: Fetches account details and billing record for the authenticated user.
   - From: `continuumOrdersApi_serviceClientsGateway`
   - To: `continuumUsersService`
   - Protocol: REST

3. **Validates deal availability**: Fetches deal data including pricing, inventory constraints, and taxonomy.
   - From: `continuumOrdersApi_serviceClientsGateway`
   - To: `continuumDealCatalogService`
   - Protocol: REST

4. **Applies incentives and credits**: Calculates applicable promotions and credits against the order total.
   - From: `continuumOrdersApi_serviceClientsGateway`
   - To: `continuumIncentivesService`
   - Protocol: REST

5. **Reserves voucher inventory**: Holds inventory units for each line item to prevent overselling.
   - From: `continuumOrdersApi_serviceClientsGateway`
   - To: `continuumVoucherInventoryService`
   - Protocol: REST

6. **Requests fraud signal**: Obtains an initial fraud risk score for the order.
   - From: `continuumOrdersApi_serviceClientsGateway`
   - To: `continuumFraudArbiterService`
   - Protocol: REST

7. **Authorizes payment**: Submits payment authorization against the customer billing record via the Payments Service and underlying payment gateway.
   - From: `continuumOrdersApi_serviceClientsGateway`
   - To: `continuumPaymentsService` -> `paymentGateways`
   - Protocol: REST

8. **Persists order record**: Writes order, line items, inventory units, and payment authorization record to the Orders DB.
   - From: `continuumOrdersApi_ordersControllers`
   - To: `continuumOrdersDb`
   - Protocol: ActiveRecord

9. **Publishes OrderSnapshots event**: Writes order creation event to the outbox in `continuumOrdersMsgDb` and dispatches to Message Bus.
   - From: `continuumOrdersApi_messageBusPublishers`
   - To: `messageBus`
   - Protocol: Message Bus

10. **Enqueues collection job**: Places async payment capture job onto Resque queue in Redis.
    - From: `continuumOrdersApi_ordersControllers`
    - To: `continuumRedis` (Resque queue)
    - Protocol: Redis client

11. **Executes payment collection**: Workers dequeue and process payment capture against the payment gateway.
    - From: `continuumOrdersWorkers_orderCollectionWorkers`
    - To: `paymentGateways` (via `continuumOrdersWorkers`)
    - Protocol: REST

12. **Updates order to collected state**: Workers write final collection result to Orders DB and publish Transactions event.
    - From: `continuumOrdersWorkers_paymentProcessingWorkers`
    - To: `continuumOrdersDb`, `messageBus`
    - Protocol: ActiveRecord, Message Bus

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Deal unavailable (sold out) | Order rejected at validation step 3 | HTTP 422 returned to client; inventory not reserved |
| Voucher reservation failure | Order rejected; no payment authorization | HTTP 422 returned; client retries |
| Payment authorization declined | Order persisted in `pending_payment` state | HTTP 402 or 422 returned; client presents error to user |
| Collection job failure (gateway error) | Job placed in Resque retry queue; daemon re-enqueues | Order retried up to configured retry limit; moved to failed state if exhausted |
| Fraud hold triggered | Order persisted; fraud review job enqueued | Order status set to `pending_fraud_review`; see [Fraud Review and Arbitration](fraud-review-arbitration.md) |

## Sequence Diagram

```
Client -> continuumOrdersService: POST /orders/v1/orders
continuumOrdersService -> continuumUsersService: GET user account + billing record
continuumUsersService --> continuumOrdersService: user data
continuumOrdersService -> continuumDealCatalogService: GET deal availability + pricing
continuumDealCatalogService --> continuumOrdersService: deal data
continuumOrdersService -> continuumIncentivesService: POST apply incentives
continuumIncentivesService --> continuumOrdersService: adjusted totals
continuumOrdersService -> continuumVoucherInventoryService: POST reserve inventory
continuumVoucherInventoryService --> continuumOrdersService: reservation confirmed
continuumOrdersService -> continuumFraudArbiterService: POST fraud signal request
continuumFraudArbiterService --> continuumOrdersService: fraud risk score
continuumOrdersService -> continuumPaymentsService: POST authorize payment
continuumPaymentsService -> paymentGateways: authorize charge
paymentGateways --> continuumPaymentsService: authorization code
continuumPaymentsService --> continuumOrdersService: authorization confirmed
continuumOrdersService -> continuumOrdersDb: INSERT order + line items + payment auth
continuumOrdersService -> messageBus: PUBLISH OrderSnapshots
continuumOrdersService -> continuumRedis: ENQUEUE collection job
continuumOrdersService --> Client: HTTP 201 order created
continuumOrdersWorkers -> continuumRedis: DEQUEUE collection job
continuumOrdersWorkers -> paymentGateways: capture payment
paymentGateways --> continuumOrdersWorkers: capture confirmed
continuumOrdersWorkers -> continuumOrdersDb: UPDATE order status = collected
continuumOrdersWorkers -> messageBus: PUBLISH Transactions
```

## Related

- Architecture dynamic view: `dynamic-continuum-orders-creation`
- Related flows: [Inventory Fulfillment and Tracking](inventory-fulfillment-tracking.md), [Fraud Review and Arbitration](fraud-review-arbitration.md)
