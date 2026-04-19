---
service: "mailman"
title: "Deduplication Check"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "deduplication-check"
flow_type: synchronous
trigger: "HTTP POST to /mailman/duplicate-check"
participants:
  - "continuumMailmanApiController"
  - "mailmanPostgres"
architecture_ref: "dynamic-mail-processing-flow"
---

# Deduplication Check

## Summary

This flow handles explicit duplicate detection for transactional email requests. A caller submits a request fingerprint or identifying payload to `POST /mailman/duplicate-check`, and the API controller queries the deduplication table in `mailmanPostgres` to determine whether an equivalent request has already been processed. The result allows callers to avoid submitting duplicate requests before calling `POST /mailman/mail`.

## Trigger

- **Type**: api-call
- **Source**: Internal Continuum service or operator calling `POST /mailman/duplicate-check`
- **Frequency**: Per-request (on-demand), typically called before `POST /mailman/mail`

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| API caller (internal service) | Submits request fingerprint for duplicate check | — |
| `continuumMailmanApiController` | Receives the check request and coordinates the lookup | `continuumMailmanApiController` |
| `mailmanPostgres` | Source of deduplication records | `mailmanPostgres` |

## Steps

1. **Receives duplicate check request**: Caller sends `POST /mailman/duplicate-check` with the request identifier or fingerprint payload.
   - From: API caller
   - To: `continuumMailmanApiController`
   - Protocol: REST/HTTP/JSON

2. **Queries deduplication table**: Controller queries the deduplication records table in `mailmanPostgres` for a matching record.
   - From: `continuumMailmanApiController`
   - To: `mailmanPostgres`
   - Protocol: JDBC

3. **Returns duplicate status**: Controller returns the result indicating whether a duplicate was found.
   - From: `continuumMailmanApiController`
   - To: API caller
   - Protocol: REST/HTTP/JSON

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| `mailmanPostgres` unavailable | JDBC connection fails | Controller returns 5xx error; caller should retry or skip deduplication |
| Malformed check request | Controller validation fails | Returns 4xx; no database query performed |

## Sequence Diagram

```
Caller -> continuumMailmanApiController: POST /mailman/duplicate-check
continuumMailmanApiController -> mailmanPostgres: Query deduplication records
mailmanPostgres --> continuumMailmanApiController: Return match result
continuumMailmanApiController --> Caller: HTTP 200 (duplicate: true/false)
```

## Related

- Architecture dynamic view: `dynamic-mail-processing-flow`
- Related flows: [Submit Transactional Email](submit-transactional-email.md), [MBus Message Consumption](mbus-message-consumption.md)
