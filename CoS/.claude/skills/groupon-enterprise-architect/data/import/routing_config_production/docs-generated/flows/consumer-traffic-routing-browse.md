---
service: "routing_config_production"
title: "Consumer Traffic Routing — Browse and Homepage"
generated: "2026-03-03"
type: flow
flow_name: "consumer-traffic-routing-browse"
flow_type: synchronous
trigger: "Inbound HTTP/HTTPS request to browse or homepage paths"
participants:
  - "Consumer (browser or mobile app)"
  - "Groupon routing service (runtime)"
  - "pull.production.service:443"
architecture_ref: "dynamic-routingConfigProduction"
---

# Consumer Traffic Routing — Browse and Homepage

## Summary

This flow describes how the routing service applies the browse and homepage routing rules — defined in `src/applications/browse.flexi` — to direct inbound consumer traffic to the `pull.production.service` backend. The rules cover Groupon's homepage, global search, browse pages, gift landing pages, local and goods categories, and localized browse paths across 15+ country-specific route groups. The routing service reads the compiled config produced by this repo and applies pattern matching to each incoming request.

## Trigger

- **Type**: api-call (inbound HTTP/HTTPS request)
- **Source**: Consumer browser or mobile application making an HTTP/HTTPS request to Groupon's routing layer
- **Frequency**: Per-request (continuous, high volume)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Consumer (browser or mobile app) | Initiates HTTP/HTTPS request to a Groupon URL | — |
| Groupon routing service (runtime) | Receives request, evaluates URL against loaded Flexi config, selects matching route group, forwards to destination | — |
| `pull.production.service:443` | Backend application service that handles browse, search, homepage, and gift landing pages | — |

## Steps

1. **Receives inbound request**: The routing service receives an HTTP or HTTPS request from a consumer on one of the browse paths (e.g., `/`, `/search`, `/gift`, `/local`, `/goods`, `/landing`, `/amp/seo`, or a country-specific localized path).
   - From: `Consumer`
   - To: `Groupon routing service`
   - Protocol: HTTP/HTTPS

2. **Evaluates route groups**: The routing service evaluates the request URL against the ordered route group definitions loaded from the compiled Flexi config. For browse traffic, the relevant groups are defined in `src/applications/browse.flexi`, including country-specific groups for US, UK, DE, FR, ES, IT, NL, PL, BE, AU, JP, NZ, CA, AE, and IE.

3. **Matches destination**: The routing service selects the highest-priority matching route group. For browse requests, the destination is `tls_conveyor_pull_itier` (defined as `server pull.production.service:443` with TLS, keep-alive enabled, `Host: pull.production.service` forced header, and `x-service-name: ion-internal/pull`).
   - From: `Groupon routing service`
   - To: Flexi config (in-memory)
   - Protocol: direct (in-process)

4. **Injects forced headers**: The routing service injects the configured forced headers onto the upstream request:
   - `Host: pull.production.service`
   - `x-test-keep-alive: 1`
   - `x-service-name: ion-internal/pull`

5. **Forwards request to backend**: The routing service forwards the request over TLS to `pull.production.service:443`.
   - From: `Groupon routing service`
   - To: `pull.production.service:443`
   - Protocol: HTTPS (TLS, keep-alive)

6. **Returns response to consumer**: The routing service relays the backend response back to the consumer.
   - From: `pull.production.service:443`
   - To: `Consumer`
   - Protocol: HTTP/HTTPS

## Route Groups Covered (from `src/applications/browse.flexi`)

| Route Group | Example Paths | Country |
|-------------|--------------|---------|
| `browse_homepage_ita` | `/` | All (ITA) |
| `search_ita` | `/search` | All (ITA) |
| `gifts_ita` | `/gift` | All (ITA) |
| `us_browse_routes` | `/landing`, `/legal`, `/pages`, `/amp/local`, `/articles`, `/lists` | US |
| `uk_browse_routes` | `/vouchers`, `/landing`, `/gift-ideas`, `/discount-codes/blog` | UK |
| `de_browse_routes` | `/gutscheine`, `/geschenkideen`, `/gutscheincode/blog` | DE |
| `fr_browse_routes` | `/bon-plan`, `/cartes-cadeaux`, `/code-promo/blog` | FR |
| `es_browse_routes` | `/ofertas`, `/tarjetas-de-regalo`, `/cupones-descuento/blog` | ES |
| `it_browse_routes` | `/offerte`, `/buoni-regalo`, `/buoni-sconto/blog` | IT |
| `nl_browse_routes` | `/kortingsbonnen`, `/cadeaubonnen`, `/kortingscodes/blog` | NL |
| `pl_browse_routes` | `/oferta`, `/karty-prezentowe`, `/kody-rabatowe/blog` | PL |
| `be_browse_routes` | `/fr/bon-plan`, `/nl/kortingsbonnen`, `/cartes-cadeaux` | BE |
| `au_browse_routes` | `/coupons`, `/gift-cards`, `/vouchers/blog` | AU |
| `jp_browse_routes` | `/coupons`, `/gift-ideas`, `/amp/coupons` | JP |
| `ca_browse_routes` | `/fr/offre`, `/en/coupons`, `/cartes-cadeaux` | CA |

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| `pull.production.service` unreachable | Routing service applies its own error handling (managed by routing runtime) | Consumer receives error response; config repo is not involved |
| No route matches the request URL | Routing service applies default/fallback behavior (managed by routing runtime) | Consumer receives 404 or default response |
| Flexi config not loaded (startup) | Routing service cannot serve traffic until config loads | Service unavailable until config is applied |

## Sequence Diagram

```
Consumer -> Groupon routing service: GET / (or /search, /gift, /local, /goods, etc.)
Groupon routing service -> Flexi config (in-memory): evaluate URL against route groups
Flexi config (in-memory) --> Groupon routing service: matched group=browse_homepage_ita, dest=tls_conveyor_pull_itier
Groupon routing service -> pull.production.service:443: GET / (with Host, x-service-name headers injected, TLS)
pull.production.service:443 --> Groupon routing service: 200 OK (page content)
Groupon routing service --> Consumer: 200 OK (page content)
```

## Related

- Architecture dynamic view: `dynamic-routingConfigProduction`
- Related flows: [Consumer Traffic Routing — Checkout](consumer-traffic-routing-checkout.md), [Config Change and Deployment](config-change-deployment.md)
- Source: `src/applications/browse.flexi`
