---
service: "gcp-prometheus"
title: "Metric Scraping and Remote Write"
generated: "2026-03-03"
type: flow
flow_name: "metric-scraping-remote-write"
flow_type: synchronous
trigger: "Prometheus scrape interval (every N seconds per target)"
participants:
  - "prometheusServer"
  - "prometheusBlackboxExporter"
  - "thanosReceive"
architecture_ref: "dynamic-gcp-prometheus-scrape"
---

# Metric Scraping and Remote Write

## Summary

Prometheus Server periodically scrapes metrics from Kubernetes workload targets and the Blackbox Exporter. Scraped samples are appended to a local TSDB. The Remote Write component then forwards these samples to Thanos Receive via HTTP, where they are ingested into the Thanos distributed TSDB with a 1-day local retention window before being flushed to GCS.

## Trigger

- **Type**: schedule
- **Source**: Prometheus Server scrape interval configuration
- **Frequency**: Per configured scrape interval per target (typically 15s-300s)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Prometheus Scraper | Initiates scrapes against Kubernetes targets | `promScraper` |
| Prometheus TSDB | Appends scraped samples locally | `promTsdb` |
| Prometheus Remote Write | Forwards samples to Thanos Receive | `promRemoteWriter` |
| Prometheus Blackbox Exporter | Executes and exposes probe results | `blackboxProbeHandler` |
| Thanos Receive Receiver | Accepts remote-write HTTP payloads | `thanosReceiveReceiver` |
| Thanos Receive Store API | Exposes recent blocks via gRPC | `thanosReceiveStoreApi` |

## Steps

1. **Scrape targets**: Prometheus Scraper polls configured Kubernetes service endpoints and exporters at the defined scrape interval.
   - From: `promScraper`
   - To: Kubernetes workload targets
   - Protocol: HTTP

2. **Scrape Blackbox Exporter**: Prometheus Scraper also scrapes `prometheusBlackboxExporter` to collect blackbox probe results (HTTP, TCP, ICMP probes).
   - From: `promScraper`
   - To: `blackboxProbeHandler`
   - Protocol: HTTP

3. **Append to local TSDB**: Scraped time-series samples are appended to the Prometheus local TSDB (`promTsdb`). Head blocks are held in memory and flushed to disk periodically.
   - From: `promScraper`
   - To: `promTsdb`
   - Protocol: direct (in-process)

4. **Remote write to Thanos Receive**: The Remote Write component batches samples from the TSDB head and ships them to all five Thanos Receive pods on port 19291 (`/api/v1/receive`). The hashring determines which pod owns each time series.
   - From: `promRemoteWriter`
   - To: `thanosReceiveReceiver` (port 19291)
   - Protocol: HTTP (Prometheus Remote Write protocol, protobuf-encoded)

5. **Append to Thanos Receive TSDB**: Thanos Receive appends the remote-written samples to its own TSDB at `/var/thanos/receive` with a 1-day retention. Each pod is labelled with `replica="<pod-name>"` and `receive="true"`.
   - From: `thanosReceiveReceiver`
   - To: local TSDB (`/var/thanos/receive`)
   - Protocol: direct (in-process)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Scrape target unreachable | Prometheus marks target `down`; `up` metric set to 0 | Gap in metric series; alert if threshold exceeded |
| Thanos Receive pod unavailable | Prometheus remote write retries against other hashring pods | Possible sample loss for that shard; replication factor 1 means no redundancy |
| Thanos Receive TSDB full (PVC) | Receive pod enters error state | Remote write fails; upstream Prometheus buffers until timeout |
| Blackbox probe timeout | Probe result reported as failed | `probe_success=0` metric exposed |

## Sequence Diagram

```
promScraper -> KubernetesTargets: GET /metrics (HTTP)
KubernetesTargets --> promScraper: Prometheus text format samples
promScraper -> blackboxProbeHandler: GET /probe (HTTP)
blackboxProbeHandler --> promScraper: Probe results
promScraper -> promTsdb: Append samples (in-process)
promRemoteWriter -> thanosReceiveReceiver: POST /api/v1/receive (HTTP, port 19291)
thanosReceiveReceiver -> thanosReceiveTsdb: Append samples (in-process)
```

## Related

- Architecture dynamic view: `dynamic-gcp-prometheus-scrape`
- Related flows: [Metric Federation via Conveyor](metric-federation-conveyor.md), [Long-Term Block Storage to GCS](block-storage-gcs.md)
