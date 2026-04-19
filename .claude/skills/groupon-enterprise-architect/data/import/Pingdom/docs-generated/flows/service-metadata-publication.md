---
service: "pingdom"
title: "Service Metadata Publication"
generated: "2026-03-03"
type: flow
flow_name: "service-metadata-publication"
flow_type: event-driven
trigger: "Daily architecture federation sync from central architecture repository"
participants:
  - "pingdomServicePortal"
  - "continuumSystem"
architecture_ref: "dynamic-pingdom-metadata-publication"
---

# Service Metadata Publication

## Summary

The Service Metadata Publication flow is the mechanism by which the Pingdom service's ownership, SRE contacts, documentation links, and monitoring endpoint definitions are made available to the central Groupon architecture model. The `metadataPublisher` component within `pingdomServicePortal` maintains the `.service.yml` and architecture DSL files; the central `architecture` repository's daily federation sync (`pull-federated-architecture` GitHub Actions workflow) pulls these files into `structurizr/import/Pingdom/` and makes them available to all consumers of the architecture model.

## Trigger

- **Type**: event-driven / schedule
- **Source**: GitHub Actions `pull-federated-architecture` workflow in the central `architecture` repository; runs daily at 02:00 UTC and on manual dispatch
- **Frequency**: Daily (automated) + on-demand (manual)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Pingdom repository (`Pingdom` git repo) | Source of truth for service metadata (`.service.yml`) and architecture DSL files | `pingdomServicePortal` |
| `metadataPublisher` component | Maintains service metadata definitions that are read by the federation sync | `pingdomServicePortal` |
| `monitoringLinkResolver` component | Maintains Pingdom status and dashboard link definitions in the architecture model | `pingdomServicePortal` |
| Central `architecture` repository | Pulls federated files; imports into `structurizr/import/Pingdom/`; validates and publishes the unified architecture model | `continuumSystem` |
| Groupon service-portal / internal tooling | Consumes published metadata for operational review workflows | Internal tooling |

## Steps

1. **Commit metadata update**: A developer or automated process updates `.service.yml` or architecture DSL files in the Pingdom repository on the `master` branch.
   - From: Developer / automation
   - To: Pingdom git repository
   - Protocol: Git push

2. **Federation sync triggers**: The `pull-federated-architecture` workflow in the central `architecture` repository runs on schedule or manual dispatch.
   - From: GitHub Actions scheduler
   - To: `pull-federated-architecture` workflow
   - Protocol: GitHub Actions event

3. **Clone/pull Pingdom repository**: The federation workflow clones or pulls the Pingdom repository (configured in `.github/architecture-sources.yml`) into `structurizr/import-staging/Pingdom/`.
   - From: `pull-federated-architecture` workflow
   - To: Pingdom git repository
   - Protocol: Git (HTTPS)

4. **Copy to import directory**: The workflow copies the staged files to `structurizr/import/Pingdom/`, making the architecture DSL and metadata available to the Structurizr workspace.
   - From: `pull-federated-architecture` workflow
   - To: `structurizr/import/Pingdom/`
   - Protocol: File system copy

5. **Validate DSL**: The central `architecture` CI pipeline runs `validate.sh` / `validate.ps1` against the updated workspace, which includes the Pingdom DSL files.
   - From: CI pipeline (`architecture-docs.yml` workflow)
   - To: Structurizr CLI
   - Protocol: Docker / CLI execution

6. **Export and publish**: On the `main` branch, the pipeline exports diagrams (PlantUML, Mermaid, PNG, SVG) and publishes the updated architecture model to Confluence.
   - From: CI pipeline
   - To: Confluence (`https://confluence.groupondev.com/display/GSOC/Pingdom`)
   - Protocol: Confluence REST API

7. **Resolve monitoring links**: The `monitoringLinkResolver` component's DSL definitions (`status_endpoint: disabled: true`) and SRE dashboard references (`https://status.pingdom.com/`) are incorporated into the published model and made available to internal tooling.
   - From: Published architecture model
   - To: Internal tooling (service-portal, operational review workflows)
   - Protocol: Architecture model reference

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| DSL validation fails | CI pipeline fails; changes not merged to `main` | Architecture model not updated; PR blocked |
| Federation sync cannot reach Pingdom repository | Workflow logs error; existing imported files remain unchanged | Stale metadata in architecture model until next successful sync |
| Confluence publish fails | CI logs error; Confluence page not updated | Architecture diagrams not refreshed on Confluence; model still valid in repository |

## Sequence Diagram

```
Developer -> PingdomRepo: git push (update .service.yml or DSL)
GitHubActions -> pull-federated-architecture: schedule trigger (02:00 UTC)
pull-federated-architecture -> PingdomRepo: git clone/pull
PingdomRepo --> pull-federated-architecture: .service.yml, architecture/ DSL files
pull-federated-architecture -> architecture-repo: copy to structurizr/import/Pingdom/
architecture-repo -> StructurizrCLI: validate workspace.dsl
StructurizrCLI --> architecture-repo: validation result
architecture-repo -> StructurizrCLI: export diagrams
StructurizrCLI --> architecture-repo: PNG/SVG/PlantUML/Mermaid
architecture-repo -> Confluence: publish updated architecture pages
Confluence --> architecture-repo: publish confirmation
```

## Related

- Architecture dynamic view: `dynamic-pingdom-metadata-publication`
- Related flows: [Shift Report Generation](shift-report-generation.md)
