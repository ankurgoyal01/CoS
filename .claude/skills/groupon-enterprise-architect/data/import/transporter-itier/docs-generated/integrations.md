---
service: "transporter-itier"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 1
internal_count: 1
---

# Integrations

## Overview

Transporter I-Tier has two dependencies: one external system (Salesforce, for OAuth2 login redirect only) and one internal service (transporter-jtier, for all backend data operations). All Salesforce interaction is limited to the OAuth2 authorization redirect — no direct Salesforce data API calls are made by this service. Transporter-jtier is the single backend for all data operations and is called via HTTP using the `gofer` client.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Salesforce | HTTPS/OAuth2 | OAuth2 login redirect for user authentication | yes | `salesForce` |

### Salesforce Detail

- **Protocol**: HTTPS, OAuth2 authorization code grant flow
- **Base URL / SDK**: `https://login.salesforce.com` (production), `https://groupon-dev--staging.my.salesforce.com` (staging) — configured in `config/stage/*.cson` via `connectedApp.loginUrl`
- **Auth**: Client credentials (client ID and secret) are read from a YAML secrets file at the path specified by `config.secret.pathToSecret`. Credentials are stored Base64-encoded and decoded at runtime using `jsforce.OAuth2`.
- **Purpose**: When a user is not yet validated in jtier, the service constructs a Salesforce OAuth2 authorization URL and issues an HTTP redirect to the Salesforce login page. The OAuth2 redirect URI is `https://transporter.groupondev.com/oauth2/callback` (production) or `https://transporter-staging.groupondev.com/oauth2/callback` (staging), configured in `connectedApp.redirectUri`.
- **Failure mode**: If Salesforce OAuth login is unavailable, unauthenticated users cannot access any protected pages. Users already validated in jtier are unaffected since the validation check occurs before any Salesforce redirect.
- **Circuit breaker**: No — the OAuth redirect is a simple HTTP redirect; no network call is made to Salesforce by the I-Tier server itself.

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| transporter-jtier | HTTP | User validation, upload job listing, CSV upload, job details, S3 file retrieval, Salesforce object browsing, OAuth token exchange | `transporterJtierSystem_7f3a2c` |

### transporter-jtier Detail

- **Protocol**: HTTP (plain, not TLS) over internal service mesh; mTLS handled at the Hybrid Boundary level
- **Base URL**:
  - Production: `http://transporter-jtier.production.service/v0` (from `config/stage/production.cson`)
  - Staging: `http://transporter-jtier.staging.service/v0` (from `config/stage/staging.cson`)
  - Local (upload proxy middleware): `localhost:9000` when `DEPLOY_ENV` is not `staging` or `production`
- **Auth**: None — user identity is passed as the query parameter `user=<username>` extracted from the `x-grpn-username` header
- **Purpose**: All application data operations are delegated to jtier. The `gofer`-based `jtierClient` calls the following jtier endpoints:
  - `GET /validUser?user=<username>` — checks if the user is registered in jtier before granting upload access
  - `GET /userInfo?user=<username>` — retrieves user details
  - `GET /getUploads?pageIndex=&pageSize=&action=&object=&user=&status=` — returns a paginated, filtered list of upload jobs
  - `GET /getUploadsById?jobId=<id>` — retrieves detail for a single upload job
  - `GET /getAWSFile?filename=<key>` — streams an S3 file (source, success, or error CSV)
  - `POST /auth?code=<code>&user=<username>` — exchanges the Salesforce OAuth2 authorization code for a jtier session
  - `GET /sfObjects` — lists all available Salesforce object types
  - `GET /getSfObject?sfObjectName=&sfObjectId=&user=` — retrieves record fields for a single Salesforce object instance
  - `POST /v0/upload?user=&userInputFileName=&salesforceObject=&action=&batchSize=&inputFileRecords=` — receives the CSV binary for a bulk Salesforce operation (via the upload proxy middleware using raw Node.js `http`)
- **Failure mode**: If jtier is unavailable, all page renders that depend on jtier data return errors. The upload proxy returns the upstream HTTP error status to the browser. No fallback or cached data is provided.
- **Circuit breaker**: No explicit circuit breaker. The `gofer` client propagates errors directly.

## Consumed By

> Upstream consumers are tracked in the central architecture model.

Transporter I-Tier is accessed directly by internal Groupon employees via web browser. It is not called programmatically by other services.

## Dependency Health

- Check transporter-jtier availability: HTTP GET to `http://transporter-jtier.production.service/v0/validUser?user=healthcheck`
- Monitor Wavefront metrics for upstream HTTP error rates on the `transporter-itier` dashboard
- Review Kibana logs filtered on trace source `transporter-jtier-client` (emitted by `itier-tracing('transporter-jtier-client')` in `modules/common/jtier.js`)
- Check sf-readonly tracing errors via trace source `sf-readonly-home`
