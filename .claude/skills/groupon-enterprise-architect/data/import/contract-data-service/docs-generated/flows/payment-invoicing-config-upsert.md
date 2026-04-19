---
service: "contract-data-service"
title: "Payment Invoicing Configuration Upsert"
generated: "2026-03-03"
type: flow
flow_name: "payment-invoicing-config-upsert"
flow_type: synchronous
trigger: "API call to PUT /v1/paymentInvoicingConfiguration"
participants:
  - "cds_paymentInvoicingConfigResource"
  - "cds_paymentInvoicingConfigReadOnlyDao"
  - "cds_paymentInvoicingConfigDao"
  - "continuumContractDataServicePostgresRo"
  - "continuumContractDataServicePostgresRw"
architecture_ref: "components-continuum-contract-data-service-components"
---

# Payment Invoicing Configuration Upsert

## Summary

A caller submits a payment invoicing configuration via `PUT /v1/paymentInvoicingConfiguration`. The service checks whether a configuration with the given `externalKey.id` already exists. If none exists, a new record is created. If one exists, the new values are merged with the old (partial update semantics: only specified fields are updated; unspecified fields retain their existing values). This allows incremental updates to invoicing configuration without requiring callers to send the full object each time.

## Trigger

- **Type**: api-call
- **Source**: Any authorized service sending `PUT /v1/paymentInvoicingConfiguration` with a `PaymentConfigurationParam` JSON body
- **Frequency**: On demand (per invoicing configuration change)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Payment Invoicing Configuration Resource | Receives request, coordinates lookup and write | `cds_paymentInvoicingConfigResource` |
| Payment Invoicing Config Read-Only DAO | Checks whether configuration already exists by external reference ID | `cds_paymentInvoicingConfigReadOnlyDao` |
| Payment Invoicing Config DAO | Inserts new or updates existing invoicing configuration record | `cds_paymentInvoicingConfigDao` |
| Contract Data Service DB (RO) | Read-only Postgres replica | `continuumContractDataServicePostgresRo` |
| Contract Data Service DB (RW) | Primary Postgres for writes | `continuumContractDataServicePostgresRw` |

## Steps

1. **Receive request**: Client sends `PUT /v1/paymentInvoicingConfiguration` with a `PaymentConfigurationParam` body containing `externalKey` (required), and optional `initialPayment` and `installments[]`.
   - From: caller
   - To: `cds_paymentInvoicingConfigResource`
   - Protocol: REST/HTTP

2. **Validate CLIENT-ID header**: `cds_clientIdRequestFilter` validates the `CLIENT-ID` header.
   - From: `cds_clientIdRequestFilter`
   - To: `cds_clientIdReadOnlyDao` → `continuumContractDataServicePostgresRo`
   - Protocol: JDBI

3. **Build new configuration object**: Converts `PaymentConfigurationParam` to a `PaymentInvoicingConfiguration` domain object.
   - From: `cds_paymentInvoicingConfigResource`
   - To: in-process
   - Protocol: direct

4. **Look up existing configuration**: Queries the read-only replica for a configuration with `externalKey.id` as the `externalReferenceId`.
   - From: `cds_paymentInvoicingConfigResource`
   - To: `cds_paymentInvoicingConfigReadOnlyDao` → `continuumContractDataServicePostgresRo`
   - Protocol: JDBI

5a. **Not found — insert**: If no existing record, inserts the full configuration transactionally.
   - From: `cds_paymentInvoicingConfigResource`
   - To: `cds_paymentInvoicingConfigDao` (`insertInTransaction`) → `continuumContractDataServicePostgresRw`
   - Protocol: JDBI

5b. **Found — partial update**: If record exists, merges new values over the old configuration (fields not specified in the request retain their existing values). Then updates the record transactionally.
   - From: `cds_paymentInvoicingConfigResource`
   - To: `paymentConfigurationParam.get(paymentInvoicingConfigurationOld)` (merge), then `cds_paymentInvoicingConfigDao` (`updateInTransaction`) → `continuumContractDataServicePostgresRw`
   - Protocol: JDBI

6. **Return response**: Returns `PaymentConfigurationResponse` with HTTP 200.
   - From: `cds_paymentInvoicingConfigResource`
   - To: caller
   - Protocol: REST/HTTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Invalid request body | Bean validation (`@Valid`, `@NotNull`) | HTTP 400 via `IllegalArgumentExceptionMapper` |
| `externalKey` missing | Bean validation (`@NotNull` on `externalKey`) | HTTP 400 |
| Database write failure | Exception propagates | HTTP 500 via `CodsExceptionMapper` |

## Sequence Diagram

```
Caller -> PaymentInvoicingConfigResource: PUT /v1/paymentInvoicingConfiguration {paymentConfigurationParam}
PaymentInvoicingConfigResource -> PaymentInvoicingConfigReadOnlyDao: findInTransaction(externalKey.id)
PaymentInvoicingConfigReadOnlyDao -> PostgresRO: SELECT by externalReferenceId
alt not found
  PaymentInvoicingConfigResource -> PaymentInvoicingConfigDao: insertInTransaction(newConfig)
  PaymentInvoicingConfigDao -> PostgresRW: INSERT payment_invoicing_configuration
else found
  PaymentInvoicingConfigResource -> PaymentInvoicingConfigResource: merge(old, new)
  PaymentInvoicingConfigResource -> PaymentInvoicingConfigDao: updateInTransaction(old, merged)
  PaymentInvoicingConfigDao -> PostgresRW: UPDATE payment_invoicing_configuration
end
PaymentInvoicingConfigResource --> Caller: 200 PaymentConfigurationResponse
```

## Related

- Related flows: [Contract Term Upsert](contract-term-upsert.md) (PIC must exist before contract terms can reference it)
- API reference: [API Surface](../api-surface.md)
