---
service: "deals-cluster"
title: "Rules Fetch at Job Startup"
generated: "2026-03-03"
type: flow
flow_name: "rules-fetch-at-startup"
flow_type: synchronous
trigger: "Job entry point — invoked before any Spark processing begins"
participants:
  - "continuumDealsClusterSparkJob"
  - "dealsClusterRulesApi_b1c2"
  - "topClustersRulesApi_c3d4"
architecture_ref: "dynamic-dealsClusterJob"
---

# Rules Fetch at Job Startup

## Summary

Before either Spark job begins processing data, it synchronously fetches its rule configuration from the Deals Cluster Rules API over HTTPS. For `DealsClusterJob`, this retrieves the list of `Rule` objects that define how deals are grouped and decorated. For `TopClustersJob`, this retrieves `TopClustersRule` objects that define how cluster output is ranked and filtered. Rules can be optionally narrowed to a single named rule via a CLI argument. If the fetch fails, the job fails immediately without processing any data.

## Trigger

- **Type**: api-call (synchronous, blocking)
- **Source**: `ClustersGenerator.generate()` (for `DealsClusterJob`) or `TopClustersExtractor.extractByRules()` (for `TopClustersJob`) — called after Spark session initialization
- **Frequency**: Once per job execution

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| ClustersGenerator / TopClustersExtractor | Initiates rule fetch; uses rules to drive all subsequent processing | `continuumDealsClusterSparkJob` |
| DealsClustersRulesReader | HTTP client for the Deals Cluster Rules API | `continuumDealsClusterSparkJob` |
| TopClustersRulesReader | HTTP client for the Top Clusters Rules API | `continuumDealsClusterSparkJob` |
| Deals Cluster Rules API | Returns JSON list of clustering `Rule` objects | `dealsClusterRulesApi_b1c2` |
| Top Clusters Rules API | Returns JSON list of `TopClustersRule` objects | `topClustersRulesApi_c3d4` |

## Steps

1. **Resolve rule API URL**: The reader reads the `cluster_rule_source` (or `top_clusters_rule_source`) property from `ApplicationProperties`. If a `ruleName` CLI argument was provided, it appends `&name=<ruleName>` to the URL to filter to a single rule.
   - From: `continuumDealsClusterSparkJob`
   - To: `continuumDealsClusterSparkJob` (in-process property lookup)

2. **Open HTTPS connection with mutual TLS**: `GenericReader.loadData()` opens an `HttpsURLConnection` to the resolved URL, setting the `Host` header to the value of `deals_cluster_rule_hb_url` (for SNI-based VIP routing). The JVM is configured with:
   - Truststore: `/var/groupon/truststore.jks` (JKS format)
   - Keystore: `/var/groupon/mis-data-pipelines-keystore.jks` (PKCS12 format)
   - From: `continuumDealsClusterSparkJob`
   - To: `dealsClusterRulesApi_b1c2` or `topClustersRulesApi_c3d4`
   - Protocol: HTTPS (mTLS)

3. **Read and deserialize response**: The JSON response body is read as an `InputStreamReader` and deserialized using Jackson's `JSONUtil.deserialize()` into:
   - `List<Rule>` for `DealsClusterJob`
   - `List<TopClustersRule>` for `TopClustersJob`
   - From: `continuumDealsClusterSparkJob`
   - To: `continuumDealsClusterSparkJob` (in-process Jackson deserialization)

4. **Filter excluded rules** (DealsClusterJob only): If the `exclude_rules` CLI argument was provided, any rules whose names appear in the exclusion list are filtered out before processing begins.
   - From: `continuumDealsClusterSparkJob`
   - To: `continuumDealsClusterSparkJob` (in-process Java stream filter)

5. **Log active rules**: `ClustersGenerator.generate()` logs a `PROCESSING_RULES` info event with the list of active rule names before processing begins.
   - From: `continuumDealsClusterSparkJob`
   - To: GdoopLogger / log output

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Malformed rules API URL | `MalformedURLException` caught by `GenericReader`; re-thrown as `IOException` with event `loadRulesDataError` | Job fails at startup; no data processed |
| HTTPS connection failure / API unavailable | `IOException` caught by `GenericReader`; re-thrown with event `loadRulesDataError` | Job fails at startup; no data processed |
| JSON deserialization failure | `IOException` from Jackson; propagates up; job fails at startup | Job fails at startup; no data processed |
| Empty rules list returned | No explicit handling; `DealsClusterJob` iterates over an empty list and exits cleanly | No clusters produced; no error emitted |

## Sequence Diagram

```
DealsClusterJob -> ClustersGenerator: generate(filePath, countries, ruleName, excludeRules, date)
ClustersGenerator -> DealsClustersRulesReader: getRules(cluster_rule_source, hb_url, ruleName)
DealsClustersRulesReader -> GenericReader: loadData(url + "?name=ruleName" [optional], hbUrl)
GenericReader -> DealsClusterRulesAPI: HTTPS GET /rules [?name=<ruleName>] (Host: hb_url)
DealsClusterRulesAPI --> GenericReader: JSON array of Rule objects
GenericReader --> DealsClustersRulesReader: InputStreamReader
DealsClustersRulesReader -> JSONUtil: deserialize(reader, List<Rule>.class)
JSONUtil --> DealsClustersRulesReader: List<Rule>
DealsClustersRulesReader --> ClustersGenerator: List<Rule>
ClustersGenerator -> ClustersGenerator: filter(excludeRules)
ClustersGenerator -> Logger: PROCESSING_RULES info event
```

## Related

- Architecture dynamic view: `dynamic-dealsClusterJob`
- Related flows: [Deals Cluster Job Execution](deals-cluster-job-execution.md), [Top Clusters Job Execution](top-clusters-job-execution.md)
