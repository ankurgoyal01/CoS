---
service: "magneto-gcp"
title: "DAG Generation"
generated: "2026-03-03"
type: flow
flow_name: "dag-generation"
flow_type: batch
trigger: "Docker container startup at deploy time"
participants:
  - "continuumMagnetoDagGenerator"
  - "continuumMagnetoConfigStorage"
  - "continuumMagnetoOrchestrator"
architecture_ref: "components-continuumMagnetoDagGenerator"
---

# DAG Generation

## Summary

At deploy time, the `continuumMagnetoDagGenerator` container starts and executes three Python scripts in sequence to produce Airflow DAG source files for every configured Salesforce table. The scripts read per-table YAML configuration, render each table's DAG from an embedded Python string template, syntax-validate the output via Python's `compile()` builtin, and write the files to the `./orchestrator/` path. The DeployBot system then copies the resulting Python DAG files to the Composer DAGs GCS bucket, where Cloud Composer picks them up and registers them as runnable DAGs.

## Trigger

- **Type**: schedule / deployment
- **Source**: Jenkins pipeline `dataPipeline` DSL — `optionalBuildStep` runs `docker run ... $(docker build -q .)` which executes all three generator scripts inside the built image
- **Frequency**: On every successful build/deploy (per branch push or tag)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| DAG Template Builder | Reads `dag_factory_config.yaml`, iterates SOX and NON-SOX tables, renders ingestion DAG Python source | `continuumMagnetoDagGenerator` |
| Validation DAG Template Builder | Reads `dag_factory_config.yaml`, renders validation/audit DAG Python source for each table | `continuumMagnetoDagGenerator` |
| DAG File Writer | Writes rendered DAG files to `./orchestrator/`; validates syntax via `compile()` | `continuumMagnetoDagGenerator` |
| Composer DAGs GCS Bucket | Receives generated DAG Python files from DeployBot after container run | `continuumMagnetoConfigStorage` |
| Cloud Composer (Airflow) | Picks up new/updated DAG files from GCS bucket and registers them | `continuumMagnetoOrchestrator` |

## Steps

1. **Start container**: Docker container starts; `CMD` executes `python magneto_dag_generator.py ; python magneto_dag_generator_simple_salesforce.py ; python magneto_validation_dag_generator.py`
   - From: `Jenkins` (DeployBot optionalBuildStep)
   - To: `continuumMagnetoDagGenerator`
   - Protocol: Docker run

2. **Load configuration**: Each generator script loads `dag_factory_config.yaml` and `config.yaml` from `./orchestrator/magneto/config/`
   - From: `continuumMagnetoDagGenerator`
   - To: local filesystem (bundled in image)
   - Protocol: file read

3. **Iterate table config**: Generator iterates over all SOX and NON-SOX entries in `dag_factory_config.yaml`; for each table, reads the `simple_salesforce` flag to determine which DAG template to use
   - From: DAG Template Builder
   - To: DAG Template Builder
   - Protocol: in-process Python

4. **Render DAG template**: For each table, substitutes `$dagid` and `$compliance` tokens in the Python string template, producing a complete Airflow DAG module with hardcoded table-specific parameters (schedule, cluster sizing, compliance path, project IDs)
   - From: DAG Template Builder
   - To: DAG File Writer
   - Protocol: in-process Python

5. **Validate and write DAG file**: `write_dag_file()` writes the rendered Python source to `./orchestrator/<filename>.py`; calls `compile()` to detect syntax errors before writing
   - From: DAG File Writer
   - To: `./orchestrator/` path (bundled into image layer)
   - Protocol: file write

6. **Render validation DAG**: `magneto_validation_dag_generator.py` repeats the same pattern for audit/validation DAGs (named `MAGNETO-<compliance>-<table>-audit`), reading `audit_schedule` from config
   - From: Validation DAG Template Builder
   - To: DAG File Writer
   - Protocol: in-process Python

7. **DeployBot copies DAG files to GCS**: After container exits, DeployBot copies `./orchestrator/*.py` to `COMPOSER_DAGS_BUCKET` (the environment-specific Composer DAGs bucket)
   - From: DeployBot
   - To: `continuumMagnetoConfigStorage` (Composer DAGs GCS bucket)
   - Protocol: gsutil / GCS API

8. **Composer registers DAGs**: Cloud Composer detects new/updated files in the DAGs bucket and registers the DAGs in Airflow, making them schedulable
   - From: `continuumMagnetoConfigStorage`
   - To: `continuumMagnetoOrchestrator` (Airflow scheduler)
   - Protocol: GCS DAG sync

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| YAML syntax error in `dag_factory_config.yaml` | Python `yaml.safe_load` raises `YAMLError` at script startup | Container exits non-zero; Jenkins build fails; no DAGs deployed |
| Rendered DAG has Python syntax error | `compile()` in `write_dag_file()` raises `SyntaxError` | Script aborts; partial DAG file may exist; Jenkins build fails |
| Config key missing for a table | `KeyError` raised during template substitution | Script aborts; remaining tables not generated; Jenkins build fails |
| GCS copy fails (DeployBot) | DeployBot reports failure; Slack notification to `#dnd-ingestion-ops` | No DAG update; previous DAG version remains active in Composer |

## Sequence Diagram

```
Jenkins -> DagGeneratorContainer: docker run (CMD executes all 3 generators)
DagGeneratorContainer -> dag_factory_config.yaml: load table config
DagGeneratorContainer -> DagTemplateBuilder: iterate SOX + NON_SOX tables
DagTemplateBuilder -> DagFileWriter: render DAG Python source per table
DagFileWriter -> ./orchestrator/: write + compile-validate DAG file
DagGeneratorContainer -> DagValidationTemplateBuilder: iterate all tables for audit DAGs
DagValidationTemplateBuilder -> DagFileWriter: render validation DAG per table
DagFileWriter -> ./orchestrator/: write + compile-validate validation DAG file
DagGeneratorContainer --> Jenkins: exit 0 (success)
Jenkins -> DeployBot: trigger GCS copy step
DeployBot -> ComposerDagsBucket: gsutil cp ./orchestrator/*.py gs://$COMPOSER_DAGS_BUCKET/
ComposerDagsBucket --> Airflow: DAG sync picks up new files
```

## Related

- Architecture dynamic view: `dynamic-magneto-salesforce-ingestion-flow`
- Related flows: [Salesforce Incremental Ingestion](salesforce-incremental-ingestion.md), [Salesforce Simple Ingestion](salesforce-simple-ingestion.md), [Salesforce Data Validation](salesforce-validation-audit.md)
