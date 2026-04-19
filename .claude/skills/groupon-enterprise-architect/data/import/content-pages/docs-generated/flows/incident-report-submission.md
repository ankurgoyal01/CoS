---
service: "content-pages"
title: "Incident Report Submission Flow"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "incident-report-submission"
flow_type: synchronous
trigger: "User submits the incident report form at POST /report_incident"
participants:
  - "continuumContentPagesService"
  - "incidentController"
  - "imageUploadService"
  - "emailerService"
  - "continuumImageService"
architecture_ref: "dynamic-incident-report-submission"
---

# Incident Report Submission Flow

## Summary

This flow handles multi-step incident report submissions. A user first navigates to the report form (`GET /report_incident`), fills in details and optionally attaches an image, then submits (`POST /report_incident`). The service validates the submission, uploads any attached image to `continuumImageService` via `image-service-client`, and sends a notification email to the operations team via Rocketman using `@grpn/rocketman-client`. This is the only flow in the service that spans an externally modeled container (`continuumImageService`).

## Trigger

- **Type**: user-action
- **Source**: User submits the incident report form on the `/report_incident` page
- **Frequency**: on-demand

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| User browser | Fills and submits the incident report form | — |
| Incident Controller | Handles GET and POST for `/report_incident`; orchestrates submission | `incidentController` |
| Image Upload Service | Validates and uploads the attached image | `imageUploadService` |
| Emailer Service | Sends notification email via Rocketman | `emailerService` |
| Image Service | Stores the uploaded incident image | `continuumImageService` |
| Rocketman Email Service | Delivers notification email to operations team | stub-only |

## Steps

1. **Renders incident report form**: User browser requests `GET /report_incident`; controller renders the form.
   - From: `User browser`
   - To: `incidentController`
   - Protocol: HTTPS

2. **Returns rendered form**: Controller responds with the Preact-rendered incident report form.
   - From: `incidentController`
   - To: `User browser`
   - Protocol: HTTPS (HTML response)

3. **Receives form submission**: User submits `POST /report_incident` with incident details and optional image attachment.
   - From: `User browser`
   - To: `incidentController`
   - Protocol: HTTPS (multipart/form-data)

4. **Validates submission**: Incident controller validates required fields and image file constraints.
   - From: `incidentController`
   - To: in-process validation
   - Protocol: direct

5. **Uploads incident image**: If an image is attached, the controller delegates to `imageUploadService`.
   - From: `incidentController`
   - To: `imageUploadService`
   - Protocol: direct

6. **Sends image to Image Service**: `imageUploadService` calls `continuumImageService` via `image-service-client`.
   - From: `imageUploadService`
   - To: `continuumImageService`
   - Protocol: HTTPS

7. **Receives image URL**: Image Service returns a stored image reference URL.
   - From: `continuumImageService`
   - To: `imageUploadService`
   - Protocol: HTTPS/JSON

8. **Sends notification email**: Controller delegates to `emailerService` to send the incident report email.
   - From: `incidentController`
   - To: `emailerService`
   - Protocol: direct

9. **Delivers email via Rocketman**: `emailerService` calls Rocketman Email Service via `@grpn/rocketman-client`.
   - From: `emailerService`
   - To: `Rocketman Email Service`
   - Protocol: HTTPS

10. **Returns confirmation**: Controller renders a confirmation page or redirects the user.
    - From: `incidentController`
    - To: `User browser`
    - Protocol: HTTPS (HTML response / redirect)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Missing required form fields | Validation rejects submission | Form re-rendered with error messages |
| Image file too large or invalid type | `imageUploadService` validation rejects | Form re-rendered with image error |
| `continuumImageService` unavailable | `imageUploadService` throws error | Submission may fail or proceed without image depending on configuration |
| Rocketman Email Service unavailable | `emailerService` logs error | Report received but notification email not delivered |

## Sequence Diagram

```
User browser -> incidentController: GET /report_incident
incidentController --> User browser: 200 OK (incident report form)
User browser -> incidentController: POST /report_incident {incident data, image}
incidentController -> incidentController: Validate submission
incidentController -> imageUploadService: Upload attached image
imageUploadService -> continuumImageService: POST image upload (image-service-client)
continuumImageService --> imageUploadService: 200 OK {imageUrl}
imageUploadService --> incidentController: imageUrl
incidentController -> emailerService: Send incident notification email
emailerService -> Rocketman Email Service: POST send email (@grpn/rocketman-client)
Rocketman Email Service --> emailerService: 200 OK
incidentController --> User browser: 200 OK (confirmation page)
```

## Related

- Architecture dynamic view: No dynamic view defined in DSL
- Modeled relationship: `continuumContentPagesService -> continuumImageService` (HTTPS)
- Related flows: [Infringement Report Submission](infringement-report-submission.md), [Error Page Rendering](error-page-rendering.md)
