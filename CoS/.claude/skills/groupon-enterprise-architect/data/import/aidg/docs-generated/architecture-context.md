---
service: "aidg"
title: Architecture Context
generated: "2026-03-03T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: [inferPDS, merchantQuality]
---

# Architecture Context

## System Context

AIDG sits within the **Continuum** platform (`continuumSystem`) as a pair of internal backend API services supporting AI-driven deal generation. The service occupies the Advertising, Sponsored & SEM domain and provides enrichment and scoring capabilities to other Continuum services. Neither container has documented external dependencies or upstream consumers in the current federated workspace; cross-service relationships are tracked in the central architecture model.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| InferPDS API | `inferPDS` | Backend API | Java | Unknown | Internal enrichment API for PDS inference |
| Merchant Quality API | `merchantQuality` | Backend API | Java | Unknown | Internal service providing merchant quality score |

## Components by Container

### InferPDS API (`inferPDS`)

> No components documented yet. Component decomposition will be added when source code is federated or when service owners provide internal architecture details.

### Merchant Quality API (`merchantQuality`)

> No components documented yet. Component decomposition will be added when source code is federated or when service owners provide internal architecture details.

## Key Relationships

> No container or component relationships are documented in the current federated workspace. The architecture DSL files (`relations.dsl`, `components-relations.dsl`) are empty placeholders. Cross-service relationships are tracked in the central architecture model.

## Architecture Diagram References

- Component view for InferPDS API: not yet defined in architecture DSL
- Component view for Merchant Quality API: not yet defined in architecture DSL

> Architecture diagram views will be generated when component definitions and relationships are added to the DSL.
