---
service: "billing-record-options-service"
title: "Payment Methods by Country Query"
generated: "2026-03-03"
type: flow
flow_name: "payment-methods-by-country"
flow_type: synchronous
trigger: "HTTP GET /paymentmethods/{countryCode} from a checkout or payment client"
participants:
  - "brosPaymentMethodsResource"
  - "brosPaymentMethodsService"
  - "brosClientTypeService"
  - "brosCountryService"
  - "brosPaymentProviderService"
  - "brosPaymentTypeService"
  - "brosJdbiDataAccessor"
  - "daasPostgresPrimary"
  - "raasRedis"
architecture_ref: "components-continuumBillingRecordOptionsService"
---

# Payment Methods by Country Query

## Summary

This is the primary read flow of BROS. When a checkout frontend or payment orchestration service needs to know which payment methods are available for a given country, it sends a GET request to `/paymentmethods/{countryCode}`. BROS resolves the caller's client type, loads country metadata, loads and filters applicable payment providers (applying include/exclude rules based on inventory context, brand, and exchange flag), ranks them by client-type importance, enriches each with payment type definitions, and returns a structured list to the caller.

## Trigger

- **Type**: api-call
- **Source**: Checkout frontend (FRONTEND, MOBILE, CHECKOUT application) or internal payment orchestration service
- **Frequency**: Per-request (on demand at checkout time)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Checkout Client | Initiates request with country code and context filters | External consumer |
| Payment Methods Resource | Receives the HTTP request and extracts query parameters | `brosPaymentMethodsResource` |
| Payment Methods Service | Orchestrates all sub-service calls and composes the final response | `brosPaymentMethodsService` |
| Client Type Service | Resolves client type from user-agent / role headers | `brosClientTypeService` |
| Country Service | Loads country-level constraints and active status | `brosCountryService` |
| Payment Provider Service | Loads, filters, and ranks applicable payment providers | `brosPaymentProviderService` |
| Payment Type Service | Loads payment type definitions for the matched providers | `brosPaymentTypeService` |
| JDBI Data Accessor | Executes SQL queries across all configuration tables | `brosJdbiDataAccessor` |
| DaaS PostgreSQL | Stores all payment method configuration data | `daasPostgresPrimary` |
| RAAS Redis | Serves cached responses for previously seen query patterns | `raasRedis` |

## Steps

1. **Receive HTTP Request**: Checkout client sends `GET /paymentmethods/{countryCode}` with optional query parameters (`amount`, `userAgent`, `inventoryProductIds`, `inventoryServiceTypes`, `brand`, `exchange`, `primaryDealServiceIds`).
   - From: Checkout client
   - To: `brosPaymentMethodsResource`
   - Protocol: REST HTTP

2. **Check Cache**: Payment Methods Resource (or Service) checks RAAS Redis for a cached response matching the request parameters.
   - From: `brosPaymentMethodsService`
   - To: `raasRedis`
   - Protocol: Redis

3. **Resolve Client Type**: Payment Methods Service invokes Client Type Service to map the `userAgent` query parameter or `X-CLIENT-ROLES` header to a client type (e.g., `touch` for mobile, `desktop` for web).
   - From: `brosPaymentMethodsService`
   - To: `brosClientTypeService`
   - Protocol: Direct (in-process)

4. **Load Client Type Mappings from DB**: Client Type Service reads `client_types` table (and `applications_client_types`) from PostgreSQL via the JDBI Data Accessor.
   - From: `brosClientTypeService`
   - To: `brosJdbiDataAccessor` then `daasPostgresPrimary`
   - Protocol: JDBI / PostgreSQL

5. **Load Country Metadata**: Payment Methods Service invokes Country Service to load the country record for the requested `countryCode` from the `countries` table. Validates that the country is active.
   - From: `brosPaymentMethodsService`
   - To: `brosCountryService` then `brosJdbiDataAccessor` then `daasPostgresPrimary`
   - Protocol: Direct / JDBI / PostgreSQL

6. **Load and Filter Payment Providers**: Payment Methods Service invokes Payment Provider Service to query all `payment_providers` records for the country. Applies include/exclude filter logic using `inventoryProductIds`, `inventoryServiceTypes`, `brand`, `exchange`, and `primaryDealServiceIds` query parameters against each provider's `include_filters` and `exclude_filters` JSONB columns.
   - From: `brosPaymentMethodsService`
   - To: `brosPaymentProviderService` then `brosJdbiDataAccessor` then `daasPostgresPrimary`
   - Protocol: Direct / JDBI / PostgreSQL

