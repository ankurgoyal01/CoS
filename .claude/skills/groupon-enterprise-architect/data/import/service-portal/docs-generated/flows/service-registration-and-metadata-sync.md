---
service: "service-portal"
title: "Service Registration and Metadata Sync"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "service-registration-and-metadata-sync"
flow_type: synchronous
trigger: "API call — POST /api/v2/services followed by PUT /api/v2/services/{id}/metadata"
participants:
  - "continuumServicePortalWeb"
  - "continuumServicePortalDb"
  - "Google Directory"
---

# Service Registration and Metadata Sync

## Summary

An engineering team registers a new service in the Service Portal catalog by calling the REST API. The web process validates the request, resolves team ownership via Google Directory, persists the service record and its metadata to MySQL, and returns the created resource. The service is then visible in the catalog and eligible for governance checks.

## Trigger

- **Type**: api-call
- **Source**: Engineering team or automated tooling calling `POST /api/v2/services`
- **Frequency**: On-demand (each time a new service is registered or metadata is updated)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Engineering team / CI tool | Initiates registration via API | external caller |
| Rails Web App | Receives API request, validates payload, coordinates persistence | `continuumServicePortalWeb` |
| Google Directory | Resolves team ownership from Google Group membership | external system |
| MySQL Database | Persists service record and metadata | `continuumServicePortalDb` |

## Steps

1. **Receive registration request**: Engineering team sends `POST /api/v2/services` with service name, tier, and initial attributes.
   - From: Engineering team / CI tool
   - To: `continuumServicePortalWeb`
   - Protocol: HTTPS REST

2. **Validate payload**: Rails controller validates required fields (service name, tier, repository URL, owning team) and checks for duplicate service names.
   - From: `continuumServicePortalWeb`
   - To: `continuumServicePortalDb` (uniqueness check)
   - Protocol: MySQL query

3. **Resolve team ownership**: Web app looks up the provided team identifier against Google Directory to confirm group existence and retrieve member details.
   - From: `continuumServicePortalWeb`
   - To: Google Directory (Admin Directory API)
   - Protocol: HTTPS REST via `google-apis-admin_directory_v1`

4. **Persist service record**: Validated service record is written to the `services` table in MySQL.
   - From: `continuumServicePortalWeb`
   - To: `continuumServicePortalDb`
   - Protocol: MySQL (ActiveRecord)

5. **Return created resource**: HTTP 201 response with the created service record (JSON) is returned to the caller.
   - From: `continuumServicePortalWeb`
   - To: Engineering team / CI tool
   - Protocol: HTTPS REST

6. **Update metadata (optional follow-up)**: Caller sends `PUT /api/v2/services/{id}/metadata` to populate extended metadata (tech stack, links, contacts).
   - From: Engineering team / CI tool
   - To: `continuumServicePortalWeb`
   - Protocol: HTTPS REST

7. **Persist metadata**: Web app writes updated metadata to the `service_metadata` table.
   - From: `continuumServicePortalWeb`
   - To: `continuumServicePortalDb`
   - Protocol: MySQL (ActiveRecord)

8. **Return updated metadata**: HTTP 200 response with updated metadata returned to caller.
   - From: `continuumServicePortalWeb`
   - To: Engineering team / CI tool
   - Protocol: HTTPS REST

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Duplicate service name | Uniqueness validation fails before insert | HTTP 422 Unprocessable Entity with error details |
| Missing required fields | Rails model validation fails | HTTP 422 with field-level validation errors |
| Google Directory lookup failure | Ownership resolution fails | HTTP 503 or validation error; registration blocked if ownership is required |
| MySQL write failure | ActiveRecord exception raised | HTTP 500; error logged via sonoma-logger |

## Sequence Diagram

```
Engineering Team -> continuumServicePortalWeb: POST /api/v2/services
continuumServicePortalWeb -> continuumServicePortalDb: SELECT (duplicate check)
continuumServicePortalDb --> continuumServicePortalWeb: no duplicate found
continuumServicePortalWeb -> Google Directory: lookup team group
Google Directory --> continuumServicePortalWeb: group details
continuumServicePortalWeb -> continuumServicePortalDb: INSERT services record
continuumServicePortalDb --> continuumServicePortalWeb: record created
continuumServicePortalWeb --> Engineering Team: 201 Created (service JSON)
Engineering Team -> continuumServicePortalWeb: PUT /api/v2/services/{id}/metadata
continuumServicePortalWeb -> continuumServicePortalDb: UPDATE service_metadata
continuumServicePortalDb --> continuumServicePortalWeb: metadata updated
continuumServicePortalWeb --> Engineering Team: 200 OK (metadata JSON)
```

## Related

- Architecture dynamic view: `dynamic-service-registration`
- Related flows: [GitHub Repository Validation and Sync](github-repository-validation-and-sync.md), [Scheduled Service Checks Execution](scheduled-service-checks-execution.md)
