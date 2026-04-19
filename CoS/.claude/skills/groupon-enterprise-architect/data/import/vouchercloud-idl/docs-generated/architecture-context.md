---
service: "vouchercloud-idl"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: [continuumVcApi, continuumRestfulApi, continuumVcWebSite, continuumWhiteLabelWebSite, continuumHoldingPagesWebSite, continuumVcMongoDb, continuumVcSqlDb, continuumVcRedisCache]
---

# Architecture Context

## System Context

Vouchercloud IDL is a set of containers within the `continuumSystem` (Continuum Platform). It exposes two distinct API surfaces — the internal Vouchercloud API (`continuumVcApi`) and the public-partner Restful API (`continuumRestfulApi`) — both backed by shared MongoDB, SQL Server, and Redis data stores. Three web-tier containers (`continuumVcWebSite`, `continuumWhiteLabelWebSite`, `continuumHoldingPagesWebSite`) consume the internal API and serve consumer traffic. The system integrates with several external services (Algolia, Giftcloud, AWS SNS/SQS, EagleEye Air, Wolfhound) for search, rewards, notifications, and analytics.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Vouchercloud Web | `continuumVcWebSite` | WebApp | ASP.NET MVC (.NET Framework) | 4.7.2 | Consumer-facing vouchercloud v3 web application |
| Vouchercloud White Label | `continuumWhiteLabelWebSite` | WebApp | ASP.NET MVC (.NET Framework) | 4.7.2 | White-label vouchercloud web application for partner brands |
| Vouchercloud Holding Pages | `continuumHoldingPagesWebSite` | WebApp | ASP.NET MVC (.NET Framework) | 4.7.2 | Country-specific holding pages for vouchercloud |
| Vouchercloud API | `continuumVcApi` | Backend | ASP.NET Web API (.NET Framework) | 4.7.2 | Core API for offers, users, rewards, and sessions |
| Vouchercloud Restful API | `continuumRestfulApi` | Backend | ASP.NET Web API (.NET Framework) / ServiceStack 4.0.48 | 4.7.2 | Public/partner REST API for vouchercloud |
| Vouchercloud MongoDB | `continuumVcMongoDb` | Database | MongoDB | 2.26.0 driver | Primary document store for offers, merchants, and content |
| Vouchercloud SQL | `continuumVcSqlDb` | Database | SQL Server | — | Relational data store for sessions and affiliate data |
| Vouchercloud Redis | `continuumVcRedisCache` | Cache | Redis | 2.6.48 client | Cache and session store |

## Components by Container

### Vouchercloud Restful API (`continuumRestfulApi`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| OfferService | Serves offer listings, details, search, featured, expiring, popular, community codes | ServiceStack Service |
| MerchantService | Serves merchant listings, details, branches, similar merchants | ServiceStack Service |
| UserService | User profile reads, push preferences, feedback, closed-loop offers | ServiceStack Service |
| AuthenticationService | Email/password, Facebook, Google, Apple Sign-In authentication | ServiceStack Auth |
| UserOffersService | User wallet: save, redeem, remove, history | ServiceStack Service |
| UserRewardsService | Reward initialisation, redemption, Giftcloud claim, CloudCoins | ServiceStack Service |
| AffiliateService | Affiliate redirect, click tracking, purchase attribution | ServiceStack Service |
| CategoryService | Offer and merchant category listings | ServiceStack Service |
| EmailService | Email template and offer content for newsletters | ServiceStack Service |
| CompetitionService | Competition details, entry, analytics | ServiceStack Service |
| GenieService | All-merchants-by-country data feed | ServiceStack Service |
| SyncQueueService | Merchant sync queue insert/acquire/resolve/fail/recover | ServiceStack Service |
| WebhookService | ShortStack webhook ingestion for user registration | ServiceStack Service |
| MessageBus Producer | Publishes events to Groupon STOMP message broker (Thrift-encoded) | Stomp.Net + Apache Thrift |
| ApiKeyAuthorisation | API key validation and owner matching | ServiceStack Filter |
| VouchercloudAuthProvider | Credential-based session authentication | ServiceStack AuthProvider |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumVcWebSite` | `continuumVcApi` | Uses for offers, user, and session data | HTTP/REST |
| `continuumWhiteLabelWebSite` | `continuumVcApi` | Uses for offers and merchant data | HTTP/REST |
| `continuumHoldingPagesWebSite` | `continuumVcApi` | Uses for offer previews and landing data | HTTP/REST |
| `continuumVcApi` | `continuumVcMongoDb` | Reads/Writes offers and merchant documents | MongoDB wire protocol |
| `continuumVcApi` | `continuumVcSqlDb` | Reads/Writes session and affiliate data | SQL/TCP |
| `continuumVcApi` | `continuumVcRedisCache` | Caches responses and loads sessions | Redis protocol |
| `continuumRestfulApi` | `continuumVcMongoDb` | Reads/Writes offers and merchant documents | MongoDB wire protocol |
| `continuumRestfulApi` | `continuumVcSqlDb` | Reads/Writes session and affiliate data | SQL/TCP |
| `continuumRestfulApi` | `continuumVcRedisCache` | Caches responses and loads sessions | Redis protocol |

## Architecture Diagram References

- System context: `contexts-vouchercloud-idl`
- Container: `containers-vouchercloud-idl`
- Component: `components-vouchercloud-idl`
