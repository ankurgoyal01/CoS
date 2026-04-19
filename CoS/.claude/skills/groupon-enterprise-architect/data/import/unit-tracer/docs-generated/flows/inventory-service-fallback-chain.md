---
service: "unit-tracer"
title: "Inventory Service Fallback Chain"
generated: "2026-03-03"
type: flow
flow_name: "inventory-service-fallback-chain"
flow_type: synchronous
trigger: "Invoked by UnitReportBuilder during unit report generation"
participants:
  - "continuumUnitTracerService"
  - "continuumThirdPartyInventoryService"
  - "continuumVoucherInventoryService"
  - "grouponLiveInventoryService_9c0d"
architecture_ref: "dynamic-unit-tracer-report-flow"
---

# Inventory Service Fallback Chain

## Summary

Unit Tracer determines which inventory service holds a given unit by querying three inventory services in a fixed priority order: Third Party Inventory Service (TPIS) first, Voucher Inventory Service (VIS) second, and Groupon Live Inventory Service (GLIS) third. Each service is queried with the same endpoint (`GET /inventory/v1/units`) and parameters. If a service returns a non-empty unit list, the fallback chain halts and the first unit in the response is used. This design reflects that different unit types (third-party vouchers, standard vouchers, Groupon Live deals) are owned by different inventory backends.

## Trigger

- **Type**: direct (in-process)
- **Source**: `UnitReportBuilder` calls `InventoryServicesReportSectionBuilder.populateSection()` as part of report assembly
- **Frequency**: Once per unit ID per report request

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| InventoryServicesReportSectionBuilder | Orchestrates the fallback query chain; builds query map; populates `inventoryUnit` and `merchantId` on the report | `continuumUnitTracerService` |
| ThirdPartyInventoryServiceClient | Retrofit client; calls `GET /inventory/v1/units` on TPIS | `continuumUnitTracerService` |
| VoucherInventoryServiceClient | Retrofit client; calls `GET /inventory/v1/units` on VIS | `continuumUnitTracerService` |
| GrouponLiveInventoryServiceClient | Retrofit client; calls `GET /inventory/v1/units` on GLIS | `continuumUnitTracerService` |
| Third Party Inventory Service | Returns inventory unit data for third-party vouchers | `continuumThirdPartyInventoryService` |
| Voucher Inventory Service | Returns inventory unit data for standard vouchers | `continuumVoucherInventoryService` |
| Groupon Live Inventory Service | Returns inventory unit data for Groupon Live deals | stub `grouponLiveInventoryService_9c0d` |

## Steps

1. **Validate report has identifier**: Checks that the report has either a UUID or Groupon code. If neither is present, logs an error and returns early without querying any service.
   - From: InventoryServicesReportSectionBuilder
   - To: UnitReport
   - Protocol: direct (in-process)

2. **Build query parameters**: Constructs an `ImmutableMap` with `clientId=unit-tracer` and either `ids={uuid}` (if UUID) or `grouponCodes={code}` (if Groupon code).
   - From: InventoryServicesReportSectionBuilder
   - To: InventoryServicesReportSectionBuilder (internal)
   - Protocol: direct (in-process)

3. **Query Third Party Inventory Service (TPIS)**: Calls `GET /inventory/v1/units` with the query map. Logs a step entry with request URL and HTTP response code.
   - From: `continuumUnitTracerService` (ThirdPartyInventoryServiceClient)
   - To: `continuumThirdPartyInventoryService`
   - Protocol: REST/HTTP

4. **Evaluate TPIS response**: If the HTTP response is successful and the unit list is non-empty, sets `report.inventoryUnit`, `report.merchantId`, resolves UUID and Groupon code if not already set, and halts the fallback chain.
   - From: InventoryServicesReportSectionBuilder
   - To: UnitReport
   - Protocol: direct (in-process)

