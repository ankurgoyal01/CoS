---
service: "audienceDerivationSpark"
title: "CQD Field Validation"
generated: "2026-03-03"
type: flow
flow_name: "cqd-field-validation"
flow_type: scheduled
trigger: "Manual Fabric task or scheduled invocation of validate_ams_cqd.py"
participants:
  - "continuumAudienceDerivationOps"
  - "continuumAudienceDerivationSpark"
  - "hiveMetastore"
  - "amsApi"
architecture_ref: "audienceDerivationSparkComponents"
---

# CQD Field Validation

## Summary

The CQD (Customer Query Definition) Field Validation flow validates that the field definitions configured in the CQD system are consistent with both the actual Hive table schemas and the AMS field metadata. The `CQDFieldValidatorMain` Spark job reads CQD field configurations from the AudienceCqdConfig repository (synced via `sync_ams_cqd.py`), compares them against Hive table structures and AMS state, and reports any discrepancies. This flow is used by the Audience Management operations team to ensure data integrity before CRM campaign execution.

## Trigger

- **Type**: manual or scheduled
- **Source**: `validate_ams_cqd.py` executed directly on the job submitter host; or via Fabric task `fab {stage}:{region} validate_ams_cqd_fields`
- **Frequency**: On-demand; typically run after CQD config changes or after schema migrations

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Operations Scripts | Triggers validation via `validate_ams_cqd.py` or Fabric | `continuumAudienceDerivationOps` (`cqdValidationScript`) |
| Audience Derivation Spark App | Executes CQD validation rules and produces report | `continuumAudienceDerivationSpark` (`cqdFieldValidatorMain`, `cqdValidationEngine`) |
| Hive Metastore | Source of actual table schema for comparison | `hiveMetastore` |
| AMS API | Source of current AMS field metadata for comparison | `amsApi` |

## Steps

1. **Trigger validation**: Operator runs `fab {stage}:{region} validate_ams_cqd_fields` or executes `validate_ams_cqd.py` directly on the job submitter host.
   - From: `continuumAudienceDerivationOps` (`cqdValidationScript`)
   - To: `continuumAudienceDerivationSpark` (`CQDFieldValidatorMain`)
   - Protocol: spark-submit (via `ValidateAmsCqd.validate()` which constructs the submit command)

2. **Load CQD field config**: `CQDFieldValidatorMain` loads the CQD field definitions (from synced CSV/config files).
   - From: `continuumAudienceDerivationSpark`
   - To: Local config files (previously synced via `sync_ams_cqd.py`)
   - Protocol: File read

3. **Read Hive table schema**: Reads the schema of the referenced Hive tables to get actual column names and data types.
   - From: `continuumAudienceDerivationSpark`
   - To: `hiveMetastore`
   - Protocol: Spark SQL with Hive support

4. **Read AMS field metadata**: Retrieves field definitions registered in AMS for the target table.
   - From: `continuumAudienceDerivationSpark`
   - To: `amsApi`
   - Protocol: HTTP / gRPC

5. **Execute validation rules**: `CQDFieldValidator` applies validation rules comparing CQD config fields against Hive schema and AMS metadata. Identifies missing, extra, or type-mismatched fields.
   - From: `continuumAudienceDerivationSpark` (`CQDFieldValidator`)
   - To: In-memory computation
   - Protocol: Scala logic

6. **Produce validation report**: Outputs validation results (passed, warnings, failures) to job logs and/or stdout for operator review.
   - From: `continuumAudienceDerivationSpark`
   - To: Splunk / operator console
   - Protocol: Log4j / stdout

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| CQD config not synced | Validation fails with config-not-found error | Run `fab sync_ams_cqd_fields` first; then re-run validation |
| AMS API unavailable | Spark job throws exception | Re-run when AMS is available |
| Hive table not found | Spark AnalysisException | Update CQD config to reference correct table name; re-sync and re-validate |
| Validation failures found | Report generated; job exits with failure code | Review report; update CQD config or Hive schema as appropriate |

## Sequence Diagram

```
validate_ams_cqd.py -> YARN: spark-submit CQDFieldValidatorMain
YARN -> AudienceDerivationSpark: allocate driver
AudienceDerivationSpark -> config files: load CQD field definitions
AudienceDerivationSpark -> HiveMetastore: describe table (get schema)
AudienceDerivationSpark -> AMS API: get AMS field metadata
AudienceDerivationSpark -> CQDFieldValidator: apply validation rules
CQDFieldValidator --> AudienceDerivationSpark: validation report
AudienceDerivationSpark --> Splunk/log: emit validation results
AudienceDerivationSpark --> YARN: job SUCCEEDED (or FAILED if violations)
```

## Related

- Architecture component view: `audienceDerivationSparkComponents`
- Related flows: [AMS Field Sync](ams-field-sync.md), [Nightly Audience Derivation](nightly-audience-derivation.md)
- CQD config source: [AudienceCqdConfig repo](https://github.groupondev.com/crm/AudienceCqdConfig)
- Fabric tasks: `fab {stage}:{region} sync_ams_cqd_fields:...` and `fab {stage}:{region} validate_ams_cqd_fields`
