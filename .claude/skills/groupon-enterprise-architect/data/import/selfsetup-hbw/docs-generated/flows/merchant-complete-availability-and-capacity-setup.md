---
service: "selfsetup-hbw"
title: "Merchant Complete Availability and Capacity Setup"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "merchant-complete-availability-and-capacity-setup"
flow_type: synchronous
trigger: "Merchant submits the availability (/week) or capping (/capping) form"
participants:
  - "ssuWebUi"
  - "ssuPersistence"
  - "continuumSsuDatabase"
  - "ssuMetricsReporter"
  - "ssuLogger"
architecture_ref: "dynamic-selfsetup-hbw"
---

# Merchant Complete Availability and Capacity Setup

## Summary

After session initialisation, the merchant works through the availability and capacity wizard steps. The merchant submits their weekly availability windows via `/week` and their per-slot capacity caps via `/capping`. Each submission is validated by the application, persisted to `continuumSsuDatabase`, and acknowledged to the merchant. This flow operates entirely within selfsetup-hbw — no external API calls are made until the final push step.

## Trigger

- **Type**: user-action
- **Source**: Merchant submits the availability form (`/week`) or the capacity/capping form (`/capping`) in the browser
- **Frequency**: On-demand (once per wizard session; may be revisited if the merchant uses the edit flow)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Merchant browser | Submits form data for availability and capacity | — |
| Web UI / Controllers | Receives, validates, and processes form submissions | `ssuWebUi` |
| Data Access | Writes validated availability and capping data | `ssuPersistence` |
| SSU HBW Database | Persists availability schedule and capacity configuration | `continuumSsuDatabase` |
| Metrics Reporter | Emits submission metrics to Telegraf | `ssuMetricsReporter` |
| Logging | Records validation outcomes and errors to Splunk | `ssuLogger` |

## Steps

1. **Renders availability form**: `ssuWebUi` serves the `/week` page, pre-populating any previously saved availability windows from `continuumSsuDatabase`.
   - From: `ssuWebUi`
   - To: Merchant browser
   - Protocol: REST / HTTPS (HTTP 200 HTML)

2. **Receives availability submission**: Merchant submits weekly availability windows via HTTP POST to `/week`.
   - From: Merchant browser
   - To: `ssuWebUi`
   - Protocol: REST / HTTPS (form POST)

3. **Validates availability data**: `ssuWebUi` applies business rules to the submitted schedule (e.g., slot format, minimum availability, locale-specific constraints).
   - From: `ssuWebUi`
   - To: (in-process validation logic)
   - Protocol: Direct

4. **Persists availability configuration**: On successful validation, `ssuWebUi` calls `ssuPersistence` to write the availability schedule to `continuumSsuDatabase`.
   - From: `ssuWebUi` via `ssuPersistence`
   - To: `continuumSsuDatabase`
   - Protocol: TCP / MySQL

5. **Renders capacity/capping form**: `ssuWebUi` serves the `/capping` page, pre-populating any previously saved capping configuration.
   - From: `ssuWebUi`
   - To: Merchant browser
   - Protocol: REST / HTTPS (HTTP 200 HTML)

6. **Receives capping submission**: Merchant submits per-slot capacity caps via HTTP POST to `/capping`.
   - From: Merchant browser
   - To: `ssuWebUi`
   - Protocol: REST / HTTPS (form POST)

7. **Validates capping data**: `ssuWebUi` validates the capacity values (e.g., numeric range, per-slot constraints).
   - From: `ssuWebUi`
   - To: (in-process validation logic)
   - Protocol: Direct

8. **Persists capping configuration**: `ssuPersistence` writes the validated capping settings to `continuumSsuDatabase`.
   - From: `ssuWebUi` via `ssuPersistence`
   - To: `continuumSsuDatabase`
   - Protocol: TCP / MySQL

9. **Emits metrics and logs**: `ssuMetricsReporter` records submission counts and `ssuLogger` records validation results and any errors.
   - From: `ssuMetricsReporter` / `ssuLogger`
   - To: `telegrafAgent` / `logAggregation`
   - Protocol: InfluxDB line protocol / Splunk HEC

10. **Advances wizard**: `ssuWebUi` redirects the merchant to the next step or to the review/submit page.
    - From: `ssuWebUi`
    - To: Merchant browser
    - Protocol: REST / HTTPS (HTTP 302 redirect)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Validation failure (availability) | `ssuWebUi` re-renders `/week` with inline error messages | Merchant corrects and resubmits; data is not persisted |
| Validation failure (capping) | `ssuWebUi` re-renders `/capping` with inline error messages | Merchant corrects and resubmits; data is not persisted |
| MySQL write failure | `ssuPersistence` throws exception; caught by controller | Error logged via `ssuLogger`; merchant sees an error page with retry option |

## Sequence Diagram

```
Merchant -> ssuWebUi: GET /week
ssuWebUi -> ssuPersistence: readAvailability(sessionId)
ssuPersistence -> continuumSsuDatabase: SELECT ...
continuumSsuDatabase --> ssuPersistence: existing schedule (or empty)
ssuWebUi --> Merchant: HTTP 200 (availability form)
Merchant -> ssuWebUi: POST /week (schedule data)
ssuWebUi -> ssuWebUi: validate(scheduleData)
ssuWebUi -> ssuPersistence: saveAvailability(sessionId, scheduleData)
ssuPersistence -> continuumSsuDatabase: INSERT/UPDATE availability
continuumSsuDatabase --> ssuPersistence: OK
ssuWebUi --> Merchant: HTTP 302 -> /capping
Merchant -> ssuWebUi: GET /capping
ssuWebUi --> Merchant: HTTP 200 (capping form)
Merchant -> ssuWebUi: POST /capping (capacity data)
ssuWebUi -> ssuWebUi: validate(capacityData)
ssuWebUi -> ssuPersistence: saveCapping(sessionId, capacityData)
ssuPersistence -> continuumSsuDatabase: INSERT/UPDATE capping
continuumSsuDatabase --> ssuPersistence: OK
ssuMetricsReporter -> telegrafAgent: submit_count++
ssuLogger -> logAggregation: INFO submission accepted
ssuWebUi --> Merchant: HTTP 302 -> /front (review/submit)
```

## Related

- Architecture dynamic view: `dynamic-selfsetup-hbw`
- Related flows: [Merchant Signup and Opportunity Lookup](merchant-signup-and-opportunity-lookup.md), [Merchant Push Configuration to Salesforce and BookingTool](merchant-push-configuration-to-salesforce-and-bookingtool.md)
