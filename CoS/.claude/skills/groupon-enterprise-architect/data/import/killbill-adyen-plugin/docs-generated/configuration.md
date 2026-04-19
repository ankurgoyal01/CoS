---
service: "killbill-adyen-plugin"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [kill-bill-tenant-config, system-properties, osgi-config]
---

# Configuration

## Overview

The plugin is configured via Kill Bill's per-tenant configuration API (`POST /1.0/kb/tenants/uploadPluginConfig/killbill-adyen`) or system-wide via Java System Properties loaded at OSGi bundle startup. All properties use the prefix `org.killbill.billing.plugin.adyen.`. Per-region overrides are supported by prefixing the property key with the region code (e.g., `EMEA.org.killbill.billing.plugin.adyen.paymentUrl`). Configuration is loaded and parsed into `AdyenConfigProperties` at startup and on tenant-level reconfiguration events.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `IS_CLOUD` | Activates cloud-mode URL property keys (`cloud.paymentUrl`, `checkout.cloud.liveUrl.*`) | no | `false` | env |

## Plugin Configuration Properties

All properties use the prefix `org.killbill.billing.plugin.adyen.` unless otherwise noted.

| Property | Purpose | Required | Default |
|----------|---------|----------|---------|
| `org.killbill.billing.plugin.adyen.merchantAccount` | Merchant account(s) in `CC#MerchantAccount\|...` format; `FALLBACK#FallbackAccount` supported | yes | none |
| `org.killbill.billing.plugin.adyen.username` | SOAP API username(s) in `CC#username\|...` or `MerchantAccount#username\|...` format | yes | none |
| `org.killbill.billing.plugin.adyen.password` | SOAP API password(s) matching username format | yes | none |
| `org.killbill.billing.plugin.adyen.paymentUrl` | Adyen SOAP Payment Service URL | yes | none |
| `org.killbill.billing.plugin.adyen.recurringUrl` | Adyen SOAP Recurring Service URL | yes (for recurring) | none |
| `org.killbill.billing.plugin.adyen.directoryUrl` | Adyen HPP Directory lookup URL | no | none |
| `org.killbill.billing.plugin.adyen.hpp.target` | Adyen HPP redirect target URL | no | none |
| `org.killbill.billing.plugin.adyen.hmac.secret` | HPP HMAC secret(s) in skin-keyed format | no (required for HPP) | none |
| `org.killbill.billing.plugin.adyen.hmac.algorithm` | HMAC algorithm for HPP signature | no | `HmacSHA256` |
| `org.killbill.billing.plugin.adyen.skin` | HPP skin code(s) per merchant account | no | none |
| `org.killbill.billing.plugin.adyen.paymentConnectionTimeout` | Connection timeout (ms) for SOAP Payment Service calls | no | `30000` |
| `org.killbill.billing.plugin.adyen.paymentReadTimeout` | Read timeout (ms) for SOAP Payment Service calls | no | `60000` |
| `org.killbill.billing.plugin.adyen.recurringConnectionTimeout` | Connection timeout (ms) for SOAP Recurring Service calls | no | `30000` |
| `org.killbill.billing.plugin.adyen.recurringReadTimeout` | Read timeout (ms) for SOAP Recurring Service calls | no | `60000` |
| `org.killbill.billing.plugin.adyen.proxyServer` | Proxy server hostname | no | none |
| `org.killbill.billing.plugin.adyen.proxyPort` | Proxy server port | no | none |
| `org.killbill.billing.plugin.adyen.proxyType` | Proxy type (`HTTP` or `SOCKS`) | no | none |
| `org.killbill.billing.plugin.adyen.trustAllCertificates` | Disable SSL certificate validation | no | `false` |
| `org.killbill.billing.plugin.adyen.allowChunking` | Allow HTTP chunked transfer encoding | no | `false` |
| `org.killbill.billing.plugin.adyen.sensitiveProperties` | Pipe-delimited list of plugin property keys to exclude from HPP request persistence | no | none |
| `org.killbill.billing.plugin.adyen.persistablePluginProperties` | Pipe-delimited list of plugin property keys to include in response `additional_data` | no | none |
| `org.killbill.billing.plugin.adyen.paymentProcessorAccountIdToMerchantAccount` | Mappings from `paymentProcessorAccountId` to Adyen merchant accounts | no | none |
| `org.killbill.billing.plugin.adyen.invoicePaymentEnabled` | Enable invoice-triggered payment flows | no | `false` |
| `org.killbill.billing.plugin.adyen.chargebackAsFailurePaymentMethods` | Comma-delimited payment methods for which chargebacks are treated as failures | no | `""` |
| `org.killbill.billing.plugin.adyen.is5xxenabled` | Enable 5xx error experiment | no | `false` |
| `org.killbill.billing.plugin.adyen.countries.with5xx` | Pipe-delimited country codes participating in 5xx experiment | no | none |
| `org.killbill.billing.plugin.adyen.paypalShippingAddress.enabled` | Enable PayPal shipping address enrichment | no | `false` |
| `org.killbill.billing.plugin.adyen.paypalShippingAddress.merchantIds` | Pipe-delimited merchant IDs for PayPal shipping address | no | none |
| `org.killbill.billing.plugin.adyen.cloud.paymentUrl` | Cloud-mode SOAP Payment Service URL (used when `IS_CLOUD=true`) | no | none |

