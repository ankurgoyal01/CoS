---
service: "ghe-gcp-migration"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 4
---

# Flows

Process and flow documentation for GHE GCP Migration.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Infrastructure Provisioning](infrastructure-provisioning.md) | batch | Manual `terraform apply` | Provisions all GCP resources for the GHE environment from scratch |
| [HTTP/HTTPS Traffic Routing](http-traffic-routing.md) | synchronous | Inbound HTTP/HTTPS request to load balancer | Routes developer web requests through the GCP load balancer to the Nginx proxy and onward to GHE |
| [SSH Traffic Routing](ssh-traffic-routing.md) | synchronous | Inbound SSH connection on ports 22 or 122 | Routes git SSH operations through the TCP load balancer to the GHE managed instance group |
| [GHE Autoscaling](ghe-autoscaling.md) | event-driven | GCP Autoscaler CPU threshold breach | Scales the GHE managed instance group based on CPU utilization |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 2 |
| Asynchronous (event-driven) | 1 |
| Batch / Scheduled | 1 |

## Cross-Service Flows

All flows are contained within the GCP infrastructure provisioned by this repository. There are no cross-Groupon-service flows — this is an infrastructure project. Groupon engineers and CI/CD systems interact with GitHub Enterprise via the load balancer endpoints once provisioned.
