---
service: "getaways-partner-integrator"
title: "Partner Reservation Inbound"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "partner-reservation-inbound"
flow_type: synchronous
trigger: "Inbound SOAP reservation notification from a channel manager (SiteMinder)"
participants:
  - "siteminderChannelManager_6b1c"
  - "continuumGetawaysPartnerIntegrator"
  - "soapApi"
  - "reservationService"
  - "getawaysPartnerIntegrator_mappingService"
  - "partnerSoapClient"
  - "getawaysPartnerIntegrator_persistenceLayer"
  - "continuumGetawaysPartnerIntegratorDb"
architecture_ref: "components-getawaysPartnerIntegratorComponents"
---

# Partner Reservation Inbound

## Summary

SiteMinder sends an inbound SOAP reservation notification to the `/SiteConnectService` endpoint when a hotel booking is created or cancelled by a traveler. The service authenticates the WS-Security header, processes the reservation through the Reservation Service, persists the record to MySQL, and sends an outbound SOAP confirmation call back to the channel manager via the Channel Manager Client. All outbound SOAP request/response payloads are logged to MySQL for audit and replay purposes.

## Trigger

- **Type**: api-call (inbound SOAP)
- **Source**: SiteMinder channel manager — triggered when a hotel reservation is created, modified, or cancelled
- **Frequency**: On demand — driven by traveler booking activity at the channel manager

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| SiteMinder Channel Manager | Sends inbound reservation SOAP notification | `siteminderChannelManager_6b1c` |
| SOAP API | Receives, authenticates, and routes reservation request | `soapApi` |
| Reservation Service | Processes reservation creation, update, or cancellation | `reservationService` |
| Mapping Service | Coordinates reservation workflow; resolves inventory identifiers | `getawaysPartnerIntegrator_mappingService` |
| Channel Manager Client | Sends outbound SOAP reservation confirmation to SiteMinder | `partnerSoapClient` |
| Persistence Layer | Persists reservation records and SOAP logs to MySQL | `getawaysPartnerIntegrator_persistenceLayer` |
| Getaways Partner Integrator DB | Stores reservation records and SOAP request/response audit logs | `continuumGetawaysPartnerIntegratorDb` |

## Steps

1. **Receives reservation SOAP notification**: SiteMinder sends a SOAP reservation message (booking, modification, or cancellation) to `/SiteConnectService`.
   - From: `siteminderChannelManager_6b1c`
   - To: `soapApi`
   - Protocol: SOAP / WS-Security

2. **Authenticates WS-Security header**: SOAP API validates the WS-Security credentials using Apache CXF and WSS4J.
   - From: `soapApi`
   - To: `soapApi` (WS-Security interceptor)
   - Protocol: WS-Security

3. **Delegates to Reservation Service**: SOAP API routes the parsed reservation payload to the Reservation Service.
   - From: `soapApi`
   - To: `reservationService`
   - Protocol: Direct (in-process)

4. **Resolves mapping via Mapping Service**: Reservation Service coordinates with the Mapping Service to resolve Groupon inventory identifiers for the hotel, room, and rate plan referenced in the reservation.
   - From: `reservationService`
   - To: `getawaysPartnerIntegrator_mappingService`
   - Protocol: Direct (in-process)

5. **Reads mapping records**: Mapping Service reads hotel/room/rate plan mappings from MySQL to resolve identifiers.
   - From: `getawaysPartnerIntegrator_mappingService` → `getawaysPartnerIntegrator_persistenceLayer`
   - To: `continuumGetawaysPartnerIntegratorDb`
   - Protocol: JDBC / MySQL

6. **Persists reservation record**: Persistence Layer writes the reservation (or cancellation) record to MySQL.
   - From: `reservationService` → `getawaysPartnerIntegrator_persistenceLayer`
   - To: `continuumGetawaysPartnerIntegratorDb`
   - Protocol: JDBC / MySQL

7. **Sends outbound SOAP confirmation**: Reservation Service instructs the Channel Manager Client to send a SOAP confirmation (or cancellation acknowledgement) back to SiteMinder.
   - From: `reservationService` → `partnerSoapClient`
   - To: `siteminderChannelManager_6b1c`
   - Protocol: SOAP / WS-Security

8. **Logs SOAP request/response**: Channel Manager Client persists the outbound SOAP request and partner response to MySQL for audit and replay.
   - From: `partnerSoapClient` → `getawaysPartnerIntegrator_persistenceLayer`
   - To: `continuumGetawaysPartnerIntegratorDb`
   - Protocol: JDBC / MySQL

9. **Returns SOAP response**: SOAP API returns success or fault to SiteMinder.
   - From: `soapApi`
   - To: `siteminderChannelManager_6b1c`
   - Protocol: SOAP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| WS-Security authentication failure | CXF interceptor rejects request | SOAP Fault returned; reservation not processed |
| Mapping not found for reservation identifiers | Mapping Service returns error to Reservation Service | Reservation not persisted; SOAP Fault returned |
| MySQL write failure on reservation record | JDBC exception | Reservation not saved; SOAP Fault returned |
| Outbound SOAP confirmation failure (SiteMinder unavailable) | `partnerSoapClient` logs failure to MySQL | SOAP error logged; confirmation not delivered; manual replay needed |

## Sequence Diagram

```
SiteMinder -> soapApi: SOAP reservation notification (WS-Security)
soapApi -> soapApi: Validate WS-Security credentials
soapApi -> reservationService: Process reservation payload
reservationService -> mappingService: Resolve inventory identifiers
mappingService -> persistenceLayer: Read hotel/room/rate mapping
persistenceLayer -> MySQL: SELECT mappings
MySQL --> persistenceLayer: Mapping records
persistenceLayer --> mappingService: Resolved identifiers
mappingService --> reservationService: Identifiers resolved
reservationService -> persistenceLayer: Persist reservation record
persistenceLayer -> MySQL: INSERT reservation
MySQL --> persistenceLayer: OK
reservationService -> partnerSoapClient: Send SOAP confirmation to SiteMinder
partnerSoapClient -> SiteMinder: SOAP confirmation/cancellation
SiteMinder --> partnerSoapClient: SOAP response
partnerSoapClient -> persistenceLayer: Log request/response
persistenceLayer -> MySQL: INSERT SOAP audit log
MySQL --> persistenceLayer: OK
reservationService --> soapApi: Processing result
soapApi --> SiteMinder: SOAP response (success or fault)
```

## Related

- Architecture dynamic view: `components-getawaysPartnerIntegratorComponents`
- Related flows: [Partner Availability Inbound](partner-availability-inbound.md), [Inventory Mapping REST API](inventory-mapping-rest-api.md)
