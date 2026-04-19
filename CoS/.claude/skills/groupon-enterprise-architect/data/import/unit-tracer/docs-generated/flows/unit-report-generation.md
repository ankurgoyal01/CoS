---
service: "unit-tracer"
title: "Unit Report Generation"
generated: "2026-03-03"
type: flow
flow_name: "unit-report-generation"
flow_type: synchronous
trigger: "HTTP GET request to /unit or /api/unit with unitIds query parameter"
participants:
  - "continuumUnitTracerService"
  - "continuumThirdPartyInventoryService"
  - "continuumVoucherInventoryService"
  - "grouponLiveInventoryService_9c0d"
  - "continuumAccountingService"
  - "messageToLedgerService_3f4e"
architecture_ref: "dynamic-unit-tracer-report-flow"
---

# Unit Report Generation

## Summary

This is the primary flow for Unit Tracer. It is triggered by an HTTP request supplying one or more unit identifiers (UUIDs or Groupon codes). For each unit ID, the service validates and normalizes the identifier, then delegates to three section builders in sequence — inventory, accounting, and ledger — each of which makes synchronous HTTP calls to upstream services. All results are assembled into a `UnitReport` and returned to the caller as either an HTML view or JSON.

## Trigger

- **Type**: api-call
- **Source**: Internal user or tooling calling `GET /unit?unitIds=<ids>` (HTML) or `GET /api/unit?unitIds=<ids>` (JSON)
- **Frequency**: On-demand

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| UnitTracerResource / ApiResource | Receives HTTP request, splits comma-separated IDs, delegates to UnitReportBuilder, returns response | `continuumUnitTracerService` |
| UnitReportBuilder | Validates and normalizes each unit ID; orchestrates three section builders per unit | `continuumUnitTracerService` |
| InventoryServicesReportSectionBuilder | Queries inventory services in fallback order; populates `inventoryUnit` and `merchantId` fields | `continuumUnitTracerService` |
| AccountingServiceSectionBuilder | Queries Accounting Service for unit financial data and vendor schedules | `continuumUnitTracerService` |
| MessageToLedgerReportSectionBuilder | Queries Message to Ledger for lifecycle events | `continuumUnitTracerService` |
| Third Party Inventory Service | Returns inventory unit data for the requested ID | `continuumThirdPartyInventoryService` |
| Voucher Inventory Service | Returns inventory unit data (fallback) | `continuumVoucherInventoryService` |
| Groupon Live Inventory Service | Returns inventory unit data (second fallback) | stub `grouponLiveInventoryService_9c0d` |
| Accounting Service | Returns unit financial data and vendor payment schedules | `continuumAccountingService` |
| Message to Ledger | Returns lifecycle message history | stub `messageToLedgerService_3f4e` |

## Steps

1. **Receive HTTP request**: User or tooling calls `GET /unit?unitIds=<ids>` or `GET /api/unit?unitIds=<ids>`.
   - From: Caller
   - To: `continuumUnitTracerService` (UnitTracerResource or ApiResource)
   - Protocol: REST

2. **Parse and split unit IDs**: The resource strips whitespace and splits the `unitIds` parameter on commas. Each ID is passed to `UnitReportBuilder.createReports()`.
   - From: UnitTracerResource / ApiResource
   - To: UnitReportBuilder
   - Protocol: direct (in-process)

3. **Validate and normalize each unit ID**: `UnitReportBuilder.createReport()` checks if the ID matches UUID format. If not, checks for valid Groupon code prefixes (`LG`, `TP`, `VS`, `GL`). Invalid IDs receive an error entry and processing continues.
   - From: UnitReportBuilder
   - To: UnitReportBuilder (internal)
   - Protocol: direct (in-process)

4. **Populate inventory section**: Delegates to `InventoryServicesReportSectionBuilder.populateSection()`. See [Inventory Service Fallback Chain](inventory-service-fallback-chain.md) for detail.
   - From: UnitReportBuilder
   - To: InventoryServicesReportSectionBuilder
   - Protocol: direct (in-process)

5. **Populate accounting section**: Delegates to `AccountingServiceSectionBuilder.populateSection()`. See [Accounting Data Retrieval](accounting-data-retrieval.md) for detail.
   - From: UnitReportBuilder
   - To: AccountingServiceSectionBuilder
   - Protocol: direct (in-process)

