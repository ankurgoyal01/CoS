---
service: "orders-ext"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: [continuumOrdersExtService, continuumOrdersExtRedis]
---

# Architecture Context

## System Context

Orders Ext sits within the Continuum platform as a narrow inbound adapter between external fraud and payment partners and Groupon's internal order processing infrastructure. External partners (Accertify, Signifyd, KillBill/Adyen, PayPal) push notifications to Orders Ext endpoints; Orders Ext authenticates each request, dispatches events to internal services (Fraud Arbiter, Users Service, KillBill), and either enqueues async jobs via Redis or publishes events to the internal MessageBus.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Orders Ext Service | `continuumOrdersExtService` | Backend API | Ruby on Rails | 7.0.3 | Rails service exposing fraud and payment webhook endpoints |
| Orders Ext Redis | `continuumOrdersExtRedis` | Cache / Queue | Redis | — | Redis datastore used by Resque for background job enqueue |

## Components by Container

### Orders Ext Service (`continuumOrdersExtService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `AccertifyListenerController` | Authenticates Accertify HTTP Basic requests, parses XML resolution callbacks, invokes OrderResolver | Rails Controller |
| `PaypalWebhooksController` | Validates PayPal webhook headers, verifies signature via PayPal API, routes `BILLING_AGREEMENTS.AGREEMENT.CANCELLED` events | Rails Controller |
| `SignifydWebhooksController` | Validates HMAC-SHA256 signature, checks `SIGNIFYD-TOPIC` and `SIGNIFYD-CHECKPOINT`, forwards decision reviews to Fraud Arbiter | Rails Controller |
| `KillbillController` | Proxies Adyen payment notifications to KillBill by subservice and region | Rails Controller |
| `RequestValidator` | Validates presence of required webhook headers and body fields for PayPal and Signifyd requests | Validator |
| `OrderResolver` | Parses Accertify XML, resolves admin identity via Users Service, enqueues ACCEPT/REJECT jobs to Resque | Domain Service |
| `EventsProcessor` | Routes PayPal billing agreement cancellation events to the appropriate publisher | Domain Service |
| `PaypalBillingAgreementMessagePublisher` | Builds `PaypalBillingAgreementCancelled` message envelope and delegates to MessagePublisher | Message Publisher |
| `MessagePublisher` | Publishes JSON payloads to the MessageBus with configurable retry logic (up to 5 retries, 200 ms interval) | Message Publisher |
| `PayPal Service Client` | Calls PayPal `POST /v1/notifications/verify-webhook-signature` to verify webhook authenticity | HTTP Client |
| `KillBill Service Client` | Calls KillBill `POST /1.0/kb/paymentGateways/notification/killbill-adyen` by region | HTTP Client |
| `FraudArbiterService Client` | Calls Fraud Arbiter `PUT /orders/{order_id}/decision_review` with Signifyd payload | HTTP Client |
| `UsersService Client` | Looks up admin account by domain and email via Users Service | HTTP Client |
| `Resque Job Enqueuer` | Pushes order resolution job payloads to the `accertify_order_resolution` Resque queue in Redis | Queue Adapter |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `ordersExt_usersServiceClient` | `continuumUsersService` | Fetches admin account by email | REST/HTTP |
| `ordersExt_messagePublisher` | `messageBus` | Publishes `PaypalBillingAgreementCancelled` | STOMP/JMS |
| `ordersExt_resqueJobEnqueuer` | `continuumOrdersExtRedis` | Pushes job payload to `accertify_order_resolution` queue | Redis protocol |
| `ordersExt_paypalWebhooksController` | `ordersExt_requestValidator` | Validates required PayPal webhook fields | in-process |
| `ordersExt_paypalWebhooksController` | `ordersExt_payPalClient` | Verifies webhook authenticity | in-process |
| `ordersExt_paypalWebhooksController` | `ordersExt_eventsProcessor` | Handles billing agreement cancellation | in-process |
| `ordersExt_eventsProcessor` | `ordersExt_paypalBillingAgreementMessagePublisher` | Dispatches cancellation message | in-process |
| `ordersExt_signifydWebhooksController` | `ordersExt_fraudArbiterClient` | Submits decision review payload | in-process |
| `ordersExt_killbillController` | `ordersExt_killBillClient` | Forwards payment notification | in-process |
| `ordersExt_accertifyListenerController` | `ordersExt_orderResolver` | Resolves order action from XML callback | in-process |
| `ordersExt_orderResolver` | `ordersExt_usersServiceClient` | Resolves admin user by email | in-process |
| `ordersExt_orderResolver` | `ordersExt_resqueJobEnqueuer` | Enqueues async resolution job | in-process |

## Architecture Diagram References

- Component: `components-ordersext-service-components`
- Dynamic (Accertify flow): `dynamic-ordersext-accertify-order-resolution`
- Dynamic (PayPal cancellation): `dynamic-ordersext-paypal-webhook-cancellation`
- Dynamic (Signifyd review): `dynamic-ordersext-signifyd-decision-review`
