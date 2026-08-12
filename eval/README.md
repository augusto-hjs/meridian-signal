# Eval — Meridian Signal

Signal's correctness is about **statefulness**, so the check is behavioral rather than a labeled dataset:

## The statefulness test

1. **Run 1 (cold):** with an empty `signal_items`, a run over the seed feed should:
   - insert all feed items into `signal_items`, and
   - write exactly one `signal_digests` row with `item_count = <feed length>`.
2. **Run 2 (warm, no changes):** immediately re-run. It should:
   - insert **0** new items, and
   - write **no** new digest, and
   - make **no** LLM call (cost = $0).
3. **Run 3 (one new item):** add a single item (new `id`) to `sources/feed.json` and re-run. It should:
   - insert exactly **1** item, and
   - write one digest with `item_count = 1` covering only that item.

## Checks (SQL)

```sql
select count(*) from signal_items;                       -- grows only when new items appear
select id, item_count, created_at from signal_digests;   -- one row per run that had new items
```

Pass = the counts match the expectations above across the three runs. This proves dedup, quiet-by-default behavior, and cost control.
