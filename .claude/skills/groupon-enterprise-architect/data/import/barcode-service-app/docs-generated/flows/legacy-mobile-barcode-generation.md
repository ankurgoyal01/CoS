---
service: "barcode-service-app"
title: "Legacy Mobile Barcode Generation"
generated: "2026-03-03"
type: flow
flow_name: "legacy-mobile-barcode-generation"
flow_type: synchronous
trigger: "HTTP GET request from a mobile client using the v1 API endpoint"
participants:
  - "barcodeSvc_apiResources"
  - "barcodeSvc_validationService"
  - "barcodeSvc_generationService"
  - "barcodeSvc_sizePolicy"
  - "barcodeSvc_renderingEngine"
architecture_ref: "dynamic-barcode-generation-flow"
---

# Legacy Mobile Barcode Generation

## Summary

The legacy mobile barcode generation flow handles v1 API requests from mobile clients. It uses the same internal generation pipeline as the standard flow, but the external path structure differs: v1 exposes both a mobile-specific endpoint (`/fubar/v1/barcode/mobile/...`) with an explicit file extension, and a generic v1 endpoint (`/fubar/v1/barcode/...`) without a file extension (relying on `Accept` header content negotiation). This flow is maintained for backward compatibility with older mobile client versions.

## Trigger

- **Type**: api-call
- **Source**: Mobile redemption clients sending HTTP GET requests to `/fubar/v1/barcode/mobile/{codeType}/{payloadType}/{payload}.{filetype}` or `/fubar/v1/barcode/{codeType}/{payloadType}/{payload}`
- **Frequency**: On demand, per-request

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Mobile client | Sends HTTP GET using v1 path structure with codeType, payloadType, payload, and optional file extension | External to service |
| API Resources | Receives request on the v1 route; routes to validation and generation | `barcodeSvc_apiResources` |
| Barcode Validation Service | Validates codeType and payloadType values | `barcodeSvc_validationService` |
| Barcode Service (generation) | Generates barcode using standard generation logic (same as v2/v3 flows) | `barcodeSvc_generationService` |
| Barcode Size Policy | Applies legacy default dimensions for the requested code type | `barcodeSvc_sizePolicy` |
| Barcode Rendering Engine | Renders the barcode image using ZXing or Barbecue | `barcodeSvc_renderingEngine` |

## Steps

1. **Receives legacy mobile HTTP GET request**: Mobile client sends a request such as `GET /fubar/v1/barcode/mobile/{codeType}/{payloadType}/{payload}.png` or `GET /fubar/v1/barcode/{codeType}/{payloadType}/{payload}` (without file extension, using Accept header).
   - From: Mobile client
   - To: `barcodeSvc_apiResources`
   - Protocol: REST (HTTP)

2. **Validates codeType and payloadType**: API Resources routes to Validation Service to confirm the requested code type and payload type are valid enum values.
   - From: `barcodeSvc_apiResources`
   - To: `barcodeSvc_validationService`
   - Protocol: In-process (Java)

3. **Delegates to generation service**: With validated inputs, API Resources invokes the standard Barcode Generation Service. No rotation parameter is available on v1 endpoints.
   - From: `barcodeSvc_apiResources`
   - To: `barcodeSvc_generationService`
   - Protocol: In-process (Java)

4. **Applies legacy default dimensions**: Generation Service consults Size Policy using the code-type's legacy default dimensions (e.g., 350x80 for Code128, 135x135 for QR code) since v1 endpoints do not accept explicit width/height parameters.
   - From: `barcodeSvc_generationService`
   - To: `barcodeSvc_sizePolicy`
   - Protocol: In-process (Java)

5. **Renders barcode image**: Rendering Engine produces the image at legacy default dimensions in the requested or negotiated format (PNG or GIF).
   - From: `barcodeSvc_generationService`
   - To: `barcodeSvc_renderingEngine`
   - Protocol: In-process (Java)

6. **Returns image to mobile client**: HTTP 200 response with `image/png` or `image/gif` body. For the non-extension endpoint, content type is determined by the Accept header.
   - From: `barcodeSvc_apiResources`
   - To: Mobile client
   - Protocol: REST (HTTP)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Invalid `codeType` value | Validation rejects | HTTP 400 |
| Invalid `payloadType` value | Validation rejects | HTTP 400 |
| Malformed payload for the selected encoder | Renderer throws `ApplicationException` | HTTP 4xx |
| Rendering library exception | Propagated as internal server error | HTTP 500 |

## Sequence Diagram

```
MobileClient -> barcodeSvc_apiResources: GET /fubar/v1/barcode/mobile/{codeType}/{payloadType}/{payload}.{filetype}
barcodeSvc_apiResources -> barcodeSvc_validationService: Validates codeType, payloadType
barcodeSvc_validationService --> barcodeSvc_apiResources: Validation result
barcodeSvc_apiResources -> barcodeSvc_generationService: Generate(codeType, payloadType, payload, format)
barcodeSvc_generationService -> barcodeSvc_sizePolicy: Get legacy default dimensions for codeType
barcodeSvc_sizePolicy --> barcodeSvc_generationService: legacyDefaultWidth, legacyDefaultHeight
barcodeSvc_generationService -> barcodeSvc_renderingEngine: Render(codeType, decodedPayload, defaultWidth, defaultHeight, format)
barcodeSvc_renderingEngine --> barcodeSvc_generationService: Image bytes
barcodeSvc_generationService --> barcodeSvc_apiResources: Image bytes
barcodeSvc_apiResources --> MobileClient: HTTP 200 image/png or image/gif
```

## Related

- Architecture dynamic view: `dynamic-barcode-generation-flow`
- Related flows: [Barcode Generation (Standard)](barcode-generation.md), [JEDI Barcode Generation](jedi-barcode-generation.md)