### Checkout API Properties

| Property | Purpose | Required | Default |
|----------|---------|----------|---------|
| `org.killbill.billing.plugin.adyen.checkout.environment` | Adyen Checkout environment (`TEST` or `LIVE`) | no | `TEST` |
| `org.killbill.billing.plugin.adyen.checkout.authEnabled` | Enable Checkout API for authorization flows | no | `false` |
| `org.killbill.billing.plugin.adyen.checkout.country` | Pipe-delimited country codes for Checkout API configuration | no | none |
| `org.killbill.billing.plugin.adyen.checkout.apiKey.<COUNTRY>` | Checkout API key per country code | yes (for Checkout API) | none |
| `org.killbill.billing.plugin.adyen.checkout.liveUrl.<COUNTRY>` | Checkout API live URL per country code | yes (for Checkout API live) | none |
| `org.killbill.billing.plugin.adyen.checkout.cloud.liveUrl.<COUNTRY>` | Cloud-mode Checkout API live URL per country code | no | none |
| `org.killbill.billing.plugin.adyen.checkout.test.users` | Pipe-delimited test user identifiers for Checkout API routing | no | none |

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| `org.killbill.billing.plugin.adyen.checkout.authEnabled` | Enables Checkout REST API for authorization instead of SOAP | `false` | per-tenant |
| `org.killbill.billing.plugin.adyen.invoicePaymentEnabled` | Enables invoice-triggered payment callbacks | `false` | per-tenant |
| `org.killbill.billing.plugin.adyen.is5xxenabled` | Experimental: treat Adyen 5xx as specific error classification | `false` | global |
| `org.killbill.billing.plugin.adyen.paypalShippingAddress.enabled` | Enrich PayPal payments with shipping address | `false` | global |

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `src/main/resources/cxf/Payment.wsdl` | WSDL | Adyen SOAP Payment service contract |
| `src/main/resources/cxf/Recurring.wsdl` | WSDL | Adyen SOAP Recurring service contract |
| `src/main/resources/cxf/Notification.wsdl` | WSDL | Adyen SOAP Notification service contract |
| `src/main/resources/cxf/OpenInvoiceDetail.wsdl` | WSDL | Adyen SOAP Open Invoice Detail contract |
| `src/main/resources/ddl.sql` | SQL | Plugin database schema (full create) |
| `src/main/resources/migration/` | SQL (Flyway) | Incremental schema migration scripts |
| `.ci/settings.xml` | XML | Maven settings for Groupon Nexus repositories |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `org.killbill.billing.plugin.adyen.password` | Adyen SOAP API password(s) | Kill Bill tenant config / System property |
| `org.killbill.billing.plugin.adyen.hmac.secret` | HPP HMAC signing secret(s) | Kill Bill tenant config / System property |
| `org.killbill.billing.plugin.adyen.checkout.apiKey.<COUNTRY>` | Adyen Checkout REST API key(s) | Kill Bill tenant config / System property |
| `org.killbill.billing.plugin.adyen.rbacPassword` | RBAC password (if applicable) | System property |

> Secret values are never documented. Only names and purposes are listed here.

## Per-Environment Overrides

- **Per-tenant**: Upload property strings via `POST /1.0/kb/tenants/uploadPluginConfig/killbill-adyen`. Configuration handlers (`AdyenConfigPropertiesConfigurationHandler`, `AdyenConfigurationHandler`, etc.) reload on tenant-level `TENANT_CONFIG_CHANGE` events.
- **Per-region**: Prefix any URL property with the region code (e.g., `EMEA.org.killbill.billing.plugin.adyen.paymentUrl=...`). The region is resolved from `org.killbill.server.region` system property.
- **Cloud vs. non-cloud**: When `IS_CLOUD=true`, URL properties switch from `paymentUrl` to `cloud.paymentUrl` and from `checkout.liveUrl.*` to `checkout.cloud.liveUrl.*`.
