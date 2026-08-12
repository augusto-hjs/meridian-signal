-- Meridian Signal — scheduled competitive/industry monitor with dedup + digests.
create table if not exists public.signal_items (
  id           bigint generated always as identity primary key,
  external_id  text unique,               -- dedup key (source item id)
  source       text,
  title        text,
  url          text,
  published    date,
  created_at   timestamptz not null default now()
);

create table if not exists public.signal_digests (
  id           bigint generated always as identity primary key,
  item_count   int not null default 0,
  digest_md    text,
  created_at   timestamptz not null default now()
);

-- Dedup: a repeated external_id is a silent no-op, so re-scans never
-- re-store (or re-summarize) an item that was already seen.
create or replace function public.signal_items_skip_duplicate()
returns trigger language plpgsql set search_path = '' as $$
begin
  if new.external_id is not null
     and exists (select 1 from public.signal_items s where s.external_id = new.external_id) then
    return null;
  end if;
  return new;
end;
$$;
drop trigger if exists signal_items_skip_duplicate_trg on public.signal_items;
create trigger signal_items_skip_duplicate_trg
  before insert on public.signal_items
  for each row execute function public.signal_items_skip_duplicate();

alter table public.signal_items   enable row level security;
alter table public.signal_digests enable row level security;
