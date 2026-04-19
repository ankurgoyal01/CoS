---
service: "booster"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: ["rest"]
auth_mechanisms: ["api-key"]
---

# API Surface

## Overview

Booster exposes a relevance and ranking API consumed by Groupon's `continuumRelevanceApi` on the critical consumer request path. The API is called over HTTPS and returns ranked deal recommendations. The integration contract is modeled as the `boosterSvc_apiContract` component within `continuumBoosterService`.

Booster is an external SaaS operated by Data Breakers. Specific endpoint paths, request/response schemas, and authentication mechanisms are defined in the vendor-provided API contract and are not discoverable from this repository's source code. Refer to vendor documentation for full API specification details.

## Endpoints

> No evidence found in codebase. Booster API endpoint paths are defined by the vendor (Data Breakers) and are referenced in the Confluence documentation at:
> https://groupondev.atlassian.net/wiki/spaces/RAPI/pages/80466641012/Data+Breakers+-+Booster

## Request/Response Patterns

### Common headers

> No evidence found in codebase. Refer to the Booster API Contract component (`boosterSvc_apiContract`) and vendor documentation.

### Error format

> No evidence found in codebase. Error handling behavior is governed by the vendor API contract.

### Pagination

> No evidence found in codebase. Pagination strategy is vendor-managed.

## Rate Limits

> No evidence found in codebase. Rate limiting terms are governed by the vendor agreement with Data Breakers.

## Versioning

> No evidence found in codebase. API versioning strategy is vendor-managed by Data Breakers.

## OpenAPI / Schema References

- Vendor documentation: https://groupondev.atlassian.net/wiki/spaces/RAPI/pages/80466641012/Data+Breakers+-+Booster#Overview
- Architecture model: `boosterSvc_apiContract` component within `continuumBoosterService`
