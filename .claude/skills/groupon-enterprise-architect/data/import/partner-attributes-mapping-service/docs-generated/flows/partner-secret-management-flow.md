---
service: "partner-attributes-mapping-service"
title: "Partner Secret Management Flow"
generated: "2026-03-03"
type: flow
flow_name: "partner-secret-management-flow"
flow_type: synchronous
trigger: "HTTP API call — POST /v1/partners/{partner_name}/secrets/generate or PUT /v1/partners/{partner_name}/secrets/update"
participants:
  - "pams_requestFilters"
  - "pams_apiResources"
  - "pams_secretService"
  - "pams_secretDao"
  - "pams_partnerRegistry"
  - "continuumPartnerAttributesMappingPostgres"
architecture_ref: "dynamic-pams-signature-request-flow"
---

# Partner Secret Management Flow

## Summary

This flow manages the lifecycle of HMAC signing secrets for registered partners. When a new partner is onboarded, an operator or automation calls the generate endpoint to create and persist a new secret. When a secret must be rotated for security purposes, the update endpoint is used. After each secret operation, the `PartnerRegistry` is refreshed so that subsequent signature requests use the new secret without requiring a service restart.

## Trigger

- **Type**: api-call
- **Source**: Operator or onboarding automation calling the partner secrets API
- **Frequency**: On demand — at partner onboarding, or when rotating secrets

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Operator / Automation | Initiates secret generation or rotation | (external to service) |
| `pams_requestFilters` | Validates `client-id` header; logs request payload | `pams_requestFilters` |
| `pams_apiResources` | Routes to `PartnerAttributesSecretsResource` | `pams_apiResources` |
| `pams_secretService` | Business logic for secret generation and update | `pams_secretService` |
| `pams_secretDao` | Persists or updates the partner secret row | `pams_secretDao` |
| `pams_partnerRegistry` | Refreshed after secret changes to pick up new secret material | `pams_partnerRegistry` |
| `continuumPartnerAttributesMappingPostgres` | Stores partner secret rows | `continuumPartnerAttributesMappingPostgres` |

## Steps

### Generate Secret (`POST /v1/partners/{partner_name}/secrets/generate`)

1. **Receives generate request**: Operator sends `POST /v1/partners/{partner_name}/secrets/generate` with `client-id` header and a `GenerateSecretRequest` JSON body (containing version, digest algorithm, and optionally pre-supplied secret material).
   - From: Operator
   - To: `pams_requestFilters`
   - Protocol: REST / HTTP

2. **Validates headers and logs payload**: `HeadersValidationFilter` checks `client-id` presence (HTTP 403 if missing); `RequestPayloadLoggingFilter` logs the body.
   - From: `pams_requestFilters`
   - To: `pams_apiResources`
   - Protocol: Jersey filter chain

3. **Validates partner name**: `PartnerAttributesSecretsResource.generateSecret()` validates the `partner_name` path parameter. Returns HTTP 400 `BadRequestException` if invalid.
   - From: `pams_apiResources`
   - To: `pams_secretService`
   - Protocol: Direct (in-process)

4. **Generates and persists secret**: `PartnerAttributesSecretService.createSecret()` creates a new `PartnerSecret` domain object (using `SecretGeneratorHelper` to generate or use supplied secret material) and calls `PartnerAttributeSecretDao.create()`.
   - From: `pams_secretService`
   - To: `pams_secretDao`
   - Protocol: Direct (in-process)

5. **Inserts secret row**: `PartnerAttributeSecretDao.create()` executes `INSERT INTO partner_secrets (partner, created_at, updated_at, secret, version, digest) VALUES (...)`.
   - From: `pams_secretDao`
   - To: `continuumPartnerAttributesMappingPostgres`
   - Protocol: JDBI / PostgreSQL

