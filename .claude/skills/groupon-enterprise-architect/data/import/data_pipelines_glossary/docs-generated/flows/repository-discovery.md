---
service: "data_pipelines_glossary"
title: "Repository Discovery"
generated: "2026-03-03"
type: flow
flow_name: "repository-discovery"
flow_type: synchronous
trigger: "Engineer navigates to the Data Pipelines Glossary site to locate a workflow repository"
participants:
  - "dataPipelinesGlossary"
architecture_ref: "data_pipelines_glossary_container"
---

# Repository Discovery

## Summary

The Repository Discovery flow describes how a data engineer or platform team member uses the Data Pipelines Glossary to locate the correct workflow repository for a given data pipeline concern. The engineer arrives at the static site, browses or searches the glossary index, and follows navigation links to the target repository. The glossary acts as the sole discovery mechanism; no runtime service calls are involved.

## Trigger

- **Type**: user-action
- **Source**: Engineer navigates to the Data Pipelines Glossary static site URL
- **Frequency**: On demand, as needed by data engineers and platform team members

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Data Pipelines Glossary | Serves the navigational index of workflow repositories | `dataPipelinesGlossary` |
| Engineer (human) | Browses the glossary to find the relevant pipeline repository | N/A (person actor) |
| Target Workflow Repository | Destination reached after navigation; owns the actual pipeline logic | External to this container |

## Steps

1. **Arrives at glossary**: Engineer opens the Data Pipelines Glossary static site in a browser.
   - From: Engineer browser
   - To: `dataPipelinesGlossary`
   - Protocol: HTTP/HTTPS (static file serving)

2. **Browses index**: Engineer reads the glossary index to identify the domain area relevant to their pipeline concern.
   - From: `dataPipelinesGlossary`
   - To: Engineer browser
   - Protocol: Static HTML/page render

3. **Follows navigation link**: Engineer clicks the link corresponding to the target workflow repository.
   - From: `dataPipelinesGlossary`
   - To: Target workflow repository (external)
   - Protocol: Browser redirect (hyperlink)

4. **Reaches target repository**: Engineer lands on the correct workflow repository and can access pipeline code, documentation, and ownership information.
   - From: Target workflow repository
   - To: Engineer browser
   - Protocol: HTTP/HTTPS

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Glossary site is unreachable | Engineer contacts grpn-gcloud-data-pipelines team; no automated fallback | Blocked until site is restored |
| Target repository link is broken or outdated | Engineer reports stale link; content owner updates the glossary via pull request | Link repaired in next deployment |
| Target repository does not exist | Engineer contacts grpn-gcloud-data-pipelines team for guidance | Manual resolution by platform team |

## Sequence Diagram

```
Engineer -> dataPipelinesGlossary: Opens glossary site (HTTP/HTTPS)
dataPipelinesGlossary --> Engineer: Returns navigational index (static HTML)
Engineer -> dataPipelinesGlossary: Clicks link to workflow repository
dataPipelinesGlossary --> Engineer: Browser redirects to target repository URL
Engineer -> TargetWorkflowRepository: Accesses workflow repository
TargetWorkflowRepository --> Engineer: Returns repository content
```

## Related

- Architecture dynamic view: `data_pipelines_glossary_container`
- Related flows: [Content Update](content-update.md)
