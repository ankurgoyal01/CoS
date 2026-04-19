---
service: "bling"
title: "Paysource File Upload"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "paysource-file-upload"
flow_type: synchronous
trigger: "Finance staff selects a paysource file and submits the upload form"
participants:
  - "continuumBlingWebApp"
  - "blingNginx"
  - "continuumAccountingService"
  - "fileSharingService"
architecture_ref: "dynamic-finance-operations-flow"
---

# Paysource File Upload

## Summary

This flow covers the upload of paysource files by finance staff through the bling SPA. A paysource file is first uploaded to the File Sharing Service via the Nginx proxy, then a paysource record is registered with the Accounting Service to link the file to the appropriate financial context. Both operations use POST requests proxied through `blingNginx`. The File Sharing Service owns file storage; the Accounting Service owns the paysource metadata record.

## Trigger

- **Type**: user-action
- **Source**: Finance staff selects a file using the paysource upload form and clicks submit
- **Frequency**: On-demand; per paysource file submission

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Finance Staff | Selects and submits the paysource file | — |
| bling Web Application | Captures file input; constructs multipart POST; renders result | `continuumBlingWebApp` |
| bling Nginx | Proxies POST to File Sharing Service and Accounting Service | `blingNginx` |
| File Sharing Service | Stores the uploaded file; returns file ID | `fileSharingService` |
| Accounting Service | Creates paysource file record linked to the file ID | `continuumAccountingService` |

## Steps

1. **Finance staff selects file**: Staff opens the Paysource File Module and selects a file via the browser file input control.
   - From: Browser (user)
   - To: `continuumBlingWebApp`
   - Protocol: Browser file input event

2. **Ember issues file upload POST to File Sharing Service**: The application sends `POST /file-sharing-service/files` with the file as multipart form data.
   - From: `continuumBlingWebApp`
   - To: `blingNginx`
   - Protocol: REST/HTTP POST multipart/form-data, `Authorization: Bearer <okta_token>`

3. **Nginx proxies file POST to File Sharing Service**: `blingNginx` routes the request via the `/file-sharing-service/` proxy path to the File Sharing Service.
   - From: `blingNginx`
   - To: `fileSharingService`
   - Protocol: REST/HTTP POST multipart/form-data

4. **File Sharing Service stores file and returns file ID**: The File Sharing Service persists the file and returns the assigned file ID in the response.
   - From: `fileSharingService`
   - To: `blingNginx` -> `continuumBlingWebApp`
   - Protocol: REST/HTTP JSON `{id: "<file_id>"}`

5. **Ember issues paysource record POST to Accounting Service**: Using the file ID from step 4, the application sends `POST /api/v1/paysource-files` to create the associated paysource metadata record.
   - From: `continuumBlingWebApp`
   - To: `blingNginx`
   - Protocol: REST/HTTP POST `Content-Type: application/json` with file_id, metadata

6. **Nginx proxies paysource POST to Accounting Service**: `blingNginx` routes the request to the Accounting Service.
   - From: `blingNginx`
   - To: `continuumAccountingService`
   - Protocol: REST/HTTP POST with Bearer token

7. **Accounting Service creates paysource record**: Accounting Service validates the payload, links the file ID to the financial context, and persists the paysource record.
   - From: `continuumAccountingService`
   - To: `blingNginx` -> `continuumBlingWebApp`
   - Protocol: REST/HTTP JSON 201 Created

8. **SPA renders confirmation**: The Paysource File Module displays the upload confirmation and updated paysource list.
   - From: `continuumBlingWebApp`
   - To: Browser (user)
   - Protocol: Browser DOM update

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| File Sharing Service returns 500 on upload | ember-ajax rejects; error shown in UI | File not stored; paysource record not created; staff must retry |
| Accounting Service returns 500 after file upload | File is stored in File Sharing Service but paysource record is not created | Orphaned file in File Sharing Service; staff must retry paysource record creation or contact support |
| File too large (if enforced by File Sharing Service) | 413 returned; ember-ajax rejects | Error message displayed; staff must upload a smaller file |
| OAuth token expired (401) | Hybrid Boundary redirect triggered | Upload must be restarted after session renewal |
| Nginx 502/503 on File Sharing Service path | Upload fails immediately | No file stored; no paysource record created; retry safe |

## Sequence Diagram

```
FinanceStaff -> continuumBlingWebApp: Select file and submit upload form
continuumBlingWebApp -> blingNginx: POST /file-sharing-service/files (multipart)
blingNginx -> fileSharingService: POST /files (proxied, Bearer token)
fileSharingService --> blingNginx: 201 Created {id: "<file_id>"}
blingNginx --> continuumBlingWebApp: 201 Created {id: "<file_id>"}
continuumBlingWebApp -> blingNginx: POST /api/v1/paysource-files {file_id: "<file_id>", ...}
blingNginx -> continuumAccountingService: POST /api/v1/paysource-files (proxied, Bearer token)
continuumAccountingService --> blingNginx: 201 Created, paysource record JSON
blingNginx --> continuumBlingWebApp: 201 Created, paysource record JSON
continuumBlingWebApp --> FinanceStaff: Render upload confirmation
```

## Related

- Architecture dynamic view: `dynamic-finance-operations-flow`
- Related flows: [Finance Data Viewing](finance-data-viewing.md)
