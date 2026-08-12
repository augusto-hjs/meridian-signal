# Runbook — Meridian Signal

## Prerequisites
- n8n (Cloud or self-hosted) with the LangChain/AI nodes
- Supabase project
- OpenAI API key

## Setup
1. Copy `.env.example` → `.env` and fill `OPENAI_API_KEY`, `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`.
2. Run [`database/schema.sql`](../database/schema.sql) in Supabase.
3. Import `workflows/meridian-signal.json` into n8n; set the OpenAI + Supabase credentials.
4. (Optional) adjust the Schedule Trigger cadence.

## Running & verifying statefulness
1. **Run once** — all seed items are new → a digest is written and items are stored.
   - `select item_count, left(digest_md, 120) from signal_digests order by id desc limit 1;`
   - `select count(*) from signal_items;`
2. **Run again** — no new items → `Select New` returns 0, no digest is written, no model call is made.
3. **Add an item** to [`sources/feed.json`](../sources/feed.json) (new `id`) and re-run → only that item is summarized and stored.

## Observability
- Seen items: `select source, title, published from signal_items order by published desc;`
- Digests: `select id, item_count, created_at from signal_digests order by id desc;`

## Troubleshooting
| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| Every run re-digests everything | `external_id` not stable across runs | Ensure the source id is deterministic |
| No digest on first run | fetch failed or feed empty | Check the Fetch Sources node output |
| Context-limit error on digest | too many new items at once | Window the digest by source or date |
