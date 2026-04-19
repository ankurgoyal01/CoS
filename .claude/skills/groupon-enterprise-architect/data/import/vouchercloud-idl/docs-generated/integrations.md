---
service: "vouchercloud-idl"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 9
internal_count: 3
---

# Integrations

## Overview

Vouchercloud IDL integrates with nine external systems spanning search (Algolia), rewards (Giftcloud), loyalty (EagleEye Air), marketing/CRM (Blueshift, Google Analytics), Groupon platform (Wolfhound), AWS infrastructure services (SNS, SQS, Secrets Manager, CloudWatch), and social auth providers (Facebook, Google, Apple). Internally, the web-tier containers (`continuumVcWebSite`, `continuumWhiteLabelWebSite`, `continuumHoldingPagesWebSite`) are the primary consumers of the API containers.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Algolia | rest (SDK) | Offer and merchant full-text search | yes | `algoliaSearch_41e0` (stub) |
| Giftcloud API | rest | Rewards: initialise, claim, and download gift rewards per country | yes | External |
| EagleEye Air | rest | Loyalty and promotional code validation | no | External |
| AWS SNS | sdk | Publish offer rejection, community codes, user feedback, rewards failure notifications | yes | `awsSns_2b51` (stub) |
| AWS SQS | sdk | Analytics event queue (user interactions, affiliate events) | yes | `awsSqs_7c8e` (stub) |
| AWS Secrets Manager | sdk | Runtime credential retrieval for all data stores and integrations | yes | External |
| AWS CloudWatch | sdk | Custom timing metrics buffered and submitted to CloudWatch | no | External |
| Wolfhound (Groupon Platform) | rest | Groupon platform integration (base URL: `https://api.groupon.com`) | no | External |
| Blueshift | rest | CRM event upload (base URL: `https://api.getblueshift.com/api/v1`) | no | External |
| Google Analytics | rest | Analytics upload (base URL: `https://www.google-analytics.com`) | no | External |
| Facebook Graph API | rest | Facebook access token verification (`https://graph.facebook.com/v3.0/`) | yes (for FB auth) | External |
| Apple ID (OIDC) | rest | Apple Sign-In key retrieval (`https://appleid.apple.com/auth/keys`) | yes (for Apple auth) | External |

### Algolia Detail

- **Protocol**: REST SDK (`Algolia.Search` 7.34.0)
- **Base URL / SDK**: `AlgoliaApplicationId=<REDACTED>` (per environment); `AlgoliaApiKey` and `AlgoliaOfferIndexName` / `AlgoliaMerchantIndexName` configured per environment
- **Auth**: Algolia API key via `appSettings`
- **Purpose**: Powers offer full-text search (`/offers/search`) and merchant search using Algolia hosted indexes
- **Failure mode**: Search requests fail; offer/merchant listings via MongoDB are unaffected
- **Circuit breaker**: Polly (`Polly` 7.2.2) used for resilience patterns; specific Algolia circuit breaker not confirmed

### Giftcloud API Detail

- **Protocol**: REST (`Coupons.GiftcloudApiClient` 2.9.0)
- **Base URL / SDK**: `https://api-staging.giftcloud.com` (staging); production URL injected via Secrets Manager
- **Auth**: Per-country API credentials (`IDL-VCAPI-GCAPI{country}User`, `IDL-VCAPI-GCAPI{country}Password`, `IDL-VCAPI-GCAPI{country}Key`) for GB, US, IE, FR, DE, IT, AU, ES, USgroupon
- **Purpose**: Initialise, claim, and download gift card rewards for supported countries; CloudCoins balance operations
- **Failure mode**: Rewards flows fail; SNS topic `Vouchercloud-{env}-RewardsInitialiseFailed` is published on error
- **Circuit breaker**: Not confirmed from codebase

### EagleEye Air Detail

