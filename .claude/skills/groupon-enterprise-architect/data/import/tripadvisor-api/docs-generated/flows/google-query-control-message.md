---
service: "tripadvisor-api"
title: "Google Query Control Message"
generated: "2026-03-03"
type: flow
flow_name: "google-query-control-message"
flow_type: synchronous
trigger: "POST /google/query_control_message from Google Hotel Ads"
participants:
  - "continuumGoogleHotelAds"
  - "continuumTripadvisorApiV1Webapp"
  - "googleQueryControlMessageController"
  - "queryControlMessageFactory"
architecture_ref: "dynamic-google-query-control-message"
---

# Google Query Control Message

## Summary

Google Hotel Ads requests a query control message to understand what booking itineraries and length-of-stay constraints Groupon Getaways supports. The service reads a static pre-configured XML document and returns it as a `QueryControl` XML response. This is a lightweight, near-static flow with no upstream API calls — the control message is built from configuration, not live data.

## Trigger

- **Type**: api-call
- **Source**: `continuumGoogleHotelAds` (Google Hotel Ads integration)
- **Frequency**: On demand; typically infrequent polling by Google

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Google Hotel Ads | Requests booking capability constraints | `continuumGoogleHotelAds` |
| TripAdvisor API v1 Webapp | Receives request and coordinates response | `continuumTripadvisorApiV1Webapp` |
| Google Query Control Message Controller | Routes request to factory | `googleQueryControlMessageController` |
| Query Control Message Factory | Builds the `QueryControl` XML response from static config | `queryControlMessageFactory` |

## Steps

1. **Receives query control message request**: Google Hotel Ads sends `POST /google/query_control_message` to the service.
   - From: `continuumGoogleHotelAds`
   - To: `googleQueryControlMessageController`
   - Protocol: HTTPS

2. **Delegates to factory**: Controller calls `QueryControlMessageFactory` to build the response.
   - From: `googleQueryControlMessageController`
   - To: `queryControlMessageFactory`
   - Protocol: direct

3. **Loads static control message**: Factory reads the pre-configured XML file from `google/google-query-control-message.xml` (configured via `google.queryControlMessage.location` property). The file defines `ItineraryCapabilities`, `HintControl`, and per-property constraints (`MinLengthOfStay`, `MaxLengthOfStay`, `MinAdvancePurchase`, `MaxAdvancePurchase`).
   - From: `queryControlMessageFactory`
   - To: file system / classpath resource
   - Protocol: direct

4. **Returns QueryControl XML**: Controller returns the `QueryControl` XML document (JAXB-generated type from `xsd/query_control.xsd`) to Google Hotel Ads.
   - From: `googleQueryControlMessageController`
   - To: `continuumGoogleHotelAds`
   - Protocol: HTTPS

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Static config file missing | IOException / resource load failure | HTTP 500 Internal Server Error |
| JAXB marshalling failure | XML serialization exception | HTTP 500 Internal Server Error |

## Sequence Diagram

```
continuumGoogleHotelAds -> googleQueryControlMessageController: POST /google/query_control_message
googleQueryControlMessageController -> queryControlMessageFactory: Build QueryControl response
queryControlMessageFactory -> queryControlMessageFactory: Load google-query-control-message.xml from classpath
queryControlMessageFactory --> googleQueryControlMessageController: QueryControl object
googleQueryControlMessageController --> continuumGoogleHotelAds: QueryControl XML response
```

## Related

- Architecture dynamic view: `dynamic-google-query-control-message` (not yet defined in `architecture/views/dynamics.dsl`)
- Related flows: [Google Transaction Query](google-transaction-query.md), [Google Hotel List Feed](google-hotel-list-feed.md)
- Static config: `google.queryControlMessage.location=google/google-query-control-message.xml` in `settings.properties`
- Query control XSD: `ta-api-v1/src/main/resources/xsd/query_control.xsd`
