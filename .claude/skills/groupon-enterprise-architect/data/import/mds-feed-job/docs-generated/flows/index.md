---
service: "mds-feed-job"
title: Flows
generated: "2026-03-03T00:00:00Z"
type: flows-index
flow_count: 7
---

# Flows

Process and flow documentation for MDS Feed Job.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Feed Job Orchestration](feed-job-orchestration.md) | batch | Livy job submission / scheduler | End-to-end lifecycle of a single feed batch run from bootstrap to completion |
| [Transformer Pipeline Execution](transformer-pipeline-execution.md) | batch | Internal — triggered by feedOrchestrator | Ordered execution of transformer and UDF chains against Spark datasets |
| [External API Enrichment](external-api-enrichment.md) | batch | Internal — triggered by transformerPipeline | API calls to upstream services to enrich deal records during transformation |
| [Feed Output Validation and Publishing](feed-output-validation-publishing.md) | batch | Internal — triggered by transformerPipeline | Validates feed output quality and publishes files to GCS and downstream channels |
| [SEM Feed Generation](sem-feed-generation.md) | batch | Scheduler (SEM feed type job submission) | Reads SEM datasets from EDW, applies SEM-specific transforms, and produces SEM feed output |
| [Multi-Language Translation](multi-language-translation.md) | batch | Internal — triggered by transformerPipeline for locale-specific feeds | Translates deal content via Google Translate for multi-locale feed variants |
| [Metrics and Monitoring](metrics-monitoring.md) | batch | Internal — triggered at job completion / checkpoints | Collects and publishes operational metrics to InfluxDB; updates batch status |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 0 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 7 |

## Cross-Service Flows

The **Feed Job Orchestration** and **Feed Output Validation and Publishing** flows span multiple Continuum services. The primary dynamic architecture view is `dynamic-mds-feed-job-feed-generation`, which captures the full sequence of service interactions during a feed generation run.

- Architecture dynamic view: `dynamic-mds-feed-job-feed-generation`
- Container view: `containers-mds-feed-job`
- Component view: `components-mds-feed-job`