6. **Populate ledger section**: Delegates to `MessageToLedgerReportSectionBuilder.populateSection()`. See [Ledger Lifecycle Retrieval](ledger-lifecycle-retrieval.md) for detail.
   - From: UnitReportBuilder
   - To: MessageToLedgerReportSectionBuilder
   - Protocol: direct (in-process)

7. **Assemble and return report**: The assembled `UnitReport` (containing `inventoryUnit`, `accountingServiceUnitResponse`, `accountingServiceVendorSchedulesResponse`, `messageToLedgerLifeCycleResponse`, `steps`, and `errors`) is returned. For `GET /unit`, it is rendered as HTML via Mustache. For `GET /api/unit`, it is serialized as JSON.
   - From: `continuumUnitTracerService`
   - To: Caller
   - Protocol: REST

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Invalid unit ID format (not UUID, not valid Groupon code) | `ErrorLog` added to report; processing continues for remaining sections | Report returned with error entry; inventory/accounting/ledger sections empty |
| Inventory service HTTP error / IOException | `ErrorLog` added to report; next fallback inventory service is tried | If all three inventory services fail, `inventoryUnit` is null |
| Accounting Service HTTP error / IOException | `ErrorLog` added to report; assembly continues | `accountingServiceUnitResponse` is null in report |
| Message to Ledger HTTP error / IOException | `ErrorLog` added to report; assembly continues | `messageToLedgerLifeCycleResponse` is null in report |
| Jackson serialization error (JSON endpoint only) | Exception message returned as plain text with HTTP 200 | Caller receives error string instead of JSON |
| Missing `unitIds` parameter (HTML endpoint) | Dropwizard `@NotEmpty` constraint violation | HTTP 400 / 422 returned |

## Sequence Diagram

```
Caller -> UnitTracerResource: GET /unit?unitIds=<ids>
UnitTracerResource -> UnitReportBuilder: createReports(unitIds[])
UnitReportBuilder -> UnitReportBuilder: validate & normalize each ID
UnitReportBuilder -> InventoryServicesReportSectionBuilder: populateSection(report)
InventoryServicesReportSectionBuilder -> ThirdPartyInventoryService: GET /inventory/v1/units?ids=<uuid>&clientId=unit-tracer
ThirdPartyInventoryService --> InventoryServicesReportSectionBuilder: InventoryServiceResponse (or empty)
InventoryServicesReportSectionBuilder -> VoucherInventoryService: GET /inventory/v1/units (fallback if no units)
VoucherInventoryService --> InventoryServicesReportSectionBuilder: InventoryServiceResponse (or empty)
InventoryServicesReportSectionBuilder -> GrouponLiveInventoryService: GET /inventory/v1/units (fallback if still no units)
GrouponLiveInventoryService --> InventoryServicesReportSectionBuilder: InventoryServiceResponse
InventoryServicesReportSectionBuilder --> UnitReportBuilder: report populated with inventoryUnit + merchantId
UnitReportBuilder -> AccountingServiceSectionBuilder: populateSection(report)
AccountingServiceSectionBuilder -> AccountingService: GET /api/v3/units/{uuid}
AccountingService --> AccountingServiceSectionBuilder: AccountingServiceUnitResponse
AccountingServiceSectionBuilder -> AccountingService: GET api/v3/vendors/{merchantId}/schedules
AccountingService --> AccountingServiceSectionBuilder: AccountingServiceVendorSchedulesResponse
AccountingServiceSectionBuilder --> UnitReportBuilder: report populated with accounting data
UnitReportBuilder -> MessageToLedgerReportSectionBuilder: populateSection(report)
MessageToLedgerReportSectionBuilder -> MessageToLedger: GET /admin/units/{uuid}/lifecycle
MessageToLedger --> MessageToLedgerReportSectionBuilder: MessageToLedgerLifeCycleResponse
MessageToLedgerReportSectionBuilder --> UnitReportBuilder: report populated with ledger lifecycle
UnitReportBuilder --> UnitTracerResource: UnitReports
UnitTracerResource --> Caller: ReportsView (HTML) or JSON
```

## Related

- Architecture dynamic view: `dynamic-unit-tracer-report-flow`
- Related flows: [Inventory Service Fallback Chain](inventory-service-fallback-chain.md), [Accounting Data Retrieval](accounting-data-retrieval.md), [Ledger Lifecycle Retrieval](ledger-lifecycle-retrieval.md)
