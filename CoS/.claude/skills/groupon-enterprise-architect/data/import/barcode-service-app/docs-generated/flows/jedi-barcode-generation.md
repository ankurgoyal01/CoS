---
service: "barcode-service-app"
title: "JEDI Barcode Generation"
generated: "2026-03-03"
type: flow
flow_name: "jedi-barcode-generation"
flow_type: synchronous
trigger: "HTTP GET request containing a merchant center redemption URL as the payload"
participants:
  - "barcodeSvc_apiResources"
  - "barcodeSvc_validationService"
  - "barcodeSvc_jediGenerationService"
  - "barcodeSvc_sizePolicy"
  - "barcodeSvc_renderingEngine"
architecture_ref: "dynamic-barcode-generation-flow"
---

# JEDI Barcode Generation

## Summary

The JEDI barcode generation flow handles a specialized variant of barcode rendering where the payload is a Groupon merchant center redemption URL embedded directly (unencoded) in the URL path. This flow is used for generating barcodes that encode full HTTPS redemption URLs for the merchant-facing redemption portal. It routes through the `JEDI Barcode Service` component rather than the standard generation path, which applies JEDI-specific sizing normalization rules.

## Trigger

- **Type**: api-call
- **Source**: Merchant center redemption portal or a voucher rendering service sending an HTTP GET to `/fubar/v3/barcode/{codeType}/{width}/{height}/https:/{domain}/merchant/center/redeem/{payload}.png` or `.gif`
- **Frequency**: On demand, per-request

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Consumer (merchant portal / redemption renderer) | Sends HTTP GET with code type, explicit dimensions, and redemption URL payload path | External to service |
| API Resources | Receives request; routes to validation and JEDI generation | `barcodeSvc_apiResources` |
| Barcode Validation Service | Validates `codeType`, dimension values, and URL path segments | `barcodeSvc_validationService` |
| JEDI Barcode Service | Orchestrates JEDI-specific generation with specialized size normalization | `barcodeSvc_jediGenerationService` |
| Barcode Size Policy | Applies JEDI-specific size normalization rules | `barcodeSvc_sizePolicy` |
| Barcode Rendering Engine | Renders the barcode image for the redemption URL payload | `barcodeSvc_renderingEngine` |

## Steps

1. **Receives HTTP GET with redemption URL path**: Consumer sends a request such as `GET /fubar/v3/barcode/{codeType}/{width}/{height}/https:/{domain}/merchant/center/redeem/{payload}.png`. The redemption URL is embedded unencoded as part of the URL path.
   - From: Consumer
   - To: `barcodeSvc_apiResources`
   - Protocol: REST (HTTP)

2. **Validates inputs**: API Resources delegates to Validation Service to confirm that `codeType` is a supported value, `width` and `height` are valid positive integers, and the `domain` and `payload` path segments are well-formed.
   - From: `barcodeSvc_apiResources`
   - To: `barcodeSvc_validationService`
   - Protocol: In-process (Java)

3. **Delegates to JEDI generation service**: API Resources invokes the JEDI Barcode Service with the validated parameters, distinguishing this path from the standard generation flow.
   - From: `barcodeSvc_apiResources`
   - To: `barcodeSvc_jediGenerationService`
   - Protocol: In-process (Java)

4. **Applies JEDI size normalization**: JEDI Barcode Service consults Barcode Size Policy to apply JEDI-specific sizing rules, which may differ from the standard per-code-type defaults.
   - From: `barcodeSvc_jediGenerationService`
   - To: `barcodeSvc_sizePolicy`
   - Protocol: In-process (Java)

5. **Renders JEDI barcode image**: JEDI Barcode Service invokes the Rendering Engine to produce a PNG or GIF image encoding the full merchant center redemption URL.
   - From: `barcodeSvc_jediGenerationService`
   - To: `barcodeSvc_renderingEngine`
   - Protocol: In-process (Java)

6. **Returns image response**: Rendered image bytes are written to the HTTP response body with `Content-Type: image/png` or `image/gif`. Optional `xdim` and `pad` query params control bar width and padding.
   - From: `barcodeSvc_apiResources`
   - To: Consumer
   - Protocol: REST (HTTP)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Invalid `codeType` | Validation rejects | HTTP 400 |
| Invalid dimension values (width/height) | Validation rejects | HTTP 400 |
| URL path reconstruction failure (malformed domain/payload) | JEDI service throws `ApplicationException` | HTTP 4xx or 5xx |
| Rendering library exception | Propagated as internal server error | HTTP 500 |

## Sequence Diagram

```
Consumer -> barcodeSvc_apiResources: GET /fubar/v3/barcode/{codeType}/{width}/{height}/https:/{domain}/merchant/center/redeem/{payload}.png
barcodeSvc_apiResources -> barcodeSvc_validationService: Validates codeType, dimensions, domain, payload
barcodeSvc_validationService --> barcodeSvc_apiResources: Validation result
barcodeSvc_apiResources -> barcodeSvc_jediGenerationService: Generate(codeType, width, height, redemptionUrl, PNG)
barcodeSvc_jediGenerationService -> barcodeSvc_sizePolicy: Apply JEDI size normalization
barcodeSvc_sizePolicy --> barcodeSvc_jediGenerationService: Effective dimensions
barcodeSvc_jediGenerationService -> barcodeSvc_renderingEngine: Render(codeType, redemptionUrl, width, height, PNG)
barcodeSvc_renderingEngine --> barcodeSvc_jediGenerationService: Image bytes
barcodeSvc_jediGenerationService --> barcodeSvc_apiResources: Image bytes
barcodeSvc_apiResources --> Consumer: HTTP 200 image/png
```

## Related

- Architecture dynamic view: `dynamic-barcode-generation-flow`
- Related flows: [Barcode Generation (Standard)](barcode-generation.md), [Barcode Width Lookup](barcode-width-lookup.md)
