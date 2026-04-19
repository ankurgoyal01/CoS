---
service: "raas_c1"
title: Architecture Context
generated: "2026-03-03T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: [continuumRaasC1Service]
---

# Architecture Context

## System Context

RAAS C1 exists within the Continuum Platform (`continuumSystem`) as a thin Service Portal container that provides an identity for the C1 colocation Redis nodes. It sits alongside the `raas` platform containers and the `redislabs_config` service within the same Continuum system boundary. The entry was created to work around an OCT tooling constraint (DATA-5855): OCT cannot associate two BASTIC tickets with one service, so the RaaS platform is split into `raas_c1` (C1 colos: snc1, sac1, dub1) and `raas_c2` (C2 colos). Actual Redis lifecycle management flows through the `raas` platform containers; this record serves as a routing and ticketing anchor for C1.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| RAAS C1 Service Portal | `continuumRaasC1Service` | Service Portal | Service Portal | — | Service Portal entry that represents the RAAS C1 service for internal tooling and routing |

## Components by Container

### RAAS C1 Service Portal (`continuumRaasC1Service`)

> No evidence found — no components are defined for this container. The container is a Service Portal registration record only.

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumRaasC1Service` | `raas_dns` | Internal DNS service discovery for C1 Redis node routing | Internal DNS |

> No explicit container-level relationships are modeled in the DSL beyond the `raas_dns` dependency declared in `.service.yml`. Cross-service relationships are tracked in the central architecture model.

## Architecture Diagram References

- System context: `contexts-continuumSystem`
- Container: `containers-continuumRaasC1Service`
- Component: No component views defined
