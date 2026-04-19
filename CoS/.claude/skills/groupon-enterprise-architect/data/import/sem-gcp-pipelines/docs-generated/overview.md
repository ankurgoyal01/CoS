---
service: "sem-gcp-pipelines"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Search & Display Marketing"
platform: "GCP / Continuum"
team: "SEM Engineering"
status: active
tech_stack:
  language: "Python"
  language_version: "3"
  framework: "Apache Airflow"
  framework_version: "2.x (GCP Composer managed)"
  runtime: "GCP Composer / Dataproc"
  runtime_version: "Dataproc image 1.5-debian10"
  build_tool: "Jenkins dataPipeline DSL"
  package_manager: "pip / Artifactory"
---

# sem-gcp-pipelines Overview

## Purpose

sem-gcp-pipelines is the Search and Display Marketing (SEM/DM) data pipeline orchestration layer on GCP. It manages a collection of Apache Airflow DAGs that prepare, process, and deliver ad-platform feeds and conversion data to external partners including Google Ads, Google Places, Google Things To Do, Google Appointment Services, Facebook Ads, and CSS Affiliate programs. The pipelines run scheduled Spark jobs on ephemeral Dataproc clusters, fetching deal and merchant data from internal Groupon services and pushing the results to external ad platforms.

## Scope

### In scope

- Authoring and scheduling Apache Airflow DAGs for SEM and Display Marketing data processing
- Provisioning and tearing down ephemeral GCP Dataproc clusters for each pipeline run
- Submitting PySpark and Java Spark jobs (via `sem-common-jobs` JAR) for feed generation and processing
- Generating and delivering ad-platform feeds to Google Ads, Facebook Ads, Google Places, Google Things To Do, Google Appointment Services, and CSS Affiliates
- Publishing keyword submission messages to the internal Message Bus (STOMP protocol)
- Dispatching feed and report uploads to the Marketing Deal Service (MDS)
- Fetching deal data from Deal Catalog, GAPI, and Databreakers services
- Managing secrets retrieval from GCP Secret Manager for job credentials
- Logging pipeline metrics and events to GCP Cloud Logging and ELK/Kibana dashboards

### Out of scope

- Serving HTTP API traffic (this service has no inbound HTTP endpoints)
- Storing persistent application state (all data is processed and forwarded to downstream systems)
- Keyword bid calculation logic (handled by `sem-common-jobs` JAR, `cerebro_v2`)
- Managing ad campaign structure directly in Google Ads or Facebook Ads (handled by the ad platforms themselves)
- Frontend deal display or pricing logic

## Domain Context

- **Business domain**: Search & Display Marketing — automated pipeline orchestration for SEM and Display channel feed delivery and reporting
- **Platform**: GCP / Continuum — runs on GCP Composer (Airflow) with Dataproc for Spark execution
- **Upstream consumers**: Google Ads, Facebook Ads, CSS Affiliates, Google Places, Google Things To Do, Google Appointment Services (all receive generated feeds)
- **Downstream dependencies**: Deal Catalog Service, GAPI Service, Databreakers Service, Denylisting Service, Keyword Service, Marketing Deal Service (MDS), GCP Secret Manager, Message Bus (STOMP), GCS buckets, Dataproc

## Stakeholders

| Role | Description |
|------|-------------|
| Service owner | asdwivedi (SEM Engineering team) |
| Engineering team | SEM Engineering — sem-devs@groupon.com |
| On-call / alerts | sem-application-alerts@groupon.pagerduty.com (PagerDuty service PFA1RPI) |
| Display Marketing requesters | kwojdyna@groupon.com — Facebook and geo-cat pipelines |
| SEM requesters | skhytrenko@groupon.com, c_jkrhovjak@groupon.com — Google places, DSA, Google Appointment |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Python | 3 | `orchestrator/**/*.py` |
| Framework | Apache Airflow | 2.x (GCP Composer managed) | `orchestrator/cluster/create_cluster.py` |
| Spark runtime | GCP Dataproc | image 1.5-debian10 | `orchestrator/cluster/config/cluster_config_prod.json` |
| Java Spark jobs | sem-common-jobs JAR | 2.132 | `orchestrator/facebook/facebook.py` |
| Build / release | Jenkins dataPipeline DSL | dpgm-1396 | `Jenkinsfile` |
| Package manager | pip / Artifactory | — | `orchestrator/cluster/config/cluster_config_prod.json` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| apache-airflow | 2.x | scheduling | DAG orchestration and scheduling |
| apache-airflow-providers-google | 2.x | scheduling | `DataprocCreateClusterOperator`, `DataprocSubmitJobOperator`, `DataprocDeleteClusterOperator` |
| pyspark | 3.x | data-processing | Spark DataFrame operations for keyword submission jobs |
| stomp.py | 8.1.0 | message-client | STOMP protocol client for Message Bus keyword publishing |
| thrift | 0.16.0 | serialization | Thrift binary protocol for Message Bus payloads |
| hburllib | internal | http-framework | Groupon internal mTLS HTTP client for internal service calls |
| requests | 2.x | http-framework | HTTP client for Databreakers API calls (HMAC-signed) |
| pyyaml | — | configuration | Loading per-pipeline `global_variables_*.yml` config files |
| google-cloud-secret-manager | — | auth | Accessing GCP Secret Manager via `gcloud` CLI |
| preutils | internal | monitoring | `trigger_event` / `resolve_event` callbacks for PagerDuty integration |
