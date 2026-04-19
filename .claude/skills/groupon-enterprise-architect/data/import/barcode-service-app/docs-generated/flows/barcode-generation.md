---
service: "barcode-service-app"
title: "Barcode Generation (Standard)"
generated: "2026-03-03"
type: flow
flow_name: "barcode-generation"
flow_type: synchronous
trigger: "HTTP GET request from a consumer service or client"
participants:
  - "barcodeSvc_apiResources"
  - "barcodeSvc_validationService"
  - "barcodeSvc_generationService"
  - "barcodeSvc_sizePolicy"
  - "barcodeSvc_renderingEngine"
architecture_ref: "dynamic-barcode-generation-flow"
---

# Barcode Generation (Standard)

## Summary

This is the primary barcode generation flow used by the v2 and v3 API endpoints. A consumer sends an HTTP GET request specifying the desired barcode symbology (`codeType`), payload encoding (`payloadType`), data (`payload`), optional dimensions, and output format. The service validates inputs, normalizes size constraints, selects the appropriate renderer, and returns a rendered PNG or GIF image in the HTTP response body.

## Trigger

- **Type**: api-call
- **Source**: Any internal consumer (voucher print service, mobile client, merchant portal) sending an HTTP GET to `/fubar/v2/barcode/...` or `/fubar/v3/barcode/...` (or their `/v2/` alias equivalents)
- **Frequency**: On demand, per-request; peak ~486 requests per minute

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Consumer (caller) | Sends HTTP GET with code type, payload type, payload, optional dimensions and rotation | External to service |
| API Resources | Receives the HTTP request; routes to validation and generation components | `barcodeSvc_apiResources` |
| Barcode Validation Service | Validates codeType enum, payloadType enum, dimension bounds, and rotation value | `barcodeSvc_validationService` |
| Barcode Service (generation) | Orchestrates generation: decodes payload, enforces size policy, invokes rendering engine | `barcodeSvc_generationService` |
| Barcode Size Policy | Applies per-code-type dimension defaults (e.g., `code128` default 350x80, `qrcode` default 135x135) and enforces `minBarcodeHeight` | `barcodeSvc_sizePolicy` |
| Barcode Rendering Engine | Instantiates and executes the renderer for the requested code type (ZXing or Barbecue); produces image bytes | `barcodeSvc_renderingEngine` |

## Steps

1. **Receives HTTP GET request**: Consumer sends request to an endpoint such as `GET /fubar/v2/barcode/{codeType}/{payloadType}/{payload}.{filetype}` with optional `?rotate=<degrees>`.
   - From: Consumer
   - To: `barcodeSvc_apiResources`
   - Protocol: REST (HTTP)

2. **Validates inputs**: API Resources delegates to Validation Service to verify that `codeType` is a known `CodeType` enum value, `payloadType` is one of `plain`, `base64`, or `base64url`, dimensions (if supplied) are positive integers, and rotation value (if supplied) is a valid integer.
   - From: `barcodeSvc_apiResources`
   - To: `barcodeSvc_validationService`
   - Protocol: In-process (Java)

3. **Delegates to generation service**: If validation passes, API Resources invokes Barcode Generation Service with the validated parameters.
   - From: `barcodeSvc_apiResources`
   - To: `barcodeSvc_generationService`
   - Protocol: In-process (Java)

4. **Applies size policy**: Generation Service consults Barcode Size Policy to determine effective width and height — using request-supplied dimensions if present, otherwise falling back to the code-type legacy defaults (e.g., 350x80 for linear codes, 135x135 for QR codes) and enforcing the configured `minBarcodeHeight`.
   - From: `barcodeSvc_generationService`
   - To: `barcodeSvc_sizePolicy`
   - Protocol: In-process (Java)

5. **Renders image**: Generation Service invokes Barcode Rendering Engine with the final parameters. The engine selects the renderer class mapped to the requested `codeType` (e.g., `Code128Renderer`, `QRCodeRenderer`) and calls the ZXing or Barbecue library to produce image bytes in the requested format (PNG or GIF).
   - From: `barcodeSvc_generationService`
   - To: `barcodeSvc_renderingEngine`
   - Protocol: In-process (Java)

6. **Returns image response**: The rendered image bytes are written to the HTTP response body with the appropriate `Content-Type` (`image/png` or `image/gif`). HTTP 200 is returned on success.
   - From: `barcodeSvc_apiResources`
   - To: Consumer
   - Protocol: REST (HTTP)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Invalid `codeType` value | Validation rejects; throws `BadRequestException` | HTTP 400 returned to caller |
| Invalid `payloadType` value | Validation rejects; throws `BadRequestException` | HTTP 400 returned to caller |
| Malformed or invalid `payload` for the given encoder | Renderer throws `ApplicationException` | HTTP 4xx returned to caller |
| Dimension out of range or below `minBarcodeHeight` | Size Policy enforces bounds; invalid requests return error | HTTP 400 returned to caller |
| Rendering library exception | Propagated as internal server error | HTTP 500 returned to caller |

## Sequence Diagram

```
Consumer -> barcodeSvc_apiResources: GET /fubar/v2/barcode/{codeType}/{payloadType}/{payload}.{filetype}
barcodeSvc_apiResources -> barcodeSvc_validationService: Validates codeType, payloadType, dimensions, rotation
barcodeSvc_validationService --> barcodeSvc_apiResources: Validation result (ok or BadRequestException)
barcodeSvc_apiResources -> barcodeSvc_generationService: Generate(codeType, payloadType, payload, width, height, rotation, format)
barcodeSvc_generationService -> barcodeSvc_sizePolicy: Resolve effective dimensions
barcodeSvc_sizePolicy --> barcodeSvc_generationService: Effective width, height
barcodeSvc_generationService -> barcodeSvc_renderingEngine: Render(codeType, decodedPayload, width, height, format)
barcodeSvc_renderingEngine --> barcodeSvc_generationService: Image bytes (PNG or GIF)
barcodeSvc_generationService --> barcodeSvc_apiResources: Image bytes
barcodeSvc_apiResources --> Consumer: HTTP 200 image/png or image/gif
```

## Related

- Architecture dynamic view: `dynamic-barcode-generation-flow`
- Related flows: [JEDI Barcode Generation](jedi-barcode-generation.md), [Legacy Mobile Barcode Generation](legacy-mobile-barcode-generation.md), [Barcode Width Lookup](barcode-width-lookup.md)
