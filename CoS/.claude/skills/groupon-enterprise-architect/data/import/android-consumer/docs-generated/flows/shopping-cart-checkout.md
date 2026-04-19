---
service: "android-consumer"
title: "Shopping Cart and Checkout"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "shopping-cart-checkout"
flow_type: synchronous
trigger: "User taps 'Add to Cart' on a deal or proceeds to checkout"
participants:
  - "androidConsumer_appEntryPoints"
  - "androidConsumer_featureModules"
  - "androidConsumer_networkIntegration"
  - "androidConsumer_localPersistence"
  - "androidConsumer_telemetryAndCrash"
  - "continuumAndroidLocalStorage"
  - "apiProxy"
  - "adyen"
architecture_ref: "dynamic-android-consumer-checkout"
---

# Shopping Cart and Checkout

## Summary

The shopping cart and checkout flow begins when a user adds a deal to their cart and ends with an order confirmation or payment failure. Cart mutations are sent to `apiProxy` and the cart state is cached locally in Room. During checkout, the app initiates a checkout session via `apiProxy`, invokes the Adyen Android SDK for 3D Secure payment processing, and submits the final payment result back to `apiProxy` to confirm the order. Analytics events are emitted at each major stage.

## Trigger

- **Type**: user-action
- **Source**: User taps "Add to Cart" on a deal detail screen, or taps "Checkout" from the cart screen
- **Frequency**: On demand — per purchase intent

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| App Entry Points | Routes user to deal detail, cart, and checkout screens | `androidConsumer_appEntryPoints` |
| Feature Modules (Checkout) | Orchestrates cart CRUD, checkout session, and payment submission | `androidConsumer_featureModules` |
| Network Integration Layer | Issues cart and checkout API calls via Retrofit | `androidConsumer_networkIntegration` |
| Local Persistence Layer | Caches cart state locally for offline read | `androidConsumer_localPersistence` |
| Android Local Storage | Stores cart cache | `continuumAndroidLocalStorage` |
| Groupon Backend APIs | Manages cart state and processes checkout | `apiProxy` |
| Adyen SDK | Renders 3D Secure payment UI and processes card challenge | External (Adyen Android SDK 5.16.0) |
| Telemetry and Crash Reporting | Emits cart and purchase analytics events | `androidConsumer_telemetryAndCrash` |

## Steps

1. **User taps "Add to Cart"**: User selects a deal and taps the add-to-cart button on the deal detail screen.
   - From: `androidConsumer_appEntryPoints`
   - To: `androidConsumer_featureModules`
   - Protocol: Direct (Android UI event)

2. **Checkout module sends add-to-cart request**: Feature module calls Network Integration Layer to `POST /cart/*` with the deal SKU and quantity.
   - From: `androidConsumer_featureModules`
   - To: `androidConsumer_networkIntegration`
   - Protocol: Direct (Kotlin Coroutine)

3. **Network Integration Layer calls `apiProxy`**: Retrofit issues `POST /cart/*` with OAuth 2.0 bearer token.
   - From: `androidConsumer_networkIntegration`
   - To: `apiProxy`
   - Protocol: HTTPS/REST

4. **`apiProxy` returns updated cart**: Response contains current cart contents and item count.
   - From: `apiProxy`
   - To: `androidConsumer_networkIntegration`
   - Protocol: HTTPS/REST

5. **Cart state cached in Room**: Network Integration Layer writes the updated cart payload to `continuumAndroidLocalStorage` via `androidConsumer_localPersistence`.
   - From: `androidConsumer_networkIntegration`
   - To: `androidConsumer_localPersistence` → `continuumAndroidLocalStorage`
   - Protocol: Direct (Room DAO)

6. **Cart UI updated and analytics emitted**: Feature module renders the updated cart; emits `add_to_cart` analytics event.
   - From: `androidConsumer_featureModules`
   - To: `androidConsumer_telemetryAndCrash`
   - Protocol: Direct

7. **User reviews cart and taps "Checkout"**: User navigates to the cart screen, reviews items, and proceeds to checkout.
   - From: `androidConsumer_appEntryPoints`
   - To: `androidConsumer_featureModules`
   - Protocol: Direct

