---
service: "transporter-itier"
title: "Salesforce Read-Only View Flow"
generated: "2026-03-03"
type: flow
flow_name: "salesforce-readonly-view-flow"
flow_type: synchronous
trigger: "User navigates to /sfdata or submits a Salesforce object and record ID lookup"
participants:
  - "continuumTransporterItierWeb"
  - "transporterItier_webUi"
  - "jtierClient"
  - "transporterJtierSystem_7f3a2c"
architecture_ref: "dynamic-upload-flow"
---

# Salesforce Read-Only View Flow

## Summary

The Salesforce read-only view (`/sfdata`) allows internal users to browse and inspect Salesforce object data without performing any modifications. The service fetches the list of available Salesforce object types from `transporter-jtier` and presents a dropdown selector. When the user provides a Salesforce object name and record ID, the service fetches the specific record via jtier and renders a read-only detail view. If no object ID is specified, only the home page with the object selector is shown.

## Trigger

- **Type**: user-action
- **Source**: User navigates to `/sfdata` (home view) or `/sfdata/{object}/{objectId}` (record detail), or submits the object search form
- **Frequency**: On demand

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Browser | Initiates page requests with optional object and objectId path parameters | (external) |
| UI Routes and Views | Handles GET `/sfdata` and GET `/sfdata/{object}/{objectId}`; renders home or detail view | `transporterItier_webUi` |
| JTIER Client | Calls jtier to list Salesforce object types and fetch specific object records | `jtierClient` |
| transporter-jtier | Provides the list of Salesforce object types and individual record data from Salesforce | `transporterJtierSystem_7f3a2c` |

## Steps

1. **User navigates to `/sfdata`**: Browser sends GET request. Optional query parameters `object` and `objectId` may be included from form submission.
   - From: `Browser`
   - To: `continuumTransporterItierWeb GET /sfdata` or `GET /sfdata/{object}/{objectId}`
   - Protocol: HTTPS

2. **Identify current user**: The `sf_readonly_page` action extracts the username from the `x-grpn-username` request header via `getUsername`. An `itier-tracing` instant event is logged with username and params.
   - From: `transporterItier_webUi`
   - To: Local (header extraction + trace log)
   - Protocol: Internal

3. **Fetch Salesforce object list**: The action calls jtier to retrieve all available Salesforce object types.
   - From: `jtierClient`
   - To: `transporter-jtier GET /sfObjects`
   - Protocol: HTTP

4. **jtier returns object list**: jtier responds with an array of Salesforce object descriptors (each with `name` and `label` fields). On error, jtier traces `Error fetching SF objects`.
   - From: `transporter-jtier`
   - To: `jtierClient`
   - Protocol: HTTP (JSON)

5. **Sort and format object list**: Objects are sorted alphabetically by label and mapped to `{ label, value }` format for the dropdown selector.
   - From: `transporterItier_webUi`
   - To: Local
   - Protocol: Internal

6. **Fetch specific record (conditional)**: If both `object` and `objectId` parameters are present, the action calls jtier to fetch the specific Salesforce record.
   - From: `jtierClient`
   - To: `transporter-jtier GET /getSfObject?sfObjectName=<object>&sfObjectId=<objectId>&user=<username>`
   - Protocol: HTTP

7. **jtier returns Salesforce record**: jtier returns the Salesforce SOQL query result including record fields and metadata. If the record is not found (`records.length === 0`), an error message is set.
   - From: `transporter-jtier`
   - To: `jtierClient`
   - Protocol: HTTP (JSON — Salesforce SOQL result format)

8. **Render view**: The server renders one of two Preact components:
   - If a valid record was found: `SFROObject` — a detail view with the object type as title and record fields
   - Otherwise: `SFROHome` — the home view with the object selector dropdown, any error message, and current input values
   - From: `continuumTransporterItierWeb`
   - To: `Browser`
   - Protocol: HTTPS (HTML response)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| jtier `/sfObjects` unavailable | `try/catch` sets `errorMessage` from caught error | `SFROHome` is rendered with error message displayed |
| jtier `/getSfObject` unavailable | `try/catch` sets `errorMessage` | `SFROHome` is rendered with error message; no object detail shown |
| Record not found (`records.length === 0`) | Explicit check sets `errorMessage = "Record with ID <id> not present in <object>"` | `SFROHome` rendered with descriptive error message |
| jtier traces fetch errors | `itier-tracing` logs error with object name and ID | Logged to ELK; surface in Kibana via `sf-readonly-home` trace source |
| Missing object or objectId params | Conditional block skips the `getSfObject` call | `SFROHome` renders without error; user can enter search criteria |

## Sequence Diagram

```
Browser                 -> transporter-itier-web (GET /sfdata): Load SF readonly home
transporter-itier-web   -> transporter-jtier (GET /sfObjects): List Salesforce object types
transporter-jtier       --> transporter-itier-web: [ { name, label }, ... ]
transporter-itier-web   -> transporter-itier-web: Sort objects alphabetically by label
transporter-itier-web   --> Browser: Render SFROHome (object selector dropdown)
Browser (user)          -> transporter-itier-web (GET /sfdata/Opportunity/0068000000NDeLiAAL): Lookup record
transporter-itier-web   -> transporter-jtier (GET /sfObjects): Refresh object list
transporter-jtier       --> transporter-itier-web: Object list
transporter-itier-web   -> transporter-jtier (GET /getSfObject?sfObjectName=Opportunity&sfObjectId=0068000...&user=<u>): Fetch record
transporter-jtier       --> transporter-itier-web: { totalSize: 1, done: true, records: [...] }
transporter-itier-web   -> transporter-itier-web: Check records.length > 0
transporter-itier-web   --> Browser: Render SFROObject (record detail view)
```

## Related

- Architecture dynamic view: `dynamic-upload-flow`
- Related flows: [Job List and Pagination Flow](job-list-pagination-flow.md), [Salesforce OAuth Login Flow](salesforce-oauth-login-flow.md)
- [Flows Index](index.md)
