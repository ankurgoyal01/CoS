---
service: "akamai"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "akamai"
  containers: [continuumAkamaiServiceMetadata]
---

# Architecture Context

## System Context

Akamai is modeled as an external software system (`akamai`) in the Groupon C4 architecture, representing the Akamai edge platform providing CDN, WAF, and web acceleration services. Within the Continuum platform, the `continuumAkamaiServiceMetadata` container captures repository-managed ownership, environment configuration, and dashboard references for this external platform. The metadata container references the live Akamai control plane (`https://control.akamai.com`) for WAF, bot-management analytics, and security center operations.

A related but distinct service, `akamai-cdn` (`continuumAkamaiCdn`), owns CDN property configuration and delivery rule management for the same Akamai platform; the two services divide responsibility along security controls (this service) vs. delivery configuration (`akamai-cdn`).

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Akamai Service Metadata | `continuumAkamaiServiceMetadata` | Configuration | YAML Configuration | N/A | Repository-managed service metadata describing Akamai security ownership, environments, and dashboard integration |
| Akamai (external platform) | `akamai` | External SaaS | Akamai Platform | N/A | Edge platform providing CDN, WAF, and web acceleration (external system stub) |

## Components by Container

### Akamai Service Metadata (`continuumAkamaiServiceMetadata`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Service Profile (`akamaiServiceProfile`) | Core service metadata including name, title, and security description; links to ownership and escalation contacts | YAML Section |
| Contacts and Ownership (`akamaiContactsAndOwnership`) | Team ownership, member roster, mailing list, and SRE notification channels | YAML Section |
| Environment Endpoints (`akamaiEnvironmentEndpoints`) | Environment and colo base URLs mapped for staging and production Akamai control-plane access | YAML Section |
| Security Dashboards (`akamaiSecurityDashboards`) | Akamai Security Center dashboard references used for incident investigation and analytics | YAML Section |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumAkamaiServiceMetadata` | `akamai` | References Akamai control plane, WAF, and bot-management analytics endpoints | HTTPS |
| `akamaiServiceProfile` | `akamaiContactsAndOwnership` | Assigns ownership and escalation contacts | internal |
| `akamaiServiceProfile` | `akamaiEnvironmentEndpoints` | Defines environment URL mappings | internal |
| `akamaiServiceProfile` | `akamaiSecurityDashboards` | Links security analytics dashboards | internal |

## Architecture Diagram References

- Component: `components-continuum-akamai-service-metadata`
