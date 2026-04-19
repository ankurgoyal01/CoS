---
service: "seo-deal-api"
title: "Deal SEO Attribute Update"
generated: "2026-03-03"
type: flow
flow_name: "deal-seo-attribute-update"
flow_type: synchronous
trigger: "PUT /seodeals/deals/{dealId}/edits/attributes called by seo-admin-ui"
participants:
  - "seo-admin-ui"
  - "continuumSeoDealApiService"
  - "seoDealApi_apiResources"
  - "orchestrator"
  - "seoDataDao"
  - "continuumSeoDealPostgres"
  - "indexNowClient"
  - "seoDealApi_jiraClient"
architecture_ref: "components-seoDealApiServiceComponents"
---

# Deal SEO Attribute Update

## Summary

When an SEO analyst edits deal attributes in the `seo-admin-ui` admin console, the console calls one of the attribute update endpoints on SEO Deal API. The service validates and persists the new attributes to its PostgreSQL database, and optionally triggers downstream actions such as submitting URL updates to IndexNow and creating a Jira issue for tracking. This flow covers single attribute updates (PUT `/edits/attributes`), canonical URL updates (PUT `/edits/canonical`), and targeted redirect URL updates (PUT `/edits/attributes/redirectUrl`).

## Trigger

- **Type**: api-call
- **Source**: `seo-admin-ui` DealServerClient (`updateAttributes`, `editCanonical`, `cancelDealRedirect`) — initiated by an SEO analyst action in the admin UI
- **Frequency**: On-demand, per admin console attribute save action

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| `seo-admin-ui` | Initiates the attribute update request | External consumer |
| `continuumSeoDealApiService` | Receives and processes the update request | `continuumSeoDealApiService` |
| API Resources (`seoDealApi_apiResources`) | Handles the inbound HTTP PUT request and routes to orchestrator and side-effect clients | `seoDealApi_apiResources` |
| Orchestrator (`orchestrator`) | Coordinates the write to the database | `orchestrator` |
| SEO Data DAO (`seoDataDao`) | Persists updated SEO attributes to PostgreSQL | `seoDataDao` |
| SEO Deal Database | Stores the updated SEO deal attributes | `continuumSeoDealPostgres` |
| IndexNow Client (`indexNowClient`) | Submits the updated URL to IndexNow for re-indexing | `indexNowClient` |
| Jira Client (`seoDealApi_jiraClient`) | Creates a Jira issue to track the SEO change | `seoDealApi_jiraClient` |

## Steps

1. **Receives attribute update request**: `seo-admin-ui` calls `PUT /seodeals/deals/{dealId}/edits/attributes?source=seo-admin-ui` with a JSON body containing the updated attributes
   - From: `seo-admin-ui`
   - To: `continuumSeoDealApiService`
   - Protocol: REST/HTTP

2. **Routes to API Resources**: The Dropwizard/JAX-RS router dispatches the request to the API Resources component
   - From: `continuumSeoDealApiService`
   - To: `seoDealApi_apiResources`
   - Protocol: Direct (in-process)

3. **Delegates to Orchestrator**: API Resources delegates the persistence operation to the Orchestrator
   - From: `seoDealApi_apiResources`
   - To: `orchestrator`
   - Protocol: Direct (in-process)

4. **Reads current SEO data**: Orchestrator reads current attributes via SEO Data DAO before applying the update
   - From: `orchestrator`
   - To: `seoDataDao` -> `continuumSeoDealPostgres`
   - Protocol: JDBC/SQL

5. **Writes updated attributes**: SEO Data DAO persists the new attribute values to PostgreSQL
   - From: `seoDataDao`
   - To: `continuumSeoDealPostgres`
   - Protocol: JDBC/SQL

6. **Submits URL update to IndexNow**: API Resources calls the IndexNow Client to notify search engines of the URL change
   - From: `seoDealApi_apiResources`
   - To: `indexNowClient` -> `indexNowService`
   - Protocol: REST/HTTP

7. **Creates Jira issue**: API Resources calls the Jira Client to create a tracking issue for the attribute change
   - From: `seoDealApi_apiResources`
   - To: `seoDealApi_jiraClient` -> `continuumJiraService`
   - Protocol: REST/HTTP

8. **Returns updated SEO data**: API Resources serializes the updated deal SEO response and returns HTTP 200 with the current state (including `seoData.brands.groupon.attributes`)
   - From: `continuumSeoDealApiService`
   - To: `seo-admin-ui`
   - Protocol: REST/HTTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Database write failure | Not specified in available evidence | HTTP 500 returned |
| IndexNow submission failure | Non-critical; evidenced as a side-effect call | Attribute write succeeds; search engine notification delayed |
| Jira issue creation failure | Non-critical; evidenced as a side-effect call | Attribute write succeeds; tracking issue not created |
| Missing `dealId` | Return error response | `seo-admin-ui` returns `{ error: true, msg: 'You must provide dealId value' }` |
| Missing `attributes` | Return error response | `seo-admin-ui` returns `{ error: true, msg: 'You must provide attributes value' }` |

## Sequence Diagram

```
seo-admin-ui -> continuumSeoDealApiService: PUT /seodeals/deals/{dealId}/edits/attributes?source=seo-admin-ui
continuumSeoDealApiService -> seoDealApi_apiResources: Route request
seoDealApi_apiResources -> orchestrator: Delegate write orchestration
orchestrator -> seoDataDao: Read current attributes
seoDataDao -> continuumSeoDealPostgres: SQL SELECT by deal UUID
continuumSeoDealPostgres --> seoDataDao: Current SEO data
orchestrator -> seoDataDao: Write updated attributes
seoDataDao -> continuumSeoDealPostgres: SQL UPDATE/INSERT attributes
continuumSeoDealPostgres --> seoDataDao: Write confirmed
seoDataDao --> orchestrator: Updated attributes
orchestrator --> seoDealApi_apiResources: Write result
seoDealApi_apiResources -> indexNowClient: Submit URL update
indexNowClient -> indexNowService: POST updated URL
seoDealApi_apiResources -> seoDealApi_jiraClient: Create Jira issue
seoDealApi_jiraClient -> continuumJiraService: POST new issue
seoDealApi_apiResources --> seo-admin-ui: HTTP 200 JSON { seoData: { brands: { groupon: { attributes: {...} } } } }
```

## Related

- Architecture dynamic view: `components-seoDealApiServiceComponents`
- Related flows: [Deal SEO Attribute Read](deal-seo-attribute-read.md), [Automated Redirect Upload](automated-redirect-upload.md)
