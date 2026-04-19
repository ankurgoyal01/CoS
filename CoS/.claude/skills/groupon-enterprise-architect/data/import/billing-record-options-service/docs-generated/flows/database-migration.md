---
service: "billing-record-options-service"
title: "Database Migration"
generated: "2026-03-03"
type: flow
flow_name: "database-migration"
flow_type: batch
trigger: "Manual CLI invocation via FlywayMigrateCommand, or automatic on startup when AUTOMIGRATE=true"
participants:
  - "continuumBillingRecordOptionsService"
  - "daasPostgresPrimary"
architecture_ref: "components-continuumBillingRecordOptionsService"
---

# Database Migration

## Summary

BROS uses Flyway (via the `jtier-migrations` library) to manage all schema changes to the `bros` PostgreSQL database. Migrations are versioned SQL scripts located in `src/main/resources/db/migrations/`. They can be executed either manually via the `flyway-migrate` CLI command or automatically on service startup if the `AUTOMIGRATE` environment variable is set to `"true"`. In production, `AUTOMIGRATE` is set to `"false"` so migrations are applied manually before deployment.

## Trigger

- **Type**: manual (CLI command) or schedule (startup when `AUTOMIGRATE=true`)
- **Source**: Operations engineer running the `flyway-migrate` command, or the service JVM startup sequence
- **Frequency**: On demand (prior to deployments that introduce schema changes)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Service JVM / CLI | Executes the `FlywayMigrateCommand` Dropwizard command | `continuumBillingRecordOptionsService` |
| DaaS PostgreSQL | Target database — receives DDL and DML migration statements | `daasPostgresPrimary` |

## Steps

1. **Invoke Flyway Migrate Command**: An operator runs the following command against the target environment configuration:
   ```sh
   java -jar billing-record-options-service-<version>.jar flyway-migrate <config-file-path>
   ```
   Or, on service startup with `AUTOMIGRATE=true`, the JVM invokes `FlywayMigrateCommand` automatically.
   - From: Operations engineer or JVM startup
   - To: `continuumBillingRecordOptionsService` (FlywayMigrateCommand)
   - Protocol: CLI / JVM startup

2. **Load Configuration**: The command loads the YAML configuration file (path from `JTIER_RUN_CONFIG` or the supplied argument) to obtain PostgreSQL connection details from the `postgres` configuration block.
   - From: `FlywayMigrateCommand`
   - To: `BillingRecordOptionsServiceConfiguration`
   - Protocol: Direct (in-process)

3. **Connect to PostgreSQL**: Flyway establishes a connection to the target `bros` schema using the DaaS-managed credentials from the configuration.
   - From: `FlywayMigrateCommand`
   - To: `daasPostgresPrimary`
   - Protocol: PostgreSQL (JDBC)

4. **Check Migration State**: Flyway queries the `flyway_schema_history` table in the `bros` schema to determine which migrations have already been applied.
   - From: Flyway
   - To: `daasPostgresPrimary`
   - Protocol: PostgreSQL

5. **Apply Pending Migrations**: Flyway identifies and executes all pending versioned migration scripts from `src/main/resources/db/migrations/` in version order. Each migration is executed as a transaction and recorded in `flyway_schema_history` on success.
   - From: Flyway
   - To: `daasPostgresPrimary`
   - Protocol: PostgreSQL (DDL/DML)

6. **Report Results**: Flyway logs the count of applied migrations and any errors. The command exits with code 0 on success or non-zero on failure.
   - From: `FlywayMigrateCommand`
   - To: operator / deployment log
   - Protocol: STDOUT / log

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Database connection failure | JDBC exception thrown | Command exits with error; schema unchanged |
| Migration script syntax error | SQL exception during execution; Flyway rolls back the failed migration | Failed migration not recorded; schema reverted to pre-migration state |
| Migration checksum mismatch | Flyway detects modification to a previously applied migration file | Command fails with validation error; no migrations applied |
| `AUTOMIGRATE=true` in production (discouraged) | Migration runs on every pod restart | Risk of multiple pods attempting concurrent migrations — mitigated by Flyway's schema-level lock |

## Sequence Diagram

```
Operator -> ServiceJVM: java -jar bros.jar flyway-migrate production-us-central1.yml
ServiceJVM -> BillingRecordOptionsServiceConfiguration: load postgres config
BillingRecordOptionsServiceConfiguration --> ServiceJVM: PostgresConfig
ServiceJVM -> daasPostgresPrimary: JDBC connect (bros schema)
daasPostgresPrimary --> ServiceJVM: connection established
ServiceJVM -> daasPostgresPrimary: SELECT * FROM flyway_schema_history
daasPostgresPrimary --> ServiceJVM: applied migration versions
ServiceJVM -> daasPostgresPrimary: BEGIN; <migration SQL>; COMMIT;
daasPostgresPrimary --> ServiceJVM: migration applied
ServiceJVM -> daasPostgresPrimary: INSERT INTO flyway_schema_history (...)
ServiceJVM --> Operator: Migration complete: N applied, 0 failed
```

## Related

- Architecture dynamic view: `components-continuumBillingRecordOptionsService`
- Related flows: [Payment Methods by Country Query](payment-methods-by-country.md)
- Data store details: [Data Stores](../data-stores.md)
- Configuration: [Configuration](../configuration.md) — `AUTOMIGRATE` environment variable
