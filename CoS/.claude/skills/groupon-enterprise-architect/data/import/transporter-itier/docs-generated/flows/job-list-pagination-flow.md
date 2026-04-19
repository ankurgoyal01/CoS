---
service: "transporter-itier"
title: "Job List and Pagination Flow"
generated: "2026-03-03"
type: flow
flow_name: "job-list-pagination-flow"
flow_type: synchronous
trigger: "User loads the / home page or changes page number or filter state"
participants:
  - "continuumTransporterItierWeb"
  - "transporterItier_webUi"
  - "jtierClient"
  - "transporterJtierSystem_7f3a2c"
architecture_ref: "dynamic-upload-flow"
---

# Job List and Pagination Flow

## Summary

The home page (`/`) of Transporter I-Tier displays a paginated list of Salesforce bulk upload jobs. When the user loads the page, the server fetches a page of upload records from `transporter-jtier` using the jtier client and renders an HTML table. When the user changes the page or applies filters (action, object, user, status), the browser fetches updated data from the `/page-num` endpoint, which returns JSON for client-side rendering.

## Trigger

- **Type**: user-action
- **Source**: User navigates to `/` or interacts with pagination/filter controls
- **Frequency**: On demand, per page navigation or filter change

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Browser | Requests the home page; triggers AJAX pagination calls | (external) |
| UI Routes and Views | Handles GET `/` initial render and GET `/page-num` AJAX endpoint | `transporterItier_webUi` |
| JTIER Client | Fetches paginated upload records from jtier | `jtierClient` |
| transporter-jtier | Provides paginated upload job data from its data store | `transporterJtierSystem_7f3a2c` |

## Steps

1. **User loads home page**: Browser sends GET `/` with optional query parameters (`page`, `pageSize`, `action`, `object`, `user`, `status`).
   - From: `Browser`
   - To: `continuumTransporterItierWeb GET /`
   - Protocol: HTTPS

2. **Fetch user info**: The form module action calls jtier to retrieve user information for the current user (from `x-grpn-username` header).
   - From: `jtierClient`
   - To: `transporter-jtier GET /userInfo?user=<username>`
   - Protocol: HTTP

3. **Fetch paginated upload jobs**: The form module calls jtier with pagination and filter parameters. Page index is zero-based (page param minus 1). Default page size is 10.
   - From: `jtierClient`
   - To: `transporter-jtier GET /getUploads?pageIndex=<n>&pageSize=<s>&action=<a>&object=<o>&user=<u>&status=<st>`
   - Protocol: HTTP

4. **jtier returns job data**: jtier returns a JSON structure containing `map.data.myArrayList` (array of job records) and `map.count` (total job count for pagination).
   - From: `transporter-jtier`
   - To: `jtierClient`
   - Protocol: HTTP (JSON)

5. **Render job list page**: The server renders an HTML page with the Form Preact component, passing upload records, total count, current page, and filter state as props.
   - From: `continuumTransporterItierWeb`
   - To: `Browser`
   - Protocol: HTTPS (HTML response)

6. **User changes page or filter** (AJAX path): The browser sends GET `/page-num` with updated query parameters.
   - From: `Browser`
   - To: `continuumTransporterItierWeb GET /page-num`
   - Protocol: HTTPS

7. **Fetch updated page from jtier**: The `getPageUploadInfo` handler calls jtier with the new page index and filter parameters.
   - From: `jtierClient`
   - To: `transporter-jtier GET /getUploads?pageIndex=<n>&...`
   - Protocol: HTTP

8. **Return JSON to browser**: The server returns the jtier JSON payload directly to the browser for client-side rendering.
   - From: `continuumTransporterItierWeb`
   - To: `Browser`
   - Protocol: HTTPS (JSON)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| jtier `/getUploads` unavailable | `gofer` Promise rejects | 500 error page rendered by itier-error-page |
| jtier `/userInfo` unavailable | `gofer` Promise rejects | 500 error; page does not render |
| Invalid page or pageSize parameter | Defaults applied: `num = 0`, `pageSize = 10` | First page rendered with default size |
| undefined filter parameters | Defaults to empty string filters (no filter applied) | All records returned |

## Sequence Diagram

```
Browser               -> transporter-itier-web (GET /?page=1&pageSize=10): Load home page
transporter-itier-web -> transporter-jtier (GET /userInfo?user=<u>): Get user info
transporter-jtier     --> transporter-itier-web: User info JSON
transporter-itier-web -> transporter-jtier (GET /getUploads?pageIndex=0&pageSize=10): Fetch jobs
transporter-jtier     --> transporter-itier-web: { map: { data: { myArrayList: [...] }, count: N } }
transporter-itier-web --> Browser: Render HTML job list (server-side Preact)
Browser (user)        -> transporter-itier-web (GET /page-num?page=2&pageSize=10): Next page
transporter-itier-web -> transporter-jtier (GET /getUploads?pageIndex=2&pageSize=10): Fetch page 2
transporter-jtier     --> transporter-itier-web: Updated job page JSON
transporter-itier-web --> Browser: JSON job data for client-side render
```

## Related

- Architecture dynamic view: `dynamic-upload-flow`
- Related flows: [CSV Upload Flow](csv-upload-flow.md), [Salesforce OAuth Login Flow](salesforce-oauth-login-flow.md)
- [Flows Index](index.md)
