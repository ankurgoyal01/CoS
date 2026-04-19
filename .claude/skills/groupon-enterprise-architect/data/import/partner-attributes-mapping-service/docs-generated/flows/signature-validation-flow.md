---
service: "partner-attributes-mapping-service"
title: "Signature Validation Flow"
generated: "2026-03-03"
type: flow
flow_name: "signature-validation-flow"
flow_type: synchronous
trigger: "HTTP API call — POST /v1/signature/validation"
participants:
  - "pams_requestFilters"
  - "pams_apiResources"
  - "pams_signatureService"
  - "pams_partnerRegistry"
  - "pams_secretDao"
  - "continuumPartnerAttributesMappingPostgres"
architecture_ref: "dynamic-pams-signature-request-flow"
---

# Signature Validation Flow

## Summary

This flow validates an inbound HMAC signature that a partner has attached to a payload sent to Groupon. An internal Groupon service receives a webhook or callback from an external partner, extracts the partner's signature header, and calls `POST /v1/signature/validation` to verify authenticity. PAMS recomputes the expected signature using the partner's stored secret key and compares it to the signature the partner supplied.

## Trigger

- **Type**: api-call
- **Source**: Internal Groupon service (CLO distribution system) processing an inbound partner callback or webhook
- **Frequency**: On demand, per inbound partner request requiring signature verification

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Caller (internal service) | Forwards partner signature for validation | (tracked in central architecture model) |
| `pams_requestFilters` | Logs request payload | `pams_requestFilters` |
| `pams_apiResources` | Routes to `PartnerSignatureServiceResource`; returns validation result | `pams_apiResources` |
| `pams_signatureService` | Orchestrates secret resolution and signature comparison | `pams_signatureService` |
| `pams_partnerRegistry` | Resolves partner secret by brand name | `pams_partnerRegistry` |
| `pams_secretDao` | Reads partner secret from the database | `pams_secretDao` |
| `continuumPartnerAttributesMappingPostgres` | Stores partner secret rows | `continuumPartnerAttributesMappingPostgres` |

## Steps

1. **Receives validation request**: Caller sends `POST /v1/signature/validation` with required header `X-BRAND: <partner-brand-id>` and JSON body containing `baseUrl`, `bodySha`, `digest`, `httpMethod`, `version`, `signatureHeader` (the partner's signature string), and optionally `nonce`, `scheme`, and `urlParams`.
   - From: Caller
   - To: `pams_requestFilters`
   - Protocol: REST / HTTP

2. **Logs payload**: `RequestPayloadLoggingFilter` logs the request for observability.
   - From: `pams_requestFilters`
   - To: `pams_apiResources`
   - Protocol: Jersey filter chain

3. **Dispatches to signature resource**: `PartnerSignatureServiceResource.post()` (the validation handler) is invoked with the `X-BRAND` header and the `SignatureValidationAttributes` body.
   - From: `pams_apiResources`
   - To: `pams_signatureService`
   - Protocol: Direct (in-process)

4. **Resolves partner secret**: Same secret resolution path as the creation flow — the registry looks up the partner by brand name and returns the stored secret.
   - From: `pams_signatureService`
   - To: `pams_partnerRegistry`
   - Protocol: Direct (in-process)

5. **Loads partner secret from database** (if not in registry): `PartnerAttributeSecretDao.getPartnerSecretsByName()` queries `partner_secrets`.
   - From: `pams_partnerRegistry`
   - To: `pams_secretDao`
   - Protocol: Direct (in-process)

6. **Reads secret row**
   - From: `pams_secretDao`
   - To: `continuumPartnerAttributesMappingPostgres`
   - Protocol: JDBI / PostgreSQL

7. **Recomputes expected signature**: `SignatureValidator` uses the same `Signature` class algorithm to recompute what the signature should be given the provided request attributes and the stored partner secret.
   - From: `pams_signatureService` (internal)
   - To: JDK `javax.crypto.Mac` (HmacSHA1)
   - Protocol: Direct (in-process)

8. **Compares signatures**: The recomputed signature is compared to the `signatureHeader` value provided in the request body. The result (`true`/`false`) is returned.
   - From: `SignatureValidator`
   - To: `pams_signatureService`
   - Protocol: Direct (in-process)

9. **Returns validation result**: HTTP 200 with a map object containing the validation outcome (`{"valid": true}` or equivalent).
   - From: `pams_apiResources`
   - To: Caller
   - Protocol: REST / HTTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Unknown brand (`X-BRAND` not in registry) | Registry lookup returns empty | HTTP 404 "Brand not found" |
| Unsupported digest algorithm | `DigestNotSupportedException` in `Signature` constructor | HTTP 400 "Digest not supported" |
| Partner signature does not match recomputed value | Validation returns `false` in the response body | HTTP 200 with `valid: false` (not an error HTTP status) |
| Database unavailable | JDBI exception propagates | HTTP 500 |
| Missing required body fields | Bean validation fails | HTTP 422 |

## Sequence Diagram

```
Caller -> pams_requestFilters: POST /v1/signature/validation (X-BRAND, body + signatureHeader)
pams_requestFilters -> pams_apiResources: Logged request
pams_apiResources -> pams_signatureService: Handle signature validation request
pams_signatureService -> pams_partnerRegistry: Resolve partner metadata and secret
pams_partnerRegistry -> pams_secretDao: Load partner secret
pams_secretDao -> continuumPartnerAttributesMappingPostgres: Read partner secret row
continuumPartnerAttributesMappingPostgres --> pams_secretDao: partner_secrets row
pams_secretDao --> pams_partnerRegistry: PartnerSecret
pams_partnerRegistry --> pams_signatureService: Secret + config
pams_signatureService --> pams_signatureService: Recompute HMAC-SHA1 and compare
pams_signatureService --> pams_apiResources: Validation result map
pams_apiResources --> Caller: HTTP 200 {valid: true|false}
```

## Related

- Architecture dynamic view: `dynamic-pams-signature-request-flow`
- Related flows: [Signature Creation Flow](signature-creation-flow.md), [Partner Secret Management Flow](partner-secret-management-flow.md)
- See [API Surface](../api-surface.md) for request/response schema details
