---
service: "barcode-service-app"
title: "Barcode Width Lookup"
generated: "2026-03-03"
type: flow
flow_name: "barcode-width-lookup"
flow_type: synchronous
trigger: "HTTP GET request to compute the pixel width of a barcode"
participants:
  - "barcodeSvc_apiResources"
  - "barcodeSvc_validationService"
  - "barcodeSvc_generationService"
  - "barcodeSvc_sizePolicy"
  - "barcodeSvc_renderingEngine"
architecture_ref: "dynamic-barcode-generation-flow"
---

# Barcode Width Lookup

## Summary

The barcode width lookup flow allows consumers to determine the rendered pixel width of a barcode without generating and returning a full image. The consumer provides a code type and a base64-encoded payload; the service computes (or renders at minimum size) the barcode and returns the pixel width as a plain text or JSON response. This is useful for callers that need to pre-compute layout dimensions before requesting a full barcode image.

## Trigger

- **Type**: api-call
- **Source**: Any consumer (print layout service, voucher renderer) sending an HTTP GET to `/fubar/v2/barcode/{codeType}/width/base64/{payload}` or `/v2/barcode/{codeType}/width/base64/{payload}`
- **Frequency**: On demand, per-request; typically called before a corresponding image generation request

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Consumer (layout/print service) | Sends HTTP GET with codeType and base64-encoded payload | External to service |
| API Resources | Receives request on the width-lookup route; routes internally | `barcodeSvc_apiResources` |
| Barcode Validation Service | Validates the `codeType` and that the payload is valid base64 | `barcodeSvc_validationService` |
| Barcode Service (generation) | Computes rendered width for the given code type and payload | `barcodeSvc_generationService` |
| Barcode Size Policy | Provides code-type default dimensions used as the baseline for width computation | `barcodeSvc_sizePolicy` |
| Barcode Rendering Engine | Performs a minimal render pass to determine the output width | `barcodeSvc_renderingEngine` |

## Steps

1. **Receives width lookup HTTP GET**: Consumer sends `GET /fubar/v2/barcode/{codeType}/width/base64/{payload}` where `{payload}` is base64-encoded barcode data.
   - From: Consumer
   - To: `barcodeSvc_apiResources`
   - Protocol: REST (HTTP)

2. **Validates codeType and payload encoding**: API Resources delegates to Validation Service to confirm `codeType` is a supported `CodeType` value and the payload is valid base64.
   - From: `barcodeSvc_apiResources`
   - To: `barcodeSvc_validationService`
   - Protocol: In-process (Java)

3. **Delegates to generation service for width computation**: API Resources invokes the Barcode Generation Service in width-computation mode rather than full image mode.
   - From: `barcodeSvc_apiResources`
   - To: `barcodeSvc_generationService`
   - Protocol: In-process (Java)

4. **Consults size policy for defaults**: Generation Service retrieves the code-type's legacy default dimensions as the basis for width calculation.
   - From: `barcodeSvc_generationService`
   - To: `barcodeSvc_sizePolicy`
   - Protocol: In-process (Java)

5. **Computes rendered width via rendering engine**: The Rendering Engine performs a barcode encode pass to compute the minimum or default rendered pixel width for the given payload and code type, without necessarily producing full image bytes.
   - From: `barcodeSvc_generationService`
   - To: `barcodeSvc_renderingEngine`
   - Protocol: In-process (Java)

6. **Returns width value**: The computed pixel width is returned in the HTTP response body. Content type is `text/plain`, `image/png`, `application/json`, or `text/html` depending on the `Accept` header.
   - From: `barcodeSvc_apiResources`
   - To: Consumer
   - Protocol: REST (HTTP)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Invalid `codeType` | Validation rejects | HTTP 400 |
| Malformed base64 `payload` | Validation or decoder rejects | HTTP 400 |
| Rendering engine cannot compute width | Propagated as application exception | HTTP 4xx or 5xx |

## Sequence Diagram

```
Consumer -> barcodeSvc_apiResources: GET /fubar/v2/barcode/{codeType}/width/base64/{payload}
barcodeSvc_apiResources -> barcodeSvc_validationService: Validates codeType, base64 payload
barcodeSvc_validationService --> barcodeSvc_apiResources: Validation result
barcodeSvc_apiResources -> barcodeSvc_generationService: ComputeWidth(codeType, base64Payload)
barcodeSvc_generationService -> barcodeSvc_sizePolicy: Get default dimensions for codeType
barcodeSvc_sizePolicy --> barcodeSvc_generationService: defaultWidth, defaultHeight
barcodeSvc_generationService -> barcodeSvc_renderingEngine: ComputeWidth(codeType, decodedPayload, defaultDimensions)
barcodeSvc_renderingEngine --> barcodeSvc_generationService: Pixel width (integer)
barcodeSvc_generationService --> barcodeSvc_apiResources: Pixel width
barcodeSvc_apiResources --> Consumer: HTTP 200 width value (text/plain or application/json)
```

## Related

- Architecture dynamic view: `dynamic-barcode-generation-flow`
- Related flows: [Barcode Generation (Standard)](barcode-generation.md), [JEDI Barcode Generation](jedi-barcode-generation.md)
