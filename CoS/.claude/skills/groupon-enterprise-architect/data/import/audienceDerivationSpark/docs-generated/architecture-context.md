---
service: "audienceDerivationSpark"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: [continuumAudienceDerivationSpark, continuumAudienceDerivationOps]
---

# Architecture Context

## System Context

Audience Derivation Spark operates within the `continuumSystem` (Continuum Platform), Groupon's core commerce engine. The service forms the data preparation backbone for the Audience Management subsystem: it reads from the Groupon data warehouse (Hive/EDW tables on HDFS), applies a multi-stage SQL derivation pipeline, and writes enriched audience system tables back to Hive. The operations container (`continuumAudienceDerivationOps`) orchestrates job submission and configuration deployment. Downstream, the derived tables feed payload generation pipelines and CRM campaign systems. The service has no inbound synchronous API; all interaction is driven by scheduled cron jobs or manual `fab`/`spark-submit` commands executed by the `audiencedeploy` service account.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Audience Derivation Spark Applications | `continuumAudienceDerivationSpark` | Spark batch application | Scala 2.12, Apache Spark 2.4, Hive | 2.64.4-SNAPSHOT | Assembly JAR executing audience derivation, universal derivation, LINK SAD base-table generation, and CQD validation jobs |
| Audience Derivation Operations Scripts | `continuumAudienceDerivationOps` | Operational tooling | Python 2.7, Fabric, spark-submit | — | Python/Fabric scripts that build, deploy, and submit Spark jobs on scheduled cadences |

## Components by Container

### Audience Derivation Spark Applications (`continuumAudienceDerivationSpark`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `AudienceDerivationMain` | Primary Spark job entrypoint for users and bcookie table derivation | Scala object |
| `UniversalAudienceDerivationMain` | Spark job entrypoint for universal derivation flow | Scala object |
| `LinkSadBaseTableGeneratorMain` | Spark entrypoint for LINK SAD optimization base-table generation | Scala object |
| `AudienceDerivation` and `TableBuilder` | Core SQL/table build orchestration — iterates YAML-configured tempview steps | Scala classes |
| `UniversalAudienceDerivation` | Region-aware universal derivation implementation | Scala class |
| `LinkSadBaseTableGenerator` | Builds LINK SAD base-table datasets from latest system tables | Scala class |
| `FieldSyncMain` | Synchronizes derived Hive schema fields to AMS metadata | Scala object |
| `CQDFieldValidatorMain` | Validates CQD field definitions against Hive and AMS state | Scala object |
| `CQDFieldValidator` | Core CQD validation rules and reporting logic | Scala class |

### Audience Derivation Operations Scripts (`continuumAudienceDerivationOps`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `fabfile.py` Tasks | Operational tasks for build, deploy, kickoff, field sync, and validation commands | Python module |
| `submit_derivation.py` | Constructs and executes `spark-submit` commands for users and bcookie derivation jobs | Python script |
| `submit_link_sad_base_table_generation.py` | Constructs and executes `spark-submit` commands for LINK SAD base-table generation | Python script |
| `sync_ams_cqd.py` | Synchronizes CQD configuration fields into AMS metadata | Python script |
| `validate_ams_cqd.py` | Runs CQD field validation entrypoint for operations usage | Python script |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumAudienceDerivationOps` | `continuumAudienceDerivationSpark` | Submits Spark applications and operational jobs | spark-submit |
| `continuumAudienceDerivationOps` | `hdfsStorage` | Uploads derivation YAML configuration directories during deploy | HDFS CLI (`hdfs dfs`) |
| `continuumAudienceDerivationSpark` | `hdfsStorage` | Reads configuration and writes generated table outputs | HDFS |
| `continuumAudienceDerivationSpark` | `yarnCluster` | Runs distributed Spark derivation workloads | Apache Spark on YARN (stub — not in federated model) |
| `continuumAudienceDerivationSpark` | `hiveMetastore` | Reads source tables and writes derived Hive tables | Spark SQL with Hive support (stub — not in federated model) |
| `continuumAudienceDerivationSpark` | `amsApi` | Fetches current system table name and updates AMS field metadata | HTTP/gRPC (stub — not in federated model) |
| `continuumAudienceDerivationSpark` | `cassandraCluster` | Writes audience payload outputs for downstream delivery | Spark Cassandra connector (stub — not in federated model) |
| `continuumAudienceDerivationSpark` | `bigtableIngestion` | Uploads delta attributes for user and bcookie records | Payload upload pipeline (stub — not in federated model) |
| `continuumAudienceDerivationSpark` | `splunkLogging` | Emits job execution logs and errors | Log4j/Filebeat (stub — not in federated model) |
| `fabricTasksAud` | `sparkSubmitWrapper` | Triggers derivation submission commands | Direct call |
| `fabricTasksAud` | `linkSadSubmitWrapper` | Triggers LINK SAD base-table submissions | Direct call |
| `fabricTasksAud` | `cqdSyncScript` | Triggers AMS CQD synchronization | Direct call |
| `fabricTasksAud` | `cqdValidationScript` | Triggers AMS CQD validation | Direct call |
| `sparkSubmitWrapper` | `derivationCliMain` | Executes spark-submit with AudienceDerivationMain | spark-submit |
| `derivationCliMain` | `tableDerivationEngine` | Orchestrates derivation SQL/table generation | Direct call |
| `tableDerivationEngine` | `amsFieldSyncMain` | Syncs field metadata after successful derivation | Direct call |
| `cqdFieldValidatorMain` | `cqdValidationEngine` | Executes CQD validation rules | Direct call |

## Architecture Diagram References

- System context: `contexts-continuumSystem`
- Container: `containers-continuumAudienceDerivationSpark`
- Component (Spark): `audienceDerivationSparkComponents`
- Component (Ops): `audienceDerivationOpsComponents`
- Dynamic flow: `nightly_derivation_flow`
