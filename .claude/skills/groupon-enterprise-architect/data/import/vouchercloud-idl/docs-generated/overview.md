---
service: "vouchercloud-idl"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Global Coupons"
platform: "Continuum"
team: "Global Coupons"
status: active
tech_stack:
  language: "C#"
  language_version: ".NET Framework 4.7.2"
  framework: "ServiceStack"
  framework_version: "4.0.48"
  runtime: ".NET Framework"
  runtime_version: "4.7.2"
  build_tool: "MSBuild"
  package_manager: "NuGet"
---

# Vouchercloud IDL Overview

## Purpose

Vouchercloud IDL (Invitation Digital Limited) is Groupon's Global Coupons API platform that powers the vouchercloud discount/coupon product across multiple countries and brands. It provides a REST API for offers, merchants, user accounts, rewards (Giftcloud integration), affiliate tracking, and content to the vouchercloud consumer website, white-label partners, mobile apps, and external API partners. The system also ships a MessageBus client library (`IDL.Api.Client.MessageBus`) enabling event publishing over Groupon's STOMP-based message broker.

## Scope

### In scope
- Serving offer and merchant data to consumer-facing web and mobile clients (vouchercloud.com and white-label sites)
- User registration, authentication (email/password, Facebook, Google, Apple Sign-In), and session management
- User wallet management: saving, redeeming, and tracking offers
- Rewards lifecycle: initialising, claiming, and downloading rewards via Giftcloud API
- Affiliate link generation, click tracking, and purchase attribution (SkimLinks, EagleEye Air)
- Search over offers and merchants via Algolia
- Email content delivery for newsletter/promotional campaigns
- Competition entry and analytics
- Merchant sync queue management (internal service-to-service API)
- Webhook ingestion from ShortStack for user registration flows
- Publishing analytics events to AWS SQS/SNS (offer rejection, community codes, user feedback, rewards failures)
- Country-specific configuration for 18+ markets (GB, US, AU, DE, FR, IE, IT, NL, NZ, CA, BR, AE, CZ, ES, IN, MT, PL, ZA)
- MessageBus producer client (STOMP/Thrift) shipped as a NuGet library

### Out of scope
- Payment processing (handled by other Continuum services)
- Deal creation and merchant onboarding (handled by merchant-facing tools)
- Groupon core commerce flows (order processing, inventory)
- ControlCloud internal admin API (separate sub-project within the same repo)

## Domain Context

- **Business domain**: Global Coupons
- **Platform**: Continuum (Groupon's commerce engine)
- **Upstream consumers**: Vouchercloud Web (`continuumVcWebSite`), Vouchercloud White Label (`continuumWhiteLabelWebSite`), Vouchercloud Holding Pages (`continuumHoldingPagesWebSite`), mobile apps (iOS/Android), external API partners, internal services via API key
- **Downstream dependencies**: MongoDB (offers/merchants), SQL Server (sessions/affiliates), Redis (caching/sessions), Algolia (search), Giftcloud API (rewards), AWS SNS (notifications), AWS SQS (analytics events), AWS Secrets Manager (credentials), AWS CloudWatch (metrics), Wolfhound API (Groupon platform integration), EagleEye Air (loyalty/promotions), Blueshift (CRM), Google Analytics

## Stakeholders

| Role | Description |
|------|-------------|
| Team Owner | Global Coupons (c_marustamyan) |
| Tech Leads | vc-techleads@groupon.com |
| SRE / Alerts | vc-alerts@groupondev.opsgenie.net |
| PagerDuty | https://groupon.pagerduty.com/services/PZGV3HD |
| Members | ijohansson, japage, marcgarcia, mkanavakatini, rbracken, rdownes, c-jsutak, c-mufnal |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | C# | .NET Framework 4.7.2 | `IDL.Api.Restful/Web.config` (`targetFramework="4.7.2"`) |
| Framework | ServiceStack | 4.0.48 | `IDL.Api.Restful/packages.config` |
| Runtime | .NET Framework | 4.7.2 | `IDL.Api.Restful/Web.config` |
| Build tool | MSBuild | — | `Build.proj` |
| Package manager | NuGet | — | `packages.config` files throughout |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| ServiceStack | 4.0.48 | http-framework | REST API hosting, routing, auth, serialisation |
| MongoDB.Driver | 2.26.0 | db-client | Primary document store access (offers, merchants) |
| Dapper | 2.0.78 | db-client | SQL Server micro-ORM for sessions and affiliate data |
| StackExchange.Redis | 2.6.48 | db-client | Redis cache and session store client |
| Algolia.Search | 7.34.0 | http-framework | Offer and merchant search |
| Coupons.GiftcloudApiClient | 2.9.0 | http-framework | Rewards integration (Giftcloud) |
| Polly | 7.2.2 | http-framework | Resilience and retry policies |
| Elastic.Apm | 1.29.0 | metrics | Distributed tracing via Elastic APM |
| NLog | 4.6.8 | logging | Structured application logging (file, Papertrail, ECS) |
| AWSSDK.SimpleNotificationService | 3.7.0.12 | message-client | SNS event publishing (offer rejection, community codes) |
| AWSSDK.SQS | 3.7.2.63 | message-client | SQS analytics event queue |
| AWSSDK.SecretsManager | 3.7.0.11 | auth | Runtime credential retrieval |
| Microsoft.IdentityModel.JsonWebTokens | 7.6.0 | auth | JWT validation for Apple Sign-In |
| RestSharp | 106.15.0 | http-framework | Outbound HTTP client (Wolfhound, Blueshift integrations) |
| Newtonsoft.Json | 13.0.3 | serialization | JSON serialisation |
