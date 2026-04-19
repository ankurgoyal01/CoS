---
service: "lgtm"
title: "Trace Storage and Compaction"
generated: "2026-03-03"
type: flow
flow_name: "trace-storage-compaction"
flow_type: batch
trigger: "Tempo ingester block flush timer fires when a trace block window closes"
participants:
  - "continuumTempo"
  - "tempoGatewayApi"
  - "tempoTraceStorage"
architecture_ref: "dynamic-telemetry-ingestion-and-query-flow"
---

# Trace Storage and Compaction

## Summary

This flow describes how Grafana Tempo persists received trace data to GCS and maintains storage efficiency through compaction. Traces received by the Tempo Gateway are fanned out by the distributor to ingesters, which accumulate spans in memory within a block window. When the window closes, the ingester flushes the sealed block to a GCS bucket. The compactor component periodically reads existing blocks from GCS, merges small or overlapping blocks, and writes compacted blocks back to GCS, then removes the originals. This ensures durable, queryable, and efficiently-stored trace data.

## Trigger

- **Type**: schedule (internal timer)
- **Source**: Tempo ingester block window timer (internal Tempo configuration); Tempo compactor polling loop
- **Frequency**: Block flush — every block window interval (Tempo default: configurable, typically minutes); Compaction — periodic polling by the compactor component

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Tempo Gateway API | Receives OTLP/HTTP trace write requests and routes to distributor | `tempoGatewayApi` |
| Tempo Distributor | Fans out incoming spans to one or more ingesters | (Tempo internal) |
| Tempo Ingester | Accumulates spans in memory; flushes sealed blocks to GCS | (Tempo internal) |
| Tempo Compactor | Merges, compacts, and manages block lifecycle in GCS | (Tempo internal) |
| Trace Storage Backend | GCS bucket holding all trace blocks | `tempoTraceStorage` |

## Steps

1. **Receive trace write**: Tempo Gateway API receives an OTLP/HTTP trace write from the OTel Collector and routes it internally to the Tempo distributor.
   - From: `otelExportPipelines`
   - To: `tempoGatewayApi`
   - Protocol: OTLP/HTTP

2. **Distribute spans**: The Tempo distributor fans out span data to the appropriate ingesters based on trace ID hashing.
   - From: `tempoGatewayApi` (distributor)
   - To: Tempo ingesters
   - Protocol: Internal Tempo gRPC

3. **Accumulate spans in memory**: Ingesters hold spans in a memory-backed WAL (write-ahead log) within the current block window (replicas: 2 minimum, max 10 via HPA).
   - From: Distributor
   - To: Tempo Ingester (in-memory)
   - Protocol: Internal

4. **Flush sealed block to GCS**: When the block window closes (or the ingester is shutting down), the ingester writes the sealed trace block to the GCS bucket for the relevant environment/region.
   - From: Tempo Ingester
   - To: `tempoTraceStorage` (GCS bucket)
   - Protocol: GCS SDK (Workload Identity auth)

5. **Compactor merges blocks**: The Tempo compactor periodically scans GCS for blocks eligible for compaction (small, overlapping, or aged blocks), merges them into larger blocks, writes the merged result to GCS, and deletes the originals.
   - From: Tempo Compactor
   - To: `tempoTraceStorage` (GCS bucket)
   - Protocol: GCS SDK (read + write + delete)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| GCS write failure (ingester flush) | Ingester retries flush; data remains in memory WAL | Risk of data loss if ingester pod is evicted before successful flush |
| Ingester OOM (too many spans in memory) | Kubernetes OOMKill; pod restarts; HPA may add replicas | Potential trace data loss for spans not yet flushed |
| Compactor GCS access failure | Compactor retries on next cycle | Blocks remain uncompacted; storage grows but traces remain queryable |
| Ingester pod scaling (HPA) | HPA scales ingesters 2–10 based on load | Additional replicas absorb ingestion load; block distribution handled by distributor |

## Sequence Diagram

```
otelExportPipelines -> tempoGatewayApi: OTLP/HTTP traces
tempoGatewayApi -> TempoDistributor: distribute spans by trace ID
TempoDistributor -> TempoIngester: write spans to WAL (in-memory)
TempoIngester -> tempoTraceStorage: flush sealed block (GCS SDK)
tempoTraceStorage --> TempoIngester: block write acknowledged
TempoCompactor -> tempoTraceStorage: read blocks for compaction (GCS SDK)
TempoCompactor -> tempoTraceStorage: write compacted block (GCS SDK)
TempoCompactor -> tempoTraceStorage: delete original blocks (GCS SDK)
```

## Related

- Architecture dynamic view: `dynamic-telemetry-ingestion-and-query-flow`
- Related flows: [Telemetry Ingestion](telemetry-ingestion.md), [Trace Query and Visualization](trace-query-visualization.md)
- GCS bucket config: `tempo/.meta/deployment/cloud/components/tempo/<env>.yml`
- Ingester scaling config: `tempo/.meta/deployment/cloud/components/tempo/common.yml`
