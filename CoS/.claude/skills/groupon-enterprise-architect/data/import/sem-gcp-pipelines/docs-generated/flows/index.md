---
service: "sem-gcp-pipelines"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 6
---

# Flows

Process and flow documentation for sem-gcp-pipelines.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Dataproc Cluster Lifecycle](dataproc-cluster-lifecycle.md) | batch | Airflow DAG start / end | Provisions an ephemeral Dataproc cluster, runs a Spark job, then deletes the cluster |
| [Keyword Submission](keyword-submission.md) | batch | Scheduled Airflow DAG (cron) | Reads final keyword Parquet data from GCS and publishes per-deal keyword messages to the Message Bus over STOMP |
| [Facebook Feed Generation](facebook-feed-generation.md) | scheduled | Cron schedule (3-4x daily per country) | Generates and delivers Facebook Location and Display feeds for multiple countries via sem-common-jobs Spark job |
| [Google Places Feed](google-places-feed.md) | scheduled | Cron schedule (daily 04:00 UTC per country) | Generates and delivers Google Places merchant location feeds for 13 countries via sem-common-jobs Spark job |
| [Google Things To Do Feed](google-things-todo-feed.md) | scheduled | Cron schedule (daily 08:00 and 18:00 UTC) | Fetches GTTD feed from MDS, splits into 5,000-row files, and delivers via SFTP |
| [CSS Affiliates Feed](css-affiliates-feed.md) | scheduled | Cron schedule (daily 10:00 UTC per country) | Generates and delivers CSS affiliate product feeds for 9 EU markets via sem-common-jobs Spark job |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 0 |
| Asynchronous (event-driven) | 1 |
| Batch / Scheduled | 5 |

## Cross-Service Flows

All flows in sem-gcp-pipelines are cross-service by nature — each pipeline bridges internal Groupon services (Deal Catalog, GAPI, Databreakers, MDS, Message Bus) with external ad platforms (Google Ads, Facebook Ads, Google Places, CSS Affiliates). Key cross-service flows:

- **Keyword Submission** spans: `continuumSemGcpPipelinesComposer` → `gcpDataprocCluster_469e25` → `gcsDataBucket_a28d89` → `messageBus`
- **Facebook Feed** spans: `continuumSemGcpPipelinesComposer` → `gcpDataprocCluster_469e25` → `facebookAds`
- **Google Things To Do** spans: `continuumSemGcpPipelinesComposer` → `continuumMarketingDealService` → `googleThingsToDo_b74080` (via SFTP)
- **Google Places** spans: `continuumSemGcpPipelinesComposer` → `gcpDataprocCluster_469e25` → `googlePlaces`
- **CSS Affiliates** spans: `continuumSemGcpPipelinesComposer` → `gcpDataprocCluster_469e25` → `cssAffiliates_59280e`
