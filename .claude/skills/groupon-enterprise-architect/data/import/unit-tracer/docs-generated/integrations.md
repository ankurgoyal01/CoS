---
service: "unit-tracer"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 0
internal_count: 5
---

# Integrations

## Overview

Unit Tracer has five downstream internal service dependencies, all called synchronously via Retrofit HTTP clients at report-generation time. There are no external (third-party) dependencies. Three of the five dependencies are inventory services queried in a sequential fallback order; the remaining two provide financial and ledger data respectively. All client connections are configured via `RetrofitConfiguration` entries in the JTier YAML config file.

## External Dependencies

> No evidence found in codebase. Unit Tracer has no external (third-party) dependencies.

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Third Party Inventory Service | REST/HTTP | Primary inventory lookup — queries `GET /inventory/v1/units` by UUID or Groupon code | `continuumThirdPartyInventoryService` |
| Voucher Inventory Service | REST/HTTP | Fallback inventory lookup — queries `GET /inventory/v1/units` if TPIS returns no results | `continuumVoucherInventoryService` |
| Groupon Live Inventory Service | REST/HTTP | Second-fallback inventory lookup — queries `GET /inventory/v1/units` if VIS also returns no results | stub (`grouponLiveInventoryService_9c0d`) |
| Accounting Service | REST/HTTP | Fetches unit financial details (`GET /api/v3/units/{id}`) and vendor payment schedules (`GET api/v3/vendors/{vendorId}/schedules`) | `continuumAccountingService` |
| Message to Ledger | REST/HTTP | Fetches unit lifecycle message history (`GET /admin/units/{unitId}/lifecycle`) | stub (`messageToLedgerService_3f4e`) |

### Third Party Inventory Service Detail

- **Protocol**: REST/HTTP via Retrofit
- **Base URL / SDK**: Configured via `thirdPartyInventoryServiceClient` in JTier YAML (`RetrofitConfiguration`)
- **Auth**: Managed by JTier Retrofit bundle (platform-level)
- **Purpose**: Primary source of inventory unit data; queried first in the fallback chain using `clientId=unit-tracer` and either `ids={uuid}` or `grouponCodes={code}` query parameters
- **Failure mode**: If the HTTP call throws `IOException`, the error is logged in the report's `errors` array; report assembly continues with remaining sections
- **Circuit breaker**: No evidence found in codebase

### Voucher Inventory Service Detail

- **Protocol**: REST/HTTP via Retrofit
- **Base URL / SDK**: Configured via `voucherInventoryServiceClient` in JTier YAML (`RetrofitConfiguration`)
- **Auth**: Managed by JTier Retrofit bundle (platform-level)
- **Purpose**: Fallback inventory source queried only when TPIS returns an empty unit list; uses the same `/inventory/v1/units` endpoint with the same query parameters
- **Failure mode**: `IOException` captured in report errors; assembly continues
- **Circuit breaker**: No evidence found in codebase

### Groupon Live Inventory Service Detail

- **Protocol**: REST/HTTP via Retrofit
- **Base URL / SDK**: Configured via `grouponLiveInventoryServiceClient` in JTier YAML (`RetrofitConfiguration`)
- **Auth**: Managed by JTier Retrofit bundle (platform-level)
- **Purpose**: Second-level fallback inventory source; queried only when both TPIS and VIS return no units
- **Failure mode**: `IOException` captured in report errors; assembly continues
- **Circuit breaker**: No evidence found in codebase

### Accounting Service Detail

- **Protocol**: REST/HTTP via Retrofit
- **Base URL / SDK**: Configured via `accountingServiceClient` in JTier YAML (`RetrofitConfiguration`)
- **Auth**: Managed by JTier Retrofit bundle (platform-level)
- **Purpose**: Provides unit-level financial data (amounts, check numbers, inventory unit events, payable events, Salesforce payment term) and merchant vendor payment schedules; requires unit UUID resolved from inventory section
- **Failure mode**: `IOException` captured in report errors for both unit and schedule calls independently; assembly continues
- **Circuit breaker**: No evidence found in codebase

### Message to Ledger Detail

- **Protocol**: REST/HTTP via Retrofit
- **Base URL / SDK**: Configured via `messageToLedgerClient` in JTier YAML (`RetrofitConfiguration`)
- **Auth**: Managed by JTier Retrofit bundle (platform-level)
- **Purpose**: Provides the lifecycle message history for a unit — all messages sent to the ledger, their statuses, attempt counts, error codes, and processing timestamps
- **Failure mode**: `IOException` captured in report errors; assembly continues
- **Circuit breaker**: No evidence found in codebase

## Consumed By

> Upstream consumers are tracked in the central architecture model.

Unit Tracer is an internal diagnostic tool. It is consumed by finance engineers and customer support tooling. No upstream service-to-service callers are registered in the federated model.

## Dependency Health

All five downstream clients are called synchronously during report building. Each section builder (`InventoryServicesReportSectionBuilder`, `AccountingServiceSectionBuilder`, `MessageToLedgerReportSectionBuilder`) independently catches `IOException` and records the error in the report's `errors` array without failing the overall request. Per-step HTTP response codes and URLs are logged in the report's `steps` array (`UnitReportStepLogEntry`), enabling diagnosis of which upstream calls succeeded or failed.

No retry logic, circuit breakers, or timeouts beyond JTier Retrofit defaults are configured in the application code.
