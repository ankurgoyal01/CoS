---
service: "deploybot"
title: "Config Validation Only"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "config-validation-only"
flow_type: synchronous
trigger: "POST /v1/validate with a .deploy_bot.yml payload"
participants:
  - "deploybotApi"
  - "deploybotValidator"
  - "externalDeploybotDatabase_43aa"
architecture_ref: "dynamic-deploybot-config-validate"
---

# Config Validation Only

## Summary

The config validation flow provides a dry-run mechanism for verifying that a `.deploy_bot.yml` configuration file is syntactically and semantically valid without triggering an actual deployment. This is used by service owners and CI pipelines to validate deployment configuration changes before merging. The endpoint returns a pass/fail result with a list of any validation errors found in the configuration file.

## Trigger

- **Type**: api-call
- **Source**: Engineer or CI system via `POST /v1/validate` with HTTP Basic Auth
- **Frequency**: On-demand (typically on pull request or config change)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Caller (engineer or CI) | Submits `.deploy_bot.yml` content for validation | external |
| `deploybotApi` | Receives and authenticates request; dispatches to validator | `deploybotApi` |
| `deploybotValidator` | Parses and validates `.deploy_bot.yml` schema and semantic rules | `deploybotValidator` |
| MySQL | May record validation attempt for audit purposes | `externalDeploybotDatabase_43aa` |

## Steps

1. **Receives validation request**: Caller POSTs to `POST /v1/validate` with HTTP Basic Auth and a JSON body containing the `.deploy_bot.yml` content (or a reference to it).
   - From: Caller
   - To: `deploybotApi`
   - Protocol: REST (HTTPS)

2. **Authenticates caller**: `deploybotApi` validates HTTP Basic Auth credentials.
   - From: `deploybotApi`
   - To: `deploybotApi` (internal credential check)
   - Protocol: internal

3. **Parses `.deploy_bot.yml`**: `deploybotValidator` parses the submitted configuration file against the v1 or v2 schema (auto-detected from content).
   - From: `deploybotValidator`
   - To: `deploybotValidator` (internal schema validation)
   - Protocol: internal

4. **Validates schema**: `deploybotValidator` checks that all required fields are present, types are correct, and enum values are valid per the `.deploy_bot.yml` schema version.
   - From: `deploybotValidator`
   - To: `deploybotValidator`
   - Protocol: internal

5. **Validates semantic rules**: `deploybotValidator` checks that referenced environments, deploy commands, promotion chains, and gate configurations are internally consistent.
   - From: `deploybotValidator`
   - To: `deploybotValidator`
   - Protocol: internal

6. **Returns validation result**: `deploybotApi` returns HTTP 200 with validation pass/fail status and a list of any errors or warnings.
   - From: `deploybotApi`
   - To: Caller
   - Protocol: REST (HTTPS)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Invalid HTTP Basic Auth credentials | Return HTTP 401 | Request rejected; no validation performed |
| Missing or empty config body | Return HTTP 400 | Request rejected with error |
| Schema validation errors | Return HTTP 200 with error list | Validation fails; errors returned to caller |
| Semantic validation errors | Return HTTP 200 with warning/error list | Caller can review and fix configuration |
| Unknown schema version | Return HTTP 400 or validation error | Caller must use v1 or v2 schema format |

## Sequence Diagram

```
Caller          -> deploybotApi:       POST /v1/validate (Basic Auth, .deploy_bot.yml content)
deploybotApi    -> deploybotApi:       Validate credentials
deploybotApi    -> deploybotValidator: Parse and validate .deploy_bot.yml
deploybotValidator -> deploybotValidator: Schema validation (v1/v2)
deploybotValidator -> deploybotValidator: Semantic rule validation
deploybotValidator --> deploybotApi:   Validation result (pass/fail, error list)
deploybotApi    --> Caller:            200 OK (validation result JSON)
```

## Related

- Architecture dynamic view: `dynamic-deploybot-config-validate`
- Related flows: [Webhook-Triggered Deployment](webhook-triggered-deployment.md), [Manual API Deploy](manual-api-deploy.md), [Deployment Validation Pipeline](deployment-validation-pipeline.md)