- **Protocol**: REST
- **Base URL / SDK**: `https://consumer.sandbox.uk.eagleeye.com/2.0` (staging; production URL in Secrets Manager)
- **Auth**: `ClientId` and `Secret` via `eagleEyeAir` config section in `Web.config`
- **Purpose**: Loyalty and promotional code validation for in-store rewards flow
- **Failure mode**: Code validation fails gracefully; offer display not affected
- **Circuit breaker**: No evidence found in codebase

### AWS SNS Detail

- **Protocol**: AWS SDK (`AWSSDK.SimpleNotificationService` 3.7.0.12)
- **Base URL / SDK**: Topics in `eu-west-1` region; ARNs configured in `restfulApi` config section
- **Auth**: EC2 IAM instance role (`idl-vpc-web-ec2-role`)
- **Purpose**: Publish lifecycle notifications — offer rejection, community codes, offer invalidation, user feedback, rewards failures, gift merchant mapping not found
- **Failure mode**: Notification delivery fails silently; primary API response unaffected
- **Circuit breaker**: No evidence found

### AWS SQS Detail

- **Protocol**: AWS SDK (`AWSSDK.SQS` 3.7.2.63)
- **Base URL / SDK**: Queue URL in `analyticsSqsQueueUrl` config key; Lambda delivery via `analyticsUseSqsLambda="true"`
- **Auth**: EC2 IAM instance role
- **Purpose**: Analytics event ingestion for user interactions
- **Failure mode**: Analytics events dropped; primary API response unaffected
- **Circuit breaker**: No evidence found

### Wolfhound Detail

- **Protocol**: REST (`RestSharp` 106.15.0)
- **Base URL / SDK**: `https://api.groupon.com` (configured via `Wolfhound:BaseUrl` appSetting)
- **Auth**: Client ID via `Wolfhound:ClientId` appSetting
- **Purpose**: Groupon platform integration for cross-platform data or user linking
- **Failure mode**: Wolfhound-dependent features degrade gracefully
- **Circuit breaker**: No evidence found in codebase

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Vouchercloud MongoDB | MongoDB wire protocol | Offer and merchant document reads/writes | `continuumVcMongoDb` |
| Vouchercloud SQL | SQL/TCP | Session, affiliate, and user data reads/writes | `continuumVcSqlDb` |
| Vouchercloud Redis | Redis protocol | Response caching and session persistence | `continuumVcRedisCache` |
| Groupon MessageBus (STOMP) | STOMP 1.0 / TCP | Publishing events to internal Groupon message broker (via `IDL.Api.Client.MessageBus`) | External (STOMP broker) |

## Consumed By

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| `continuumVcWebSite` | HTTP/REST + API key | Consumer-facing vouchercloud website data |
| `continuumWhiteLabelWebSite` | HTTP/REST + API key | White-label partner website data |
| `continuumHoldingPagesWebSite` | HTTP/REST + API key | Country holding page offer previews |
| Mobile apps (iOS / Android) | HTTP/REST + API key | Native mobile app data feed |
| External API partners | HTTP/REST + API key | Public partner integrations |
| Internal services | HTTP/REST + API key | Merchant sync queue and internal tooling |
| ShortStack | HTTPS webhook | User registration via ShortStack campaigns |

> Upstream consumers are also tracked in the central architecture model.

## Dependency Health

- AWS Secrets Manager credentials are fetched at boot time via a PowerShell init script (`.ebextensions/release-set-environment-variables.config`) and set as machine-level environment variables. If Secrets Manager is unreachable at startup, the application fails to start.
- Redis connectivity is required for session management; session reads fall back to SQL if Redis is unavailable (behaviour governed by `ISqlBackedCacheClient`).
- Giftcloud API failures for rewards are captured and published to SNS (`RewardsInitialiseFailed`) for downstream alerting.
- Elastic APM (`Elastic.Apm` 1.29.0) provides distributed tracing to `https://stable-apm.us-central1.logging.stable.gcp.groupondev.com`.