8. **Checkout module initiates checkout session**: Feature module calls `POST /checkout/*` via Network Integration Layer to create a checkout session; `apiProxy` returns payment session data including Adyen payment session token.
   - From: `androidConsumer_featureModules` → `androidConsumer_networkIntegration`
   - To: `apiProxy`
   - Protocol: HTTPS/REST

9. **Adyen SDK launched for 3D Secure payment**: Feature module launches the Adyen Checkout Android SDK with the payment session token; Adyen renders the card entry and 3DS challenge UI.
   - From: `androidConsumer_featureModules`
   - To: Adyen SDK (in-process)
   - Protocol: Android SDK

10. **User completes 3DS card challenge**: Adyen SDK handles card entry, issuer authentication challenge, and returns a payment result (success / failure / cancelled).
    - From: Adyen SDK
    - To: `androidConsumer_featureModules`
    - Protocol: Android SDK callback

11. **Payment result submitted to `apiProxy`**: Feature module sends the Adyen payment result token to `POST /checkout/*` to confirm or cancel the order.
    - From: `androidConsumer_featureModules` → `androidConsumer_networkIntegration`
    - To: `apiProxy`
    - Protocol: HTTPS/REST

12. **Order confirmation displayed**: On success, `apiProxy` returns order ID and confirmation data; Feature module navigates to the order confirmation screen.
    - From: `apiProxy`
    - To: `androidConsumer_featureModules` → UI
    - Protocol: HTTPS/REST → Direct

13. **Purchase analytics emitted**: Feature module emits `purchase` event (order ID, value, items) to Firebase Analytics and Bloomreach.
    - From: `androidConsumer_featureModules`
    - To: `androidConsumer_telemetryAndCrash`
    - Protocol: Direct

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Add-to-cart API failure | Show error toast; local cart unchanged | User retries; no charge made |
| Checkout session creation failure | Show error; remain on cart screen | User retries; no charge made |
| Adyen 3DS challenge failed (wrong PIN/OTP) | Adyen SDK returns failure result | User is prompted to retry or use different card |
| Adyen SDK cancelled by user | SDK returns cancelled result | User is returned to cart/checkout screen |
| Payment confirmation call fails (network loss after 3DS) | Show error; order state uncertain | User directed to check order history; support escalation path |
| `apiProxy` checkout timeout | OkHttp timeout fires | User sees error; no duplicate order risk (idempotency on backend) |

## Sequence Diagram

```
User -> appEntryPoints: Tap "Add to Cart"
appEntryPoints -> featureModules: AddToCart(dealId, qty)
featureModules -> networkIntegration: POST /cart/*
networkIntegration -> apiProxy: POST /cart/* [OAuth token]
apiProxy --> networkIntegration: Updated cart JSON
networkIntegration -> localPersistence: Write cart to Room
featureModules -> telemetryAndCrash: Emit add_to_cart event

User -> appEntryPoints: Tap "Checkout"
appEntryPoints -> featureModules: StartCheckout
featureModules -> networkIntegration: POST /checkout/* (initiate)
networkIntegration -> apiProxy: POST /checkout/* [OAuth token]
apiProxy --> networkIntegration: Checkout session + Adyen token
featureModules -> AdyenSDK: Launch 3DS payment UI
AdyenSDK --> featureModules: PaymentResult (success/failure)
featureModules -> networkIntegration: POST /checkout/* (confirm payment)
networkIntegration -> apiProxy: POST /checkout/* [OAuth token + Adyen result]
apiProxy --> networkIntegration: Order confirmation
featureModules -> UI: Show order confirmation screen
featureModules -> telemetryAndCrash: Emit purchase event
```

## Related

- Architecture dynamic view: `dynamic-android-consumer-checkout` (not yet modeled in DSL)
- Related flows: [Deal Discovery and Browse](deal-discovery-browse.md), [User Authentication](user-authentication.md), [Analytics and Telemetry Collection](analytics-telemetry-collection.md)
