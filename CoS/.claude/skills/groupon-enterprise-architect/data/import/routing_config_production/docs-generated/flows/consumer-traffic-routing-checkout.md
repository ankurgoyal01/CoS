---
service: "routing_config_production"
title: "Consumer Traffic Routing — Checkout"
generated: "2026-03-03"
type: flow
flow_name: "consumer-traffic-routing-checkout"
flow_type: synchronous
trigger: "Inbound HTTPS request to cart or checkout paths"
participants:
  - "Consumer (browser or mobile app)"
  - "Groupon routing service (runtime)"
  - "checkout-itier.production.service:443"
architecture_ref: "dynamic-routingConfigProduction"
---

# Consumer Traffic Routing — Checkout

## Summary

This flow describes how the routing service applies the checkout routing rules — defined in `src/applications/checkout.flexi` — to direct cart and checkout traffic to the `checkout-itier.production.service` backend. The rules cover the shopping cart, checkout funnel, order confirmation, receipt pages, and Apple Pay domain association. TLS enforcement and `frameOptions:deny` filter disabling are applied on all checkout routes to support embedded payment flows.

## Trigger

- **Type**: api-call (inbound HTTPS request)
- **Source**: Consumer browser or mobile application making an HTTPS request to a cart or checkout path
- **Frequency**: Per-request (on-demand, per purchase attempt)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Consumer (browser or mobile app) | Initiates HTTPS request to checkout paths (`/cart`, `/checkout/*`, `/receipt/:order_id`, `/deals/:id/confirmation`) | — |
| Groupon routing service (runtime) | Receives request, evaluates URL against compiled Flexi config, selects matching checkout route group, enforces HTTPS scheme, forwards to destination | — |
| `checkout-itier.production.service:443` | Backend checkout application service (`workflow/checkout-reloaded`) that handles cart, checkout funnel, order confirmation, and receipt pages | — |

## Steps

1. **Receives inbound request**: The routing service receives an HTTPS request for a cart or checkout path.
   - From: `Consumer`
   - To: `Groupon routing service`
   - Protocol: HTTPS

2. **Evaluates route groups**: The routing service evaluates the request URL against checkout route groups from `src/applications/checkout.flexi`. The relevant groups include:
   - `cart_next_routes` (`routeGroup cart_next`): matches `/cart` and `/cart/error/:msg`
   - `checkout_next_routes` (`routeGroup checkout_next`): matches `/checkout/cart`, `/checkout/bundle`, `/checkout/app-payment-completion`
   - `checkout_routes_ita` (`routeGroup checkout`): matches `/checkout`, deal order confirmation/order routes, Adyen add-card, checkout proxy
   - `receipt_next_routes` (`routeGroup receipt_next`): matches `/receipt/:order_id`
   - `shopping_cart_routes` (`routeGroup shopping_cart`): matches `/cart/widget`, `/cart/proxy`, `/cart`
   - `us_checkout_routes` (`routeGroup us_checkout`): matches `/.well-known/apple-developer-merchantid-domain-association`

3. **Enforces HTTPS scheme**: All checkout route groups declare `scheme https`, causing the routing service to redirect or reject non-HTTPS requests.

4. **Disables frameOptions filter**: Routes within the checkout funnel that support embedded payment iframes (e.g., `/checkout/cart`, `/checkout/bundle`, `/deals/:id/confirmation`) include `disableFilter frameOptions:deny` to allow rendering inside payment provider iframes.

5. **Matches destination and injects headers**: The routing service selects the `tls_conveyor_checkout_itier` destination:
   - `server checkout-itier.production.service:443`
   - `Host: checkout-itier.production.service`
   - `x-test-keep-alive: 1`
   - `x-service-name: workflow/checkout-reloaded`
   - TLS and keep-alive enabled

6. **Forwards request to checkout backend**: The routing service forwards the HTTPS request to `checkout-itier.production.service:443`.
   - From: `Groupon routing service`
   - To: `checkout-itier.production.service:443`
   - Protocol: HTTPS (TLS, keep-alive)

7. **Returns response to consumer**: The routing service relays the checkout backend response back to the consumer.
   - From: `checkout-itier.production.service:443`
   - To: `Consumer`
   - Protocol: HTTPS

## Route Groups Covered (from `src/applications/checkout.flexi`)

| Route Group | Key Paths | Notes |
|-------------|-----------|-------|
| `cart_next` | `/cart`, `/cart/error/:msg` | HTTPS enforced |
| `checkout_next` | `/checkout/cart`, `/checkout/bundle`, `/checkout/app-payment-completion` | `frameOptions:deny` disabled |
| `checkout` (ITA) | `/checkout`, `/deals/:id/confirmation`, `/deals/:id/orders`, `/checkout/adyen/add-card`, `/checkout/proxy/` | HTTPS enforced; Adyen card flow |
| `receipt_next` | `/receipt/:order_id` | HTTPS enforced |
| `shopping_cart` | `/cart/widget`, `/cart/proxy`, `/cart` | HTTPS enforced |
| `us_checkout_next` | `/deals/:deal_id/confirmation/:order_id` | US only; HTTPS enforced |
| `us_checkout` | `/.well-known/apple-developer-merchantid-domain-association` | US Apple Pay domain association |

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| HTTP (non-HTTPS) request to checkout path | Routing service enforces `scheme https` — redirects or rejects | Consumer redirected to HTTPS; no traffic reaches checkout backend over HTTP |
| `checkout-itier.production.service` unreachable | Routing runtime error handling (outside this repo) | Consumer receives error; checkout flow fails |
| No checkout route matches | Routing service falls through to default/fallback | Consumer may see 404 or fallback behavior |

## Sequence Diagram

```
Consumer -> Groupon routing service: HTTPS POST /cart (or /checkout/cart, /receipt/:id, etc.)
Groupon routing service -> Flexi config (in-memory): evaluate URL against route groups
Flexi config (in-memory) --> Groupon routing service: matched group=checkout_next, dest=tls_conveyor_checkout_itier
Groupon routing service -> checkout-itier.production.service:443: HTTPS POST /cart (Host, x-service-name headers injected)
checkout-itier.production.service:443 --> Groupon routing service: 200 OK (cart response)
Groupon routing service --> Consumer: 200 OK (cart response)
```

## Related

- Architecture dynamic view: `dynamic-routingConfigProduction`
- Related flows: [Consumer Traffic Routing — Browse and Homepage](consumer-traffic-routing-browse.md), [Config Change and Deployment](config-change-deployment.md)
- Source: `src/applications/checkout.flexi`
