---
service: "ugc-moderation"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 6
---

# Flows

Process and flow documentation for the UGC Moderation Tool.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Tip Search and Delete](tip-search-and-delete.md) | synchronous | Moderator searches for merchant tips then deletes one or all | Moderator searches tips by merchant/deal/masked name, reviews results, and deletes individual or all tips via the UGC API |
| [Reported Tips Review](reported-tips-review.md) | synchronous | Moderator opens the reported tips page | Fetches flagged tips (action=flag) from the last 30 days and displays them for moderator review and date-range search |
| [Image Moderation](image-moderation.md) | synchronous | Moderator opens the user images page | Searches images by status/merchant/deal/user, then accepts, rejects (with reason), or updates image URLs |
| [Video Moderation](video-moderation.md) | synchronous | Moderator opens the user videos page | Searches user-submitted videos and accepts or rejects them via the UGC API |
| [Review Rating Update](review-rating-update.md) | synchronous | Moderator searches ratings and updates a review score | Searches review ratings by merchant/deal/masked name and updates rating score with case ID and reason |
| [Merchant UGC Transfer](merchant-ugc-transfer.md) | synchronous | Moderator initiates a merchant UGC transfer | Previews UGC data for source and target merchants (tip counts, recommendations), then transfers all UGC associations from old merchant to new merchant |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 6 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

All flows in this service cross into `continuumUgcService` for data retrieval and mutation. The Merchant UGC Transfer flow additionally crosses into `m3_merchant_service` for merchant profile validation. No dynamic architecture views are defined in the DSL at this time.

- [Architecture Context](../architecture-context.md) for container and component relationships
- [Integrations](../integrations.md) for dependency details
