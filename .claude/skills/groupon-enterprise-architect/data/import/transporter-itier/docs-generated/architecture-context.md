---
service: "transporter-itier"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumTransporterItierWeb"]
---

# Architecture Context

## System Context

Transporter I-Tier is a container within `continuumSystem` (Continuum Platform). It is an internal-only web portal accessed by Groupon employees via browser. It sits at the boundary between internal browser clients and the `transporter-jtier` backend service, which owns all Salesforce connectivity and job persistence. For authentication, the service redirects unauthenticated users to Salesforce OAuth2 login and handles the resulting callback. The service is fronted by Groupon's Hybrid Boundary ingress and is reachable at internal DNS names `transporter-itier.production.service` and `transporter-itier.staging.service`.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Transporter I-Tier Web | `continuumTransporterItierWeb` | WebApp | Node.js (ITier) | ^16.13.0 | Internal ITier web application for bulk Salesforce data operations via CSV upload and read-only Salesforce data browsing. |

## Components by Container

### Transporter I-Tier Web (`continuumTransporterItierWeb`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| UI Routes and Views (`transporterItier_webUi`) | Renders server-side HTML pages for the upload form, paginated job list, job description detail, and Salesforce read-only object browser. Dispatches requests to module-specific action handlers. | Preact, phy, itier-routing |
| JTIER Upload Proxy (`uploadProxy`) | Receives multipart CSV uploads from the browser, buffers the file in memory, and streams the binary payload to `transporter-jtier /v0/upload` over plain HTTP with Salesforce operation parameters as query strings. | multer, Node.js `http` module |
| JTIER Client (`jtierClient`) | HTTP client that calls transporter-jtier API endpoints: user validation (`/validUser`), user info (`/userInfo`), upload listing (`/getUploads`), job detail (`/getUploadsById`), AWS file retrieval (`/getAWSFile`), Salesforce object list (`/sfObjects`), Salesforce object record (`/getSfObject`), and OAuth code exchange (`/auth`). | gofer |
| Salesforce OAuth Handler (`salesforceOAuth`) | Reads Salesforce client credentials from a mounted YAML secrets file, constructs an OAuth2 authorization URL via jsforce, and redirects unauthenticated users to Salesforce login. Handles the `/oauth2/callback` response by forwarding the authorization code to jtier for token exchange. | jsforce, itier-routing |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumTransporterItierWeb` | `salesForce` | Redirects users to Salesforce OAuth login for authentication. | HTTPS/OAuth2 |
| `transporterItier_webUi` | `jtierClient` | Fetches upload list, job details, and user data for page rendering. | HTTP |
| `uploadProxy` | `jtierClient` | Streams CSV binary payload to jtier upload API. | HTTP |
| `salesforceOAuth` | `jtierClient` | Validates users and exchanges OAuth authorization code. | HTTP |
| `continuumTransporterItierWeb` | `transporterJtierSystem_7f3a2c` | Uploads CSVs, validates users, and fetches all job and Salesforce data. | HTTP |

## Architecture Diagram References

- System context: `contexts-continuumSystem`
- Container: `containers-continuumTransporterItierWeb`
- Component: `components-continuumTransporterItierWeb`
- Dynamic view (upload flow): `dynamic-upload-flow`
