---
service: "badges-service"
title: "Localization Cache Refresh Job"
generated: "2026-03-03"
type: flow
flow_name: "localization-cache-refresh"
flow_type: scheduled
trigger: "Quartz schedule — LocalizationJob (ENABLE_JOBS=true)"
participants:
  - "externalClientGateway"
  - "continuumLocalizationApi"
architecture_ref: "dynamic-badgeLookupFlow"
---

# Localization Cache Refresh Job

## Summary

This scheduled job keeps the in-memory localization cache populated with current localized string packages. The `LocalizationJob` calls the Localization API to fetch the latest badge-related localized strings for the configured locale/package, then passes the result to `LocalizationUtil.populateCache()` which updates the in-memory cache used by the badge decoration step during request handling.

## Trigger

- **Type**: schedule
- **Source**: Quartz scheduler within the `jobs` deployment component (`ENABLE_JOBS=true`); schedule interval configured via the `quartz` block in the per-environment YAML run config
- **Frequency**: Scheduled (cron interval defined in YAML run config)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| LocalizationJob | Drives the fetch and cache population; invoked by Quartz | `externalClientGateway` (via `LocalizationClient`) |
| LocalizationClient | Issues the HTTP call to the Localization API | `externalClientGateway` |
| Localization API | Returns the current localized string package for badges | `continuumLocalizationApi` |
| LocalizationUtil (in-memory cache) | Stores the fetched strings for use during badge decoration | Internal (`badgeEngine`) |

## Steps

1. **Job triggered by Quartz scheduler**: The Quartz scheduler fires `LocalizationJob` on its configured schedule within the `jobs` pod.
   - From: Quartz scheduler
   - To: `LocalizationJob`
   - Protocol: In-process (JTier Quartz bundle)

2. **Log job trigger**: The job logs `"LocalizationClient triggered"` at INFO level.
   - From/To: `LocalizationJob` (internal)
   - Protocol: Direct (in-process)

3. **Fetch localization data package**: The job calls `LocalizationClient.fetchLocalizationDataForPackage()` which issues an HTTP request to the Localization API to retrieve the current badge-related localized strings.
   - From: `LocalizationClient`
   - To: `continuumLocalizationApi`
   - Protocol: HTTPS/JSON

4. **Populate in-memory cache**: If the API returns a non-empty `Optional<JsonNode>`, the job calls `LocalizationUtil.populateCache(node)` to update the in-memory localization string store.
   - From: `LocalizationJob`
   - To: `LocalizationUtil` (in-memory)
   - Protocol: Direct (in-process)

5. **Log success**: The job logs `"LocalizationClient success"` at INFO level.
   - From/To: `LocalizationJob` (internal)
   - Protocol: Direct (in-process)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Localization API returns empty or unavailable | `Optional.empty()` returned by `fetchLocalizationDataForPackage()`; `ifPresent` guard means `populateCache` is not called | In-memory cache retains previously loaded strings; badge display text remains from last successful fetch; no exception thrown |
| Localization API throws exception | Exception propagates up to `JTierJob.run()`; JTier Quartz bundle handles and logs the failure | Cache not updated; next scheduled run will retry |

## Sequence Diagram

```
QuartzScheduler -> LocalizationJob: Fire scheduled job
LocalizationJob -> LocalizationClient: fetchLocalizationDataForPackage()
LocalizationClient -> continuumLocalizationApi: HTTPS GET localized strings package
continuumLocalizationApi --> LocalizationClient: JSON string package
LocalizationClient --> LocalizationJob: Optional<JsonNode>
LocalizationJob -> LocalizationUtil: populateCache(jsonNode)
LocalizationUtil -> LocalizationUtil: Update in-memory string map
```

## Related

- Related flows: [Merchandising Badge Refresh Job](merchandising-badge-refresh.md), [Badge Lookup Request](badge-lookup-request.md)
- Configuration: [Configuration](../configuration.md) — `localizationConfig`, `quartz`, `ENABLE_JOBS`
- Integrations: [Integrations](../integrations.md) — Localization API detail
