---
service: "data_pipelines_glossary"
title: "Content Update"
generated: "2026-03-03"
type: flow
flow_name: "content-update"
flow_type: synchronous
trigger: "Pull request merged to the main branch of the data_pipelines_glossary repository"
participants:
  - "dataPipelinesGlossary"
architecture_ref: "data_pipelines_glossary_container"
---

# Content Update

## Summary

The Content Update flow describes how the Data Pipelines Glossary is updated when a contributor adds, modifies, or removes navigational entries or glossary content. A contributor opens a pull request with the content changes, the `grpn-gcloud-data-pipelines` team reviews and merges it, and the static site is republished to reflect the updated content. This is the primary maintenance flow for keeping the glossary accurate as the data platform evolves.

## Trigger

- **Type**: user-action
- **Source**: Contributor opens a pull request with content changes to the glossary repository
- **Frequency**: On demand, whenever data pipeline repositories are created, renamed, deprecated, or restructured

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Content Contributor | Authors the content change (new links, updated descriptions, removed entries) | N/A (person actor) |
| grpn-gcloud-data-pipelines Team | Reviews and approves pull request; owns content correctness | N/A (person actor) |
| Data Pipelines Glossary | Static site container that is rebuilt and republished after merge | `dataPipelinesGlossary` |

## Steps

1. **Identifies content gap**: Contributor recognises that a workflow repository is missing from, incorrectly described in, or has been removed from the glossary.
   - From: Contributor observation
   - To: N/A
   - Protocol: N/A

2. **Authors pull request**: Contributor edits the relevant content files in the repository and opens a pull request targeting the main branch.
   - From: Contributor
   - To: `data_pipelines_glossary` repository
   - Protocol: Git / GitHub pull request

3. **Reviews pull request**: The `grpn-gcloud-data-pipelines` team reviews the changes for accuracy, completeness, and link correctness.
   - From: grpn-gcloud-data-pipelines team reviewer
   - To: Pull request
   - Protocol: GitHub pull request review

4. **Merges pull request**: Reviewer approves and merges the pull request to the main branch.
   - From: grpn-gcloud-data-pipelines team reviewer
   - To: `data_pipelines_glossary` repository main branch
   - Protocol: Git merge

5. **Publishes updated site**: The static site is rebuilt and deployed from the updated main branch content.
   - From: CI/CD pipeline (details managed externally)
   - To: `dataPipelinesGlossary` (hosting environment)
   - Protocol: Static site deployment (details not discoverable from repository)

6. **Updated content available**: Engineers browsing the glossary see the new or corrected navigational entries.
   - From: `dataPipelinesGlossary`
   - To: Engineer browser
   - Protocol: HTTP/HTTPS

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Pull request contains incorrect links | Reviewer rejects changes and requests corrections before merge | Content remains accurate until correct change is merged |
| Deployment pipeline fails after merge | Platform team investigates externally managed CI/CD; no automated rollback defined in this repository | Site may temporarily serve stale content |
| Contributor lacks repository access | Contact grpn-gcloud-data-pipelines team to request write access | Contributor can re-submit once access is granted |

## Sequence Diagram

```
Contributor -> Repository: Opens pull request with content changes
Repository -> Team: Notifies reviewers (GitHub)
Team -> Repository: Reviews and approves pull request
Team -> Repository: Merges pull request to main branch
Repository -> CICDPipeline: Triggers static site rebuild (externally managed)
CICDPipeline -> dataPipelinesGlossary: Publishes updated static site
dataPipelinesGlossary --> Engineer: Serves updated content on next request
```

## Related

- Architecture dynamic view: `data_pipelines_glossary_container`
- Related flows: [Repository Discovery](repository-discovery.md)