6. **Refreshes partner registry**: After successful creation, `PartnerAttributesSecretsResource` calls `partnerRegistry.refreshedPartnersConfigs()` to reload all partner secrets from the database into the in-memory registry. Subsequent signature requests immediately use the new secret.
   - From: `pams_apiResources`
   - To: `pams_partnerRegistry`
   - Protocol: Direct (in-process)

7. **Returns GenerateSecretResponse**: HTTP 200 with a `GenerateSecretResponse` confirming the partner name and generated secret reference.
   - From: `pams_apiResources`
   - To: Operator
   - Protocol: REST / HTTP

### Update Secret (`PUT /v1/partners/{partner_name}/secrets/update`)

1. **Receives update request**: Operator sends `PUT /v1/partners/{partner_name}/secrets/update` with `client-id` header and an `UpdateSecretRequest` JSON body containing the new secret value, version, and digest.
   - From: Operator
   - To: `pams_requestFilters`
   - Protocol: REST / HTTP

2. **Validates headers and logs payload**: Same as generate flow.
   - From: `pams_requestFilters`
   - To: `pams_apiResources`

3. **Updates secret**: `PartnerAttributesSecretService.updateSecret()` calls `PartnerAttributeSecretDao.updateSecret()`.
   - From: `pams_secretService`
   - To: `pams_secretDao`
   - Protocol: Direct (in-process)

4. **Executes UPDATE**: `PartnerAttributeSecretDao.updateSecret()` executes `UPDATE partner_secrets SET secret = :secret, updated_at = now(), version = :version, digest = :digest WHERE partner = :partner`.
   - From: `pams_secretDao`
   - To: `continuumPartnerAttributesMappingPostgres`
   - Protocol: JDBI / PostgreSQL

5. **Returns UpdateSecretResponse**: HTTP 200 with an `UpdateSecretResponse` confirming the partner name. The registry is not explicitly refreshed on update (unlike generate); the in-memory registry retains the previous secret until the next refresh or restart.
   - From: `pams_apiResources`
   - To: Operator
   - Protocol: REST / HTTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Missing `client-id` header | `HeadersValidationFilter` | HTTP 403 |
| Invalid or blank partner name | `BadRequestException` in `createSecret()` | HTTP 400 with `ErrorResponse` |
| Invalid request payload format | `JsonParsingExceptionMapper` | HTTP 400 |
| Database insert fails (e.g., duplicate partner) | `JdbiExceptionMapper` | HTTP 500 |
| Database unavailable | JDBI exception propagates | HTTP 500 |

## Sequence Diagram

```
Operator -> pams_requestFilters: POST /v1/partners/{name}/secrets/generate (client-id, body)
pams_requestFilters -> pams_apiResources: Validated and logged request
pams_apiResources -> pams_secretService: createSecret(request, partner_name)
pams_secretService -> pams_secretDao: create(PartnerSecret)
pams_secretDao -> continuumPartnerAttributesMappingPostgres: INSERT INTO partner_secrets
continuumPartnerAttributesMappingPostgres --> pams_secretDao: OK
pams_secretDao --> pams_secretService: OK
pams_secretService --> pams_apiResources: GenerateSecretResponse
pams_apiResources -> pams_partnerRegistry: refreshedPartnersConfigs()
pams_partnerRegistry -> pams_secretDao: getAllPartnerSecrets()
pams_secretDao -> continuumPartnerAttributesMappingPostgres: SELECT * FROM partner_secrets
continuumPartnerAttributesMappingPostgres --> pams_secretDao: All secret rows
pams_secretDao --> pams_partnerRegistry: List<PartnerSecret>
pams_partnerRegistry --> pams_apiResources: Registry refreshed
pams_apiResources --> Operator: HTTP 200 GenerateSecretResponse
```

## Related

- Related flows: [Signature Creation Flow](signature-creation-flow.md), [Signature Validation Flow](signature-validation-flow.md)
- See [API Surface](../api-surface.md) for full endpoint documentation
- See [Data Stores](../data-stores.md) for `partner_secrets` table schema
