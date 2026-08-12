# Design Decisions (ADR-lite) — Meridian Signal

## ADR-001: Keep state so the monitor is quiet by default

- **Context.** A monitor that re-reports everything every run is noise and cost.
- **Decision.** Persist a stable `external_id` per source item and process only items not already in `signal_items`.
- **Consequence.** Runs are quiet unless there's genuinely something new; spend tracks *new* volume, not corpus size. Trade-off: sources must provide (or allow deriving) a stable id.

## ADR-002: One LLM call per run, over the new batch

- **Context.** Summarization is the only paid step.
- **Options.** One call per item vs one call for the whole new batch vs re-summarize everything each run.
- **Decision.** Aggregate the new items and summarize them in a single call.
- **Consequence.** A no-new-items run costs $0 on the model; a busy run is one call. Trade-off: very large batches could hit context limits — then window by source/time.

## ADR-003: Idempotent persistence in the database

- **Context.** Retries and overlapping runs can re-insert the same item.
- **Decision.** `external_id` unique + a `BEFORE INSERT` trigger that turns a duplicate into a no-op (same pattern as the other Meridian projects).
- **Consequence.** Persistence is safe under retries; dedup is enforced centrally, not trusted to the workflow.

## ADR-004: Store the digest instead of hard-wiring a channel

- **Context.** Delivery targets differ per team (email, Slack, Notion).
- **Decision.** Write the digest to `signal_digests`; leave channel delivery as a thin last step.
- **Consequence.** The core is channel-agnostic and testable; adding Slack/email is a one-node change. Trade-off: this repo stops at the stored digest (the contract), not a specific inbox.
