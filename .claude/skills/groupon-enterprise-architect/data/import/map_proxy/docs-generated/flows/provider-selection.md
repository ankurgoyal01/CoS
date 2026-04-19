---
service: "map_proxy"
title: "Provider Selection"
generated: "2026-03-03"
type: flow
flow_name: "provider-selection"
flow_type: synchronous
trigger: "Inbound map request (any v2 endpoint)"
participants:
  - "mapProxy_providerSelection"
  - "mapProxy_googleAdapter"
  - "mapProxy_yandexAdapter"
architecture_ref: "components-continuum-map-proxy-service"
---

# Provider Selection

## Summary

Provider selection is a cross-cutting logic flow invoked by both the v2 static and v2 dynamic endpoints. It determines which upstream map provider — Google Maps V3 or Yandex Maps V2 — should handle a given request, based on the geographic context of the caller. The decision is made by the `MapProvider.create()` factory method and results in instantiation of either a `GoogleV3Provider` or a `YandexV2Provider`. The selected provider is then used to build the upstream URL for the request.

## Trigger

- **Type**: api-call (internal to MapProxy, invoked per inbound v2 request)
- **Source**: `StaticMapsV2Servlet` or `DynamicMapsV2Servlet` after parameter validation
- **Frequency**: Once per v2 map request

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Provider Selection | Core logic that resolves country and instantiates the correct provider | `mapProxy_providerSelection` |
| Google Maps Adapter | Instantiated when the country is not in the Yandex list (or unknown) | `mapProxy_googleAdapter` |
| Yandex Maps Adapter | Instantiated when the country is in the Yandex country list | `mapProxy_yandexAdapter` |

## Steps

1. **Receive country context**: `MapProvider.create(request, country)` is called with the HTTP servlet request and the `country` query parameter value (may be null or blank).
   - From: `mapProxy_requestIngress`
   - To: `mapProxy_providerSelection`
   - Protocol: direct

2. **Resolve country from query parameter**: If the `country` query parameter is non-blank, use it as the country code. Log: `Processing request from country code: {country}`.
   - From: `mapProxy_providerSelection`
   - To: `mapProxy_providerSelection` (internal)
   - Protocol: direct

3. **Resolve country from X-Country header**: If the query parameter is blank, check the `X-Country` HTTP header. If present and non-null, use it as the country code. Log: `Processing request from X-Country: {country}`.
   - From: `mapProxy_providerSelection`
   - To: `mapProxy_providerSelection` (internal)
   - Protocol: direct

4. **Resolve country from Referer TLD**: If the `X-Country` header is also null, parse the host from the `Referer` request header. Extract the TLD (last dot-separated segment of the hostname) as the country code. Log: `Processing request from Referer: {host}`.
   - From: `mapProxy_providerSelection`
   - To: `mapProxy_providerSelection` (internal, regex/URL parsing)
   - Protocol: direct

5. **Resolve country from Host header**: If the `Referer` header is also absent, parse the host from the `Host` request header and extract the TLD. Log: `Processing request from Host: {host}`. This is intended only for local/development use.
   - From: `mapProxy_providerSelection`
   - To: `mapProxy_providerSelection` (internal)
   - Protocol: direct

6. **Yandex country check**: Converts the resolved country code to uppercase and checks whether it is present in the `MapProxy.yandex.countryList` configuration (a comma-separated list of ISO country codes loaded at startup). If the country is in the list, instantiates `YandexV2Provider`. Otherwise instantiates `GoogleV3Provider`.
   - From: `mapProxy_providerSelection`
   - To: `mapProxy_yandexAdapter` or `mapProxy_googleAdapter`
   - Protocol: direct (Java constructor)

7. **Default to Google**: If the country code is blank after all resolution steps, `GoogleV3Provider` is instantiated without any country-based logic. This is the safe default.
   - From: `mapProxy_providerSelection`
   - To: `mapProxy_googleAdapter`
   - Protocol: direct

8. **Return provider to caller**: The concrete `MapProvider` instance is returned to the calling servlet, which uses it to build the upstream URL via `provider.buildQueryUrl(...)` (for static) or `provider.getDynamicLibraryUrl()` (for dynamic).
   - From: `mapProxy_providerSelection`
   - To: `mapProxy_requestIngress`
   - Protocol: direct

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| `country` param, `X-Country` header, Referer, and Host are all absent or blank | Defaults to `GoogleV3Provider` | Google is used; no error |
| `MalformedURLException` parsing Referer or Host | Logs the exception; country remains blank → defaults to Google | Google is used |
| Country code not in Yandex list | `GoogleV3Provider` is used | Google is used |
| Country code is in Yandex list | `YandexV2Provider` is used | Yandex is used |

## Sequence Diagram

```
mapProxy_requestIngress -> mapProxy_providerSelection: MapProvider.create(request, country)
mapProxy_providerSelection -> mapProxy_providerSelection: check country query param (non-blank?)
mapProxy_providerSelection -> mapProxy_providerSelection: [blank] check X-Country header
mapProxy_providerSelection -> mapProxy_providerSelection: [null] parse Referer host TLD
mapProxy_providerSelection -> mapProxy_providerSelection: [null] parse Host header TLD
mapProxy_providerSelection -> mapProxy_providerSelection: countryCode.toUpperCase()
mapProxy_providerSelection -> mapProxy_providerSelection: yandexCountryList.contains(countryCode)?
mapProxy_providerSelection -> mapProxy_yandexAdapter: new YandexV2Provider() [yes]
mapProxy_yandexAdapter --> mapProxy_providerSelection: YandexV2Provider instance
mapProxy_providerSelection -> mapProxy_googleAdapter: new GoogleV3Provider() [no or blank]
mapProxy_googleAdapter --> mapProxy_providerSelection: GoogleV3Provider instance
mapProxy_providerSelection --> mapProxy_requestIngress: MapProvider instance
```

## Related

- Architecture dynamic view: `dynamic-map-proxy-static-request`
- Related flows: [Static Map Request (v2)](static-map-request-v2.md), [Dynamic Map JavaScript Request (v2)](dynamic-map-js-request-v2.md)
