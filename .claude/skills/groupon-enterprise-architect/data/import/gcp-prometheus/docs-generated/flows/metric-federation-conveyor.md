---
service: "gcp-prometheus"
title: "Metric Federation via Conveyor"
generated: "2026-03-03"
type: flow
flow_name: "metric-federation-conveyor"
flow_type: synchronous
trigger: "Prometheus Conveyor scrape interval against /federate endpoint"
participants:
  - "prometheusConveyor"
  - "prometheusServer"
architecture_ref: "dynamic-gcp-prometheus-federation"
---

# Metric Federation via Conveyor

## Summary

Prometheus Conveyor acts as a federation bridge between distributed Prometheus instances (running in the `monitoring` namespace) and the central Prometheus Server. It periodically calls the `/federate` HTTP endpoint of upstream Prometheus servers and relays the matched time-series into the central scrape pipeline, from where they are forwarded to Thanos Receive via remote write. This enables centralized collection of metrics from multiple Prometheus deployments without requiring direct scraping access to every cluster.

## Trigger

- **Type**: schedule
- **Source**: Prometheus Conveyor scrape configuration with 300-second interval (`scrapeTimeout: 300s`)
- **Frequency**: Every 300 seconds per federated Prometheus source

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Prometheus Conveyor Federation Scraper | Initiates federation scrapes and relays metrics | `conveyorFederationScraper` |
| Prometheus Server | Receives federated metrics from Conveyor | `prometheusServer` |

## Steps

1. **Discover upstream Prometheus targets**: Conveyor's Federation Scraper is configured via a `ServiceMonitor` (`svc-prometheus`) that selects services with label `prometheus: prometheus` in the `monitoring` namespace.
   - From: `conveyorFederationScraper`
   - To: Kubernetes API (service discovery)
   - Protocol: HTTP

2. **Request federated metrics**: Conveyor calls the `/federate` endpoint on each upstream Prometheus service with match parameter `{__name__=~".+"}` (all metrics) on port `web`.
   - From: `conveyorFederationScraper`
   - To: upstream Prometheus `/federate` endpoint
   - Protocol: HTTP (Prometheus federation protocol, Prometheus text format)

3. **Relay metrics with relabelling**: Conveyor applies metric relabelling to normalise namespace and source labels:
   - Replaces `__meta_kubernetes_namespace` with `telegraf-production`
   - Replaces `__meta_kubernetes_endpoints_label_prometheus` with `prometheus-conveyor`
   - Sets `prometheus` label to `telegraf-production/prometheus-conveyor`

4. **Forward to central Prometheus Server**: Relabelled metrics are ingested by the central Prometheus Server (`prometheusServer`).
   - From: `conveyorFederationScraper`
   - To: `prometheusServer`
   - Protocol: HTTP (federation / relayed scrape)

5. **Remote write to Thanos Receive**: Central Prometheus Server remote-writes the federated samples to Thanos Receive as part of the standard scraping pipeline (see [Metric Scraping and Remote Write](metric-scraping-remote-write.md)).
   - From: `promRemoteWriter`
   - To: `thanosReceiveReceiver`
   - Protocol: HTTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Upstream Prometheus unreachable | Conveyor marks federation target as down | Gap in federated metrics for that source |
| Federation scrape timeout (300s) | Scrape abandoned after `scrapeTimeout` | No samples ingested for that interval |
| Metric relabelling mismatch | Metrics dropped or incorrectly labelled | Potential data quality issues in central storage |

## Sequence Diagram

```
conveyorFederationScraper -> KubernetesAPI: Service discovery (monitoring namespace)
KubernetesAPI --> conveyorFederationScraper: Prometheus service endpoints
conveyorFederationScraper -> upstreamPrometheus: GET /federate?match[]={__name__=~".+"} (HTTP, 300s timeout)
upstreamPrometheus --> conveyorFederationScraper: Prometheus text format metrics
conveyorFederationScraper -> prometheusServer: Relay with relabelling (HTTP)
prometheusServer -> thanosReceiveReceiver: Remote write (HTTP, port 19291)
```

## Related

- Architecture dynamic view: `dynamic-gcp-prometheus-federation`
- Related flows: [Metric Scraping and Remote Write](metric-scraping-remote-write.md)
