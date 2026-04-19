---
service: "logging-elasticstack"
title: "Log Source Onboarding Flow"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "log-source-onboarding-flow"
flow_type: batch
trigger: "A Groupon service team requests integration with the centralized logging platform for a new log sourcetype"
participants:
  - "continuumLoggingLogstash"
  - "continuumLoggingElasticsearch"
  - "continuumLoggingKibana"
  - "continuumLoggingFilebeat"
architecture_ref: "dynamic-logging-logstashPipeline-flow"
---

# Log Source Onboarding Flow

## Summary

When a new Groupon service or application type needs to be integrated into the centralized logging platform, the Logging Platform Team follows a structured onboarding process. This involves creating a per-sourcetype Logstash filter configuration for log parsing, registering an Elasticsearch index template for field mappings, configuring an ILM policy for retention, deploying the updated Logstash pipeline, and creating a Kibana data view so engineers can immediately query the new log source.

## Trigger

- **Type**: manual
- **Source**: Logging Platform Team engineer responding to a new service onboarding request
- **Frequency**: On-demand, per new sourcetype or significant format change

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Logging Platform Team | Performs all onboarding steps; creates and validates filter configs, templates, and data views | — |
| Logstash Pipeline | Receives the new per-sourcetype filter configuration; parses new log format | `continuumLoggingLogstash` |
| Elasticsearch Cluster | Receives new index template and ILM policy; indexes the new sourcetype's documents | `continuumLoggingElasticsearch` |
| Kibana | Receives the new data view registration; makes logs queryable to engineers | `continuumLoggingKibana` |
| Filebeat Agent | Deployed on the new service; configured to harvest the new log files/streams | `continuumLoggingFilebeat` |
| Apache Kafka | Automatically creates the new sourcetype topic on first Filebeat publish | `messageBus` |

## Steps

1. **Define sourcetype identifier**: Agree on the `<sourcetype>` name following naming conventions (e.g., `my_service_name`). This identifier is used in Kafka topic names, Logstash filter selection, and Elasticsearch index names.
   - From: `Service team` + `Logging Platform Team`
   - To: `Logging Platform Team (config authoring)`
   - Protocol: manual process

2. **Configure Filebeat on the new service**: Add or update the Filebeat configuration for the new service, specifying log file paths or container stream inputs and the `sourcetype` field value. Deploy the updated Filebeat agent alongside the service.
   - From: `Logging Platform Team` / `Service team`
   - To: `continuumLoggingFilebeat`
   - Protocol: Filebeat config file update; deployment via Kubernetes DaemonSet or sidecar

3. **Create Logstash filter configuration**: Author a new per-sourcetype Logstash filter `.conf` file defining grok patterns, field mutations, date parsing, and any enrichment fields specific to the new log format.
   - From: `Logging Platform Team`
   - To: `continuumLoggingLogstash` (filter config file)
   - Protocol: file authoring + source control

4. **Run Logstash filter unit tests**: Execute the Logstash filter unit test suite against the new filter config to validate parsing correctness with sample log lines before deployment.
   - From: `Logging Platform Team` / `Jenkins`
   - To: `continuumLoggingLogstash` (test runner)
   - Protocol: Make / Jenkins test stage

5. **Register Elasticsearch index template**: Create or update an Elasticsearch index template via the REST API defining field mappings, index settings (shard count, codec), and the ILM policy assignment for the new sourcetype's index pattern.
   - From: `Logging Platform Team`
   - To: `continuumLoggingElasticsearch`
   - Protocol: REST HTTP (`PUT /_index_template/<sourcetype>`)

6. **Register ILM policy**: Create or assign the ILM policy for the new sourcetype's indices, specifying `default_ilm_managed: true` and configuring `default_elasticsearch_post_rollover_retention_in_hours` for retention.
   - From: `Logging Platform Team`
   - To: `continuumLoggingElasticsearch`
   - Protocol: REST HTTP (`PUT /_ilm/policy/<policy_name>`)

7. **Deploy updated Logstash**: Deploy the updated Logstash configuration containing the new filter via the Jenkins CI/CD pipeline (branch push to the appropriate release branch) or Ansible for on-prem.
   - From: `Logging Platform Team`
   - To: `continuumLoggingLogstash`
   - Protocol: Jenkins pipeline → Krane (GKE) / Ansible (on-prem)

8. **Validate first events in Elasticsearch**: Verify that the new sourcetype's first log events arrive in Elasticsearch with correct field mappings (no `_grokparsefailure` tags). Check the target index in Kibana or via `_search` API.
   - From: `Logging Platform Team`
   - To: `continuumLoggingElasticsearch` / `continuumLoggingKibana`
   - Protocol: REST HTTP (`GET /<sourcetype>-*/_search`) or Kibana Discover

9. **Create Kibana data view**: Register a new Kibana data view (index pattern) for the sourcetype via the Kibana REST API or Kibana UI, enabling engineers to query the new log source in Kibana Discover and dashboards.
   - From: `Logging Platform Team`
   - To: `continuumLoggingKibana`
   - Protocol: REST HTTP (`POST /api/data_views/data_view`) or Kibana UI

10. **Notify service team**: Confirm onboarding completion; provide the sourcetype name, Kibana data view URL, and any relevant Logstash field names to the requesting service team.
    - From: `Logging Platform Team`
    - To: `Service team`
    - Protocol: manual communication

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Logstash filter unit test failure | Fix grok patterns or filter logic; re-run tests before deploying | Deployment blocked until tests pass; prevents parse failures in production |
| Elasticsearch index template conflict | Review existing templates for pattern overlap; adjust index pattern or priority | Re-register template with corrected pattern; existing indices unaffected |
| First events tagged `_grokparsefailure` | Inspect sample events in error index; update grok pattern to match actual log format; redeploy Logstash | Parse failures visible in error index; clean up error documents after filter fix |
| Kafka topic not created automatically | Manually create topic with correct partition count and replication factor | Filebeat events fail to publish until topic exists; manual topic creation resolves |

## Sequence Diagram

```
Service Team -> Logging Platform Team: Request new sourcetype onboarding
Logging Platform Team -> Filebeat: Configure input for new log source; deploy agent
Logging Platform Team -> Logstash: Author new filter .conf for sourcetype
Logging Platform Team -> Jenkins: Run filter unit tests
Jenkins --> Logging Platform Team: Tests pass
Logging Platform Team -> Elasticsearch: PUT /_index_template/<sourcetype>
Logging Platform Team -> Elasticsearch: PUT /_ilm/policy/<policy_name>
Logging Platform Team -> Jenkins: Push release branch to deploy updated Logstash
Jenkins -> Logstash: Deploy updated pipeline via Krane/Ansible
Filebeat -> Kafka: Publishes first events for new sourcetype
Kafka -> Logstash: Delivers events via new sourcetype topic
Logstash -> Elasticsearch: Indexes enriched documents for new sourcetype
Logging Platform Team -> Elasticsearch: GET /<sourcetype>-*/_search (validate parsing)
Logging Platform Team -> Kibana: POST /api/data_views/data_view (register data view)
Logging Platform Team -> Service Team: Onboarding complete; data view URL provided
```

## Related

- Architecture dynamic view: `dynamic-logging-logstashPipeline-flow`
- Related flows: [Log Ingestion and Search Flow](logging-ingestion-search-flow.md), [Cluster Deployment Flow](cluster-deployment-flow.md), [Index Lifecycle Flow](index-lifecycle-flow.md)
