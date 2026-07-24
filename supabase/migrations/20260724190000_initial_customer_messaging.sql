-- Schmidt Tuning System
-- Initial schema: customers, vehicles and WhatsApp communication
-- Generated 2026-07-24

create extension if not exists pgcrypto;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create table public.customers (
  id uuid primary key default gen_random_uuid(),
  whatsapp_wa_id text unique,
  phone_e164 text unique,
  display_name text,
  first_name text,
  last_name text,
  company_name text,
  email text,
  notes text,
  source text not null default 'whatsapp'
    check (source in ('whatsapp', 'phone', 'email', 'website', 'manual', 'other')),
  privacy_notice_sent_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.vehicles (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references public.customers(id) on delete cascade,
  vin text unique,
  license_plate text,
  manufacturer text,
  model text,
  model_year integer check (model_year between 1900 and 2200),
  engine_code text,
  engine_displacement_cc integer,
  fuel_type text,
  transmission_code text,
  ecu_type text,
  current_mileage_km integer check (current_mileage_km >= 0),
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index vehicles_customer_id_idx on public.vehicles(customer_id);
create index vehicles_license_plate_idx on public.vehicles(license_plate);

create table public.conversations (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references public.customers(id) on delete cascade,
  vehicle_id uuid references public.vehicles(id) on delete set null,
  channel text not null default 'whatsapp'
    check (channel in ('whatsapp', 'phone', 'email', 'website', 'other')),
  status text not null default 'open'
    check (status in ('open', 'waiting_customer', 'waiting_business', 'closed')),
  subject text,
  last_message_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index conversations_customer_id_idx on public.conversations(customer_id);
create index conversations_status_idx on public.conversations(status);
create index conversations_last_message_at_idx on public.conversations(last_message_at desc);

create table public.messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  customer_id uuid not null references public.customers(id) on delete cascade,
  external_message_id text unique,
  direction text not null check (direction in ('inbound', 'outbound')),
  message_type text not null default 'text',
  body text,
  media_id text,
  media_mime_type text,
  media_filename text,
  message_timestamp timestamptz,
  received_at timestamptz not null default now(),
  delivery_status text,
  raw_payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index messages_conversation_id_idx on public.messages(conversation_id);
create index messages_customer_id_idx on public.messages(customer_id);
create index messages_message_timestamp_idx on public.messages(message_timestamp desc);

create trigger customers_set_updated_at
before update on public.customers
for each row execute function public.set_updated_at();

create trigger vehicles_set_updated_at
before update on public.vehicles
for each row execute function public.set_updated_at();

create trigger conversations_set_updated_at
before update on public.conversations
for each row execute function public.set_updated_at();

alter table public.customers enable row level security;
alter table public.vehicles enable row level security;
alter table public.conversations enable row level security;
alter table public.messages enable row level security;

revoke all on table public.customers from anon, authenticated;
revoke all on table public.vehicles from anon, authenticated;
revoke all on table public.conversations from anon, authenticated;
revoke all on table public.messages from anon, authenticated;

grant usage on schema public to service_role;
grant all on table public.customers to service_role;
grant all on table public.vehicles to service_role;
grant all on table public.conversations to service_role;
grant all on table public.messages to service_role;
grant usage, select on all sequences in schema public to service_role;

comment on table public.customers is 'Schmidt Tuning customer master data';
comment on table public.vehicles is 'Vehicles assigned to customers';
comment on table public.conversations is 'Customer conversations by communication channel';
comment on table public.messages is 'Inbound and outbound messages including original Meta payload';
