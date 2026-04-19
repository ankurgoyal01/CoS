---
service: "unit-tracer"
title: "Ledger Lifecycle Retrieval"
generated: "2026-03-03"
type: flow
flow_name: "ledger-lifecycle-retrieval"
flow_type: synchronous
trigger: "Invoked by UnitReportBuilder during unit report generation, after inventory section is populated"
participants:
  - "continuumUnitTracerService"
  - "messageToLedgerService_3f4e"
architecture_ref: "dynamic-unit-tracer-report-flow"
---

# Ledger Lifecycle Retrieval

## Summary

After the inventory section has been populated and a unit UUID has been resolved, Unit Tracer queries the Message to Ledger service to retrieve the complete lifecycle event history for the unit. This history records every message that was submitted to the accounting ledger for the unit — including its type, status, processing timestamps, attempt count, and any error codes. This data enables finance engineers to trace whether a unit's financial events (such as a capture or refund) were successfully communicated to the ledger system.

## Trigger

- **Type**: direct (in-process)
- **Source**: `UnitReportBuilder` calls `MessageToLedgerReportSectionBuilder.populateSection()` as the third and final section-building step
- **Frequency**: Once per unit ID per report request

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| MessageToLedgerReportSectionBuilder | Guards on UUID presence; invokes lifecycle call; populates report | `continuumUnitTracerService` |
| MessageToLedgerClient | Retrofit HTTP client targeting `GET /admin/units/{unitId}/lifecycle` | `continuumUnitTracerService` |
| Message to Ledger | Returns lifecycle message list and unit metadata for the given UUID | stub `messageToLedgerService_3f4e` |

## Steps

1. **Validate unit UUID is present**: Checks `report.getUuid()`. If null (inventory lookup failed and no UUID was resolved), logs an error ("Unable to lookup message2ledger - no UUID") and returns immediately without making any HTTP call.
   - From: MessageToLedgerReportSectionBuilder
   - To: UnitReport
   - Protocol: direct (in-process)

2. **Fetch lifecycle message history**: Calls `GET /admin/units/{unitId}/lifecycle` on Message to Ledger. Logs a step entry with request URL and HTTP response code.
   - From: `continuumUnitTracerService` (MessageToLedgerClient)
   - To: Message to Ledger (stub `messageToLedgerService_3f4e`)
   - Protocol: REST/HTTP

3. **Apply response to report**: If the HTTP response is successful, sets `report.messageToLedgerLifeCycleResponse`. The response contains:
   - `unit` — the `MessageToLedgerUnit` object with `id`, `inventoryProductId`, `inventoryServiceId`
   - `msgs` — list of `Message` objects, each with `msgID`, `type`, `status`, `attempt`, `messageAt`, `processedAt`, `errorCode`, `errorMessage`
   - From: MessageToLedgerReportSectionBuilder
   - To: UnitReport
   - Protocol: direct (in-process)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| No UUID on report | Error logged ("Unable to lookup message2ledger - no UUID"); no HTTP call made | `messageToLedgerLifeCycleResponse` is null |
| Message to Ledger returns non-2xx | Response not applied; step logged with HTTP code | `messageToLedgerLifeCycleResponse` is null |
| IOException on lifecycle call | Exception caught; error string added to report errors | `messageToLedgerLifeCycleResponse` is null |

## Sequence Diagram

```
MessageToLedgerReportSectionBuilder -> MessageToLedgerReportSectionBuilder: check report.getUuid() != null
MessageToLedgerReportSectionBuilder -> MessageToLedgerClient: getLifeCycle(uuid)
MessageToLedgerClient -> MessageToLedger: GET /admin/units/{uuid}/lifecycle
MessageToLedger --> MessageToLedgerClient: MessageToLedgerLifeCycleResponse
MessageToLedgerClient --> MessageToLedgerReportSectionBuilder: Response<MessageToLedgerLifeCycleResponse>
MessageToLedgerReportSectionBuilder -> UnitReport: setMessageToLedgerLifeCycleResponse()
MessageToLedgerReportSectionBuilder -> UnitReport: logStep(Message2Ledger, response)
```

## Related

- Architecture dynamic view: `dynamic-unit-tracer-report-flow`
- Related flows: [Unit Report Generation](unit-report-generation.md), [Accounting Data Retrieval](accounting-data-retrieval.md)
