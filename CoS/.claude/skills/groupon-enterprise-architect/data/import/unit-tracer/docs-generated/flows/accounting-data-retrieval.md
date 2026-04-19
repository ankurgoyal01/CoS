---
service: "unit-tracer"
title: "Accounting Data Retrieval"
generated: "2026-03-03"
type: flow
flow_name: "accounting-data-retrieval"
flow_type: synchronous
trigger: "Invoked by UnitReportBuilder during unit report generation, after inventory section is populated"
participants:
  - "continuumUnitTracerService"
  - "continuumAccountingService"
architecture_ref: "dynamic-unit-tracer-report-flow"
---

# Accounting Data Retrieval

## Summary

After the inventory section has been populated and a unit UUID has been resolved, Unit Tracer queries the Accounting Service for two types of financial data: unit-level accounting details and the associated merchant vendor payment schedule. Both calls are made synchronously to `continuumAccountingService`. The results are stored on the `UnitReport` as `accountingServiceUnitResponse` and `accountingServiceVendorSchedulesResponse`. This data supports finance engineers in understanding the payment state and schedule for a given voucher unit.

## Trigger

- **Type**: direct (in-process)
- **Source**: `UnitReportBuilder` calls `AccountingServiceSectionBuilder.populateSection()` after inventory section completes
- **Frequency**: Once per unit ID per report request

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| AccountingServiceSectionBuilder | Orchestrates both Accounting Service calls; requires unit UUID and merchant ID from prior inventory step | `continuumUnitTracerService` |
| AccountingServiceClient | Retrofit HTTP client; calls Accounting Service endpoints | `continuumUnitTracerService` |
| Accounting Service | Provides unit financial data (`amounts`, `checkNumbers`, `inventoryUnitEvents`, `payableEvents`, `salesforcePaymentTerm`) and vendor payment schedules | `continuumAccountingService` |

## Steps

1. **Validate unit UUID is present**: Checks `report.getUuid()`. If null (inventory lookup failed), logs an error ("Unable to lookup Unit - no UUID") and skips the unit data call. Proceeds to attempt the vendor schedule lookup.
   - From: AccountingServiceSectionBuilder
   - To: UnitReport
   - Protocol: direct (in-process)

2. **Fetch unit financial data**: Calls `GET /api/v3/units/{uuid}` on Accounting Service. On success, sets `report.accountingServiceUnitResponse` with amounts, check numbers, inventory unit events, payable events, and Salesforce payment term. Logs a step entry with request URL and HTTP response code.
   - From: `continuumUnitTracerService` (AccountingServiceClient)
   - To: `continuumAccountingService`
   - Protocol: REST/HTTP

3. **Validate merchant ID is present**: Checks `report.getMerchantId()`. If null (no merchant ID was resolved from inventory), logs an error ("Unable to lookup Merchant Schedule - no Merchant ID") and skips the schedule call.
   - From: AccountingServiceSectionBuilder
   - To: UnitReport
   - Protocol: direct (in-process)

4. **Fetch vendor payment schedule**: Calls `GET api/v3/vendors/{merchantId}/schedules?findByVendorId=legal_entity_id` on Accounting Service. On success, sets `report.accountingServiceVendorSchedulesResponse` with the list of `VendorSchedule` objects (start/end times, iCal string, next/prev run timestamps). Logs a step entry.
   - From: `continuumUnitTracerService` (AccountingServiceClient)
   - To: `continuumAccountingService`
   - Protocol: REST/HTTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| No UUID on report (inventory failed) | Error logged; unit data call skipped | `accountingServiceUnitResponse` is null |
| No merchant ID on report (inventory returned no merchant) | Error logged; schedule call skipped | `accountingServiceVendorSchedulesResponse` is null |
| Accounting Service returns non-2xx for unit data | Response not applied to report; step logged with HTTP code | `accountingServiceUnitResponse` is null |
| Accounting Service returns non-2xx for schedule | Response not applied to report; step logged with HTTP code | `accountingServiceVendorSchedulesResponse` is null |
| IOException on either call | Exception caught; error string added to report errors | Affected response is null; other call may still succeed |

## Sequence Diagram

```
AccountingServiceSectionBuilder -> AccountingServiceSectionBuilder: check report.getUuid() != null
AccountingServiceSectionBuilder -> AccountingServiceClient: getUnit(uuid)
AccountingServiceClient -> AccountingService: GET /api/v3/units/{uuid}
AccountingService --> AccountingServiceClient: AccountingServiceUnitResponse
AccountingServiceClient --> AccountingServiceSectionBuilder: Response<AccountingServiceUnitResponse>
AccountingServiceSectionBuilder -> UnitReport: setAccountingServiceUnitResponse()
AccountingServiceSectionBuilder -> UnitReport: logStep(ACCOUNTING_SERVICE, response)
AccountingServiceSectionBuilder -> AccountingServiceSectionBuilder: check report.getMerchantId() != null
AccountingServiceSectionBuilder -> AccountingServiceClient: getSchedules(merchantId)
AccountingServiceClient -> AccountingService: GET api/v3/vendors/{merchantId}/schedules?findByVendorId=legal_entity_id
AccountingService --> AccountingServiceClient: AccountingServiceVendorSchedulesResponse
AccountingServiceClient --> AccountingServiceSectionBuilder: Response<AccountingServiceVendorSchedulesResponse>
AccountingServiceSectionBuilder -> UnitReport: setAccountingServiceVendorSchedulesResponse()
AccountingServiceSectionBuilder -> UnitReport: logStep(ACCOUNTING_SERVICE, response)
```

## Related

- Architecture dynamic view: `dynamic-unit-tracer-report-flow`
- Related flows: [Unit Report Generation](unit-report-generation.md), [Inventory Service Fallback Chain](inventory-service-fallback-chain.md), [Ledger Lifecycle Retrieval](ledger-lifecycle-retrieval.md)
