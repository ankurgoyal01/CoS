---
service: "wishlist-service"
title: "User Bucket Enqueue Dequeue"
generated: "2026-03-03"
type: flow
flow_name: "user-bucket-enqueue-dequeue"
flow_type: scheduled
trigger: "Quartz scheduler: UserEnqueueJob (every 5 seconds) and UserDequeueJob (every 2 seconds)"
participants:
  - "wishlistBackgroundJobs"
  - "wishlistPersistenceLayer"
  - "continuumWishlistPostgresRo"
  - "continuumWishlistPostgresRw"
  - "continuumWishlistRedisCluster"
architecture_ref: "components-wishlist-service"
---

# User Bucket Enqueue Dequeue

## Summary

The Wishlist Service uses a bucket-based background processing queue to scale periodic per-user item processing across the worker fleet. Users are partitioned into numbered buckets in PostgreSQL. The `UserEnqueueJob` periodically claims a free bucket, loads its user IDs, and pushes them into a Redis queue. The `UserDequeueJob` pops users from that queue and dispatches each user ID through a chain of registered `UserProcessingTask` implementations (channel update, expiry update, list item processing, bucket number update). This architecture decouples the rate of user ingestion from the rate of user processing.

## Trigger

- **Type**: schedule
- **Source**: Quartz `UserEnqueueJob` (cron `0/5 * * ? * * *`) and `UserDequeueJob` (cron `0/2 * * ? * * *`)
- **Frequency**: Enqueue every 5 seconds; dequeue every 2 seconds

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Background Job Pipeline | Runs both Quartz jobs; chains processing tasks per dequeued user | `wishlistBackgroundJobs` |
| Persistence Layer | Reads user bucket state; writes bucket claim and release; reads/writes user item data | `wishlistPersistenceLayer` |
| Wishlist Postgres RO | Serves user bucket enumeration and item read queries | `continuumWishlistPostgresRo` |
| Wishlist Postgres RW | Stores bucket claim/release state and user processing results | `continuumWishlistPostgresRw` |
| Wishlist Redis Cluster | Acts as the user ID queue (LPUSH/RPOP operations) | `continuumWishlistRedisCluster` |

## Steps

### Enqueue Phase (UserEnqueueJob, every 5 seconds)

1. **Identify free bucket**: `UserEnqueueJob` queries PostgreSQL for a bucket with status `IDLE` (i.e., not currently being processed). Bucket numbers rotate across the full partition range.
   - From: `wishlistBackgroundJobs`
   - To: `wishlistPersistenceLayer` → `continuumWishlistPostgresRo`
   - Protocol: JDBC

2. **Claim the bucket**: Marks the selected bucket as `QUEUEING` in PostgreSQL to prevent concurrent workers from claiming the same bucket.
   - From: `wishlistPersistenceLayer`
   - To: `continuumWishlistPostgresRw`
   - Protocol: JDBC

3. **Load user IDs for bucket**: Fetches all user IDs assigned to this bucket from PostgreSQL. Filters out users with no wishlist activity in the past 12 months (based on `minBucketAge` configuration).
   - From: `wishlistBackgroundJobs`
   - To: `wishlistPersistenceLayer` → `continuumWishlistPostgresRo`
   - Protocol: JDBC

4. **Push user IDs into Redis queue**: Pushes the filtered set of user UUIDs into the Redis list (LPUSH). If the queue is already populated (from a previous cycle that has not been fully consumed), the push is skipped to avoid queue growth.
   - From: `wishlistBackgroundJobs`
   - To: `continuumWishlistRedisCluster`
   - Protocol: Redis

5. **Release the bucket**: After pushing, marks the bucket as `IDLE` again in PostgreSQL so it can be claimed in a future cycle.
   - From: `wishlistPersistenceLayer`
   - To: `continuumWishlistPostgresRw`
   - Protocol: JDBC

### Dequeue Phase (UserDequeueJob, every 2 seconds)

6. **Pop user batch from Redis**: `UserDequeueJob` (annotated `@DisallowConcurrentExecution`) calls `UserIdQueue.pop()` to RPOP a batch of user UUIDs from the Redis list.
   - From: `wishlistBackgroundJobs`
   - To: `continuumWishlistRedisCluster`
   - Protocol: Redis

7. **Fan out to processing tasks**: For each dequeued `userId`, the job sequentially invokes each registered `UserProcessingTask`:
   - `LoggingUserProcessingTask`: Logs the dequeue event for audit/debugging.
   - `ListItemProcessingTask`: Runs the item processor pipeline (expiry notify, channel update, etc.).
   - `UpdateBucketNumbersTask` (optional, if configured): Redistributes users across buckets if bucket numbers need updating.
   - From: `wishlistBackgroundJobs`
   - To: registered `UserProcessingTask` implementations
   - Protocol: direct

8. **Record metrics**: After each user dequeue, the `WishlistSMAMetrics` instance records a `USER_DEQUEUE` counter increment and a `USER_DEQUEUE_TIME` timer measurement. Exceptions are counted via `userTaskExceptionCounter`.
   - From: `wishlistBackgroundJobs`
   - To: `metricsStack` (Wavefront via SMA)
   - Protocol: Metrics

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| No free bucket available | Enqueue job skips this cycle | Next cycle attempts again; no data loss |
| Redis queue unavailable | Exception in `UserEnqueueJob` logged; bucket not claimed | Processing skipped for this cycle |
| User processing task throws exception | Caught in `UserDequeueJob` loop; logged; `userTaskExceptionCounter` incremented | Other users in the batch continue processing |
| `@DisallowConcurrentExecution` on UserDequeueJob | Quartz skips the next trigger if previous execution is still running | Prevents queue thrashing |

## Sequence Diagram

```
[Quartz Scheduler] -> wishlistBackgroundJobs: UserEnqueueJob fires (every 5s)
wishlistBackgroundJobs -> continuumWishlistPostgresRo: SELECT bucket WHERE status=IDLE LIMIT 1
continuumWishlistPostgresRo --> wishlistBackgroundJobs: bucket record
wishlistBackgroundJobs -> continuumWishlistPostgresRw: UPDATE bucket SET status=QUEUEING
wishlistBackgroundJobs -> continuumWishlistPostgresRo: SELECT userId WHERE bucketId=... AND lastActive > (now - 12mo)
continuumWishlistPostgresRo --> wishlistBackgroundJobs: Set<userId>
wishlistBackgroundJobs -> continuumWishlistRedisCluster: LPUSH <userId> ... (filtered users)
wishlistBackgroundJobs -> continuumWishlistPostgresRw: UPDATE bucket SET status=IDLE

[Quartz Scheduler] -> wishlistBackgroundJobs: UserDequeueJob fires (every 2s)
wishlistBackgroundJobs -> continuumWishlistRedisCluster: RPOP batch of userIds
continuumWishlistRedisCluster --> wishlistBackgroundJobs: Set<userId>
loop for each userId
  wishlistBackgroundJobs -> LoggingUserProcessingTask: processUserId(userId)
  wishlistBackgroundJobs -> ListItemProcessingTask: processUserId(userId)
  wishlistBackgroundJobs -> UpdateBucketNumbersTask: processUserId(userId) [if configured]
  wishlistBackgroundJobs -> metricsStack: increment USER_DEQUEUE, record USER_DEQUEUE_TIME
end loop
```

## Related

- Architecture component view: `components-wishlist-service`
- Related flows: [Background Item Expiry Notification](background-expiry-notification.md)
