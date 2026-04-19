---
service: "content-pages"
title: "Infringement Report Submission Flow"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "infringement-report-submission"
flow_type: synchronous
trigger: "User submits the infringement report form at POST /report_infringement"
participants:
  - "continuumContentPagesService"
  - "infringementController"
  - "emailerService"
architecture_ref: "dynamic-infringement-report-submission"
---

# Infringement Report Submission Flow

## Summary

This flow handles intellectual property infringement report submissions. A user navigates to the infringement report form (`GET /report_infringement`), completes the form describing the alleged infringement, and submits (`POST /report_infringement`). The service validates the submission and sends a notification email to the Groupon legal/operations team via Rocketman Email Service. Unlike the incident report flow, infringement reports do not involve image uploads.

## Trigger

- **Type**: user-action
- **Source**: User submits the infringement report form on the `/report_infringement` page
- **Frequency**: on-demand

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| User browser | Fills and submits the infringement report form | — |
| Infringement Controller | Handles GET and POST for `/report_infringement`; orchestrates submission | `infringementController` |
| Emailer Service | Sends infringement notification email via Rocketman | `emailerService` |
| Rocketman Email Service | Delivers notification email to legal/operations team | stub-only |

## Steps

1. **Renders infringement report form**: User browser requests `GET /report_infringement`; controller renders the form.
   - From: `User browser`
   - To: `infringementController`
   - Protocol: HTTPS

2. **Returns rendered form**: Controller responds with the Preact-rendered infringement report form.
   - From: `infringementController`
   - To: `User browser`
   - Protocol: HTTPS (HTML response)

3. **Receives form submission**: User submits `POST /report_infringement` with infringement details.
   - From: `User browser`
   - To: `infringementController`
   - Protocol: HTTPS (application/x-www-form-urlencoded)

4. **Validates submission**: Infringement controller validates required fields (infringement description, contact information, etc.).
   - From: `infringementController`
   - To: in-process validation
   - Protocol: direct

5. **Sends notification email**: Controller delegates to `emailerService` to send the infringement report email.
   - From: `infringementController`
   - To: `emailerService`
   - Protocol: direct

6. **Delivers email via Rocketman**: `emailerService` calls Rocketman Email Service via `@grpn/rocketman-client`.
   - From: `emailerService`
   - To: `Rocketman Email Service`
   - Protocol: HTTPS

7. **Returns confirmation**: Controller renders a confirmation page to the user.
   - From: `infringementController`
   - To: `User browser`
   - Protocol: HTTPS (HTML response)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Missing required form fields | Validation rejects submission | Form re-rendered with validation error messages |
| Rocketman Email Service unavailable | `emailerService` logs error | Report submission may succeed with confirmation shown but notification email not delivered |

## Sequence Diagram

```
User browser -> infringementController: GET /report_infringement
infringementController --> User browser: 200 OK (infringement report form)
User browser -> infringementController: POST /report_infringement {infringement details}
infringementController -> infringementController: Validate submission
infringementController -> emailerService: Send infringement notification email
emailerService -> Rocketman Email Service: POST send email (@grpn/rocketman-client)
Rocketman Email Service --> emailerService: 200 OK
infringementController --> User browser: 200 OK (confirmation page)
```

## Related

- Architecture dynamic view: No dynamic view defined in DSL
- Related flows: [Incident Report Submission](incident-report-submission.md), [Error Page Rendering](error-page-rendering.md)
