---
service: "global_subscription_service"
title: "Subscription List Management"
generated: "2026-03-03"
type: flow
flow_name: "subscription-list-management"
flow_type: synchronous
trigger: "HTTP POST or PUT to /lists/list/{country_code}/{list_type}/{list_id}"
participants:
  - "globalSubscriptionService"
  - "continuumSmsConsentPostgres"
architecture_ref: "components-globalSubscriptionService-components"
---

# Subscription List Management

## Summary

This flow handles the creation and visibility management of email and SMS subscription list definitions. Subscription lists define the categories of notifications available per country and list type (e.g., promotional emails, deal alerts). Internal admin tools and marketing systems create or update list definitions, which are then used to scope which consent types are visible and active for consumers in a given country.

## Trigger

- **Type**: api-call
- **Source**: Internal admin tooling, marketing configuration systems
- **Frequency**: On demand — when new notification categories are introduced or list visibility changes

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Email Subscription API Resources | Receives and validates list management requests | `emailSubscriptionApi` |
| Subscription Managers | Applies business logic for list creation and visibility update | `subscriptionManagers` |
| SMS Consent Repository | Persists list definitions to the database | `smsConsentRepository` |
| SMS Consent Postgres | Stores subscription list records (`subscription_lists` table) | `continuumSmsConsentPostgres` |

## Steps

### Create Subscription List

1. **Receive create request**: Admin tool calls `POST /lists/list/{country_code}/{list_type}/{list_id}` with a `SubscriptionListCreationMetaData` body containing list name, description, and visibility settings.
   - From: Admin tool
   - To: `emailSubscriptionApi`
   - Protocol: REST / HTTP

2. **Validate request**: API validates that `country_code`, `list_type`, and `list_id` path parameters are present and non-null. Returns HTTP 400 if missing.
   - From: `emailSubscriptionApi`
   - To: `subscriptionManagers`
   - Protocol: Direct / Java

3. **Persist list definition**: Subscription Managers instructs SMS Consent Repository to insert the new subscription list record into `continuumSmsConsentPostgres` with the provided metadata.
   - From: `subscriptionManagers` → `smsConsentRepository`
   - To: `continuumSmsConsentPostgres`
   - Protocol: JDBC / PostgreSQL

4. **Return response**: API returns HTTP 200 (or 201) confirming the list was created.
   - From: `emailSubscriptionApi`
   - To: Admin tool
   - Protocol: REST / HTTP (JSON)

### Update List Visibility

1. **Receive visibility update**: Admin tool calls `PUT /lists/list/visible/{country_code}/{list_type}/{list_id}` with a `SubscriptionListCreationMetaData` body containing the new visibility flag.
   - From: Admin tool
   - To: `emailSubscriptionApi`
   - Protocol: REST / HTTP

2. **Validate and update**: API validates parameters; Subscription Managers updates the `visible` field on the existing subscription list record.
   - From: `subscriptionManagers` → `smsConsentRepository`
   - To: `continuumSmsConsentPostgres`
   - Protocol: JDBC / PostgreSQL

3. **Return response**: API returns HTTP 200 with updated list data.
   - From: `emailSubscriptionApi`
   - To: Admin tool
   - Protocol: REST / HTTP (JSON)

### List Retrieval

1. **Receive list query**: Caller sends `GET /lists/{country_code}?listTypes=<types>` to retrieve active subscription lists for a country filtered by list type.
   - From: Any consumer
   - To: `emailSubscriptionApi`
   - Protocol: REST / HTTP

2. **Query database**: Subscription Managers queries `continuumSmsConsentPostgres` for subscription lists matching the country code and list types.
   - From: `subscriptionManagers` → `smsConsentRepository`
   - To: `continuumSmsConsentPostgres`
   - Protocol: JDBC / PostgreSQL

3. **Return list**: API returns HTTP 200 with the matching subscription list records.
   - From: `emailSubscriptionApi`
   - To: Caller
   - Protocol: REST / HTTP (JSON)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Missing country_code or list_type | Return HTTP 400 `Query Param country_code / locale may not be null` | List not created/updated |
| country_code or list_type not found | Return HTTP 404 with `ErrorResponse` | List not created/updated |
| Database write failure | Exception propagated; HTTP 500 | List not persisted |

## Sequence Diagram

```
AdminTool -> emailSubscriptionApi: POST /lists/list/{country_code}/{list_type}/{list_id}
emailSubscriptionApi -> subscriptionManagers: create list request
subscriptionManagers -> continuumSmsConsentPostgres: INSERT subscription_lists record
continuumSmsConsentPostgres --> subscriptionManagers: OK
emailSubscriptionApi --> AdminTool: 200 OK / list metadata

AdminTool -> emailSubscriptionApi: PUT /lists/list/visible/{country_code}/{list_type}/{list_id}
emailSubscriptionApi -> subscriptionManagers: update visibility request
subscriptionManagers -> continuumSmsConsentPostgres: UPDATE visible flag
continuumSmsConsentPostgres --> subscriptionManagers: OK
emailSubscriptionApi --> AdminTool: 200 OK
```

## Related

- Architecture dynamic view: No dynamic view defined — see `components-globalSubscriptionService-components`
- Related flows: [SMS Consent Creation](sms-consent-creation.md)