5. **Query Voucher Inventory Service (VIS)** — only if TPIS returned no unit: Calls `GET /inventory/v1/units` with the same query map. Logs a step entry.
   - From: `continuumUnitTracerService` (VoucherInventoryServiceClient)
   - To: `continuumVoucherInventoryService`
   - Protocol: REST/HTTP

6. **Evaluate VIS response**: If successful and non-empty, populates `inventoryUnit` and `merchantId` and halts the fallback chain.
   - From: InventoryServicesReportSectionBuilder
   - To: UnitReport
   - Protocol: direct (in-process)

7. **Query Groupon Live Inventory Service (GLIS)** — only if VIS also returned no unit: Calls `GET /inventory/v1/units` with the same query map. Logs a step entry.
   - From: `continuumUnitTracerService` (GrouponLiveInventoryServiceClient)
   - To: Groupon Live Inventory Service stub
   - Protocol: REST/HTTP

8. **Evaluate GLIS response**: If successful and non-empty, populates `inventoryUnit` and `merchantId`. If the response is empty, logs an error entry ("Search returned no results") for the GLIS step.
   - From: InventoryServicesReportSectionBuilder
   - To: UnitReport
   - Protocol: direct (in-process)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Report has no UUID and no Groupon code | Early return with error logged ("Unable to lookup Inventory Service - no UUID or Groupon Code") | No inventory services are queried |
| Any service returns empty unit list | Error logged for that step ("Search returned no results"); next service in chain is tried | Fallback continues |
| Any service throws IOException | IOException caught; error string added to report errors; fallback chain terminates (no more attempts) | `inventoryUnit` may remain null |
| All three services return no results | All three steps log errors | `inventoryUnit` is null; accounting and ledger sections will also fail (no UUID) |

## Sequence Diagram

```
InventoryServicesReportSectionBuilder -> InventoryServicesReportSectionBuilder: validate UUID or GrouponCode present
InventoryServicesReportSectionBuilder -> ThirdPartyInventoryServiceClient: getUnits(ids=<uuid>, clientId=unit-tracer)
ThirdPartyInventoryServiceClient -> ThirdPartyInventoryService: GET /inventory/v1/units?ids=<uuid>&clientId=unit-tracer
ThirdPartyInventoryService --> ThirdPartyInventoryServiceClient: InventoryServiceResponse
ThirdPartyInventoryServiceClient --> InventoryServicesReportSectionBuilder: Response<InventoryServiceResponse>
InventoryServicesReportSectionBuilder -> InventoryServicesReportSectionBuilder: units empty? -> continue to VIS
InventoryServicesReportSectionBuilder -> VoucherInventoryServiceClient: getUnits(ids=<uuid>, clientId=unit-tracer)
VoucherInventoryServiceClient -> VoucherInventoryService: GET /inventory/v1/units?ids=<uuid>&clientId=unit-tracer
VoucherInventoryService --> VoucherInventoryServiceClient: InventoryServiceResponse
VoucherInventoryServiceClient --> InventoryServicesReportSectionBuilder: Response<InventoryServiceResponse>
InventoryServicesReportSectionBuilder -> InventoryServicesReportSectionBuilder: units empty? -> continue to GLIS
InventoryServicesReportSectionBuilder -> GrouponLiveInventoryServiceClient: getUnits(ids=<uuid>, clientId=unit-tracer)
GrouponLiveInventoryServiceClient -> GrouponLiveInventoryService: GET /inventory/v1/units?ids=<uuid>&clientId=unit-tracer
GrouponLiveInventoryService --> GrouponLiveInventoryServiceClient: InventoryServiceResponse
GrouponLiveInventoryServiceClient --> InventoryServicesReportSectionBuilder: Response<InventoryServiceResponse>
InventoryServicesReportSectionBuilder -> UnitReport: setInventoryUnit() + setMerchantId()
```

## Related

- Architecture dynamic view: `dynamic-unit-tracer-report-flow`
- Related flows: [Unit Report Generation](unit-report-generation.md), [Accounting Data Retrieval](accounting-data-retrieval.md)