7. **Load Provider Importance Rankings**: Payment Provider Service reads `payment_provider_importance` for the resolved client type and applies importance scores to rank the filtered providers.
   - From: `brosPaymentProviderService`
   - To: `brosJdbiDataAccessor` then `daasPostgresPrimary`
   - Protocol: JDBI / PostgreSQL

8. **Load Payment Type Definitions**: Payment Methods Service invokes Payment Type Service to load `payment_types` records matching the filtered providers, populating `billingRecordType`, `billingRecordVariant`, `flowType`, and related metadata.
   - From: `brosPaymentMethodsService`
   - To: `brosPaymentTypeService` then `brosJdbiDataAccessor` then `daasPostgresPrimary`
   - Protocol: Direct / JDBI / PostgreSQL

9. **Compose and Return Response**: Payment Methods Service assembles the `PaymentMethodsRepresentation` response, ordered by provider importance. Emits request counter metrics (country, client type, brand, exchange, inventory service types). Populates cache for subsequent identical requests.
   - From: `brosPaymentMethodsService`
   - To: `brosPaymentMethodsResource` then checkout client
   - Protocol: Direct / REST HTTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Country code not found / inactive | Country Service finds no active record | Returns `404 Not Found` |
| No providers match filters | Provider filter eliminates all providers | Returns `200` with empty `paymentMethods` array |
| Database unavailable | JDBI throws connection exception | Returns `500 Internal Server Error` |
| Invalid query parameters | Validation fails in resource layer | Returns `400 Bad Request` |
| Cache miss | Falls back to database read | Request served from PostgreSQL; cache populated |

## Sequence Diagram

```
Checkout Client -> brosPaymentMethodsResource: GET /paymentmethods/{countryCode}?userAgent=...&inventoryServiceTypes=...
brosPaymentMethodsResource -> brosPaymentMethodsService: resolve(countryCode, params)
brosPaymentMethodsService -> raasRedis: get(cacheKey)
raasRedis --> brosPaymentMethodsService: cache miss
brosPaymentMethodsService -> brosClientTypeService: resolveClientType(userAgent)
brosClientTypeService -> brosJdbiDataAccessor: findClientTypes()
brosJdbiDataAccessor -> daasPostgresPrimary: SELECT * FROM client_types
daasPostgresPrimary --> brosJdbiDataAccessor: client type rows
brosClientTypeService --> brosPaymentMethodsService: clientType = "touch"
brosPaymentMethodsService -> brosCountryService: getCountry(countryCode)
brosCountryService -> brosJdbiDataAccessor: findByCountryCode(countryCode)
brosJdbiDataAccessor -> daasPostgresPrimary: SELECT * FROM countries WHERE country_code = ?
daasPostgresPrimary --> brosJdbiDataAccessor: country row
brosCountryService --> brosPaymentMethodsService: countryMetadata
brosPaymentMethodsService -> brosPaymentProviderService: getProviders(countryCode, filters)
brosPaymentProviderService -> brosJdbiDataAccessor: findProviders(countryCode)
brosJdbiDataAccessor -> daasPostgresPrimary: SELECT * FROM payment_providers WHERE country_iso_code = ?
daasPostgresPrimary --> brosJdbiDataAccessor: provider rows
brosPaymentProviderService -> brosJdbiDataAccessor: findImportance(clientType)
brosJdbiDataAccessor -> daasPostgresPrimary: SELECT * FROM payment_provider_importance WHERE client_type = ?
daasPostgresPrimary --> brosJdbiDataAccessor: importance rows
brosPaymentProviderService --> brosPaymentMethodsService: rankedFilteredProviders
brosPaymentMethodsService -> brosPaymentTypeService: getPaymentTypes(providerPaymentTypes)
brosPaymentTypeService -> brosJdbiDataAccessor: findPaymentTypes()
brosJdbiDataAccessor -> daasPostgresPrimary: SELECT * FROM payment_types WHERE payment_type IN (...)
daasPostgresPrimary --> brosJdbiDataAccessor: payment type rows
brosPaymentTypeService --> brosPaymentMethodsService: paymentTypeDefinitions
brosPaymentMethodsService -> raasRedis: set(cacheKey, response)
brosPaymentMethodsService --> brosPaymentMethodsResource: PaymentMethodsRepresentation
brosPaymentMethodsResource --> Checkout Client: 200 OK {paymentMethods: [...]}
```

## Related

- Architecture dynamic view: `components-continuumBillingRecordOptionsService`
- Related flows: [Payment Methods by Provider Query](payment-methods-by-provider.md), [Client Type Resolution](client-type-resolution.md)
