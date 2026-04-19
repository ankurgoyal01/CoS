---
service: "killbill-adyen-plugin"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumKillbillAdyenPluginDb"
    type: "mysql"
    purpose: "Plugin persistence for payment methods, Adyen responses, HPP requests, and notifications"
---

# Data Stores

## Overview

The plugin owns a single relational database (`continuumKillbillAdyenPluginDb`) with four domain tables. All tables are accessed via JDBI with jOOQ-generated type-safe accessors in `AdyenDao`. Schema is managed using Flyway migrations. The database serves as the authoritative record of all payment interactions between Kill Bill and Adyen.

## Stores

### Kill Bill Adyen Plugin DB (`continuumKillbillAdyenPluginDb`)

| Property | Value |
|----------|-------|
| Type | MySQL (also supports PostgreSQL) |
| Architecture ref | `continuumKillbillAdyenPluginDb` |
| Purpose | Stores plugin payment methods, Adyen API responses, HPP requests, and inbound Adyen notifications |
| Ownership | owned |
| Migrations path | `src/main/resources/migration/` |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `adyen_payment_methods` | Stores tokenised payment method details per Kill Bill account | `kb_account_id`, `kb_payment_method_id`, `token`, `cc_first_name`, `cc_last_name`, `cc_type`, `cc_exp_month`, `cc_exp_year`, `cc_last_4`, `is_default`, `is_deleted`, `additional_data`, `kb_tenant_id` |
| `adyen_responses` | Records Adyen API response for every payment transaction (authorize, capture, refund, void) | `kb_account_id`, `kb_payment_id`, `kb_payment_transaction_id`, `transaction_type`, `amount`, `currency`, `psp_result`, `psp_reference`, `auth_code`, `result_code`, `refusal_reason`, `reference`, `md`, `pa_request`, `additional_data`, `kb_tenant_id` |
| `adyen_hpp_requests` | Tracks HPP redirect requests before payment completion | `kb_account_id`, `kb_payment_id`, `kb_payment_transaction_id`, `transaction_external_key`, `additional_data`, `kb_tenant_id` |
| `adyen_notifications` | Persists inbound SOAP notifications from Adyen | `kb_account_id`, `kb_payment_id`, `kb_payment_transaction_id`, `transaction_type`, `amount`, `currency`, `event_code`, `event_date`, `merchant_account_code`, `merchant_reference`, `operations`, `original_reference`, `payment_method`, `psp_reference`, `reason`, `success`, `additional_data`, `kb_tenant_id` |

#### Access Patterns

- **Read**: `adyen_responses` is queried by `kb_payment_id`, `kb_payment_transaction_id`, and `psp_reference` to look up existing transaction records during notification reconciliation and payment method refresh. `adyen_payment_methods` is queried by `kb_payment_method_id` and `kb_account_id` for payment method lookups.
- **Write**: All tables receive inserts on each respective operation: payment method addition, Adyen API call completion, HPP form generation, and notification receipt. `adyen_payment_methods` also receives updates on soft-delete (`is_deleted`) and default flag changes.
- **Indexes**:
  - `adyen_responses`: on `kb_payment_id`, `kb_payment_transaction_id`, `psp_reference`
  - `adyen_hpp_requests`: on `kb_account_id`, `transaction_external_key`, `kb_payment_transaction_id`
  - `adyen_notifications`: on `psp_reference`, `kb_payment_id`, `kb_payment_transaction_id` (not unique — allows retry re-delivery)
  - `adyen_payment_methods`: unique on `kb_payment_method_id`

## Caches

> No evidence found of any external cache (Redis, Memcached). Configuration is loaded per-tenant on each request via Kill Bill's `ConfigurationHandler` pattern and held in memory within the OSGi bundle.

## Data Flows

- On each payment operation, `PaymentApiAdapter` calls `AdyenGatewayClient` and immediately persists the Adyen response into `adyen_responses` via `PersistenceAdapter`.
- On HPP form generation, the HPP request parameters are persisted in `adyen_hpp_requests` before the redirect URL is returned.
- On notification receipt, `NotificationProcessor` reads the matching `adyen_responses` or `adyen_hpp_requests` record by `psp_reference` / `merchant_reference`, persists the notification into `adyen_notifications`, then calls Kill Bill's payment API to reconcile the transaction state.
- Flyway migrations in `src/main/resources/migration/` apply additive schema changes (ALTER TABLE, new indexes) without destructive operations.
