---
service: "partner-attributes-mapping-service"
title: "Signature Creation Flow"
generated: "2026-03-03"
type: flow
flow_name: "signature-creation-flow"
flow_type: synchronous
trigger: "HTTP API call — POST /v1/signature"
participants:
  - "pams_requestFilters"
  - "pams_apiResources"
  - "pams_signatureService"
  - "pams_partnerRegistry"
  - "pams_secretDao"
  - "continuumPartnerAttributesMappingPostgres"
architecture_ref: "dynamic-pams-signature-request-flow"
---

# Signature Creation Flow

## Summary

This flow generates an HMAC-SHA1 cryptographic signature for a payload that an internal Groupon service intends to send to an external partner endpoint. The caller provides the target URL components, the SHA-256 hash of the request body, the HTTP method, a nonce, and the desired digest algorithm. The service resolves the partner's secret key from the registry, computes the signature using the OAuth-inspired signing algorithm, and returns a formatted authentication header string ready to include in the outbound partner request.

## Trigger

- **Type**: api-call
- **Source**: Internal Groupon service (CLO distribution system) preparing an outbound call to a partner API
- **Frequency**: On demand, per outbound partner request requiring signing

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Caller (internal service) | Submits signing request before calling partner API | (tracked in central architecture model) |
| `pams_requestFilters` | Logs request payload | `pams_requestFilters` |
| `pams_apiResources` | Routes to `PartnerSignatureServiceResource`; returns signed response | `pams_apiResources` |
| `pams_signatureService` | Orchestrates secret resolution and signature computation | `pams_signatureService` |
| `pams_partnerRegistry` | Resolves partner metadata (secret, version, digest) by brand name | `pams_partnerRegistry` |
| `pams_secretDao` | Reads partner secret row from the database | `pams_secretDao` |
| `continuumPartnerAttributesMappingPostgres` | Stores partner secret rows | `continuumPartnerAttributesMappingPostgres` |

## Steps

1. **Receives signing request**: Caller sends `POST /v1/signature` with required header `X-BRAND: <partner-brand-id>` and JSON body containing `baseUrl`, `bodySha`, `digest` (e.g., `HMAC-SHA1`), `httpMethod`, `version` (`1.1`), and optionally `nonce`, `scheme`, and `urlParams`.
   - From: Caller
   - To: `pams_requestFilters`
   - Protocol: REST / HTTP

2. **Logs payload**: `RequestPayloadLoggingFilter` logs the request for observability.
   - From: `pams_requestFilters`
   - To: `pams_apiResources`
   - Protocol: Jersey filter chain

3. **Dispatches to signature resource**: `PartnerSignatureServiceResource.post_1()` is invoked with the `X-BRAND` header and the `SignatureCreationAttributes` body.
   - From: `pams_apiResources`
   - To: `pams_signatureService`
   - Protocol: Direct (in-process)

4. **Resolves partner metadata and secret**: `pams_partnerRegistry` looks up the partner by brand name. If the partner is in the in-memory config (pre-loaded from `partnerSecretsConfig` YAML + DB secrets), the secret is returned from memory. Otherwise the registry queries the database.
   - From: `pams_signatureService`
   - To: `pams_partnerRegistry`
   - Protocol: Direct (in-process)

5. **Loads partner secret from database** (if not cached in registry): `PartnerAttributeSecretDao.getPartnerSecretsByName()` executes `SELECT * FROM partner_secrets WHERE partner = :partner`.
   - From: `pams_partnerRegistry`
   - To: `pams_secretDao`
   - Protocol: Direct (in-process)

6. **Reads secret row**: PostgreSQL returns the `partner_secrets` row containing `secret`, `version`, and `digest`.
   - From: `pams_secretDao`
   - To: `continuumPartnerAttributesMappingPostgres`
   - Protocol: JDBI / PostgreSQL

7. **Computes HMAC-SHA1 signature**: The `Signature` class constructs the signing string using the OAuth-inspired algorithm:
   ```
   PERCENT_ENCODE(
     BASE64(
       HMAC_SHA1(
         signing_key,
         uppercase_http_verb + "&" +
         PERCENT_ENCODE(nonce) + "&" +
         PERCENT_ENCODE(base_url) + "&" +
         PERCENT_ENCODE(sorted_url_params) + "&" +
         SHA256_AS_HEX_BODY_SHA
       )
     )
   )
   ```
   URL parameters are sorted alphabetically before encoding.
   - From: `pams_signatureService` (internal)
   - To: JDK `javax.crypto.Mac` (HmacSHA1)
   - Protocol: Direct (in-process)

8. **Formats authentication header**: The formatted signature header follows the pattern:
   ```
   <scheme> version="1.1",digest="HMAC-SHA1",nonce="<nonce>",signature="<percent-encoded-base64-sig>"
   ```
   - From: `Signature.getFormattedSignatureHeader()`
   - To: `pams_signatureService`
   - Protocol: Direct (in-process)

9. **Returns SignatureResponse**: HTTP 200 with `SignatureResponse` containing `body` (raw signature), `digest`, `digestVersion`, `formattedSignatureHeader`, `nonce`, and `scheme`.
   - From: `pams_apiResources`
   - To: Caller
   - Protocol: REST / HTTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Unknown brand (`X-BRAND` not in registry) | `SecretFinder` / registry returns empty | HTTP 404 "Brand not found" |
| Unsupported `digest` algorithm (not `HMAC-SHA1`) | `DigestNotSupportedException` thrown in `Signature` constructor | HTTP 400 "Digest not supported" |
| Database unavailable when reading secret | JDBI exception propagates | HTTP 500 |
| Missing required body fields (`baseUrl`, `bodySha`, `digest`, `httpMethod`, `version`) | Bean validation fails | HTTP 422 (Unprocessable Entity) |

## Sequence Diagram

```
Caller -> pams_requestFilters: POST /v1/signature (X-BRAND, body)
pams_requestFilters -> pams_apiResources: Logged request
pams_apiResources -> pams_signatureService: Handle signature request
pams_signatureService -> pams_partnerRegistry: Resolve partner metadata and secret
pams_partnerRegistry -> pams_secretDao: Load partner secret
pams_secretDao -> continuumPartnerAttributesMappingPostgres: Read partner secret row
continuumPartnerAttributesMappingPostgres --> pams_secretDao: partner_secrets row
pams_secretDao --> pams_partnerRegistry: PartnerSecret
pams_partnerRegistry --> pams_signatureService: Secret + config
pams_signatureService --> pams_signatureService: Compute HMAC-SHA1 signature
pams_signatureService --> pams_apiResources: SignatureResponse
pams_apiResources --> Caller: HTTP 200 SignatureResponse
```

## Related

- Architecture dynamic view: `dynamic-pams-signature-request-flow`
- Related flows: [Signature Validation Flow](signature-validation-flow.md), [Partner Secret Management Flow](partner-secret-management-flow.md)
- See [API Surface](../api-surface.md) for request/response schema details
