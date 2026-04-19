---
service: "marketing-and-editorial-content-service"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 5
---

# Flows

Process and flow documentation for the Marketing and Editorial Content Service.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Image Upload and Storage](image-upload-and-storage.md) | synchronous | POST /mecs/image with multipart image file | Client uploads a binary image; MECS forwards to GIMS, stores metadata in PostgreSQL, and returns the created record |
| [Text Content Create with Profanity Check](text-content-create.md) | synchronous | POST /mecs/text | Client submits text content; MECS validates for profanity before persisting to PostgreSQL |
| [Content Search and Retrieval](content-search-and-retrieval.md) | synchronous | GET /mecs/image or GET /mecs/text | Client queries content records with filters and pagination; MECS routes reads to the read replica |
| [JSON Patch Partial Update](json-patch-update.md) | synchronous | PATCH /mecs/image/{uuid} or PATCH /mecs/text/{uuid} | Client applies RFC 6902 JSON Patch operations to a content record; supports dry-run mode |
| [Content Delete with Audit](content-delete.md) | synchronous | DELETE /mecs/image/{uuid} or DELETE /mecs/text/{uuid} | Client deletes a content record; MECS writes an audit record before removing the row |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 5 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

The image upload flow spans MECS and the Global Image Service (`gims`). The outbound call to `POST https://img.grouponcdn.com/v1/upload` is the only cross-service interaction. All other flows are self-contained within MECS and its owned PostgreSQL database.
